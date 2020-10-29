REM Demonstration of small timer
REM TIMER.CSC  for v7.0, 96/06/27
REM Copyright 1996 Corel Corporation. All rights reserved.

'  Global constants
#DEFINE DLG_INIT  	0
#DEFINE DLG_CLICK 	2
#DEFINE DLG_TIMEOUT 5
#DEFINE TEXTSTYLE (32+4)
#DEFINE START_TEXT "START"
#DEFINE STOP_TEXT "STOP"

' The Stop watch dialog
BEGIN DIALOG OBJECT SW 119, 46, "Timer", SUB SWHandler
	TEXT  8, 8, 45, 15, .TimerText, ""
	PROGRESS 8, 30, 45, 5, .Ticker
	PUSHBUTTON  66, 7, 46, 14, .StopGo, "Stop/Go"
	PUSHBUTTON  66, 25, 46, 14, .ResetBtn, "RESET"
END DIALOG

'  Start dialog
SW.TimerText.SetStyle TEXTSTYLE
DIALOG sw

'  Main dialog handler
SUB SWHandler( BYVAL CtrlID%, BYVAL Event%)
	STATIC Start AS DATE, CT AS LONG, ST AS LONG, FT AS LONG
	STATIC started AS boolean 
	
	SELECT CASE Event
		CASE DLG_INIT
			SW.SETTIMER(500)
			started=FALSE
			CT=0:ST=0
			SW.StopGo.SetText START_TEXT

		CASE DLG_CLICK
			IF(CtrlId=SW.StopGo.GetID()) THEN
				'  Stop/Go was clicked
				IF started THEN
					started=FALSE
					ST=ST+CT
					CT=0
					SW.StopGo.SetText START_TEXT
				ELSE
					started=TRUE
					Start=GETCURRDATE()
					SW.StopGo.SetText STOP_TEXT
				END IF
			ELSE
				'  Reset was clicked
				SW.StopGo.SetText START_TEXT
				started=FALSE
				CT=0:ST=0:FT=0
				SW.Ticker.setvalue CT
			END IF
		
		CASE DLG_TIMEOUT
			'  Increment timer
			IF started=TRUE THEN
				CT=(GETCURRDATE()-start)*86400
				SW.Ticker.step
			END IF
			' Display
			SW.TimerText.Settext STR(CT+ST) & " S"
	END SELECT
END SUB







