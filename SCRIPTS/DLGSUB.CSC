REM Creates a dialog event handler sub.
REM Dlgsub.csc  August 8, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

REM ***************************************************************
REM * Global Data                                                 *
REM ***************************************************************

#include "ScpConst.csi"
#define TAB1 (CHR(9))
#define TAB2 (TAB1 & TAB1)
#define TAB3 (TAB2 & TAB1)
#define TAB4 (TAB2 & TAB2)

REM ***************************************************************
REM * Main Dialog                                                 *
REM ***************************************************************
BEGIN DIALOG OBJECT MainDialog 208, 131, "Select Events to Handle"
	OKBUTTON  118, 114, 40, 14, .OK1
	CANCELBUTTON  162, 114, 40, 14, .Cancel1
	TEXT  27, 15, 37, 8, .Text1, "Sub Name:"
	TEXTBOX  66, 13, 109, 13, .SubName
	CHECKBOX  22, 37, 140, 10, .Initialize, "Dialog initialization"
	CHECKBOX  22, 47, 140, 10, .ChangeContent, "Control change in content"
	CHECKBOX  22, 57, 140, 10, .MouseClick, "Control mouse click"
	CHECKBOX  22, 67, 140, 10, .DoubleClick, "Listbox double-click"
	CHECKBOX  22, 77, 140, 10, .GetFocus, "Control receive focus"
	CHECKBOX  22, 87, 140, 10, .Timer, "Dialog timer up"
	CHECKBOX  22, 97, 140, 10, .Resize, "Dialog resize"
END DIALOG

REM ***************************************************************
REM * Program                                                     *
REM ***************************************************************

'Initialize dialog
MainDialog.SubName.SetText "DialogSub"

MainDialog.Initialize.SetThreeState FALSE
MainDialog.ChangeContent.SetThreeState FALSE
MainDialog.MouseClick.SetThreeState FALSE
MainDialog.DoubleClick.SetThreeState FALSE
MainDialog.GetFocus.SetThreeState FALSE
MainDialog.Timer.SetThreeState FALSE
MainDialog.Resize.SetThreeState FALSE

MainDialog.Initialize.SetValue 1
MainDialog.MouseClick.SetValue 1

DIM Ret AS INTEGER
Ret% = Dialog(MainDialog)

'Quit on cancel
IF Ret% = MSG_CANCEL THEN END

WITHOBJECT "CorelScript.Automation.7"
	.AddLineAfter ("SUB " & MainDialog.SubName.GetText() & "(BYVAL Event%, BYVAL ControlID%)")
	.AddLineAfter TAB1 & "SELECT CASE Event%"
	IF (MainDialog.Initialize.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_INITIALIZATION"
		.AddLineAfter TAB3 & "' Add Code here..."
	ENDIF
	IF (MainDialog.ChangeContent.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_CHANGE_IN_CONTENT"
		.AddLineAfter TAB3 & "SELECT CASE ControlID%"
		.AddLineAfter TAB4 & "' Add Code here..."
		.AddLineAfter TAB3 & "END SELECT"
	ENDIF
	IF (MainDialog.MouseClick.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_MOUSE_CLICK"
		.AddLineAfter TAB3 & "SELECT CASE ControlID%"
		.AddLineAfter TAB4 & "' Add Code here..."
		.AddLineAfter TAB3 & "END SELECT"
	ENDIF
	IF (MainDialog.DoubleClick.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_DBL_MOUSE_CLICK"
		.AddLineAfter TAB3 & "SELECT CASE ControlID%"
		.AddLineAfter TAB4 & "' Add Code here..."
		.AddLineAfter TAB3 & "END SELECT"
	ENDIF
	IF (MainDialog.GetFocus.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_RECEIVE_FOCUS"
		.AddLineAfter TAB3 & "SELECT CASE ControlID%"
		.AddLineAfter TAB4 & "' Add Code here..."
		.AddLineAfter TAB3 & "END SELECT"
	ENDIF
	IF (MainDialog.Timer.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_TIMER_EVENT"
		.AddLineAfter TAB3 & "' Add Code here..."
	ENDIF
	IF (MainDialog.Timer.GetValue() = 1) THEN
		.AddLineAfter TAB2 & "CASE EVENT_DIALOG_RESIZE"
		.AddLineAfter TAB3 & "' Add Code here..."
	ENDIF
	.AddLineAfter TAB1 & "END SELECT"
	.AddLineAfter "END SUB"
END WITHOBJECT


