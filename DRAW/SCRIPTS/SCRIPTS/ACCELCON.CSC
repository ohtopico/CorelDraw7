REM Ferramenta de Contorno Acelerado
REM Cria um efeito de contorno com deslocamentos variados.

'********************************************************************
' 
'   Script:	AccelCon.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to create the effect
'                of having "acceleration" with contours.
'                Each contour line gets farther apart/closer
'                together.
' 
'********************************************************************

#addfol  "..\..\..\scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE SUB ActivateTab( TabNum AS INTEGER, From AS INTEGER )
DECLARE SUB UpdateBlendButtons()
DECLARE SUB UpdateTabTops()
DECLARE SUB ApplyContours()
DECLARE FUNCTION ValidateOffset() AS BOOLEAN
DECLARE FUNCTION Min( Val1 AS INTEGER, Val2 AS INTEGER ) AS INTEGER
DECLARE SUB MakeHSB( BYVAL InRed AS LONG,   \\
				 BYVAL InGreen AS LONG, \\
				 BYVAL InBlue AS LONG,  \\
				 BYREF OutHue AS LONG,  \\
				 BYREF OutSat AS LONG,  \\
				 BYREF OutBri AS LONG )
DECLARE FUNCTION Mod256( InNum AS LONG ) AS LONG
DECLARE FUNCTION Mod360( InNum AS LONG ) AS LONG
DECLARE SUB UndoLastApply( RequireSelection AS BOOLEAN )
DECLARE FUNCTION CheckForSelection() AS BOOLEAN
DECLARE FUNCTION CheckForContour() AS BOOLEAN

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST TITLE_ERRORBOX$		= "Erro na Ferramenta de Contorno Acelerado"
GLOBAL CONST TITLE_INFOBOX$		= "Informações da Ferramenta de Contorno Acelerado"

' These are single and double newlines.
#define NL CHR(10) + CHR(13)
#define NL2 CHR(10) + CHR(13) + CHR(10) + CHR(13)

' The graphics used for the tabs.
GLOBAL CONST TAB1_BITMAP$ = "\ConDU.bmp"
GLOBAL CONST TAB2_BITMAP$ = "\ConCU.bmp"
GLOBAL CONST TAB3_BITMAP$ = "\ConAU.bmp"

' The graphics used for the color blend type buttons.
GLOBAL CONST COLOR_DIRECT_UNPRESSED_BITMAP$ = "\ColDirec.bmp"
GLOBAL CONST COLOR_DIRECT_PRESSED_BITMAP$ = "\ColDireP.bmp"
GLOBAL CONST COLOR_CCW_UNPRESSED_BITMAP$ = "\ColCCW.bmp"
GLOBAL CONST COLOR_CCW_PRESSED_BITMAP$ = "\ColCCWP.bmp"
GLOBAL CONST COLOR_CW_UNPRESSED_BITMAP$ = "\ColCW.bmp"
GLOBAL CONST COLOR_CW_PRESSED_BITMAP$ = "\ColCWP.bmp"

' Keys for searching the registry.
GLOBAL CONST REG_CORELDRAW_PATH$ = "SOFTWARE\Corel\CorelDRAW\7.0"
GLOBAL CONST REG_CORELDRAW_MAIN_DIR_KEY$ = "Destination"

'/////GLOBAL VARIABLES////////////////////////////////////////////////
GLOBAL IDLastFullContour& AS LONG	' The last contour created.
GLOBAL IDOriginal& AS LONG		' The original object selected by
							' the user.
GLOBAL CurDir$ AS STRING			' The directory where the script
							' was started from.

'/////CONNECT TO THE DRAW OBJECT/////////////////////////////////////
ON ERROR RESUME NEXT
ERRNUM = 0
WITHOBJECT OBJECT_DRAW
IF ERRNUM <> 0 THEN
	ERRNUM = 0
	DIM NoDrawReturn AS LONG	' The code returned by MESSAGEBOX.
	NoDrawReturn& = MESSAGEBOX("Impossível localizar o CorelDRAW." + NL2 + \\
	                           "Se este erro continuar, poderá ser necessário" + \\
	                           " reinstalar o CorelDRAW.", \\ 
						  TITLE_ERRORBOX$, \\
						  MB_STOP_ICON)
	STOP
ENDIF
ON ERROR EXIT

'/////PARAMETERS DIALOG//////////////////////////////////////////////

' Retrieve the directory where the script was started.
CurDir$ = GETCURRFOLDER()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF

' Images for tab 1.
GLOBAL Tab1Bitmaps(4) AS STRING
Tab1Bitmaps(1) = CurDir$ + TAB1_BITMAP$
Tab1Bitmaps(2) = CurDir$ + TAB1_BITMAP$
Tab1Bitmaps(3) = CurDir$ + TAB1_BITMAP$
Tab1Bitmaps(4) = CurDir$ + TAB1_BITMAP$

' Images for tab 2.
GLOBAL Tab2Bitmaps(4) AS STRING
Tab2Bitmaps(1) = CurDir$ + TAB2_BITMAP$
Tab2Bitmaps(2) = CurDir$ + TAB2_BITMAP$
Tab2Bitmaps(3) = CurDir$ + TAB2_BITMAP$
Tab2Bitmaps(4) = CurDir$ + TAB2_BITMAP$

' Images for tab 3.
GLOBAL Tab3Bitmaps(4) AS STRING
Tab3Bitmaps(1) = CurDir$ + TAB3_BITMAP$
Tab3Bitmaps(2) = CurDir$ + TAB3_BITMAP$
Tab3Bitmaps(3) = CurDir$ + TAB3_BITMAP$
Tab3Bitmaps(4) = CurDir$ + TAB3_BITMAP$

' The array of possible units the user may select from.
GLOBAL UnitsArray(10) AS STRING
UnitsArray(1) = "1 pol."
UnitsArray(2) = "1/36 pol."
UnitsArray(3) = "0,1 pol."
UnitsArray(4) = "0,01 pol."
UnitsArray(5) = "0,001 pol."
UnitsArray(6) = "1 cm."
UnitsArray(7) = "0,1 cm."
UnitsArray(8) = "0,01 cm."
UnitsArray(9) = "0,001 cm."
UnitsArray(10) = "1 pt."

' Multiplicative conversion factors to convert from the units to
' tenths of a micron.
GLOBAL ConversionFactors(10) AS SINGLE
ConversionFactors(1) = 1 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(2) = (1/36) * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(3) = 0.1 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(4) = 0.01 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(5) = 0.001 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(6) = 1 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(7) = 0.1 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(8) = 0.01 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(9) = 0.001 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(10) = 1 * LENGTHCONVERT(LC_POINTS, LC_TENTHS_OFA_MICRON, 1)

' Ways to specify the offset.
GLOBAL CONST AC_OFFSET_PER_STEP%	= 2
GLOBAL CONST AC_OFFSET_TOTAL%		= 1

' Variables needed for this dialog.
GLOBAL CurTab AS INTEGER			' Which tab is selected (1-3).
GLOBAL ColorBlendType AS INTEGER 	' Which color blend type is currently selected.
GLOBAL Offset AS INTEGER			' The size of the offset.
GLOBAL ChosenUnit AS INTEGER		' Which unit the user has chosen for the offset.
GLOBAL Steps AS INTEGER			' How many steps to use.
GLOBAL Direction AS INTEGER		' The direction to apply the contour.
GLOBAL OffsetType AS INTEGER		' How is the offset specified; one of AC_OFFSET_*.
GLOBAL OffsetAccel AS INTEGER		' The speed of the offset acceleration.
GLOBAL FillAccel AS INTEGER		' The speed of the fill acceleration.
GLOBAL OriginalFillType AS LONG	' The fill type of the originally selected object.

' The color variables.
GLOBAL ToOutlineRed AS LONG
GLOBAL ToOutlineGreen AS LONG
GLOBAL ToOutlineBlue AS LONG
GLOBAL ToOutlineHue AS LONG		' We duplicate the RGB values as HSB here
GLOBAL ToOutlineSat AS LONG		' instead of in the contour subroutine 
GLOBAL ToOutlineBri AS LONG		' in order to move some calculations out
GLOBAL ToFill1Red AS LONG		' and improve efficiency.
GLOBAL ToFill1Green AS LONG
GLOBAL ToFill1Blue AS LONG
GLOBAL ToFill1Hue AS LONG
GLOBAL ToFill1Sat AS LONG
GLOBAL ToFill1Bri AS LONG
GLOBAL ToFill2Red AS LONG
GLOBAL ToFill2Green AS LONG
GLOBAL ToFill2Blue AS LONG
GLOBAL ToFill2Hue AS LONG
GLOBAL ToFill2Sat AS LONG
GLOBAL ToFill2Bri AS LONG
GLOBAL FromFill1Red AS LONG		' The original fill color's red component.
GLOBAL FromFill1Green AS LONG		' The original fill color's green component.
GLOBAL FromFill1Blue AS LONG		' The original fill color's blue component.
GLOBAL FromFill1Hue AS LONG
GLOBAL FromFill1Sat AS LONG
GLOBAL FromFill1Bri AS LONG
GLOBAL FromFill2Red AS LONG		' For fountain fills, there is a second red component.
GLOBAL FromFill2Green AS LONG		' For fountain fills, there is a second green component.
GLOBAL FromFill2Blue AS LONG		' For fountain fills, there is a second blue component.
GLOBAL FromFill2Hue AS LONG
GLOBAL FromFill2Sat AS LONG
GLOBAL FromFill2Bri AS LONG
GLOBAL FromOutlineRed AS LONG		' The original outline color's red component.
GLOBAL FromOutlineGreen AS LONG	' The original outline color's green component.
GLOBAL FromOutlineBlue AS LONG	' The original outline color's blue component.
GLOBAL FromOutlineHue AS LONG
GLOBAL FromOutlineSat AS LONG
GLOBAL FromOutlineBri AS LONG

' Set up default values.
CurTab% = 1
ColorBlendType% = DRAW_BLEND_DIRECT%
Offset% = 2
ChosenUnit% = 7
Steps% = 3
OffsetType% = AC_OFFSET_PER_STEP%
Direction% = DRAW_CONTOUR_OUTSIDE&
ToOutlineRed& = 0
ToOutlineGreen& = 0
ToOutlineBlue& = 0
ToOutlineHue& = 0
ToOutlineSat& = 0
ToOutlineBri& = 0
ToFill1Red& = 0
ToFill1Green& = 0
ToFill1Blue& = 255
ToFill1Hue& = 240
ToFill1Sat& = 255
ToFill1Bri& = 255
ToFill2Red& = 255
ToFill2Green& = 0
ToFill2Blue& = 0
ToFill2Hue& = 0
ToFill2Sat& = 255
ToFill2Bri& = 255
OffsetAccel% = 0
FillAccel% = 0
OriginalFillType& = DRAW_FILL_UNIFORM& ' We are guessing that the first
							    ' contour will be applied to an
							    ' object with a uniform fill.
							    ' If this isn't true, the user will
							    ' be warned.

BEGIN DIALOG OBJECT ParamDialog 118, 185, "Contorno Acelerado", SUB ParamDialogEventHandler
	' Main controls.
	BITMAPBUTTON  5, 4, 21, 17, .Tab1Button
	BITMAPBUTTON  26, 4, 21, 17, .Tab2Button
	BITMAPBUTTON  47, 4, 21, 17, .Tab3Button
	PUSHBUTTON  3, 21, 111, 145, .MainTabBackground, ""
	TEXT  48, 20, 19, 4, .Tab3Cover, ""
	TEXT  6, 20, 19, 4, .Tab1Cover, ""
	TEXT  27, 20, 19, 4, .Tab2Cover, ""
	PUSHBUTTON  3, 169, 54, 13, .UndoButton, "Desfazer"
	PUSHBUTTON  60, 169, 54, 13, .ApplyButton, "Aplicar"
	' First tab controls.
	GROUPBOX  8, 27, 98, 52, .DirectionGroupBox, "Direção"
	OPTIONGROUP .TypeGroup
		OPTIONBUTTON  16, 106, 80, 11, .TotalOption, "Deslocamento total"
		OPTIONBUTTON  16, 94, 64, 11, .PerStepOption, "Por etapa"
	OPTIONGROUP .DirectionGroup
		OPTIONBUTTON  16, 37, 64, 11, .CenterOption, "Paa o centro"
		OPTIONBUTTON  16, 49, 64, 11, .InsideOption, "Dentro"
		OPTIONBUTTON  16, 61, 64, 11, .OutsideOption, "Fora"
	SPINCONTROL  35, 128, 22, 13, .OffsetSpin
	TEXT  10, 148, 24, 11, .StepsText, "Etapas:"
	DDLISTBOX  63, 128, 45, 100, .UnitsListBox
	TEXT  58, 130, 5, 9, .XText, "x"
	SPINCONTROL  35, 146, 73, 13, .StepsSpin
	TEXT  10, 130, 21, 11, .OffsetText, "Deslc:"
	GROUPBOX  10, 84, 97, 38, .TypeGroupBox, "Tipo de deslocamento"
	' Second tab controls.
	GROUPBOX  10, 28, 97, 70, .BlendGroupBox, "Tipo de mistura de cor"
	BITMAPBUTTON  20, 45, 14, 14, .DirectButton
	BITMAPBUTTON  20, 59, 14, 14, .CWButton
	BITMAPBUTTON  20, 73, 14, 14, .CCWButton
	TEXT  38, 76, 60, 10, .CCWText, "Anti-horária"
	TEXT  38, 62, 55, 8, .CWText, "Horária"
	TEXT  38, 47, 20, 9, .DirectText, "Direta"
	PUSHBUTTON  10, 124, 97, 13, .FillButton1, "Selecione cor preench. alvo"
	PUSHBUTTON  10, 142, 97, 13, .FillButton2, "Selecione cor preench. alvo núm. 2"
	PUSHBUTTON  10, 106, 97, 13, .OutlineButton, "Selecione cor do traç. alvo"
	' Third tab controls.
	HSLIDER 10, 107, 95, 12, .FillSlider
	TEXT  15, 89, 85, 16, .FillAccelerateText, "Acelerar preenchimentos/traçados:"
	TEXT  15, 33, 76, 16, .OffsetAccelerateText, "Acelerar deslocamentos:"
	HSLIDER 10, 51, 95, 12, .OffsetSlider
	PUSHBUTTON  33, 122, 45, 13, .CenterFillButton, "Centralizar"
	PUSHBUTTON  33, 65, 45, 13, .CenterOffsetButton, "Centralizar"
END DIALOG

SUB ParamDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.

	IF Event% = EVENT_INITIALIZATION& THEN
		' We want a 3-D background for the pseudo-tab control.
		ParamDialog.MainTabBackground.Enable FALSE
		
		' Set up all the images for the tabs.
		ParamDialog.Tab1Button.SetArray Tab1Bitmaps$
		ParamDialog.Tab2Button.SetArray Tab2Bitmaps$
		ParamDialog.Tab3Button.SetArray Tab3Bitmaps$
		
		' Make sure the images resize to the image box size
		' so they look good in large fonts.
		ParamDialog.Tab1Button.SetStyle STYLE_IMAGE_AUTO_RESIZE
		ParamDialog.Tab2Button.SetStyle STYLE_IMAGE_AUTO_RESIZE
		ParamDialog.Tab3Button.SetStyle STYLE_IMAGE_AUTO_RESIZE
		
		' Set up the blend type buttons.
		ParamDialog.DirectButton.SetStyle STYLE_IMAGE_CENTERED
		ParamDialog.CWButton.SetStyle STYLE_IMAGE_CENTERED
		ParamDialog.CCWButton.SetStyle STYLE_IMAGE_CENTERED
		UpdateBlendButtons
		
		' Set up the units-related material.
		ParamDialog.UnitsListBox.SetArray UnitsArray$
		ParamDialog.UnitsListBox.SetSelect ChosenUnit%
		ParamDialog.OffsetSpin.SetValue Offset%
		
		' Set up the steps-related material.
		ParamDialog.StepsSpin.SetValue Steps%
		SELECT CASE Direction%
			CASE DRAW_CONTOUR_OUTSIDE&
				ParamDialog.OutsideOption.SetValue 1
			CASE DRAW_CONTOUR_INSIDE&
				ParamDialog.InsideOption.SetValue 1
			CASE DRAW_CONTOUR_TO_CENTER&
				ParamDialog.CenterOption.SetValue 1
				OffsetType% = AC_OFFSET_PER_STEP%
				ParamDialog.TotalOption.Enable FALSE
				ParamDialog.StepsSpin.Enable FALSE
				ParamDialog.StepsText.Enable FALSE
		END SELECT
		IF OffsetType% = AC_OFFSET_PER_STEP% THEN
			ParamDialog.PerStepOption.SetValue 1
		ELSE
			ParamDialog.TotalOption.SetValue 1
		ENDIF

		' Set up the acceleration bars.
		ParamDialog.OffsetSlider.SetMinRange -50
		ParamDialog.OffsetSlider.SetMaxRange 50
		ParamDialog.OffsetSlider.SetIncrement 1
		ParamDialog.OffsetSlider.SetValue OffsetAccel%
		ParamDialog.FillSlider.SetMinRange -20
		ParamDialog.FillSlider.SetMaxRange 20
		ParamDialog.FillSlider.SetIncrement 1
		ParamDialog.FillSlider.SetValue FillAccel%
		
		' There is initially nothing to Undo.
		ParamDialog.UndoButton.Enable FALSE
		
		' Activate the current tab.
		ActivateTab CurTab%, 0
		
	ELSEIF Event% = EVENT_MOUSE_CLICK& THEN
		SELECT CASE ControlID% 
		
			CASE ParamDialog.Tab1Button.GetID()
				IF CurTab% <> 1 THEN
					ActivateTab 1, CurTab%
				ENDIF
				
			CASE ParamDialog.Tab2Button.GetID()
				IF CurTab% <> 2 THEN
					ActivateTab 2, CurTab%
				ENDIF
				
			CASE ParamDialog.Tab3Button.GetID()
				IF CurTab% <> 3 THEN
					ActivateTab 3, CurTab%
				ENDIF
			
			CASE ParamDialog.DirectButton.GetID()
				ColorBlendType% = DRAW_BLEND_DIRECT%
				UpdateBlendButtons
					
			CASE ParamDialog.CCWButton.GetID()
				ColorBlendType% = DRAW_BLEND_RAINBOW_CCW%
				UpdateBlendButtons
				
			CASE ParamDialog.CWButton.GetID()
				ColorBlendType% = DRAW_BLEND_RAINBOW_CW%
				UpdateBlendButtons
				
			CASE ParamDialog.UnitsListBox.GetID()
				ChosenUnit% = ParamDialog.UnitsListBox.GetSelect()

			CASE ParamDialog.FillButton1.GetID()
				GETCOLOR ToFill1Red&, ToFill1Green&, ToFill1Blue&
				' We convert to HSB here for efficiency.
				MakeHSB ToFill1Red&, ToFill1Green&, ToFill1Blue&, \\
				        ToFill1Hue&, ToFill1Sat&, ToFill1Bri&
				
			CASE ParamDialog.FillButton2.GetID()
				GETCOLOR ToFill2Red&, ToFill2Green&, ToFill2Blue&
				' We convert to HSB here for efficiency.
				MakeHSB ToFill2Red&, ToFill2Green&, ToFill2Blue&, \\
				        ToFill2Hue&, ToFill2Sat&, ToFill2Bri&
			
			CASE ParamDialog.OutlineButton.GetID()
				GETCOLOR ToOutlineRed&, ToOutlineGreen&, ToOutlineBlue&
				' We convert to HSB here for efficiency.
				MakeHSB ToOutlineRed&, ToOutlineGreen&, ToOutlineBlue&, \\
				        ToOutlineHue&, ToOutlineSat&, ToOutlineBri&

			CASE ParamDialog.CenterOption.GetID()
				Direction% = DRAW_CONTOUR_TO_CENTER&
				ParamDialog.TotalOption.Enable FALSE
				ParamDialog.PerStepOption.SetValue 1
				ParamDialog.StepsSpin.Enable FALSE
				ParamDialog.StepsText.Enable FALSE
				
			CASE ParamDialog.InsideOption.GetID()
				Direction% = DRAW_CONTOUR_INSIDE&
				ParamDialog.TotalOption.Enable TRUE
				ParamDialog.StepsSpin.Enable TRUE
				ParamDialog.StepsText.Enable TRUE
				
			CASE ParamDialog.OutsideOption.GetID()
				Direction% = DRAW_CONTOUR_OUTSIDE&
				ParamDialog.TotalOption.Enable TRUE
				ParamDialog.StepsSpin.Enable TRUE
				ParamDialog.StepsText.Enable TRUE
				
			CASE ParamDialog.TotalOption.GetID()
				OffsetType% = AC_OFFSET_TOTAL%
				
			CASE ParamDialog.PerStepOption.GetID()
				OffsetType% = AC_OFFSET_PER_STEP%

			CASE ParamDialog.ApplyButton.GetID()
				IF ValidateOffset() THEN
					UndoLastApply TRUE
					ApplyContours
				ENDIF
				
			CASE ParamDialog.FillSlider.GetID()
				FillAccel% = ParamDialog.FillSlider.GetValue()
			
			CASE ParamDialog.OffsetSlider.GetID()
				OffsetAccel% = ParamDialog.OffsetSlider.GetValue()
				
			CASE ParamDialog.UndoButton.GetID()
				UndoLastApply FALSE
				
			CASE ParamDialog.CenterFillButton.GetID()
				ParamDialog.FillSlider.SetValue 0
				FillAccel% = 0

			CASE ParamDialog.CenterOffsetButton.GetID()
				ParamDialog.OffsetSlider.SetValue 0
				OffsetAccel% = 0

		END SELECT
	
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%
			CASE ParamDialog.OffsetSpin.GetID()
				IF (ParamDialog.OffsetSpin.GetValue() < 1) THEN
					MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                                 "entre 1 e 99.", \\
                                                 TITLE_INFOBOX$, \\
                                                 MB_INFORMATION_ICON&)
					ParamDialog.OffsetSpin.SetValue 1
					Offset% = 1
				ELSEIF (ParamDialog.OffsetSpin.GetValue() > 99) THEN
					MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                                 "entre 1 e 99.", \\
                                                 TITLE_INFOBOX$, \\
                                                 MB_INFORMATION_ICON&)
					ParamDialog.OffsetSpin.SetValue 99
					Offset% = 99
				ELSE
					Offset% = ParamDialog.OffsetSpin.GetValue()
				ENDIF
			
			CASE ParamDialog.StepsSpin.GetID()
				IF (ParamDialog.StepsSpin.GetValue() < 1) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de etapas " + \\
                                                 "entre 1 e 99.", \\
                                                 TITLE_INFOBOX$, \\
                                                 MB_INFORMATION_ICON&)
					ParamDialog.StepsSpin.SetValue 1
					Steps% = 1
				ELSEIF (ParamDialog.StepsSpin.GetValue() > 99) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de etapas " + \\
                                                 "entre 1 e 99.", \\
                                                 TITLE_INFOBOX$, \\
                                                 MB_INFORMATION_ICON&)
					ParamDialog.StepsSpin.SetValue 99
					Steps% = 99
				ELSE
					Steps% = ParamDialog.StepsSpin.GetValue()
				ENDIF
				
			CASE ParamDialog.FillSlider.GetID()
				FillAccel% = ParamDialog.FillSlider.GetValue()
			
			CASE ParamDialog.OffsetSlider.GetID()
				OffsetAccel% = ParamDialog.OffsetSlider.GetValue()

		END SELECT
	
	ELSEIF Event% = EVENT_RECEIVE_FOCUS& THEN
		' Make sure the focus change does not destroy
		' our pseudo-tab effect.
		UpdateTabTops
		
	ENDIF

END SUB

'********************************************************************
'
'	Name:	ValidateOffset (dialog function)
'
'	Action:	Checks to make sure that the user's chosen offset
'              value is greater than 0.  If not, displays an error
'              message and sets the offset to 1.
'
'	Params:	None.  Since this is intended to be a dialog function,
'              it inspects ParamDialog.OffsetSpin and may alter 
'              Offset%.
'
'	Returns:	If an error message had to be displayed, returns
'              FALSE.  Otherwise returns TRUE.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ValidateOffset() AS BOOLEAN

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.

	IF ParamDialog.OffsetSpin.GetValue() < 1 THEN
		MsgReturn& = MESSAGEBOX("O valor de deslocamento selecionado deve ser " + \\
		                        "maior que 0." + NL2 + \\
		                        "Selecione outro valor de deslocamento e " + \\
		                        "tente outra vez.", TITLE_ERRORBOX$, \\
		                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
		Offset% = 1
		ParamDialog.OffsetSpin.SetValue Offset%
		ValidateOffset = FALSE
	ELSE
		ValidateOffset = TRUE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	ActivateTab (dialog subroutine)
'
'	Action:	Activates a specified tab in ParamDialog
'              (ie. makes it look like it has been pressed and
'              brings it to the front).
'
'	Params:	TabNum - Which tab to bring forward (1-3)?
'			From - Which tab are we coming from? (0 means repaint all)
'
'	Returns:	None.
'
'	Comments:	If TabNum < 1 OR TabNum > 3 does nothing.
'
'********************************************************************
SUB ActivateTab(TabNum AS INTEGER, From AS INTEGER)

	SELECT CASE TabNum%
		CASE 1
			' Do the main tab controls. (We are not calling
			' UpdateTabTops to avoid procedure call-overhead.)
			ParamDialog.Tab1Cover.SetStyle STYLE_VISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE
			
			IF (From% = 2) OR (From% = 0) THEN
				' Tab 2 controls.
				ParamDialog.BlendGroupBox.SetStyle STYLE_INVISIBLE
				ParamDialog.DirectButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CWButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CCWButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CCWText.SetStyle STYLE_INVISIBLE
				ParamDialog.CWText.SetStyle STYLE_INVISIBLE
				ParamDialog.DirectText.SetStyle STYLE_INVISIBLE
				ParamDialog.FillButton1.SetStyle STYLE_INVISIBLE
				ParamDialog.FillButton2.SetStyle STYLE_INVISIBLE
				ParamDialog.OutlineButton.SetStyle STYLE_INVISIBLE
			ENDIF
			
			IF (From% = 3) OR (From% = 0) THEN
				' Tab 3 controls.
				ParamDialog.FillSlider.SetStyle STYLE_INVISIBLE
				ParamDialog.FillAccelerateText.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetAccelerateText.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetSlider.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterOffsetButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterFillButton.SetStyle STYLE_INVISIBLE
			ENDIF
						
			' Tab 1 controls.
			ParamDialog.DirectionGroupBox.SetStyle STYLE_VISIBLE
			ParamDialog.TotalOption.SetStyle STYLE_VISIBLE
			ParamDialog.PerStepOption.SetStyle STYLE_VISIBLE
			ParamDialog.CenterOption.SetStyle STYLE_VISIBLE
			ParamDialog.OutsideOption.SetStyle STYLE_VISIBLE
			ParamDialog.InsideOption.SetStyle STYLE_VISIBLE
			ParamDialog.OffsetSpin.SetStyle STYLE_VISIBLE
			ParamDialog.UnitsListBox.SetStyle STYLE_VISIBLE
			ParamDialog.XText.SetStyle STYLE_VISIBLE
			ParamDialog.StepsText.SetStyle STYLE_VISIBLE
			ParamDialog.StepsSpin.SetStyle STYLE_VISIBLE
			ParamDialog.OffsetText.SetStyle STYLE_VISIBLE
			ParamDialog.TypeGroupBox.SetStyle STYLE_VISIBLE
			
			' Set the current tab number.
			CurTab% = 1
			
		CASE 2
			' Do the main tab controls.
			ParamDialog.Tab1Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_VISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE

			IF (From% = 1) OR (From% = 0) THEN
				' Tab 1 controls.
				ParamDialog.DirectionGroupBox.SetStyle STYLE_INVISIBLE
				ParamDialog.TotalOption.SetStyle STYLE_INVISIBLE
				ParamDialog.PerStepOption.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterOption.SetStyle STYLE_INVISIBLE
				ParamDialog.OutsideOption.SetStyle STYLE_INVISIBLE
				ParamDialog.InsideOption.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetSpin.SetStyle STYLE_INVISIBLE
				ParamDialog.UnitsListBox.SetStyle STYLE_INVISIBLE
				ParamDialog.XText.SetStyle STYLE_INVISIBLE
				ParamDialog.StepsText.SetStyle STYLE_INVISIBLE
				ParamDialog.StepsSpin.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetText.SetStyle STYLE_INVISIBLE
				ParamDialog.TypeGroupBox.SetStyle STYLE_INVISIBLE
			ENDIF
						
			IF (From% = 3) OR (From% = 0) THEN
				' Tab 3 controls.
				ParamDialog.FillSlider.SetStyle STYLE_INVISIBLE
				ParamDialog.FillAccelerateText.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetAccelerateText.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetSlider.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterOffsetButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterFillButton.SetStyle STYLE_INVISIBLE
			ENDIF
			
			' Tab 2 controls.
			ParamDialog.BlendGroupBox.SetStyle STYLE_VISIBLE
			ParamDialog.DirectButton.SetStyle STYLE_VISIBLE
			ParamDialog.CWButton.SetStyle STYLE_VISIBLE
			ParamDialog.CCWButton.SetStyle STYLE_VISIBLE
			ParamDialog.CCWText.SetStyle STYLE_VISIBLE
			ParamDialog.CWText.SetStyle STYLE_VISIBLE
			ParamDialog.DirectText.SetStyle STYLE_VISIBLE
			ParamDialog.FillButton1.SetStyle STYLE_VISIBLE
			
			' Since the user may select different objects and expect
			' the contour to be applied to those objects, check the
			' fill type before displaying controls.
			ON ERROR GOTO STNoSelection
				OriginalFillType& = .GetFillType()
			ON ERROR EXIT
			Continue:
			SELECT CASE OriginalFillType&
				CASE DRAW_FILL_UNIFORM&
					ParamDialog.FillButton1.Enable TRUE
					ParamDialog.FillButton1.SetText "Selecione cor preench. alvo"
					ParamDialog.FillButton2.SetStyle STYLE_INVISIBLE
				CASE DRAW_FILL_FOUNTAIN&
					ParamDialog.FillButton1.Enable TRUE
					ParamDialog.FillButton1.SetText "Selecione cor preench. alvo núm. 1"
					ParamDialog.FillButton2.SetStyle STYLE_VISIBLE
				CASE ELSE
					ParamDialog.FillButton1.SetText "Selecione cor preench. alvo"
					ParamDialog.FillButton1.Enable FALSE
					ParamDialog.FillButton2.SetStyle STYLE_INVISIBLE
			END SELECT
			ParamDialog.OutlineButton.SetStyle STYLE_VISIBLE

			' Set the current tab number.
			CurTab% = 2
			
		CASE 3
			' Do the main tab controls.
			ParamDialog.Tab1Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_VISIBLE 
			ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE

			IF (From% = 1) OR (From% = 0) THEN
				' Tab 1 controls.
				ParamDialog.DirectionGroupBox.SetStyle STYLE_INVISIBLE
				ParamDialog.TotalOption.SetStyle STYLE_INVISIBLE
				ParamDialog.PerStepOption.SetStyle STYLE_INVISIBLE
				ParamDialog.CenterOption.SetStyle STYLE_INVISIBLE
				ParamDialog.OutsideOption.SetStyle STYLE_INVISIBLE
				ParamDialog.InsideOption.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetSpin.SetStyle STYLE_INVISIBLE
				ParamDialog.UnitsListBox.SetStyle STYLE_INVISIBLE
				ParamDialog.XText.SetStyle STYLE_INVISIBLE
				ParamDialog.StepsText.SetStyle STYLE_INVISIBLE
				ParamDialog.StepsSpin.SetStyle STYLE_INVISIBLE
				ParamDialog.OffsetText.SetStyle STYLE_INVISIBLE
				ParamDialog.TypeGroupBox.SetStyle STYLE_INVISIBLE
			ENDIF
			
			IF (From% = 2) OR (From% = 0) THEN
				' Tab 2 controls.
				ParamDialog.BlendGroupBox.SetStyle STYLE_INVISIBLE
				ParamDialog.DirectButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CWButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CCWButton.SetStyle STYLE_INVISIBLE
				ParamDialog.CCWText.SetStyle STYLE_INVISIBLE
				ParamDialog.CWText.SetStyle STYLE_INVISIBLE
				ParamDialog.DirectText.SetStyle STYLE_INVISIBLE
				ParamDialog.FillButton1.SetStyle STYLE_INVISIBLE
				ParamDialog.FillButton2.SetStyle STYLE_INVISIBLE
				ParamDialog.OutlineButton.SetStyle STYLE_INVISIBLE
			ENDIF
			
			' Tab 3 controls.
			ParamDialog.FillSlider.SetStyle STYLE_VISIBLE
			ParamDialog.FillAccelerateText.SetStyle STYLE_VISIBLE
			ParamDialog.OffsetAccelerateText.SetStyle STYLE_VISIBLE
			ParamDialog.OffsetSlider.SetStyle STYLE_VISIBLE
			ParamDialog.CenterOffsetButton.SetStyle STYLE_VISIBLE
			ParamDialog.CenterFillButton.SetStyle STYLE_VISIBLE

			' Set the current tab number.
			CurTab% = 3
			
	END SELECT

	EXIT SUB
	
STNoSelection:
	ERRNUM = 0
	RESUME AT Continue

END SUB

'********************************************************************
'
'	Name:	UpdateTabTops (dialog subroutine)
'
'	Action:	Makes sure that the top of the pseudo-tab control
'              retains a proper z-ordering of controls.
'
'	Params:	None.  As this is intended to be a dialog subroutine,
'              it makes use of a variable global to UpdateTabTops,
'              CurTab%.  This tells us which tab should be active.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateTabTops

	' Uncommenting the three commented lines in this routine will
	' remove some display artifacts which may occur when using the
	' keyboard to tab through the controls, but it causes unpleasant
	' flicker and so has been disabled.
	SELECT CASE CurTab%
		CASE 1
			ParamDialog.Tab1Cover.SetStyle STYLE_VISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_INVISIBLE 
			'ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE
						
		CASE 2
			ParamDialog.Tab1Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_VISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_INVISIBLE 
			'ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE

		CASE 3
			ParamDialog.Tab1Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab2Cover.SetStyle STYLE_INVISIBLE 
			ParamDialog.Tab3Cover.SetStyle STYLE_VISIBLE 
			'ParamDialog.MainTabBackground.SetStyle STYLE_VISIBLE
	END SELECT

END SUB

'********************************************************************
'
'	Name:	UpdateBlendButtons (dialog subroutine)
'
'	Action:	Updates which of the blend buttons appears
'              to be pressed down and which appears to be
'              pressed up based on the value of ColorBlendType.
'
'	Params:	None.  As this is intended to be a dialog function,
'              it makes use of the variable global to ParamDialog:
'              ColorBlendType.
'
'	Returns:	None.
'
'	Comments: None.
'
'********************************************************************
SUB UpdateBlendButtons()

	DIM Bitmaps(3) AS STRING	' Will hold the images to use.
	
	' Normally, all buttons should appear to be up.
	Bitmaps$(1) = CurDir$ + COLOR_DIRECT_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_DIRECT_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_DIRECT_UNPRESSED_BITMAP$
	ParamDialog.DirectButton.SetArray Bitmaps$
	Bitmaps$(1) = CurDir$ + COLOR_CCW_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_CCW_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_CCW_UNPRESSED_BITMAP$
	ParamDialog.CCWButton.SetArray Bitmaps$
	Bitmaps$(1) = CurDir$ + COLOR_CW_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_CW_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_CW_UNPRESSED_BITMAP$
	ParamDialog.CWButton.SetArray Bitmaps$

	' Make the appropriate button look like it's pressed down.
	SELECT CASE ColorBlendType%
	
		CASE DRAW_BLEND_DIRECT%
			Bitmaps$(1) = CurDir$ + COLOR_DIRECT_PRESSED_BITMAP$
			Bitmaps$(2) = CurDir$ + COLOR_DIRECT_UNPRESSED_BITMAP$
			Bitmaps$(3) = CurDir$ + COLOR_DIRECT_PRESSED_BITMAP$
			ParamDialog.DirectButton.SetArray Bitmaps$
			
		CASE DRAW_BLEND_RAINBOW_CCW%
			Bitmaps$(1) = CurDir$ + COLOR_CCW_PRESSED_BITMAP$
			Bitmaps$(2) = CurDir$ + COLOR_CCW_UNPRESSED_BITMAP$
			Bitmaps$(3) = CurDir$ + COLOR_CCW_PRESSED_BITMAP$
			ParamDialog.CCWButton.SetArray Bitmaps$
			
		CASE DRAW_BLEND_RAINBOW_CW%
			Bitmaps$(1) = CurDir$ + COLOR_CW_PRESSED_BITMAP$
			Bitmaps$(2) = CurDir$ + COLOR_CW_UNPRESSED_BITMAP$
			Bitmaps$(3) = CurDir$ + COLOR_CW_PRESSED_BITMAP$
			ParamDialog.CWButton.SetArray Bitmaps$
			
	END SELECT	

END SUB

'********************************************************************
'
'	Name:	UndoLastApply (dialog subroutine)
'
'	Action:	Deletes the last created contour if possible.
'
'	Params:	RequireASelection - If TRUE, this routine
'              will only perform the undo if the actual
'              contour is currently selected.
'              As this is intended to be a dialog subroutine,
'              it makes use of variables global to ParamDialog.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UndoLastApply( RequireSelection AS BOOLEAN )

	DIM MessageText AS STRING
	DIM MsgReturn AS LONG
	DIM CurObj AS LONG

	ON ERROR GOTO ULAISError
	
	IF IDLastFullContour& > 0 THEN
		IF RequireSelection THEN
			IF NOT CheckForSelection() THEN
				EXIT SUB
			ELSE
				CurObj& = .GetObjectsCDRStaticID()
			ENDIF
			IF (CurObj& <> IDLastFullContour&)  THEN
				EXIT SUB
			ENDIF
		ENDIF
		IF .SelectObjectOfCDRStaticID(IDLastFullContour&) THEN
			.DeleteObject
		ELSE
			' The object has somehow been deleted!
			' Hence, our undo fails.
			FAIL 5000 ' Trigger the error handler.
		ENDIF
		.SelectObjectOfCDRStaticID IDOriginal&
		IDLastFullContour& = 0
	ELSEIF NOT RequireSelection THEN
		FAIL 5000 ' Trigger the error handler.
	ENDIF

	VeryEnd:
		IF NOT RequireSelection THEN
			ParamDialog.UndoButton.Enable FALSE
		ENDIF
		EXIT SUB

ULAISError:
	' The operation cannot be done.
	ERRNUM = 0
	MessageText$ = "Impossível desfazer o último contorno." + NL2 + \\
	               "Talvez o grupo de contorno já tenha sido excluído."
	MsgReturn& = MESSAGEBOX( MessageText$, TITLE_INFOBOX$, MB_OK_ONLY& )
	RESUME AT VeryEnd

END SUB

'********************************************************************
'
'	Name:	ApplyContours(dialog subroutine)
'
'	Action:	Applies the contour effect specified in ParamDialog.
'
'	Params:	None.  Since this routine is intended to be
'              a dialog subroutine, it makes use of variables
'              global to ParamDialog.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB ApplyContours

	CONST BaseAdjustment# = 0.000001 ' Avoids asymptotic logarithm problems.
	CONST Precision! = 0.95		' The percentage by which inside and
							' to center blends miss the center.
							' (Higher precisions take longer.)

	DIM MsgReturn AS LONG		' The return value of MESSAGEBOX.
	DIM Counter AS INTEGER		' A counter variable for loops.
	DIM LastUOffset AS DOUBLE	' The last uniform offset distance we applied.
	DIM CurUOffset AS DOUBLE		' The current uniform offset we will apply.
	DIM UniformFill AS DOUBLE	' The uniform fill/outline logarithmic range.
	DIM CurUFill AS DOUBLE		' The current uniform fill/outline we will apply.
	DIM CurRealOffset AS LONG	' How much offset to apply (accelerated).
	DIM BaseOff AS DOUBLE		' The base of the offset accel. logarithm.
	DIM BaseCol AS DOUBLE		' The base of the color accel. logarithm.
	DIM SpeedOUp AS BOOLEAN		' Whether the offset acceleration speeds up
							' or slows down.
	DIM SpeedCUp AS BOOLEAN		' Whether the color acceleration speeds up
							' or slows down.
	DIM WholeOffset AS LONG		' The total offset that the final 
							' contour line should have (tm).
	DIM WholeRedDeltaOutline AS LONG	' The total red delta on a direct color blend.
	DIM WholeGreenDeltaOutline AS LONG ' The total green delta on a direct color blend.
	DIM WholeBlueDeltaOutline AS LONG	' The total blue delta on a direct color blend.
	DIM WholeHueDeltaOutline AS LONG	' The total hue delta on CW or CCW blends.
	DIM WholeSatDeltaOutline AS LONG	' The total saturation delta.
	DIM WholeBriDeltaOutline AS LONG	' The total brightness delta.
	DIM WholeRedDeltaFill1 AS LONG	' The total red delta on a direct color blend (1).
	DIM WholeGreenDeltaFill1 AS LONG	' The total green delta on a direct color blend (1).
	DIM WholeBlueDeltaFill1 AS LONG	' The total blue delta on a direct color blend (1).
	DIM WholeHueDeltaFill1 AS LONG	' The total hue delta on CW or CCW blends (1).
	DIM WholeSatDeltaFill1 AS LONG	' The total saturation delta.
	DIM WholeBriDeltaFill1 AS LONG	' The total brightness delta.
	DIM WholeRedDeltaFill2 AS LONG	' The total red delta on a direct color blend (2).
	DIM WholeGreenDeltaFill2 AS LONG	' The total green delta on a direct color blend (2).
	DIM WholeBlueDeltaFill2 AS LONG	' The total blue delta on a direct color blend (2).
	DIM WholeHueDeltaFill2 AS LONG	' The total hue delta on CW or CCW blends (2).
	DIM WholeSatDeltaFill2 AS LONG	' The total saturation delta.
	DIM WholeBriDeltaFill2 AS LONG	' The total brightness delta.
	DIM UniformStep AS DOUBLE	' The size of a uniform step.
	DIM IDLast AS LONG			' The CDRStaticID of the last object we had.
	DIM IDCurrent AS LONG		' The CDRStaticID of the current object we have.
	DIM IDContoured AS LONG		' The CDRStaticID of the newest contoured object.
	DIM OrigXPos AS LONG		' The X coordinate of the original.
	DIM OrigYPos AS LONG		' The Y coordinate of the original.
	DIM ColTmpModel AS LONG		' The color model of a temporary color.
	DIM ColTmp1 AS LONG			' The first component of a temporary color.
	DIM ColTmp2 AS LONG			' The second component of a temporary color.
	DIM ColTmp3 AS LONG			' The third component of a temporary color.
	DIM ColTmp4 AS LONG			' The fourth component of a temporary color.
	DIM ColTmpPosition AS LONG	' For fountain fills, the position of this color.	
	DIM CurOutlineRed AS LONG	' The current contour line's red component.
	DIM CurOutlineGreen AS LONG	' The current contour line's green component.
	DIM CurOutlineBlue AS LONG	' The current contour line's blue component.
	DIM CurOutlineHue AS LONG	' The current contour line's hue component.
	DIM CurOutlineSat AS LONG	' The current contour line's saturation component.
	DIM CurOutlineBri AS LONG	' The current contour line's brightness component.
	DIM CurFill1Red AS LONG		' The current contour fill 1's red component.
	DIM CurFill1Green AS LONG	' The current contour fill 1's green component.
	DIM CurFill1Blue AS LONG		' The current contour fill 1's blue component.
	DIM CurFill1Hue AS LONG		' The current contour fill 1's hue component.
	DIM CurFill1Sat AS LONG		' The current contour fill 1's saturation component.
	DIM CurFill1Bri AS LONG		' The current contour fill 1's brightness component.
	DIM CurFill2Red AS LONG		' The current contour fill 2's red component.
	DIM CurFill2Green AS LONG	' The current contour fill 2's green component.
	DIM CurFill2Blue AS LONG		' The current contour fill 2's blue component.
	DIM CurFill2Hue AS LONG		' The current contour fill 2's hue component.
	DIM CurFill2Sat AS LONG		' The current contour fill 2's saturation component.
	DIM CurFill2Bri AS LONG		' The current contour fill 2's brightness component.

	IF NOT CheckForSelection() THEN
		MsgReturn& = MESSAGEBOX("Selecione um objeto no CorelDRAW antes " + \\
		                        "de pressionar o botão Aplicar.", TITLE_INFOBOX$, \\
		                        MB_OK_ONLY&) 
		EXIT SUB
	ENDIF
	
	' Check to see that the object is contourable.  If it is not contourable,
	' then we need to proceed.
	IF NOT CheckForContour() THEN
		MsgReturn& = MESSAGEBOX("Impossível aplicar um contorno ao objeto selecionado." + NL2 + \\
		                        "No CorelDRAW, é possível aplicar o efeito de contorno " + \\
		                        "a alguns tipos de objeto e não a outros. " + \\
		                        "Como regra geral, se a ferramenta Contorno não funcionar " + \\
		                        "com algo, a ferramenta de contorno acelerado " + \\
		                        "também não funcionará." + NL2 + \\
		                        "Selecione outro objeto e tente outra vez.", \\
		                        TITLE_INFOBOX$, \\
		                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
		EXIT SUB
	ENDIF
	IDOriginal& = .GetObjectsCDRStaticID()

 	' Before doing anything, check to see that the user has not changed
 	' the fill type of the original object.  (They're allowed to change
 	' the color(s), but the fill type requires updating our dialog box.)
 	IF .GetFillType() <> OriginalFillType& THEN
 		MsgReturn& = MESSAGEBOX("O objeto atualmente selecionado possui um tipo de " + \\
                                  "preenchimento diferente do que a Ferramenta de Contorno Acelerado." + NL2 + \\
                                  "Como resultado, as seleções de cor de preenchimento que você " + \\
      	                        "definiu na Ferramenta de Contorno Acelerado podem não ser " + \\
 		                        "adequadas. Verifique se está " + \\
 		                        "satisfeito com suas definições de cores de preenchimento " + \\
 		                        "e, em seguida, pressione Aplicar novamente para aplicar o contorno.", \\
 		                        TITLE_INFOBOX$, \\
 		                        MB_INFORMATION_ICON&)
 		OriginalFillType& = .GetFillType()
 		ActivateTab 2, 0
 		EXIT SUB
 	ENDIF

	' Retrieve the colors of the original object.  Though it would
	' be more efficient to do this once (on initialization) instead
	' of each time, this approach allows the user to change the
	' object's colour between clicks on the "Apply" button and have
	' the contour tool still work properly.
	.GetOutlineColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
	                 ColTmp3&, ColTmp4&
	.ConvertColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
	              ColTmp3&, ColTmp4&, DRAW_COLORMODEL_RGB&, \\
	              FromOutlineRed&, FromOutlineGreen&, FromOutlineBlue&, \\
	              ColTmp4&
	MakeHSB FromOutlineRed&, FromOutlineGreen&, FromOutlineBlue&, \\
	        FromOutlineHue&, FromOutlineSat&, FromOutlineBri&
	SELECT CASE OriginalFillType&
		CASE DRAW_FILL_UNIFORM&
			.GetUniformFillColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
			                     ColTmp3&, ColTmp4&
			.ConvertColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
			              ColTmp3&, ColTmp4&, DRAW_COLORMODEL_RGB&, \\
			              FromFill1Red&, FromFill1Green&, FromFill1Blue&, \\
			              ColTmp4&
			MakeHSB FromFill1Red&, FromFill1Green&, FromFill1Blue&, \\
			        FromFill1Hue&, FromFill1Sat&, FromFill1Bri&
			
		CASE DRAW_FILL_FOUNTAIN&
			.GetFountainFillColor 0, ColTmpPosition&, ColTmpModel&, \\
							  ColTmp1&, ColTmp2&, ColTmp3&, ColTmp4&
			.ConvertColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
					    ColTmp3&, ColTmp4&, DRAW_COLORMODEL_RGB&, \\
					    FromFill1Red&, FromFill1Green&, FromFill1Blue&, \\
					    ColTmp4&
			.GetFountainFillColor 100, ColTmpPosition&, ColTmpModel&, \\
							  ColTmp1&, ColTmp2&, ColTmp3&, ColTmp4&
			.ConvertColor ColTmpModel&, ColTmp1&, ColTmp2&, \\
					    ColTmp3&, ColTmp4&, DRAW_COLORMODEL_RGB&, \\
					    FromFill2Red&, FromFill2Green&, FromFill2Blue&, \\
					    ColTmp4&
			MakeHSB FromFill1Red&, FromFill1Green&, FromFill1Blue&, \\
			        FromFill1Hue&, FromFill1Sat&, FromFill1Bri&
			MakeHSB FromFill2Red&, FromFill2Green&, FromFill2Blue&, \\
			        FromFill2Hue&, FromFill2Sat&, FromFill2Bri&

		CASE ELSE
			' Do nothing.
	END SELECT

REM 	' If there is an existing contour, erase it and start over.
REM 	IF IDLastFullContour& > 0 THEN
REM 		.SelectObjectOfCDRStaticID IDLastFullContour&
REM 		.DeleteObject
REM 	ENDIF
	.SelectObjectOfCDRStaticID IDOriginal&
	.GetPosition OrigXPos&, OrigYPos&
	.DuplicateObject
	.SetPosition OrigXPos&, OrigYPos&
	
	' Based on the selections in the sliders, calculate the
	' bases of the logarithms to use for the accelerations.
	BaseOff# = 1 + ABS(OffsetAccel%) + BaseAdjustment#
	IF OffsetAccel% >= 0 THEN
		SpeedOUp = TRUE
	ELSE
		SpeedOUp = FALSE
	ENDIF
	BaseCol# = 1 + ABS(FillAccel%) + BaseAdjustment#
	IF FillAccel% >= 0 THEN
		SpeedCUp = TRUE
	ELSE
		SpeedCUp = FALSE
	ENDIF
	
	' Calculate the offset of the final contour line.
	IF OffsetType% = AC_OFFSET_PER_STEP% THEN
		WholeOffset& = Steps% * Offset% * ConversionFactors!(ChosenUnit%)
	ELSE
		WholeOffset& = Offset% * ConversionFactors!(ChosenUnit%)
	ENDIF
	
	' Calculate the necessary color deltas.
	SELECT CASE ColorBlendType%
		CASE DRAW_BLEND_DIRECT%
			WholeRedDeltaOutline& = ToOutlineRed& - FromOutlineRed&
			WholeGreenDeltaOutline& = ToOutlineGreen& - FromOutlineGreen&
			WholeBlueDeltaOutline& = ToOutlineBlue& - FromOutlineBlue&
			WholeRedDeltaFill1& = ToFill1Red& - FromFill1Red&
			WholeGreenDeltaFill1& = ToFill1Green& - FromFill1Green&
			WholeBlueDeltaFill1& = ToFill1Blue& - FromFill1Blue&
			IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
				WholeRedDeltaFill2& = ToFill2Red& - FromFill2Red&
				WholeGreenDeltaFill2& = ToFill2Green& - FromFill2Green&
				WholeBlueDeltaFill2& = ToFill2Blue& - FromFill2Blue&				
			ENDIF
			
		CASE DRAW_BLEND_RAINBOW_CW%
			WholeHueDeltaOutline& = ToOutlineHue& - FromOutlineHue&
			WholeSatDeltaOutline& = ToOutlineSat& - FromOutlineSat&
			WholeBriDeltaOutline& = ToOutlineBri& - FromOutlineBri&
			WholeSatDeltaFill1& = ToFill1Sat& - FromFill1Sat&
			WholeBriDeltaFill1& = ToFill1Bri& - FromFill1Bri&
			IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
				WholeHueDeltaFill2& = ToFill2Hue& - FromFill2Hue& 
				WholeSatDeltaFill2& = ToFill2Sat& - FromFill2Sat&
				WholeBriDeltaFill2& = ToFill2Bri& - FromFill2Bri&
			ENDIF
			' Rotate clockwise around the color wheel.
			IF (ToOutlineHue& - FromOutlineHue&) >= 0 THEN
				WholeHueDeltaOutline& = ToOutlineHue& - FromOutlineHue&
			ELSE
				WholeHueDeltaOutline& = 360 - FromOutlineHue& + ToOutlineHue&
			ENDIF			
			IF (ToFill1Hue& - FromFill1Hue&) >= 0 THEN
				WholeHueDeltaFill1& = ToFill1Hue& - FromFill1Hue&
			ELSE
				WholeHueDeltaFill1& = 360 - FromFill1Hue& + ToFill1Hue&
			ENDIF
			IF (ToFill2Hue& - FromFill2Hue&) >= 0 THEN
				WholeHueDeltaFill2& = ToFill2Hue& - FromFill2Hue&
			ELSE
				WholeHueDeltaFill2& = 360 - FromFill2Hue& + ToFill2Hue&
			ENDIF

		CASE DRAW_BLEND_RAINBOW_CCW%
			WholeHueDeltaOutline& = ToOutlineHue& - FromOutlineHue&
			WholeSatDeltaOutline& = ToOutlineSat& - FromOutlineSat&
			WholeBriDeltaOutline& = ToOutlineBri& - FromOutlineBri&
			IF (ToFill1Hue& - FromFill1Hue&) >= 0 THEN
				WholeHueDeltaFill1& = ToFill1Hue& - FromFill1Hue&
			ELSE
				WholeHueDeltaFill1& = 360 - FromFill1Hue& + ToFill1Hue&
			ENDIF
			WholeSatDeltaFill1& = ToFill1Sat& - FromFill1Sat&
			WholeBriDeltaFill1& = ToFill1Bri& - FromFill1Bri&
			IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
				WholeHueDeltaFill2& = ToFill2Hue& - FromFill2Hue& 
				WholeSatDeltaFill2& = ToFill2Sat& - FromFill2Sat&
				WholeBriDeltaFill2& = ToFill2Bri& - FromFill2Bri&
			ENDIF
			' Rotate counter-clockwise around the color wheel.
			IF (ToOutlineHue& - FromOutlineHue&) >= 0 THEN
				WholeHueDeltaOutline& = -1 * FromOutlineHue& + ToOutlineHue& - 360
			ELSE
				WholeHueDeltaOutline& = ToOutlineHue& - FromOutlineHue&
			ENDIF			
			IF (ToFill1Hue& - FromFill1Hue&) >= 0 THEN
				WholeHueDeltaFill1& = -1 * FromFill1Hue& + ToFill1Hue& - 360
			ELSE
				WholeHueDeltaFill1& = ToFill1Hue& - FromFill1Hue&
			ENDIF
			IF (ToFill2Hue& - FromFill2Hue&) >= 0 THEN
				WholeHueDeltaFill2& = -1 * FromFill2Hue& + ToFill2Hue& - 360
			ELSE
				WholeHueDeltaFill2& = ToFill2Hue& - FromFill2Hue&
			ENDIF
					
		CASE ELSE
			MESSAGE "FALHA DE ASSERÇÃO"
			STOP
	END SELECT
	
	' If we are going to the center or inside, we have a special case, and
	' since there's no way of determining how far we have to go, we have
	' to find it the hard way.
	IF (Direction% = DRAW_CONTOUR_TO_CENTER&) OR \\
	   (Direction% = DRAW_CONTOUR_INSIDE&) THEN
		
		DIM Highest AS LONG	' The highest offset we've tried so far.
		DIM XSize AS LONG	' The current selection's x size.
		DIM YSize AS LONG	' The current selection's y size.
		DIM TmpSteps AS INTEGER	' A temporary variable for calculating the
							' number of steps.
		
		' Use the selection's size as a start.
		.GetSize XSize&, YSize&
		IF XSize& > YSize& THEN
			Highest& = YSize&
		ELSE
			Highest& = XSize&
		ENDIF
		
		' Instead of algorithmically determining the number
		' of contours that are possible, we can estimate this
		' number mathematically for speed reasons.
		' (We divide by 2, plus a little bit extra so the inside
		' contour line does not look too small.)
		Highest& = Highest& / 2.2
	
		IF OffsetType% = AC_OFFSET_PER_STEP% THEN
			TmpSteps% = FIX(Highest& / \\
			         (Offset% * ConversionFactors!(ChosenUnit%)))
			IF (TmpSteps% > 0) THEN
				IF Direction% = DRAW_CONTOUR_TO_CENTER& THEN
					Steps% = TmpSteps%
					WholeOffset& = Highest&
				ELSE ' DRAW_OFFSET_INSIDE&
					Steps% = MIN(TmpSteps%, Steps%)
					WholeOffset& = Steps% * Offset% * \\
					               ConversionFactors!(ChosenUnit%)
				ENDIF
				ParamDialog.StepsSpin.SetValue Steps%
			ELSE
				MsgReturn& = MESSAGEBOX("O deslocamento selecionado " + \\
				                       "é tão grande que " + \\
				                       "não produzirá linhas de contorno."+\\
				                       NL2 + "Selecione um "+\\
				                       "deslocamento menor e tente outra vez.",\\
				                       TITLE_INFOBOX$, \\
				                       MB_OK_ONLY& OR \\
				                       MB_EXCLAMATION_ICON&)
				EXIT SUB
			ENDIF
		ELSE
			IF Highest& < WholeOffset& THEN
				' If the user has specified a too large total
				' offset, adjust it automatically.
				WholeOffset& = Highest&
			ENDIF
			Offset% = MIN(CINT(FIX(Highest& / \\
			          ConversionFactors!(ChosenUnit%))), Offset%)
			ParamDialog.OffsetSpin.SetValue Offset%
		ENDIF

	ENDIF
	
	' We calculate a uniform step offset from 1 to BaseOff#.
	' Later, we take the logarithm of each step offset to
	' get the accelerated offset.
	UniformStep# = (BaseOff# - 1) / Steps%
	
	' Do the same for the colors.
	UniformFill# = (BaseCol# - 1) / Steps%

	' Apply each contour.
	IF SpeedOUp THEN
		LastUOffset# = 1
	ELSE
		LastUOffset# = BaseOff#
	ENDIF
		
	FOR Counter% = 1 TO Steps%
	
		' Calculate the offset for this individual contour line.
		IF SpeedOUp THEN
			CurUOffset# = UniformStep# * Counter% + 1
			CurRealOffset& = ((LOG(CurUOffset#)/LOG(BaseOff#)) * \\
			                 WholeOffset&) - \\
						  ((LOG(LastUOffset#)/LOG(BaseOff#)) * \\
						  WholeOffset&)
		ELSE
			CurUOffset# = BaseOff# - UniformStep# * Counter%
			CurRealOffset& = ((LOG(LastUOffset#)/LOG(BaseOff#)) * \\
						  WholeOffset&) - \\
						  ((LOG(CurUOffset#)/LOG(BaseOff#)) * \\
			                 WholeOffset&)
		ENDIF
		
		' Calculate the fill color(s) for this contour line.
		' This is the most important part of the code.
		IF SpeedCUp THEN
			CurUFill# = BaseCol# - UniformFill# * Counter%
			IF ColorBlendType% = DRAW_BLEND_DIRECT% THEN
				' Calculate RGB color values.
				CurOutlineRed& = ToOutlineRed& - ((LOG(CurUFill#)/LOG(BaseCol#) * WholeRedDeltaOutline&) MOD 256)
				CurOutlineGreen& = ToOutlineGreen& - ((LOG(CurUFill#)/LOG(BaseCol#) * WholeGreenDeltaOutline&) MOD 256)
				CurOutlineBlue& = ToOutlineBlue& - ((LOG(CurUFill#)/LOG(BaseCol#) * WholeBlueDeltaOutline&) MOD 256)
				CurFill1Red& = ToFill1Red& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeRedDeltaFill1&) MOD 256
				CurFill1Green& = ToFill1Green& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeGreenDeltaFill1&) MOD 256
				CurFill1Blue& = ToFill1Blue& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeBlueDeltaFill1&) MOD 256
				IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
					CurFill2Red& = ToFill2Red& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeRedDeltaFill2&) MOD 256
					CurFill2Green& = ToFill2Green& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeGreenDeltaFill2&) MOD 256
					CurFill2Blue& = ToFill2Blue& - ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeBlueDeltaFill2&) MOD 256
				ENDIF
			ELSE
				' Calculate HSB color values.
				CurOutlineHue& = Mod360( CLNG(ToOutlineHue& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaOutline&) )
				CurOutlineSat& = Mod256( CLNG(ToOutlineSat& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaOutline&) )
				CurOutlineBri& = Mod256( CLNG(ToOutlineBri& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaOutline&) )
				CurFill1Hue& = Mod360( CLNG(ToFill1Hue& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaFill1&) )
				CurFill1Sat& = Mod256( CLNG(ToFill1Sat& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaFill1&) )
				CurFill1Bri& = Mod256( CLNG(ToFill1Bri& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaFill1&) )
				IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
					CurFill2Hue& = Mod360( CLNG(ToFill2Hue& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaFill2&) )
					CurFill2Sat& = Mod256( CLNG(ToFill2Sat& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaFill2&) )
					CurFill2Bri& = Mod256( CLNG(ToFill2Bri& - (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaFill2&) )					
				ENDIF
			ENDIF
		ELSE
			CurUFill# = UniformFill# * Counter% + 1
			IF ColorBlendType% = DRAW_BLEND_DIRECT% THEN
				' Calculate the RGB color values.
				CurOutlineRed& = FromOutlineRed& + ((LOG(CurUFill#)/LOG(BaseCol#) * WholeRedDeltaOutline&) MOD 256)
				CurOutlineGreen& = FromOutlineGreen& + ((LOG(CurUFill#)/LOG(BaseCol#) * WholeGreenDeltaOutline&) MOD 256)
				CurOutlineBlue& = FromOutlineBlue& + ((LOG(CurUFill#)/LOG(BaseCol#) * WholeBlueDeltaOutline&) MOD 256)
				CurFill1Red& = FromFill1Red& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeRedDeltaFill1&) MOD 256
				CurFill1Green& = FromFill1Green& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeGreenDeltaFill1&) MOD 256
				CurFill1Blue& = FromFill1Blue& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeBlueDeltaFill1&) MOD 256	
				IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
					CurFill2Red& = FromFill2Red& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeRedDeltaFill2&) MOD 256
					CurFill2Green& = FromFill2Green& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeGreenDeltaFill2&) MOD 256
					CurFill2Blue& = FromFill2Blue& + ((LOG(CurUFill#)/LOG(BaseCol#)) * WholeBlueDeltaFill2&) MOD 256					
				ENDIF
			ELSE
				' Calculate HSB color values.
				CurOutlineHue& = Mod360( CLNG(FromOutlineHue& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaOutline&) )
				CurOutlineSat& = Mod256( CLNG(FromOutlineSat& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaOutline&) )
				CurOutlineBri& = Mod256( CLNG(FromOutlineBri& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaOutline&) )
				CurFill1Hue& = Mod360( CLNG(FromFill1Hue& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaFill1&) )
				CurFill1Sat& = Mod256( CLNG(FromFill1Sat& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaFill1&) )
				CurFill1Bri& = Mod256( CLNG(FromFill1Bri& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaFill1&) )
				IF OriginalFillType& = DRAW_FILL_FOUNTAIN& THEN
					CurFill2Hue& = Mod360( CLNG(FromFill2Hue& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeHueDeltaFill2&) )
					CurFill2Sat& = Mod256( CLNG(FromFill2Sat& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeSatDeltaFill2&) )
					CurFill2Bri& = Mod256( CLNG(FromFill2Bri& + (LOG(CurUFill#)/LOG(BaseCol#))*WholeBriDeltaFill2&) )					
				ENDIF
			ENDIF
		ENDIF
	
		' Actually make a contour object.
		.Separate
		.Ungroup	
		.SelectPreviousObject FALSE
		.SelectNextObject FALSE
		IDCurrent& = .GetObjectsCDRStaticID()
		
		ON ERROR GOTO ErrBadOffset
		IF Direction% = DRAW_CONTOUR_OUTSIDE& THEN
			IF ColorBlendType% = DRAW_BLEND_DIRECT% THEN
				.ApplyContour DRAW_CONTOUR_OUTSIDE&, CurRealOffset&, 1, DRAW_BLEND_DIRECT%, \\
				              DRAW_COLORMODEL_RGB&, CurOutlineRed&, CurOutlineGreen&, CurOutlineBlue&, 0, \\
				              DRAW_COLORMODEL_RGB&, CurFill1Red&, CurFill1Green&, CurFill1Blue&, 0, \\
				              DRAW_COLORMODEL_RGB&, CurFill2Red&, CurFill2Green&, CurFill2Blue&, 0
			ELSE
				.ApplyContour DRAW_CONTOUR_OUTSIDE&, CurRealOffset&, 1, DRAW_BLEND_DIRECT%, \\
				              DRAW_COLORMODEL_HSB&, CurOutlineHue&, ToOutlineSat&, ToOutlineBri&, 0, \\
				              DRAW_COLORMODEL_HSB&, CurFill1Hue&, CurFill1Sat&, CurFill1Bri&, 0, \\
				              DRAW_COLORMODEL_HSB&, CurFill2Hue&, CurFill2Sat&, CurFill2Bri&, 0
				' The DRAW_BLEND_DIRECT% is not a typo.  It has no effect since we're only applying 1 contour line.
			ENDIF
		ELSE
			' We simulate to-center contours, we do not use the built-in
			' functionality.
			
			' Since we may not have accurately predicted the maximum number of offset lines,
			' we need to check whether applying this contour is possible.
			DIM CurTestSizeX AS LONG
			DIM CurTestSizeY AS LONG
			DIM MaximumAllowableOffset AS LONG
			.GetSize CurTestSizeX&, CurTestSizeY&
			IF CurTestSizeX& > CurTestSizeY& THEN
				MaximumAllowableOffset& = CurTestSizeY& / 2.2
			ELSE
				MaximumAllowableOffset& = CurTestSizeX& / 2.2
			ENDIF
			IF CurRealOffset& > MaximumAllowableOffset& THEN
			
				' We no longer need to apply any other contour lines,
				' since we're out of space.
				Counter% = Steps%
				Steps% = Counter%
				ParamDialog.StepsSpin.SetValue Steps%

			ELSE

				IF ColorBlendType% = DRAW_BLEND_DIRECT% THEN
					.ApplyContour DRAW_CONTOUR_INSIDE&, CurRealOffset&, 1, DRAW_BLEND_DIRECT%, \\
					              DRAW_COLORMODEL_RGB&, CurOutlineRed&, CurOutlineGreen&, CurOutlineBlue&, 0, \\
					              DRAW_COLORMODEL_RGB&, CurFill1Red&, CurFill1Green&, CurFill1Blue&, 0, \\
					              DRAW_COLORMODEL_RGB&, CurFill2Red&, CurFill2Green&, CurFill2Blue&, 0
				ELSE
					.ApplyContour DRAW_CONTOUR_INSIDE&, CurRealOffset&, 1, DRAW_BLEND_DIRECT%, \\
					              DRAW_COLORMODEL_HSB&, CurOutlineHue&, ToOutlineSat&, ToOutlineBri&, 0, \\
					              DRAW_COLORMODEL_HSB&, CurFill1Hue&, CurFill1Sat&, CurFill1Bri&, 0, \\
					              DRAW_COLORMODEL_HSB&, CurFill2Hue&, CurFill2Sat&, CurFill2Bri&, 0
					' The DRAW_BLEND_DIRECT% is not a typo.  It has no effect since we're only applying 1 contour line.
				ENDIF
	
			ENDIF

		ENDIF
		ON ERROR EXIT
		
		.Separate
		.Ungroup	
		.SelectPreviousObject FALSE
		.SelectNextObject FALSE
		IDContoured& = .GetObjectsCDRStaticID()
		.SelectObjectOfCDRStaticID IDCurrent&
		IF IDLast& > 0 THEN
			.AppendObjectToSelection IDLast&
			.Group
		ENDIF
		IDLast& = .GetObjectsCDRStaticID()
		.SelectObjectOfCDRStaticID IDContoured&
				
		' Update LastUOffset#.
		LastUOffset# = CurUOffset#
		
	NEXT Counter%

	IF IDLast& > 0 THEN
		.AppendObjectToSelection IDLast&
		.Group
	ENDIF
	
	' Retrieve the ID of this new "contour group" in case the user
	' wants to erase it and start again.
	IDLastFullContour& = .GetObjectsCDRStaticID()
	ParamDialog.UndoButton.Enable TRUE

	VeryEnd:
		EXIT SUB
	
ErrBadOffset:
	' This is just a precaution, and should never happen
	' in practice.
	ERRNUM = 0

	' Retrieve the main CorelDRAW directory and path from the registry.
	DIM MainDrawDir AS STRING
	MainDrawDir$ = REGISTRYQUERY (HKEY_LOCAL_MACHINE, \\
	                              REG_CORELDRAW_PATH$, \\
	                              REG_CORELDRAW_MAIN_DIR_KEY$)
	MainDrawDir$ = MainDrawDir$ + "\Draw"
	.FileSave MainDrawDir$ + "\ACBackup.cdr", 3, FALSE, 0, TRUE
	MsgReturn& = MESSAGEBOX("Ocorreu um erro muito grave na " + \\
                             "Ferramenta de Contorno Acelerado." + NL2 + \\
                             "Como precaução, seu documento foi salvo como " + \\
                             MainDrawDir$ + "\ACBackup.cdr." + NL2 + \\
                             "Caso experimente problemas, recarregue o Draw e " + \\
                             "abra este arquivo.", \\
					    TITLE_ERRORBOX$, MB_STOP_ICON&)
	STOP
	Steps% = Counter% - 1
	ParamDialog.StepsSpin.SetValue Steps%
	RESUME AT VeryEnd

END SUB

'********************************************************************
'
' MAIN PROGRAM
'
'********************************************************************
DIM GenReturn AS LONG		' The return value of various routines.

REM 	' Retrieve the ID of the currently selected object in DRAW.
REM 	IDOriginal& = .GetObjectsCDRStaticID()
REM 
REM 	' Retrieve its fill type.
REM 	OriginalFillType& = .GetFillType()
	
	' Show the dialog.
	GenReturn& = DIALOG(ParamDialog)
REM 	IF GenReturn& = DIALOG_RETURN_OK% THEN
REM 
REM 		' Delete the original object, since the user wants
REM 		' to keep the contour effect.
REM 		.SelectObjectOfCDRStaticID IDOriginal&
REM 		IF IDLastFullContour& > 0 THEN
REM 			.DeleteObject
REM 			.SelectObjectOfCDRStaticID IDLastFullContour&
REM 		ENDIF
REM 
REM 	ELSE
REM 
REM 		' The user does not want to keep whatever effect
REM 		' was applied.
REM 		IF (IDLastFullContour& > 0) THEN
REM 			.SelectObjectOfCDRStaticID IDLastFullContour&
REM 			.DeleteObject
REM 		ENDIF
REM 		.SelectObjectOfCDRStaticID IDOriginal&
REM 				
REM 	ENDIF

STOP

'********************************************************************
'
'	Name:	Min (function)
'
'	Action:	Returns the lowest of two numbers.
'
'	Params:	Val1 - The first number.
'			Val2 - The second number.
'
'	Returns:	Whichever is smallest, Val1 or Val2.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION Min( Val1 AS INTEGER, Val2 AS INTEGER ) AS INTEGER

	IF Val1% < Val2% THEN
		Min% = Val1%
	ELSE
		Min% = Val2%
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	MakeHSB (subroutine)
'
'	Action:	Converts an RGB color to its HSB equivalent.
'
'	Params:	InRed - The red component of the color to convert.
'			InGreen - The green component of the color to convert.
'			InBlue - The blue component of the color to convert.
'			OutHue - The hue component of the HSB equivalent.
'			OutSat - The saturation component of the HSB equivalent.
'              OutBri - The brightness component of the HSB equivalent.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB MakeHSB( BYVAL InRed AS LONG,   \\
             BYVAL InGreen AS LONG, \\
             BYVAL InBlue AS LONG,  \\
             BYREF OutHue AS LONG,  \\
             BYREF OutSat AS LONG,  \\
             BYREF OutBri AS LONG )

	DIM OutComponent4 AS LONG
	
	.ConvertColor DRAW_COLORMODEL_RGB&, InRed&, InGreen&, InBlue&, 0, \\
	              DRAW_COLORMODEL_HSB&, OutHue&, OutSat&, OutBri&, OutComponent4&

END SUB

'********************************************************************
'
'	Name:	Mod256 (function)
'
'	Action:	Takes a long integer and adds or subtracts a
'			multiple of 256 so that the number is between
'			0 and 255 inclusive.
'
'	Params:	InNum - The number to perform the operation on.
'
'	Returns:	A LONG between 0 and 255 inclusive.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION Mod256( InNum AS LONG ) AS LONG

	IF (InNum& >= 0) THEN
		Mod256& = InNum& MOD 256
	ELSE
		Mod256& = (CLNG(InNum& / 256) * -256 + 256 + InNum&) MOD 256
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	Mod360 (function)
'
'	Action:	Takes a long integer and adds or subtracts a
'			multiple of 360 so that the number is between
'			0 and 360 inclusive.
'
'	Params:	InNum - The number to perform the operation on.
'
'	Returns:	A LONG between 0 and 360 inclusive.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION Mod360( InNum AS LONG ) AS LONG

	IF (InNum& >= 0) THEN
		Mod360& = InNum& MOD 360
	ELSE
		Mod360& = (CLNG(InNum& / 360) * -360 + 360 + InNum&) MOD 360
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	CheckForSelection (function)
'
'	Action:	Checks whether an object is currently selected
'			in CorelDRAW.
'
'	Params:	None.
'
'	Returns:	TRUE if an object is currently selected;  FALSE
'              otherwise.
'
'	Comments:	Never raises any errors. 
'
'********************************************************************
FUNCTION CheckForSelection AS BOOLEAN

	DIM ObjType AS LONG	 ' The currently selected object type.

	ON ERROR GOTO CFSNothingError
	
	ObjType& = .GetObjectType()
	IF (ObjType& <= DRAW_OBJECT_TYPE_RESERVED) THEN
		CheckForSelection = FALSE
	ELSE
		CheckForSelection = TRUE
	ENDIF

	ExitPart:
		EXIT FUNCTION

CFSNothingError:
	ERRNUM = 0
	CheckForSelection = FALSE
	RESUME AT ExitPart

END FUNCTION

'********************************************************************
'
'	Name:	CheckForContour (function)
'
'	Action:	Checks whether the currently selected object in
'              CorelDRAW can have the contour effect applied to
'              it.
'
'	Params:	None.
'
'	Returns:	FALSE if there is nothing selected in CorelDRAW or
'              if there is something selected but it cannot have
'              the contour effect applied to it.  TRUE otherwise.
'
'	Comments:	Never raises any errors. 
'
'********************************************************************
FUNCTION CheckForContour AS BOOLEAN

	ON ERROR GOTO CFCNotContourableError

	' We're just doing a simple contour, so omit most of the
	' optional parameters.
	.ApplyContour 2, 25400, 1
	
	' Undo what we just did.
	.Undo
	
	' We've been successful, so return TRUE.
	CheckForContour = TRUE	

	ExitPart:
		EXIT FUNCTION

CFCNotContourableError:
	ERRNUM = 0
	CheckForContour = FALSE
	RESUME AT ExitPart

END FUNCTION

END WITHOBJECT
