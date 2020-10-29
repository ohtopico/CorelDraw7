REM Runs programs at specified intervals
REM Schedule.csc  April 26, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

REM ***************************************************************
REM * Global Data                                                 *
REM ***************************************************************

'Standard constants
#include "ScpConst.csi"
DIM DATFOL$
DATFOL$=GetCurrFolder()

'Maximum number of events
#define MAX_EVENTS 100

'Global variables
GLOBAL Days$(7)
GLOBAL Months$(12)
GLOBAL CurrentYear$ AS STRING
GLOBAL CurrentMonth$
GLOBAL SelectedYear%
GLOBAL SelectedMonthIndex%
GLOBAL EventData(MAX_EVENTS, 6) AS VARIANT
GLOBAL ScheduledEvent$(MAX_EVENTS)
GLOBAL NumberOfEvents%
GLOBAL CurrentDay%

'Date formats
GLOBAL CONST DayNumeric$ = "dd"
GLOBAL CONST DayFormat$ = "dddd"
GLOBAL CONST MonthFormat$ = "MMMM"
GLOBAL CONST MonthNumeric$ = "MM"
GLOBAL CONST YearFormat$ = "yyyy"

REM ***************************************************************
REM * Main Dialog                                                 *
REM ***************************************************************
BEGIN DIALOG OBJECT MainDialog 447, 142, "Corel SCRIPT Scheduler", SUB MainDialogSub
	LISTBOX  6, 7, 432, 111, .MainList
	PUSHBUTTON  11, 124, 65, 14, .AddEvent, "Add Event"
	PUSHBUTTON  99, 124, 65, 14, .RemoveEvent, "Remove Event"
	PUSHBUTTON  188, 124, 65, 14, .EditEvent, "Edit Event"
	PUSHBUTTON  276, 124, 65, 14, .ExecuteEvent, "Execute Event"
	PUSHBUTTON  365, 124, 65, 14, .ExitButton, "Exit"
END DIALOG

REM ***************************************************************
REM * Event scheduling Dialog                                     *
REM ***************************************************************
BEGIN DIALOG OBJECT ScheduleEvent 264, 276, "Schedule Event", SUB ScheduleEventSub
	OPTIONGROUP .ScheduleOption
		OPTIONBUTTON  10, 47, 62, 10, .ScheduleOnce, "Schedule Once"
		OPTIONBUTTON  10, 119, 66, 11, .ScheduleHourly, "Schedule Hourly"
		OPTIONBUTTON  10, 163, 62, 10, .ScheduleDaily, "Schedule Daily"
		OPTIONBUTTON  10, 207, 69, 10, .ScheduleMonthly, "Schedule Monthly"
	GROUPBOX  6, 0, 250, 38, .ProgramGroup, "Program"
	TEXTBOX  20, 13, 180, 13, .ProgramFile
	PUSHBUTTON  203, 13, 46, 14, .BrowseButton, "Browse"
	GROUPBOX  5, 38, 165, 72, .OnceGroup
	TEXT  10, 62, 13, 8, .OnceON, "On"
	DDLISTBOX  25, 61, 47, 77, .OnceMonth
	SPINCONTROL  122, 61, 44, 12, .OnceYear
	TEXT  109, 65, 13, 8, .OnceTH, "th,"
	SPINCONTROL  74, 61, 34, 12, .OnceDay
	TEXT  15, 90, 10, 8, .OnceAT, "At"
	SPINCONTROL  25, 88, 23, 12, .OnceHour
	TEXT  49, 89, 5, 9, .OnceCOLON, ":"
	SPINCONTROL  55, 88, 23, 12, .OnceMinutes
	OPTIONGROUP .OnceOption
		OPTIONBUTTON  89, 82, 28, 10, .OnceAM, "AM"
		OPTIONBUTTON  89, 95, 28, 10, .OncePM, "PM"
	GROUPBOX  5, 110, 165, 42, .HourlyGroup
	TEXT  19, 137, 9, 8, .HourlyAT, "At"
	SPINCONTROL  31, 135, 23, 12, .HourlyMinutes
	TEXT  55, 137, 72, 8, .HourlyAFTER, "Minutes after the Hour"
	GROUPBOX  5, 152, 165, 46, .DailyGroup
	TEXT  14, 177, 10, 8, .DailyAT, "At"
	SPINCONTROL  25, 175, 23, 12, .DailyHour
	TEXT  48, 175, 5, 9, .DailyCOLON, ":"
	SPINCONTROL  54, 175, 23, 12, .DailyMinutes
	OPTIONGROUP .DailyOption
		OPTIONBUTTON  86, 169, 28, 10, .DailyAM, "AM"
		OPTIONBUTTON  86, 181, 28, 10, .DailyPM, "PM"
	GROUPBOX  5, 198, 165, 71, .MonthlyGroup
	TEXT  11, 223, 19, 8, .MonthlyEVERY, "Every"
	SPINCONTROL  32, 221, 31, 12, .MonthlyDay
	TEXT  65, 223, 10, 8, .MonthlyTH, "th"
	TEXT  75, 223, 50, 8, .MonthlyOF, "of the month"
	TEXT  14, 250, 10, 8, .MonthlyAT, "At"
	SPINCONTROL  25, 248, 23, 12, .MonthlyHour
	TEXT  48, 248, 5, 9, .MonthlyCOLON, ":"
	SPINCONTROL  54, 248, 23, 12, .MonthlyMinutes
	OPTIONGROUP .MonthlyOption
		OPTIONBUTTON  86, 242, 28, 10, .MonthlyAM, "AM"
		OPTIONBUTTON  86, 254, 28, 10, .MonthlyPM, "PM"
	GROUPBOX  174, 38, 82, 98, .DaysGroup, "Execute only on days"
	CHECKBOX  182, 51, 64, 9, .MondayBox, "Monday"
	CHECKBOX  182, 62, 64, 9, .TuesdayBox, "Tuesday"
	CHECKBOX  182, 74, 64, 9, .WednesdayBox, "Wednesday"
	CHECKBOX  182, 86, 64, 9, .ThursdayBox, "Thursday"
	CHECKBOX  182, 97, 64, 9, .FridayBox, "Friday"
	CHECKBOX  182, 109, 64, 9, .SaturdayBox, "Saturday"
	CHECKBOX  182, 121, 64, 9, .SundayBox, "Sunday"
	OKBUTTON  176, 232, 77, 14, .OK1
	CANCELBUTTON  176, 253, 77, 14, .Cancel1
END DIALOG

REM ***************************************************************
REM * Initialization: determines the names of the months and      *
REM * days.                                                       *
REM ***************************************************************
SUB Initialize()
DIM StartDate AS DATE
	DIM i AS INTEGER
	DIM x AS DOUBLE
	DIM y AS DOUBLE

	StartDate = 29221		'Jan 1 1980

	'Initialize 12 months
	i% = 0
	FOR x# = 1 TO 365 STEP 31
		i% = i% + 1
		Months$(i%) = FORMATDATE(StartDate + x#, MonthFormat$)
	NEXT x#

	'Initialize 7 days
	FOR y# = 1 TO 7
		Days$(y#) = FORMATDATE(StartDate + y# + 5, DayFormat$) 'January 6th was a Monday
	NEXT y#
	
	'Initialize current date
	CurrentYear$ = FORMATDATE(GETCURRDATE(), YearFormat$)
	SelectedYear% = CINT(CurrentYear$)

	CurrentMonth$ = FORMATDATE(GETCURRDATE(), MonthFormat$)
	SelectedMonthIndex% = CINT(FORMATDATE(GETCURRDATE(), MonthNumeric$))

	CurrentDay% = FORMATDATE(GETCURRDATE(), DayNumeric$)

	'Fill in the Schedule Event Dialog "Day boxes".
	WITH ScheduleEvent
		.MondayBox.SetText Days$(1)
		.TuesdayBox.SetText Days$(2)
		.WednesdayBox.SetText Days$(3)
		.ThursdayBox.SetText Days$(4)
		.FridayBox.SetText Days$(5)
		.SaturdayBox.SetText Days$(6)
		.SundayBox.SetText Days$(7)
	END WITH

END SUB

REM ***************************************************************
REM * NumeralToOrdinal$: Returns the appropriate ordinal          *
REM * abbreviation ("th", "st", "nd", "rd"                        *
REM ***************************************************************
FUNCTION NumeralToOrdinal$ (Number%)
	IF ((INT(Number% / 10) MOD 10) =  1) THEN
		NumeralToOrdinal$ = "th"
	ELSE
		SELECT CASE (Number% MOD 10)
			CASE 1
				NumeralToOrdinal$ = "st"
			CASE 2
				NumeralToOrdinal$ = "nd"
			CASE 3
				NumeralToOrdinal$ = "rd"
			CASE ELSE
				NumeralToOrdinal$ = "th"
		END SELECT
	ENDIF
END FUNCTION

REM ***************************************************************
REM * MakePrettyString: Transforms Event Data into a string to be *
REM * displayed in the Main Dialog List Box                       *
REM ***************************************************************
SUB MakePrettyString (Index%)
	DIM Event AS STRING
	DIM DaysRunned AS STRING
	DIM X AS LONG
	
	SELECT CASE EventData(Index%,1)
		CASE "O"
			'Schedule once
			Event$ = "On "
			'Date
			Event$ = Event$ & CDAT(CDBL(EventData(Index%, 5)))
			Event$ = Event$ & " at "
			'Time
			beep
			Event$ = Event$ & CDAT(CDBL(EventData(Index%, 6)))
			Event$ = Event$ & ", run "
			Event$ = Event$ & EventData(Index%, 2)
		CASE "H"
			'Schedule hourly
			Event$ = "Every hour"
			IF NOT(EventData(Index%, 4) = 0) THEN
				Event$ = Event$ & " at "
				'Number of minutes (ommitted if 0).
				Event$ = Event$ & EventData(Index%, 5)
				Event$ = Event$ & " minutes after the hour"
			ENDIF
			Event$ = Event$ & ", run "
			Event$ = Event$ & EventData(Index%, 2)
		CASE "D"
			'Schedule daily
			Event$ = "Every day at "
			'Time
			Event$ = Event$ & CDAT(CDBL(EventData(Index%, 5)))
			Event$ = Event$ & ", run "
			Event$ = Event$ & EventData(Index%, 2)
		CASE "M"
			'Schedule monthly
			Event$ = "Every "
			'Day number
			Event$ = Event$ & EventData(Index%, 5)
			Event$ = Event$ & NumeralToOrdinal(CINT(EventData(Index%, 5)))
			Event$ = Event$ & " of the month, at "
			Event$ = Event$ & CDAT(CDBL(EventData(Index%, 6)))
			Event$ = Event$ & ", run "
			Event$ = Event$ & EventData(Index%, 2)
		CASE ELSE
			'Other (error)
			Event$ = "Run " & EventData(Index%, 2) & " manually"
	END SELECT
	'Determine on which days the event is active
	IF NOT((EventData(Index%, 3)) = "XXXXXXX") THEN
		IF EventData(Index%, 3) = "       " THEN
			'None
			Event$ = Event$ & ", disabled (no active days)"
		ELSE
			'Concatenate the days
			DaysRunned$ = ""
			FOR X = 1 TO 7
				IF MID(EventData(Index%, 3),X,1) = "X" THEN DaysRunned$ = DaysRunned$ & ", " & Days$(X)
			NEXT X
			'Remove the first comma when adding to the string
			Event$ = Event$ & ", run only on" & MID(DaysRunned$,2)
		ENDIF
	ENDIF
	'Indicate last run
	Event$ = Event$ & ", last run on " & CDAT(CDBL(EventData(Index%,4)))
	'Set the string in the list
	ScheduledEvent$(Index%) = Event$
END SUB				

REM ***************************************************************
REM * ResetScheduleEvent: Fills the Schedule dialog with starting *
REM * data and takes care of some dialog initialization           *
REM ***************************************************************
SUB ResetScheduleEvent
	WITH ScheduleEvent
		.ScheduleOption.SetValue 0
		.ProgramFile.SetText ""
		.OnceMonth.SetArray Months$
		.OnceMonth.SetSelect SelectedMonthIndex%
		.OnceDay.SetValue CurrentDay%
		.OnceYear.SetValue SelectedYear%
		.OnceHour.SetValue 12
		.OnceMinutes.SetValue 0
		.OnceOption.SetValue 0
		.HourlyMinutes.SetValue 0
		.DailyHour.SetValue 12
		.DailyMinutes.SetValue 0
		.DailyOption.SetValue 0
		.MonthlyDay.SetValue CurrentDay%
		.MonthlyHour.SetValue 12
		.MonthlyMinutes.SetValue 0
		.MonthlyOption.SetValue 0
		
		.OnceTH.SetText NumeralToOrdinal$(CINT(.OnceDay.GetValue()))&","
		.MonthlyTH.SetText NumeralToOrdinal$(CINT(.MonthlyDay.GetValue()))
		
		.MondayBox.SetThreeState FALSE
		.TuesdayBox.SetThreeState FALSE
		.WednesdayBox.SetThreeState FALSE
		.ThursdayBox.SetThreeState FALSE
		.FridayBox.SetThreeState FALSE
		.SaturdayBox.SetThreeState FALSE
		.SundayBox.SetThreeState FALSE
		.MondayBox.SetValue 1
		.TuesdayBox.SetValue 1
		.WednesdayBox.SetValue 1
		.ThursdayBox.SetValue 1
		.FridayBox.SetValue 1
		.SaturdayBox.SetValue 1
		.SundayBox.SetValue 1
		
		.OnceYear.SetMinRange CINT(CurrentYear$)
		.OnceYear.SetMaxRange 3000
		
		.OnceMinutes.SetIncrement 15
		.HourlyMinutes.SetIncrement 15
		.DailyMinutes.SetIncrement 15
		.MonthlyMinutes.SetIncrement 15
	END WITH
END SUB

REM ***************************************************************
REM * FillScheduleEvent: Fills the Schedule Dialog with data      *
REM * obtained from the specified event. The routine relies on    *
REM * initialization performed in ResetScheduleEvent and does not *
REM * give new values to those variables where the inital values  *
REM * are appropriate.                                            *
REM ***************************************************************
SUB FillScheduleEvent (Index%)
	DIM Year AS LONG
	DIM Month AS LONG
	DIM Day AS LONG
	DIM DayWeek AS LONG
	DIM Hours AS LONG
	DIM Minutes AS LONG
	DIM Seconds AS LONG
	
	CALL ResetScheduleEvent
	WITH ScheduleEvent
		SELECT CASE EventData(Index%, 1)
			CASE "O"
				'Scheduled Once
				.ScheduleOption.SetValue 0
				'Date
				GETDATEINFO CDAT(CDBL(EventData(Index%,5))),Year&, Month&, Day&, DayWeek&
				.OnceMonth.SetSelect Month&
				.OnceDay.SetValue Day&
				.OnceYear.SetValue Year&
				'Time
				GETTIMEINFO CDAT(CDBL(EventData(Index%,6))),Hours&, Minutes&, Seconds&
				IF(Hours& >= 13) THEN
					Hours& = Hours& - 12
					.OnceOption.SetValue 1
				ENDIF
				IF Hours& = 12 THEN
					.OnceOption.SetValue 1
				ENDIF
				IF Hours& = 0 THEN
					Hours& = 12
				ENDIF				
				.OnceHour.SetValue Hours&
				.OnceMinutes.SetValue Minutes&
			CASE "H"
				'Scheduled Hourly
				.ScheduleOption.SetValue 1
				'Minutes after Hours
				.HourlyMinutes.SetValue EventData(Index%,5)
			CASE "D"
				'Scheduled Daily
				.ScheduleOption.SetValue 2
				'Time
				GETTIMEINFO CDAT(CDBL(EventData(Index%,5))),Hours&, Minutes&, Seconds&
				IF(Hours& >= 13) THEN
					Hours& = Hours& - 12
					.DailyOption.SetValue 1
				ENDIF
				IF Hours& = 12 THEN
					.DailyOption.SetValue 1
				ENDIF
				IF Hours& = 0 THEN
					Hours& = 12
				ENDIF				
				.DailyHour.SetValue Hours&
				.DailyMinutes.SetValue Minutes&
			CASE "M"
				'Scheduled Monthly
				.ScheduleOption.SetValue 3
				'Day of the month
				.MonthlyDay.SetValue EventData(Index%, 5)
				'Time
				GETTIMEINFO CDAT(CDBL(EventData(Index%,6))),Hours&, Minutes&, Seconds&
				IF(Hours& >= 13) THEN
					Hours& = Hours& - 12
					.MonthlyOption.SetValue 1
				ENDIF
				IF Hours& = 12 THEN
					.MonthlyOption.SetValue 1
				ENDIF
				IF Hours& = 0 THEN
					Hours& = 12
				ENDIF				
				.MonthlyHour.SetValue Hours&
				.MonthlyMinutes.SetValue Minutes&
			CASE ELSE
				'Other; error.
		END SELECT
		
		.OnceTH.SetText NumeralToOrdinal$(CINT(.OnceDay.GetValue())) & ","
		.MonthlyTH.SetText NumeralToOrdinal$(CINT(.MonthlyDay.GetValue()))
		
		'Set the program name
		.ProgramFile.SetText EventData(Index%,2)
		
		'Set the active days, one by one.
		IF MID(EventData(Index%,3),1,1) = " " THEN
			.MondayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),2,1) = " " THEN
			.TuesdayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),3,1) = " " THEN
			.WednesdayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),4,1) = " " THEN
			.ThursdayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),5,1) = " " THEN
			.FridayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),6,1) = " " THEN
			.SaturdayBox.SetValue 0
		ENDIF
		IF MID(EventData(Index%,3),7,1) = " " THEN
			.SundayBox.SetValue 0
		ENDIF
	END WITH
END SUB

REM ***************************************************************
REM * RemoveFromList: Removes an element from the array, sending  *
REM * all other elements upwards. This procedure is recursive: it *
REM * copies the next element in the current position, then calls *
REM * itself on the next element. The last element is simply      *
REM * deleted.                                                    *
REM ***************************************************************
SUB RemoveFromList(Index%)
	IF Index% = NumberOfEvents% THEN
		'Empty the data
		SETEMPTY EventData(Index%, 1)
		SETEMPTY EventData(Index%, 2)
		SETEMPTY EventData(Index%, 3)
		SETEMPTY EventData(Index%, 4)
		SETEMPTY EventData(Index%, 5)
		SETEMPTY ScheduledEvent$(Index%)
		'Remove the event
		NumberOfEvents% = NumberOfEvents% - 1
		'Exit
		EXIT SUB
	ENDIF
	'Copy the data from the next
	EventData(Index%,1) = EventData(Index% + 1, 1)
	EventData(Index%,2) = EventData(Index% + 1, 2)
	EventData(Index%,3) = EventData(Index% + 1, 3)
	EventData(Index%,4) = EventData(Index% + 1, 4)
	EventData(Index%,5) = EventData(Index% + 1, 5)
	ScheduledEvent$(Index%) = ScheduledEvent$(Index% + 1)
	'Now, delete the newly-copied next element
	CALL RemoveFromList CINT(Index% + 1)
END SUB

REM ***************************************************************
REM * ExecuteEvent: This executes the program associated with the *
REM * specified event. After calling this SUB, the caller should  *
REM * update the Dialog list.                                     *
REM ***************************************************************
SUB ExecuteEvent(Index%)
	IF UCASE(RIGHT(EventData(Index%,2),4)) = ".EXE" THEN
		'Executable
		STARTPROCESS EventData(Index%,2)
	ELSE
		'Script (assumed); run through Script editor.
		WITHOBJECT "CorelScript.Automation.7"
			IF (.FileOpen(EventData(Index%,2)) = FALSE) THEN
				MESSAGE "Error loading" + CHR(13) +  EventData(Index%,2) + "."
			ELSE
				IF (.Execute() = FALSE) THEN
					MESSAGE "Error executing" + CHR(13) +  EventData(Index%,2) + "."
				ENDIF
				.FileClose
			ENDIF
		END WITHOBJECT
	ENDIF
	'Set last run time to now.
	EventData(Index%,4) = GETCURRDATE()
	CALL MakePrettyString(Index%)
END SUB

REM ***************************************************************
REM * RunPrograms: Checks if any programs need running, and runs  *
REM * them if appropriate. The caller should update the entire    *
REM * list after running this function.                           *
REM ***************************************************************
SUB RunPrograms()
	DIM Year AS LONG
	DIM Month AS LONG
	DIM Day AS LONG
	DIM DayWeek AS LONG
	DIM Hours AS LONG
	DIM Minutes AS LONG
	DIM Seconds AS LONG
	DIM Index AS INTEGER
	DIM RunDate AS DATE
	DIM RunDay AS INTEGER

	GETTIMEINFO GETCURRDATE(), Hours&, Minutes&, Seconds&
	GETDATEINFO GETCURRDATE(), Year&, Month&, Day&, DayWeek&
	IF DayWeek& = 1 THEN
		'Sunday is seven
		DayWeek& = 7
	ELSE
		'Our index begins at monday
		DayWeek& = DayWeek& - 1
	ENDIF
	FOR Index% = 1 TO NumberOfEvents%
		'Check if active today
		IF (MID(EventData(Index%,3),DayWeek&,1) = "X") THEN
			SELECT CASE EventData(Index%,1)
				CASE "O"
					'Scheduled once
					'Create execution time
					RunDate = CDAT(CDBL(EventData(Index%,5)) + CDBL(EventData(Index%,6)))
					'Test for run conditions (later than the condition and not run since)
					IF (GETCURRDATE() >= Rundate) AND (RunDate > CDAT(CDBL(EventData(Index%, 4)))) THEN
						CALL ExecuteEvent Index%
					ENDIF
				CASE "H"
					'Scheduled hourly
					'Create execution time
					RunDate = BUILDDATE(Year&, Month&, Day&) + BUILDTIME(Hours&, EventData(Index%,5), 0)
					'Test for run conditions (later than the condition and not run since)
					IF (GETCURRDATE() >= Rundate) AND (RunDate > CDAT(CDBL(EventData(Index%, 4)))) THEN
						CALL ExecuteEvent Index%
					ENDIF
					'Test for run conditions (later than the condition and not run since)
					IF (GETCURRDATE() >= Rundate) AND (RunDate > CDAT(CDBL(EventData(Index%, 4)))) THEN
						CALL ExecuteEvent Index%
					ENDIF
				CASE "D"
					'Scheduled daily
					'Create execution time
					RunDate = BUILDDATE(Year&, Month&, Day&) + CDAT(CDBL(EventData(Index%,5)))
					'Test for run conditions (later than the condition and not run since)
					IF (GETCURRDATE() >= Rundate) AND (RunDate > CDAT(CDBL(EventData(Index%, 4)))) THEN
						CALL ExecuteEvent Index%
					ENDIF
				CASE "M"
					RunDay% = EventData(Index%,5)
					'Check if day exists in this month; if not, then do not run
					IF (Runday% <= 30) OR (Month& = 1 OR Month& = 3 OR Month& = 5 OR Month& = 7 OR Month& = 8 OR Month& = 10 OR Month& = 12) THEN
						IF (Runday% <= 29) OR (Month& <> 2) THEN
							IF (Runday% <= 28) OR (Month& <> 2) OR (((Year& MOD 4) = 0) AND (NOT ((Year& MOD 100) = 0) OR ((Year& MOD 400) = 0))) THEN
								'The day exists
								'Create execution time
								RunDate = BUILDDATE(Year&, Month&, Runday%) + CDAT(CDBL(EventData(Index%,6)))
								'Test for run conditions (later than the condition and not run since)
								IF (GETCURRDATE() >= Rundate) AND (RunDate > CDAT(CDBL(EventData(Index%, 4)))) THEN
									CALL ExecuteEvent Index%
								ENDIF
							ENDIF
						ENDIF
					ENDIF								
				CASE ELSE
					'Error; must be run manually
			END SELECT
		ENDIF
	NEXT Index%
END SUB
				
REM ***************************************************************
REM * EnableOption: This enables the Scheduled Event Dialog       *
REM * controls corresponding to the selected scheduling option.   *
REM ***************************************************************
SUB EnableOption (Option%)
	WITH ScheduleEvent
		SELECT CASE Option%
			CASE 0
				'Scheduled Once
				.OnceON.Enable TRUE
				.OnceMonth.Enable TRUE
				.OnceYear.Enable TRUE
				.OnceTH.Enable TRUE
				.OnceDay.Enable TRUE
				.OnceAT.Enable TRUE
				.OnceHour.Enable TRUE
				.OnceCOLON.Enable TRUE
				.OnceMinutes.Enable TRUE
				.OnceAM.Enable TRUE
				.OncePM.Enable TRUE
				.HourlyAT.Enable FALSE
				.HourlyMinutes.Enable FALSE
				.HourlyAFTER.Enable FALSE
				.DailyAT.Enable FALSE
				.DailyHour.Enable FALSE
				.DailyCOLON.Enable FALSE
				.DailyMinutes.Enable FALSE
				.DailyAM.Enable FALSE
				.DailyPM.Enable FALSE
				.MonthlyEvery.Enable FALSE
				.MonthlyDay.Enable FALSE
				.MonthlyTH.Enable FALSE
				.MonthlyOF.Enable FALSE
				.MonthlyAT.Enable FALSE
				.MonthlyHour.Enable FALSE
				.MonthlyCOLON.Enable FALSE
				.MonthlyMinutes.Enable FALSE
				.MonthlyAM.Enable FALSE
				.MonthlyPM.Enable FALSE
			CASE 1
				'Scheduled Hourly
				.OnceON.Enable FALSE
				.OnceMonth.Enable FALSE
				.OnceYear.Enable FALSE
				.OnceTH.Enable FALSE
				.OnceDay.Enable FALSE
				.OnceAT.Enable FALSE
				.OnceHour.Enable FALSE
				.OnceCOLON.Enable FALSE
				.OnceMinutes.Enable FALSE
				.OnceAM.Enable FALSE
				.OncePM.Enable FALSE
				.HourlyAT.Enable TRUE
				.HourlyMinutes.Enable TRUE
				.HourlyAFTER.Enable TRUE
				.DailyAT.Enable FALSE
				.DailyHour.Enable FALSE
				.DailyCOLON.Enable FALSE
				.DailyMinutes.Enable FALSE
				.DailyAM.Enable FALSE
				.DailyPM.Enable FALSE
				.MonthlyEvery.Enable FALSE
				.MonthlyDay.Enable FALSE
				.MonthlyTH.Enable FALSE
				.MonthlyOF.Enable FALSE
				.MonthlyAT.Enable FALSE
				.MonthlyHour.Enable FALSE
				.MonthlyCOLON.Enable FALSE
				.MonthlyMinutes.Enable FALSE
				.MonthlyAM.Enable FALSE
				.MonthlyPM.Enable FALSE
			CASE 2
				'Scheduled Daily
				.OnceON.Enable FALSE
				.OnceMonth.Enable FALSE
				.OnceYear.Enable FALSE
				.OnceTH.Enable FALSE
				.OnceDay.Enable FALSE
				.OnceAT.Enable FALSE
				.OnceHour.Enable FALSE
				.OnceCOLON.Enable FALSE
				.OnceMinutes.Enable FALSE
				.OnceAM.Enable FALSE
				.OncePM.Enable FALSE
				.HourlyAT.Enable FALSE
				.HourlyMinutes.Enable FALSE
				.HourlyAFTER.Enable FALSE
				.DailyAT.Enable TRUE
				.DailyHour.Enable TRUE
				.DailyCOLON.Enable TRUE
				.DailyMinutes.Enable TRUE
				.DailyAM.Enable TRUE
				.DailyPM.Enable TRUE
				.MonthlyEvery.Enable FALSE
				.MonthlyDay.Enable FALSE
				.MonthlyTH.Enable FALSE
				.MonthlyOF.Enable FALSE
				.MonthlyAT.Enable FALSE
				.MonthlyHour.Enable FALSE
				.MonthlyCOLON.Enable FALSE
				.MonthlyMinutes.Enable FALSE
				.MonthlyAM.Enable FALSE
				.MonthlyPM.Enable FALSE
			CASE 3
				'Scheduled Monthly
				.OnceON.Enable FALSE
				.OnceMonth.Enable FALSE
				.OnceYear.Enable FALSE
				.OnceTH.Enable FALSE
				.OnceDay.Enable FALSE
				.OnceAT.Enable FALSE
				.OnceHour.Enable FALSE
				.OnceCOLON.Enable FALSE
				.OnceMinutes.Enable FALSE
				.OnceAM.Enable FALSE
				.OncePM.Enable FALSE
				.HourlyAT.Enable FALSE
				.HourlyMinutes.Enable FALSE
				.HourlyAFTER.Enable FALSE
				.DailyAT.Enable FALSE
				.DailyHour.Enable FALSE
				.DailyCOLON.Enable FALSE
				.DailyMinutes.Enable FALSE
				.DailyAM.Enable FALSE
				.DailyPM.Enable FALSE
				.MonthlyEvery.Enable TRUE
				.MonthlyDay.Enable TRUE
				.MonthlyTH.Enable TRUE
				.MonthlyOF.Enable TRUE
				.MonthlyAT.Enable TRUE
				.MonthlyHour.Enable TRUE
				.MonthlyCOLON.Enable TRUE
				.MonthlyMinutes.Enable TRUE
				.MonthlyAM.Enable TRUE
				.MonthlyPM.Enable TRUE
			CASE ELSE
				'Other (Disable all)
				.OnceON.Enable FALSE
				.OnceMonth.Enable FALSE
				.OnceYear.Enable FALSE
				.OnceTH.Enable FALSE
				.OnceDay.Enable FALSE
				.OnceAT.Enable FALSE
				.OnceHour.Enable FALSE
				.OnceCOLON.Enable FALSE
				.OnceMinutes.Enable FALSE
				.OnceAM.Enable FALSE
				.OncePM.Enable FALSE
				.HourlyAT.Enable FALSE
				.HourlyMinutes.Enable FALSE
				.HourlyAFTER.Enable FALSE
				.DailyAT.Enable FALSE
				.DailyHour.Enable FALSE
				.DailyCOLON.Enable FALSE
				.DailyMinutes.Enable FALSE
				.DailyAM.Enable FALSE
				.DailyPM.Enable FALSE
				.MonthlyEvery.Enable FALSE
				.MonthlyDay.Enable FALSE
				.MonthlyTH.Enable FALSE
				.MonthlyOF.Enable FALSE
				.MonthlyAT.Enable FALSE
				.MonthlyHour.Enable FALSE
				.MonthlyCOLON.Enable FALSE
				.MonthlyMinutes.Enable FALSE
				.MonthlyAM.Enable FALSE
				.MonthlyPM.Enable FALSE
		END SELECT
	END WITH
END SUB

REM ***************************************************************
REM * GetEventFromDialog: This takes the data from the Schedule   *
REM * Event Dialog and puts it in the specified Event Data        *
REM * record.                                                     *
REM ***************************************************************
SUB GetEventFromDialog(Index%)
	DIM DaysToRun AS STRING

	WITH ScheduleEvent
		SELECT CASE .ScheduleOption.GetValue()
			CASE 0
				'Scheduled Once
				EventData(Index%,1) = "O"
				'Get Program
				EventData(Index%,2) = .ProgramFile.GetText()
				'Get Date
				EventData(Index%,5) = BUILDDATE(.OnceYear.GetValue(), .OnceMonth.GetSelect(), .OnceDay.GetValue())
				'Get Time
				IF (.OnceHour.GetValue() = 12) THEN
					IF (.OnceOption.GetValue() = 0) THEN
						EventData(Index%,6) = BUILDTIME(0, .OnceMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,6) = BUILDTIME(12, .OnceMinutes.GetValue(), 0)
					ENDIF
				ELSE 
					IF (.OnceOption.GetValue() = 0) THEN
						EventData(Index%,6) = BUILDTIME(.OnceHour.GetValue(), .OnceMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,6) = BUILDTIME(.OnceHour.GetValue() + 12, .OnceMinutes.GetValue(), 0)
					ENDIF
				ENDIF
			CASE 1
				'Scheduled Hourly
				EventData(Index%,1) = "H"
				'Get Program
				EventData(Index%,2) = .ProgramFile.GetText()
				'Get Minutes after Hour
				EventData(Index%,5) = .HourlyMinutes.GetValue()
			CASE 2
				'Scheduled Daily
				EventData(Index%,1) = "D"
				'Get Program
				EventData(Index%,2) = .ProgramFile.GetText()
				'Get Time
				IF (.DailyHour.GetValue() = 12) THEN
					IF (.DailyOption.GetValue() = 0) THEN
						EventData(Index%,5) = BUILDTIME(0, .DailyMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,5) = BUILDTIME(12, .DailyMinutes.GetValue(), 0)
					ENDIF
				ELSE 
					IF (.DailyOption.GetValue() = 0) THEN
						EventData(Index%,5) = BUILDTIME(.DailyHour.GetValue(), .DailyMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,5) = BUILDTIME(.DailyHour.GetValue() + 12, .DailyMinutes.GetValue(), 0)
					ENDIF
				ENDIF
			CASE 3
				'Scheduled Monthly
				EventData(Index%,1) = "M"
				'Get Program
				EventData(Index%,2) = .ProgramFile.GetText()
				'Get Day of the Month
				EventData(Index%,5) = .MonthlyDay.GetValue()
				'Get Time
				IF (.MonthlyHour.GetValue() = 12) THEN
					IF (.MonthlyOption.GetValue() = 0) THEN
						EventData(Index%,6) = BUILDTIME(0, .MonthlyMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,6) = BUILDTIME(12, .MonthlyMinutes.GetValue(), 0)
					ENDIF
				ELSE 
					IF (.MonthlyOption.GetValue() = 0) THEN
						EventData(Index%,6) = BUILDTIME(.MonthlyHour.GetValue(), .MonthlyMinutes.GetValue(), 0)
					ELSE
						EventData(Index%,6) = BUILDTIME(.MonthlyHour.GetValue() + 12, .MonthlyMinutes.GetValue(), 0)
					ENDIF
				ENDIF
			CASE ELSE
				'Other (Error)
				MESSAGE "Error, unrecognized schedule option"
				EventData(Index%,1) = "X"
				'Get program anyway.
				EventData(Index%,2) = .ProgramFile.GetText()
		END SELECT
		DaysToRun$ = ""
		'Create the Active Days matrix by getting the data
		'from the day boxes, one by one.
		IF NOT (.MondayBox.GetValue() = 0) THEN 
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.TuesdayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.WednesdayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.ThursdayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.FridayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.SaturdayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		IF NOT (.SundayBox.GetValue() = 0) THEN
			DaysToRun$ = DaysToRun$ & "X"
		ELSE
			DaysToRun$ = DaysToRun$ & " "
		ENDIF
		'Set the Active Days matrix.
		EventData(Index%, 3) = DaysToRun$
		
		'Set the last execution to right now, so that the event will
		'not be executed if the conditions are in the past
		EventData(Index%,4) = GETCURRDATE()
	END WITH
END SUB				

REM ***************************************************************
REM * MainDialogSub: Event handler for the Main Dialog. This SUB  *
REM * handles all of the user commands; it is, in effect, the     *
REM * heart of the program.                                       *
REM ***************************************************************
SUB MainDialogSub(BYVAL ControlID%, BYVAL Event%)
	DIM ReturnCode AS INTEGER
	DIM Index AS INTEGER
	DIM Mess AS STRING
	DIM DoRemove AS INTEGER
	DIM DoExec AS INTEGER
	DIM DoExit AS INTEGER

	IF Event% = EVENT_INITIALIZATION THEN
		'Initialize
		MainDialog.MainList.SetArray ScheduledEvent$
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN
		SELECT CASE ControlID%
			CASE MainDialog.AddEvent.GetID()
				'Add an event; check if room left
				IF NumberOfEvents% < MAX_EVENTS THEN
					'Give a blank event
					CALL ResetScheduleEvent
					'Create the Schedule Event Dialog
					ReturnCode% = DIALOG(ScheduleEvent)
					IF ReturnCode% = MSG_OK THEN
						'Add the new entry to the list
						NumberOfEvents% = NumberOfEvents% + 1
						CALL GetEventFromDialog NumberOfEvents%
						CALL MakePrettyString NumberOfEvents%
						MainDialog.MainList.AddItem ScheduledEvent$(NumberOfEvents%),NumberOfEvents%
						MainDialog.MainList.SetSelect NumberOfEvents%
					ENDIF
				ENDIF
			CASE MainDialog.EditEvent.GetID()
				'Edit an event; check for a selection
				IF MainDialog.MainList.GetSelect() <> 0 THEN
					'Fill the Schedule Event Dialog
					Index% = MainDialog.MainList.GetSelect()
					CALL FillScheduleEvent Index%
					'Create the Dialog
					ReturnCode% = DIALOG(ScheduleEvent)
					IF ReturnCode% = MSG_OK THEN
						'Get the data
						CALL GetEventFromDialog Index%
						'Update the list
						CALL MakePrettyString Index%
						MainDialog.MainList.RemoveItem Index%
						MainDialog.MainList.AddItem ScheduledEvent$(Index%),Index%
						MainDialog.MainList.SetSelect Index%
					ENDIF
				ENDIF
			CASE MainDialog.RemoveEvent.GetID()
				'Remove an event; check for a selection
				IF MainDialog.MainList.GetSelect() <> 0 THEN
					'Ask for confirmation
					Index% = MainDialog.MainList.GetSelect()
					Mess$ = "Remove execution of" & CHR(13) & EventData(Index%,2) & "?"
					DoRemove% = MESSAGEBOX(Mess$,"Confirm Remove", MB_YES_NO + MB_QUESTION_ICON)
					IF DoRemove% = MSG_YES THEN
						'Remove from the list
						MainDialog.MainList.RemoveItem(Index%)
						CALL RemoveFromList Index%
					ENDIF
				ENDIF
			CASE MainDialog.ExecuteEvent.GetID()
				'Execute an event; check for a selection
				IF MainDialog.MainList.GetSelect() <> 0 THEN
					'Ask for a confirmation
					Index% = MainDialog.MainList.GetSelect()
					Mess$ = "Execute" & CHR(13) & EventData(Index%,2) & "?"
					DoExec% = MESSAGEBOX(Mess$,"Confirm Remove", MB_YES_NO + MB_QUESTION_ICON)
					IF DoExec% = MSG_YES THEN
						'Execute
						CALL ExecuteEvent Index%
						'Update the list
						MainDialog.MainList.RemoveItem(Index%)
						MainDialog.MainList.AddItem ScheduledEvent$(Index%), Index%
						MainDialog.MainList.SetSelect Index%
					ENDIF
				ENDIF
			CASE MainDialog.ExitButton.GetID()
				'Exit
				DoExit% = MESSAGEBOX("Exit Corel SCRIPT Scheduler?", "Confirm Exit", MB_YES_NO + MB_QUESTION_ICON)
				IF DoExit% = MSG_YES THEN MainDialog.CloseDialog 1
			CASE ELSE
				' Nothing
		END SELECT
	END IF
	IF Event% = EVENT_TIMER_EVENT THEN
		'Run the programs if needed
		CALL RunPrograms
		'Update the screen
		Index% = MainDialog.MainList.GetSelect()
		MainDialog.MainList.SetArray ScheduledEvent$
		MainDialog.MainList.SetSelect Index%
	ENDIF
	'Enable the Edit, Remove and Execute buttons if a selection
	'is made
	IF MainDialog.MainList.GetSelect() = 0 THEN
		MainDialog.RemoveEvent.Enable FALSE
		MainDialog.EditEvent.Enable FALSE
		MainDialog.ExecuteEvent.Enable FALSE
	ELSE
		MainDialog.RemoveEvent.Enable TRUE
		MainDialog.EditEvent.Enable TRUE
		MainDialog.ExecuteEvent.Enable TRUE
	ENDIF
END SUB

REM ***************************************************************
REM * ScheduleEventSub: Event handler for the Schedule Event      *
REM * Dialog. This is a fairly complex dialog, but its main       *
REM * purpose is data entry, unlike the main dialog which is      *
REM * mostly a controller.                                        *
REM ***************************************************************
SUB ScheduleEventSub(BYVAL ControlID%, BYVAL Event%)
	DIM Option AS INTEGER
	DIM Day AS INTEGER
	DIM Month AS INTEGER
	DIM Year AS INTEGER
	DIM FileName AS STRING
	
	WITH ScheduleEvent
		IF Event% = EVENT_INITIALIZATION THEN
			' Enable the appropriate controls
			Option% = .ScheduleOption.GetValue()
			EnableOption(Option%)
					
		ENDIF
		
		IF Event% = EVENT_CHANGE_IN_CONTENT THEN
			SELECT CASE ControlID%
				CASE .OnceDay.GetID()
					'Adjust the day if exceeds the "month limits"
					Day% = .OnceDay.GetValue()
					Month% =  .OnceMonth.GetSelect()
					Year% = .OnceYear.GetValue()
					'Too low
					IF Day% < 1 THEN
						IF Month% = 1 THEN
							'Before january, go back one year
							IF Year% = CurrentYear$ THEN
								' Do not allow change
								.OnceDay.SetValue 1
							ELSE
								.OnceYear.SetValue Year% - 1
								.OnceMonth.SetSelect 12
								.OnceDay.SetValue 31
							ENDIF
						ELSE
							'Go back one month
							Month% = Month% - 1
							.OnceMonth.SetSelect Month%
							IF Month% = 2 THEN
								' Febuary; this tests for a leap year
								IF ((Year% MOD 4) = 0) AND (NOT((Year% MOD 100) = 0) OR ((Year% MOD 400) = 0)) THEN
									.OnceDay.SetValue 29
								ELSE
									.OnceDay.SetValue 28
								ENDIF
							ELSEIF (Month% = 1) OR (Month% = 3) OR (Month% = 5) OR (Month% = 7) OR (Month% = 8) OR (Month% = 10) OR (Month% = 12) THEN
								.OnceDay.SetValue 31
							ELSE
								.OnceDay.SetValue 30
							ENDIF
						ENDIF
					ELSEIF Day% > 28 THEN
						'We may have moved passed the limit
						IF Month% = 2 THEN
							' Febuary
							' This tests for a leap year; if it exceeds anyway, then we advance to March
							IF NOT((Year% MOD 4) = 0) AND (NOT ((Year% MOD 100) = 0) OR ((Year% MOD 400) = 0)) OR Day% > 29 THEN
								.OnceMonth.SetSelect 3
								.OnceDay.SetValue 1
							ENDIF
						ELSEIF (Month% = 12) THEN
							' December; we may have to advance a year
							IF Day% > 31 THEN
								.OnceYear.SetValue Year + 1
								.OnceMonth.SetSelect 1
								.OnceDay.SetValue 1
							END IF
						ELSEIF (Day% >31) OR (NOT((Month% = 1) OR (Month% = 3) OR (Month% = 5) OR (Month% = 7) OR (Month% = 8) OR (Month% = 10)) AND Day% > 30) THEN
							' Other month
							.OnceMonth.SetSelect Month% + 1
							.OnceDay.SetValue 1
						ENDIF
					ENDIF				
					
					.OnceTH.SetText NumeralToOrdinal$(CINT(.OnceDay.GetValue())) & ","

				CASE .MonthlyDay.GetID()
					' Wraparound if we come out of the limits. As we cannot limit ourselves to
					' the length of the shorter months, we have to accept any value up to 31.
					Day% = .MonthlyDay.GetValue()
					IF Day% < 1 THEN
						.MonthlyDay.SetValue 31
					ELSEIF Day% > 31 THEN
						.MonthlyDay.SetValue 1
					ENDIF
										
					.MonthlyTH.SetText NumeralToOrdinal$(CINT(.MonthlyDay.GetValue()))

				'Wraparounds for hours
				CASE .DailyHour.GetID()
					IF .DailyHour.GetValue() > 12 THEN .DailyHour.SetValue 1
					IF .DailyHour.GetValue() < 1 THEN .DailyHour.SetValue 12
				CASE .OnceHour.GetID()
					IF .OnceHour.GetValue() > 12 THEN .OnceHour.SetValue 1
					IF .OnceHour.GetValue() < 1 THEN .OnceHour.SetValue 12
				CASE .MonthlyHour.GetID()
					IF .MonthlyHour.GetValue() > 12 THEN .MonthlyHour.SetValue 1
					IF .MonthlyHour.GetValue() < 1 THEN .MonthlyHour.SetValue 12
				'Wraparounds for Minutes.
				CASE .OnceMinutes.GetID()
					WHILE .OnceMinutes.GetValue() > 59
						.OnceMinutes.SetValue .OnceMinutes.GetValue() - 60
					WEND
					WHILE .OnceMinutes.GetValue() < 0
						.OnceMinutes.SetValue .DailyMinutes.GetValue() + 60
					WEND
				CASE .DailyMinutes.GetID()
					WHILE .DailyMinutes.GetValue() > 59
						.DailyMinutes.SetValue .DailyMinutes.GetValue() - 60
					WEND
					WHILE .DailyMinutes.GetValue() < 0
						.DailyMinutes.SetValue .DailyMinutes.GetValue() + 60
					WEND
				CASE .HourlyMinutes.GetID()
					WHILE .HourlyMinutes.GetValue() > 59
						.HourlyMinutes.SetValue .HourlyMinutes.GetValue() - 60
					WEND
					WHILE .HourlyMinutes.GetValue() < 0
						.HourlyMinutes.SetValue .HourlyMinutes.GetValue() + 60
					WEND
				CASE .MonthlyMinutes.GetID()
					WHILE .MonthlyMinutes.GetValue() > 59
						.MonthlyMinutes.SetValue .MonthlyMinutes.GetValue() - 60
					WEND
					WHILE .MonthlyMinutes.GetValue() < 0
						.MonthlyMinutes.SetValue .MonthlyMinutes.GetValue() + 60
					WEND
			END SELECT
		END IF
		IF Event% = EVENT_MOUSE_CLICK THEN
			SELECT CASE ControlID%
				'Enable appropriate controls for the schedule options
				CASE .ScheduleOnce.GetID()
					Option% = .ScheduleOption.GetValue()
					EnableOption(Option%)
				CASE .ScheduleDaily.GetID()
					Option% = .ScheduleOption.GetValue()
					EnableOption(Option%)
				CASE .ScheduleHourly.GetID()
					Option% = .ScheduleOption.GetValue()
					EnableOption(Option%)
				CASE	.ScheduleMonthly.GetID()
					Option% = .ScheduleOption.GetValue()
					EnableOption(Option%)
				'Browse
				CASE .BrowseButton.GetID()
					Filename$ = GETFILEBOX("Executable Files (*.exe)|*.exe|Corel SCRIPT Files (*.csc)|*.csc|All Files|*.*", "Choose an application or Script to Run", 0)
					IF Filename$ <> "" THEN
						.ProgramFile.SetText(FileName$)
					ENDIF
				CASE ELSE
					'Nothing
			END SELECT
		ENDIF
	END WITH
END SUB


REM ***************************************************************
REM * Main Program                                                *
REM ***************************************************************
'Initialize data
DIM dbl AS LONG
DIM index AS INTEGER
CALL Initialize

'Create the file if it does not exist
OPEN DATFOL$ & "\Schedule.Dat" FOR APPEND AS 1
CLOSE

'Load the file
OPEN DATFOL$ & "\Schedule.Dat" FOR INPUT AS 1

WHILE ((NOT EOF(1)) AND (NumberOfEvents% < MAX_EVENTS))
	NumberOfEvents% = NumberOfEvents% + 1
	' Read schedule
	INPUT #1, EventData(NumberOfEvents%, 1)
	' Read program
	INPUT #1, EventData(NumberOfEvents%, 2)
	' Read active days matrix
	INPUT #1, EventData(NumberOfEvents%, 3)
	' Read last execution
	INPUT #1, dbl&
	EventData(NumberOfEvents%, 4)=dbl&
	SELECT CASE EventData(NumberOfEvents%, 1)
		CASE "O"
			'Scheduled Once
			'Read date
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 5)=dbl&
			'Read time
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 6) = dbl
		CASE "H"
			'Scheduled Hourly
			'Read number of minutes
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 5)=dbl&
		CASE "D"
			'Scheduled Daily
			'Read time
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 5)=dbl&
		CASE "M"
			'Scheduled Monthly
			'Read day of the month
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 5)=dbl&
			'Read time
			INPUT #1, dbl&
			EventData(NumberOfEvents%, 6)=dbl&
		CASE ELSE
			MESSAGE "File Error!"
			NumberOfEvents% = NumberOfEvents% - 1
	END SELECT
	CALL MakePrettyString NumberOfEvents%
WEND

CLOSE 1

MainDialog.SetStyle STYLE_MINIMIZEBOX

'Set Timer at one minute
MainDialog.SetTimer 10000

'Have a go!
DIALOG MainDialog

'Save the file
OPEN DATFOL$ & "\Schedule.Dat" FOR OUTPUT AS 1

FOR Index% = 1 TO NumberOfEvents%
	' Write event type
	WRITE #1, EventData(Index%, 1),
	' Write program
	WRITE #1, EventData(Index%, 2),
	' Write active days matrix
	WRITE #1, EventData(Index%, 3),
	'Write last execution
	WRITE #1, CDBL(EventData(Index%, 4)),
	SELECT CASE EventData(Index%, 1)
		CASE "O"
			'Scheduled Once
			'Write date
			WRITE #1, CDBL(EventData(Index%, 5)),
			'Write time
			WRITE #1, CDBL(EventData(Index%, 6))
		CASE "H"
			'Scheduled Hourly
			'Write number of minutes
			WRITE #1, EventData(Index%, 5)
		CASE "D"
			'Scheduled Daily
			'Write time
			WRITE #1, CDBL(EventData(Index%, 5))
		CASE "M"
			'Scheduled Monthly
			'Write day
			WRITE #1, EventData(Index%, 5),
			'Write time
			WRITE #1, CDBL(EventData(Index%, 6))
		CASE ELSE
	END SELECT
NEXT Index%

CLOSE 1


