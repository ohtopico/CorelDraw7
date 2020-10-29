REM Creates Header in current script
REM Copyright 1996 Corel Corporation. All rights reserved.

' Defines
#define IDOK  1
#define IDCANCEL  2

'  Adds Specified header info
sub WriteHeader(Name as string, Desc as string)
	DIM DateStamp AS DATE
	DateStamp=CDAT(Fix(GetCurrDate()))
	withobject "CorelScript.automation.7"
		.GotoLine 1
		.AddLineBefore "' " + Desc
		.AddLineBefore "' " + Name + "  for v7.0, made " + str(DateStamp) 
	end withobject
end sub

'####################################################################
' Main section
DIM Name AS STRING
DIM Desc AS STRING
BEGIN DIALOG Header 199, 92, "Header Maker" ' Ask for header name and description
	TEXT  5, 5, 105, 10, "Script Name"
	TEXTBOX  5, 15, 190, 15, Name$
	TEXT  5, 35, 75, 10, "Description"
	TEXTBOX  5, 45, 190, 15, Desc$
	OKBUTTON  50, 70, 40, 14
	CANCELBUTTON  110, 70, 40, 14
END DIALOG
if (dialog(Header)=IDOK) then WriteHeader Name$, Desc$




