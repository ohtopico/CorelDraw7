REM  This script will edit the applications available from the application launcher
REM  "AppLEd.csc"  for Version 7.0 made June 20, 1996
REM  A copy of Corelapp.ini named Corelapp.bak is created automatically
REM  Copyright 1996 Corel Corporation. All rights reserved.

#INCLUDE "ScpConst.csi"
#define AppReg "SOFTWARE\corel\CORELDRAW\7.0"

' Constants
GLOBAL CONST APPS_CATEGORY$ = "[Applications]"
GLOBAL CONST APPINCR%=25

' Globals
GLOBAL MaxNApp%
MaxNApp%=APPINCR%
GLOBAL AppName$(MaxNApp%), AppPath$(MaxNApp%), NumberOfApps%

' Main Dialog
BEGIN DIALOG OBJECT Dialog1 308, 165, "Application Launcher Editor", SUB Dialog1Sub
	LISTBOX  6, 8, 143, 148, .AppList
	OKBUTTON  216, 143, 40, 14, .OK1
	CANCELBUTTON  260, 143, 40, 14, .Cancel1
	TEXT  162, 8, 118, 8, .AppNameText, "Application Name:"
	TEXTBOX  160, 17, 140, 13, .AppName
	TEXT  162, 43, 127, 8, .PathText, "Application Path:"
	TEXTBOX  160, 52, 140, 13, .AppPath
	PUSHBUTTON  160, 96, 140, 14, .AddApp, "Add New Application"
	PUSHBUTTON  160, 116, 140, 14, .RemoveApp, "Remove Application"
	PUSHBUTTON  253, 69, 46, 14, .Browse, "Browse"
END DIALOG

'First, find the INI file
GLOBAL ConfigDir AS STRING
ConfigDir$ = REGISTRYQUERY(HKEY_LOCAL_MACHINE%,AppReg,"ConfigDir")

'Add trailing '\' if absent
IF LEFT$(ConfigDir$,1) <> "\" THEN ConfigDir$ = ConfigDir$ + "\"

'Open the file
OPEN ConfigDir$ + "Corelapp.ini" FOR INPUT AS 1

'Read data until category header is found
DIM ReadData AS STRING
DO 
	INPUT #1, ReadData$
LOOP UNTIL EOF(1) OR ReadData$ = APPS_CATEGORY$

' If we're not at the end, then read applications until another category is found.
DIM EqualPos AS LONG
IF NOT EOF(1) THEN
	DO
		INPUT #1, ReadData$
		EqualPos = INSTR(ReadData$,"=")
		IF EqualPos <> 0 THEN
			NumberOfApps% = NumberOfApps% + 1
			IF(NumberOfApps%>MaxNApp%) THEN
			  ' Increase size of App array
				MaxNApp%=MaxNApp%+APPINCR%
			  REDIM PRESERVE AppName$(MaxNApp%)
			  REDIM PRESERVE AppPath$(MaxNApp%)
		  ENDIF
			AppName$(NumberOfApps%) = LEFT$(ReadData$,EqualPos - 1)
			AppPath$(NumberOfApps%) = MID$(ReadData$,EqualPos+1) ' Skip the =
		ENDIF
	LOOP UNTIL EOF(1) OR LEFT(ReadData$, 1) = "["
ENDIF

CLOSE

' Edit the applications list
DIM DialogReturnVal AS INTEGER
DialogReturnVal% = DIALOG(Dialog1)

' End program on cancel
IF DialogReturnVal% = MSG_CANCEL% THEN END

' Keep a backup file
RENAME ConfigDir$ + "Corelapp.ini", ConfigDir$ + "Corelapp.bak"

' Open input and output files
OPEN ConfigDir$ + "Corelapp.bak" FOR INPUT AS 1
OPEN ConfigDir$ + "Corelapp.ini" FOR OUTPUT AS 2

'Read data until category header is found, copying it to the output file
DO 
	INPUT #1, ReadData$
	PRINT #2, ReadData$
LOOP UNTIL EOF(1) OR ReadData$ = APPS_CATEGORY$

' If there was no Applications category, we must create one.
IF ReadData$ <> APPS_CATEGORY$ THEN
	'Skip a line
	PRINT #2, ""
	PRINT #2, APPS_CATEGORY$
ENDIF

' If we're not at the end, then read applications until another category is found.
IF NOT EOF(1) THEN
	DO
		INPUT #1, ReadData$
	LOOP UNTIL EOF(1) OR LEFT(ReadData$, 1) = "["
ELSE
	' So as to not duplicate anything
	ReadData$ = ""
ENDIF

'Now, write the new applications to the file
DIM X AS INTEGER
FOR X% = 1 TO NumberOfApps%
	PRINT #2, AppName$(X%) + "=" + AppPath$(X%)
NEXT X%

'Finally, write the rest of the data

'Skip a line
PRINT #2, ""

'Write the category
PRINT #2, ReadData$

' Write left over
DO UNTIL EOF(1)
	INPUT #1, ReadData$
	PRINT #2, ReadData$
LOOP

'Close files
CLOSE

'End the program
END

'Event handler for main dialog.
SUB Dialog1Sub(BYVAL ControlID%, BYVAL Event%)
	DIM Selection AS INTEGER
	DIM X AS INTEGER
	DIM Filename AS STRING

	Selection% = Dialog1.AppList.GetSelect()
	SELECT CASE Event%
		CASE EVENT_INITIALIZATION
			Dialog1.AppList.SetArray AppName$

		CASE EVENT_MOUSE_CLICK
			SELECT CASE ControlID%
				CASE Dialog1.AppList.GetID()
					IF Selection% <> 0 THEN
						'Change the text boxes according to the selection
						Dialog1.AppName.SetText(AppName$(Selection%))
						Dialog1.AppPath.SetText(AppPath$(Selection%))
					ENDIF
				CASE Dialog1.AddApp.GetID()
					'Add a new application
					NumberOfApps% = NumberOfApps% + 1
					AppName$(NumberOfApps%) = "<New App>"
					AppPath$(NumberOfApps%) = "<New App>"
					Dialog1.AppList.AddItem AppName$(NumberOfApps%), NumberOfApps%
					Dialog1.AppList.SetSelect(NumberOfApps%)
					Dialog1.AppName.SetText(AppName$(NumberOfApps%))
					Dialog1.AppPath.SetText(AppPath$(NumberOfApps%))
					' Necessary for control enabling
					Selection% = NumberOfApps%
				CASE Dialog1.RemoveApp.GetID()
					IF Selection% <> 0 THEN
						Selection% = Dialog1.AppList.GetSelect()
						'Cycle through the array, replacing each element with the next,
						'starting with the deleted one
						FOR X% = Selection% TO NumberOfApps% - 1				
							AppName$(X) = AppName$(X + 1)
							AppPath$(X) = AppPath$(X + 1)
						NEXT X%
						'Delete the last element
						AppName$(NumberOfApps%) = ""
						AppPath$(NumberOfApps%) = ""
						'Remove the item from the list
						Dialog1.AppList.RemoveItem(Selection%)
						'Decrement the Applications count
						NumberOfApps% = NumberOfApps% - 1
						'Reset the selection
						IF Selection% > NumberOfApps% THEN
							Selection% = NumberOfApps%
						ENDIF
						Dialog1.AppList.SetSelect(Selection%)
						Dialog1.AppName.SetText(AppName$(Selection%))
						Dialog1.AppPath.SetText(AppPath$(Selection%))
					ENDIF
				CASE Dialog1.Browse.GetID()
					IF Selection% <> 0 THEN
						Filename$ = GETFILEBOX("Program Files (*.exe)|*.exe", "Choose an application for " + AppName$(Selection%))
						IF Filename$ <> "" THEN
							AppPath$(Selection%) = FileName$
							Dialog1.AppPath.SetText(FileName$)
						ENDIF
					ENDIF
			END SELECT

		CASE EVENT_CHANGE_IN_CONTENT
			SELECT CASE ControlID%
				CASE Dialog1.AppName.GetID()
					IF Selection% <> 0 THEN
						' Change the name both in the array and in the list box
						AppName$(Selection%) = Dialog1.AppName.GetText()
						Dialog1.AppList.RemoveItem(Selection%)
						Dialog1.AppList.AddItem AppName$(Selection%),Selection%
						Dialog1.AppList.SetSelect(Selection%)
					ENDIF
				CASE Dialog1.AppPath.GetID()
					IF Selection% <> 0 THEN
						'Change the name in the array.
						AppPath$(Selection%) = Dialog1.AppPath.GetText()
					ENDIF
			END SELECT
	END SELECT

	'Enable/disable controls
	IF Selection% = 0 THEN
		Dialog1.AppName.SetText("")
		Dialog1.AppPath.SetText("")
		Dialog1.AppName.Enable FALSE
		Dialog1.AppPath.Enable FALSE
		Dialog1.RemoveApp.Enable FALSE
		Dialog1.Browse.Enable FALSE
	ELSE
		Dialog1.AppName.Enable TRUE
		Dialog1.AppPath.Enable TRUE
		Dialog1.RemoveApp.Enable TRUE
		Dialog1.Browse.Enable TRUE
	ENDIF

END SUB
		
