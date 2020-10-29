REM Plays audio CDs
REM CDPlayer.csc  August 22, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

' Constants
GLOBAL CONST STYLE_MINIMIZEBOX% = &h0020
GLOBAL CONST EVENT_CHANGE% = 1
GLOBAL CONST EVENT_MOUSE_CLICK% = 2
GLOBAL CONST EVENT_DBL_MOUSE_CLICK% = 3

'Declare Multimedia DLL function
DECLARE FUNCTION MMString LIB "winmm" (BYVAL Command AS STRING, BYVAL ReturnString AS STRING, BYVAL ReturnSize AS LONG, BYVAL CallBack AS LONG) AS LONG ALIAS "mciSendStringA"

'Global procedures
DECLARE FUNCTION MediaPresent() AS BOOLEAN
DECLARE SUB EndProgram()
DECLARE FUNCTION CDCommand$( Command$, ErrorString$ )

' Global variables
GLOBAL NumberOfTracks%
GLOBAL PauseMode AS BOOLEAN
GLOBAL PausePosition$ AS STRING

' Dialog definition
BEGIN DIALOG OBJECT CDDialog 108, 127, "Corel Script CD", SUB CDDialogSub
	PUSHBUTTON  4, 5, 53, 16, .PlayButton, ">"
	PUSHBUTTON  59, 5, 16, 16, .PauseButton, "II"
	PUSHBUTTON  22, 23, 16, 16, .StopButton, "O"
	PUSHBUTTON  4, 23, 16, 16, .PrevTrack, "|<<"
	PUSHBUTTON  41, 23, 16, 16, .NextTrack, ">>|"
	PUSHBUTTON  59, 23, 16, 16, .Eject, "^"
	VSLIDER 89, 0, 19, 118, .Slider
	GROUPBOX  5, 42, 81, 72, .Trackbox, "Track"
	PUSHBUTTON  10, 52, 14, 14, .T1, "1"
	PUSHBUTTON  24, 52, 14, 14, .T2, "2"
	PUSHBUTTON  38, 52, 14, 14, .T3, "3"
	PUSHBUTTON  52, 52, 14, 14, .T4, "4"
	PUSHBUTTON  66, 52, 14, 14, .T5, "5"
	PUSHBUTTON  10, 66, 14, 14, .T6, "6"
	PUSHBUTTON  24, 66, 14, 14, .T7, "7"
	PUSHBUTTON  38, 66, 14, 14, .T8, "8"
	PUSHBUTTON  52, 66, 14, 14, .T9, "9"
	PUSHBUTTON  66, 66, 14, 14, .T10, "10"
	PUSHBUTTON  10, 80, 14, 14, .T11, "11"
	PUSHBUTTON  24, 80, 14, 14, .T12, "12"
	PUSHBUTTON  38, 80, 14, 14, .T13, "13"
	PUSHBUTTON  52, 80, 14, 14, .T14, "14"
	PUSHBUTTON  66, 80, 14, 14, .T15, "15"
	PUSHBUTTON  10, 94, 14, 14, .T16, "16"
	PUSHBUTTON  24, 94, 14, 14, .T17, "17"
	PUSHBUTTON  38, 94, 14, 14, .T18, "18"
	PUSHBUTTON  52, 94, 14, 14, .T19, "19"
	PUSHBUTTON  66, 94, 14, 14, .T20, "20"
	STATUS .Info
END DIALOG

'#########################################################################
'Set defaults
GLOBAL Command AS STRING
GLOBAL ErrorMsg AS LONG
GLOBAL ReturnVal AS STRING
GLOBAL CurrentTrackLength AS INTEGER
ON ERROR GOTO ScriptError
WITH CDDialog
	.SetStyle STYLE_MINIMIZEBOX
	.SetTimer 1000
	.Slider.SetMinRange 0
	.Slider.SetMaxRange 1
	.Slider.SetTick 60
END WITH
NumberOfTracks% = 0

'Reset device
Command$ = "close cdaudio"
ReturnVal$ = SPACE(300)
ErrorMsg& = MMString(Command$,ReturnVal$,255&,0&)
' Open device
CDCommand "open cdaudio", " initializing CD!"
'Initialize time format
CDCommand "set cdaudio time format tmsf wait", " initializing CD!"

'#########################################################################
'Call Main Routine
DIALOG CDDialog

'#########################################################################
'End Script
ScriptEnd:
	'Stop the CD
	IF MediaPresent() THEN
		PauseMode = FALSE
		Command$ = "stop cdaudio"
		ReturnVal$ = SPACE(300)
		ErrorMsg& = MMString(Command$,ReturnVal$,255&,0&)
	ENDIF
	'Close the device
	Command$ = "close cdaudio"
	ReturnVal$ = SPACE(300)
	ErrorMsg& = MMString(Command$,ReturnVal$,255&,0&)
	END

'#########################################################################
' Error handling	
ScriptError:
	' We try to close the device
	RESUME AT ScriptEnd	

'#########################################################################
' Procedures

' Send a command to the CD player
FUNCTION CDCommand$( Command$, ErrorString$ )
	CDCommand$ = SPACE(300)
	ErrorMsg& = MMString(Command$,CDCommand$,255&,0&)
	IF ErrorMsg& <> 0 THEN
		MESSAGE "Error " & ErrorMsg& & ErrorString$
		FAIL 800
	ENDIF
END FUNCTION

' Test presence of CD in drive
FUNCTION MediaPresent() AS BOOLEAN
	'Check for a CD
	Command$ = "status cdaudio media present"
	ReturnVal$ = SPACE(300)
	ErrorMsg& = MMString(Command$,ReturnVal$,255&,0&)
	IF ErrorMsg& <> 0 THEN MediaPresent = FALSE
	MediaPresent = CBOL(ReturnVal$)
END FUNCTION

' Get current track
FUNCTION CDGetTrack%()
	IF MediaPresent() THEN
		'Gets the current track
		CDGetTrack% = CDCommand("status cdaudio current track", " reading CD!")
	ELSE
		CDGetTrack%=1
	END IF
END FUNCTION

' Play requested Track
SUB CDPlay(BYVAL TrackToPlay%)
	IF MediaPresent() THEN
		'Remove pause
		PauseMode = FALSE
		'Have the CD play the track
		IF TrackToPlay%<1 THEN TrackToPlay%=1
		IF TrackToPlay%<=NumberOfTracks% THEN 
			CDCommand "play cdaudio from " & TrackToPlay%, " playing CD!"
			' GetTrack Length
			ReturnVal$ = CDCommand("status cdaudio length track " & TrackToPlay%, " getting status!")
			CurrentTrackLength%=CINT(LEFT(ReturnVal$,2))*60+CINT(MID(ReturnVal$,4,2))
		END IF
	ENDIF
END SUB

' Seek to requested position on current track
SUB CDSeek(BYVAL SeekPos%)
	DIM Min AS INTEGER
	DIM Sec AS INTEGER

	IF MediaPresent() THEN
		'Remove pause
		PauseMode = FALSE
		' Get track info
		Min%=SeekPos%\60
		SeekPos%=SeekPos%-Min%*60
		Sec%=SeekPos%
		'Have the CD play the track
		CDCommand "play cdaudio from " & CDGetTrack%() & ":" & Min% & ":" & Sec%, " playing CD!"
	ENDIF
END SUB

' Stop CD
SUB CDStop()
	IF MediaPresent() THEN
		'Remove pause
		PauseMode = FALSE
		'Have the CD stop playing
		CDCommand "stop cdaudio", " stopping CD!"
	END IF
END SUB

' Eject CD
SUB CDEject()
	PauseMode = FALSE
	CDCommand "set cdaudio door open", " ejecting CD!"
END SUB

' Pause/Unpause CD
SUB CDPause()
	IF MediaPresent() THEN
		IF PauseMode THEN
			'We are paused; resume
			PauseMode = FALSE
			'Play the CD from the position saved when paused.
			CDCommand "play cdaudio from " & PausePosition$, " resuming CD!"
		ELSE
			'We need to set a pause
			PauseMode = TRUE
			'Get position and keep it
			PausePosition$ = CDCommand("status cdaudio position", " pausing CD!")
			'Stop the CD from playing
			CDCommand "stop cdaudio", " stopping CD!"
		ENDIF
	ENDIF
END SUB

'Update the dialog display
SUB UpdateDisplay()
	DIM NewNumberOfTracks AS INTEGER
	DIM Track AS STRING
	DIM Sec AS INTEGER

	'Initialize number of tracks
	IF MediaPresent() THEN
		NewNumberOfTracks% = CDCommand("status cdaudio number of tracks", " getting track info!")
	ELSE
		NewNumberOfTracks% = 0
	ENDIF
	
	WITH CDDialog
		' Update track buttons
		IF NewNumberOfTracks%<>NumberOfTracks% THEN
				NumberOfTracks%=NewNumberOfTracks%
				.T1.Enable NumberOfTracks%>0 
				.T2.Enable NumberOfTracks%>1 
				.T3.Enable NumberOfTracks%>2 
				.T4.Enable NumberOfTracks%>3 
				.T5.Enable NumberOfTracks%>4 
				.T6.Enable NumberOfTracks%>5 
				.T7.Enable NumberOfTracks%>6 
				.T8.Enable NumberOfTracks%>7 
				.T9.Enable NumberOfTracks%>8 
				.T10.Enable NumberOfTracks%>9 
				.T11.Enable NumberOfTracks%>10 
				.T12.Enable NumberOfTracks%>11 
				.T13.Enable NumberOfTracks%>12 
				.T14.Enable NumberOfTracks%>13 
				.T15.Enable NumberOfTracks%>14 
				.T16.Enable NumberOfTracks%>15 
				.T17.Enable NumberOfTracks%>16 
				.T18.Enable NumberOfTracks%>17 
				.T19.Enable NumberOfTracks%>18 
				.T20.Enable NumberOfTracks%>19 
		ENDIF				

		'Get status and update
		ReturnVal$ = CDCommand("status cdaudio mode", " reading position!")
		SELECT CASE ReturnVal$
			CASE "stopped"
				IF PauseMode THEN
					'We're paused, indicate where
					.Info.SetText "Paused-" & "Track " & CINT(LEFT(PausePosition$,2)) & " Time:" & MID(PausePosition$,4,5)
					.PlayButton.Enable TRUE
					.StopButton.Enable TRUE
					.PauseButton.Enable TRUE
					.NextTrack.Enable TRUE
					.PrevTrack.Enable TRUE
					.Eject.Enable TRUE
					.Slider.Enable TRUE
				ELSE
					'We're really stopped
					.Info.SetText "Stopped"
					.PlayButton.Enable TRUE
					.Slider.Enable TRUE
					.StopButton.Enable FALSE
					.PauseButton.Enable FALSE
					.NextTrack.Enable FALSE
					.PrevTrack.Enable FALSE
					.Eject.Enable TRUE
				ENDIF
	
			CASE "not ready"
				'Device not ready; don't allow anything
				.Info.SetText "Not ready"
				.PlayButton.Enable FALSE
				.Slider.Enable FALSE
				.StopButton.Enable FALSE
				.PauseButton.Enable FALSE
				.NextTrack.Enable FALSE
				.PrevTrack.Enable FALSE
				.Eject.Enable FALSE
	
			CASE "open"
				'No CD or door is open; don't allow anything
				.Info.SetText "No CD"
				.PlayButton.Enable FALSE
				.Slider.Enable FALSE
				.StopButton.Enable FALSE
				.PauseButton.Enable FALSE
				.NextTrack.Enable FALSE
				.PrevTrack.Enable FALSE
				.Eject.Enable FALSE
	
			CASE "playing"
				'Playing; get position and indicate it
				ReturnVal$ = CDCommand("status cdaudio position", " reading position!")
				Track$=CINT(LEFT(ReturnVal$,2))
				.Info.SetText "Playing-" & "Track " & Track$ & " Time:" & MID(ReturnVal$,4,5)
				.PlayButton.Enable TRUE
				.Slider.Enable TRUE
				.StopButton.Enable TRUE
				.PauseButton.Enable TRUE
				.NextTrack.Enable TRUE
				.PrevTrack.Enable TRUE
				.Eject.Enable TRUE
				' Update slider range if track has changed
				STATIC SliderTrack$
				IF SliderTrack$<>Track$ THEN
					SliderTrack$=Track$
					ReturnVal$ = CDCommand("status cdaudio length track " & Track$, " getting status!")
					CurrentTrackLength%=CINT(LEFT(ReturnVal$,2))*60+CINT(MID(ReturnVal$,4,2))
					CDDialog.Slider.SetMaxRange CurrentTrackLength%
					.Slider.SetValue 0
				ELSE
					' Update slider
					Sec%=CINT(MID(ReturnVal$,4,2))*60+CINT(MID(ReturnVal$,7,2))
					.Slider.SetValue Sec%
				END IF

			CASE ELSE
				'Other (unknown); assume not ready.
				.Info.SetText "Not ready"
				.PlayButton.Enable FALSE
				.Slider.Enable FALSE
				.StopButton.Enable FALSE
				.PauseButton.Enable FALSE
				.NextTrack.Enable FALSE
				.PrevTrack.Enable FALSE
				.Eject.Enable FALSE
		END SELECT
	END WITH
END SUB

'#########################################################################
'# CDPlayDialogSub: Main Dialog Event Handler, the heart of    *
'# the program.                                                *
'#########################################################################
SUB CDDialogSub (BYVAL ControlID%, BYVAL Event%)
	WITH CDDialog
	  IF Event% = EVENT_CHANGE AND ControlID% = .Slider.GetID() THEN
				CDSeek(.Slider.GetValue()) 
		ELSEIF Event% = EVENT_MOUSE_CLICK THEN
			SELECT CASE ControlID%
				CASE .PlayButton.GetID()
					CDPlay CDGetTrack%() 	'Play the Current track
				CASE .StopButton.GetID()
					CDStop 	'Stops the CD from playing
				CASE .Eject.GetID()
					CDEject	'Ejects the CD
				CASE .PauseButton.GetID()
					CDPause 'Pauses or Resumes playing
				CASE .PrevTrack.GetID()
					'Goes back one track from the one that is played, and plays
					'that track.
					CDPlay(CDGetTrack%()-1)
				CASE .NextTrack.GetID()
					'Goes ahead one track from the one that is played, and plays
					'that track.
					CDPlay(CDGetTrack%()+1)
				CASE .Slider.GetID()
					'Set new position
					CDSeek(.Slider.GetValue())
				CASE ELSE
					'Did we pressed a track button
					IF ControlID%>=.T1.GetID() AND ControlID%<=.T20.GetID() THEN
						CDPlay(ControlID%-.T1.GetID()+1)
					END IF
					
			END SELECT
		END IF
		' Update dialog display
		UpdateDisplay
	END WITH
END SUB
