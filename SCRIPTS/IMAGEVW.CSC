REM Views Bitmaps in a resizable box
REM ImageVw.csc  July 29, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

REM ***************************************************************
REM * Global Data                                                 *
REM ***************************************************************

#include "ScpConst.csi"

REM ***************************************************************
REM * Main Dialog                                                 *
REM ***************************************************************
BEGIN DIALOG OBJECT MainDialog 200, 100, "Corel SCRIPT Image Viewer", SUB MainDialogSub
	TEXT  5, 6, 120, 10, .Filename, ""
	IMAGE  5, 25, 190, 70, .ImageView
	PUSHBUTTON  135, 5, 60, 14, .Browse, "Browse"
END DIALOG

'Initialize the styles for the controls
MainDialog.SetStyle STYLE_MINIMZERESIZE
MainDialog.FileName.SetStyle STYLE_SUNKEN
MainDialog.ImageView.SetStyle STYLE_SUNKEN

'Execute the dialog
DIALOG MainDialog

REM ***************************************************************
REM * MainDialogSub: handles both the Browse button and the       *
REM * dialog resizing.                                            *
REM ***************************************************************
SUB MainDialogSub(BYVAL ControlID%, BYVAL Event%)
	DIM FileName AS STRING
	DIM DialogWidth AS INTEGER
	DIM DialogHeight AS INTEGER
	DIM ImageHeight AS INTEGER
	DIM ImageWidth AS INTEGER

	WITH MainDialog
		IF Event% = EVENT_MOUSE_CLICK THEN
			'Only Browse button
			FileName$ = GETFILEBOX("Bitmap files (*.bmp)|*.bmp")
			IF FileName$ <> "" THEN
				.FileName.SetText FileName$
				.ImageView.SetImage FileName$
			ENDIF
		ENDIF
		IF Event% = 6 THEN
			'Make sure the dialog has a reasonable size
			DialogWidth% = .GetWidth()
			IF DialogWidth% < 100 THEN DialogWidth% = 100
			DialogHeight% = .GetHeight()
			IF DialogHeight% < 60 THEN DialogHeight% = 60
			.Move .GetLeftPosition(), .GetTopPosition(), DialogWidth%, DialogHeight%
			'Resize the image
			ImageHeight% = DialogHeight% - 30
			ImageWidth% = DialogWidth% - 10
			.ImageView.Move 5,25,ImageWidth%, ImageHeight%
			'Resize the file name
			.FileName.Move 5, 6, DialogWidth% - 80, 10
			'Reposition the move button
			.Browse.Move DialogWidth% - 65, 5
		ENDIF
	END WITH
END SUB

