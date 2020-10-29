REM Aplica um traçado de preenchimento gradiente
REM ao objecto atualmente selecionado.

'********************************************************************
' 
'   Script:	FillOut.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to apply a fountain filled outline
'                to the currently selected object.  Uses contour
'                and creates a grouped object.
' 
'********************************************************************

#addfol  "..\..\..\scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE SUB UpdateBlendButtons()
DECLARE SUB UpdateDisabledControls()
DECLARE FUNCTION IsInteger( InString AS STRING ) AS BOOLEAN
DECLARE FUNCTION CheckForSelection() AS BOOLEAN
DECLARE FUNCTION CheckForContour() AS BOOLEAN

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST TITLE_ERRORBOX$      = "Erro de Marcador de Traçado com Preenchimento"
GLOBAL CONST TITLE_INFOBOX$       = "Informações de Marcador de Traçado com Preenchimento"
GLOBAL NL AS STRING	     ' These must be declared as 
GLOBAL NL2 AS STRING     ' variables, not constants, because
NL$ = CHR(10) + CHR(13)	' we cannot assign expressions
NL2$ = NL + NL	     	' to constants.

GLOBAL Bitmaps(3) AS STRING	' Will hold the images to assign to buttons.
	
' The dialog return values.
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2
	
' The CDRStaticID of the duplicated object.
GLOBAL IDDuplicate AS LONG

' The current directory when this script was started.
GLOBAL CurDir AS STRING

'/////PARAMETERS DIALOG//////////////////////////////////////////////

' The graphics used for the color blend type buttons.
GLOBAL CONST COLOR_DIRECT_UNPRESSED_BITMAP$ = "\ColDirec.bmp"
GLOBAL CONST COLOR_DIRECT_PRESSED_BITMAP$ = "\ColDireP.bmp"
GLOBAL CONST COLOR_CCW_UNPRESSED_BITMAP$ = "\ColCCW.bmp"
GLOBAL CONST COLOR_CCW_PRESSED_BITMAP$ = "\ColCCWP.bmp"
GLOBAL CONST COLOR_CW_UNPRESSED_BITMAP$ = "\ColCW.bmp"
GLOBAL CONST COLOR_CW_PRESSED_BITMAP$ = "\ColCWP.bmp"

' The array of possible units the user may select from.
GLOBAL UnitsArray(6) AS STRING
UnitsArray(1) = "1 pol."
UnitsArray(2) = "1/36 pol."
UnitsArray(3) = "0,001 pol."
UnitsArray(4) = "1 cm."
UnitsArray(5) = "0,001 cm."
UnitsArray(6) = "1 pt."

' Multiplicative conversion factors to convert from the units to
' tenths of a micron.
GLOBAL ConversionFactors(6) AS SINGLE
ConversionFactors(1) = 1 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(2) = (1/36) * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(3) = 0.001 * LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(4) = 1 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(5) = 0.001 * LENGTHCONVERT(LC_CENTIMETERS, LC_TENTHS_OFA_MICRON, 1)
ConversionFactors(6) = 1 * LENGTHCONVERT(LC_POINTS, LC_TENTHS_OFA_MICRON, 1)

' Constants used for this dialog.
GLOBAL CONST FILL_TYPE_LINEAR%	= 1
GLOBAL CONST FILL_TYPE_RADIAL%	= 2
GLOBAL CONST FILL_TYPE_CONICAL%	= 3
GLOBAL CONST FILL_TYPE_SQUARE%	= 4

' Variables needed for this dialog.
GLOBAL FillType AS INTEGER		' The fill type (linear, etc.)
GLOBAL HorizOffset AS INTEGER		' The horizontal offset percentage.
GLOBAL VertOffset AS INTEGER		' The vertical offset percentage.
GLOBAL ColorBlendType AS INTEGER	' Direct, CCW, or CW.
GLOBAL Midpoint AS INTEGER		' The midpoint (rate) for the fill.
GLOBAL Angle AS INTEGER			' The fill's angle.
GLOBAL Steps AS INTEGER			' The number of steps to use for
							' the fill.
GLOBAL Pad AS INTEGER			' The amount of padding on the fill.
GLOBAL MsgReturn AS LONG			' The return value of MESSAGEBOX.
GLOBAL FromRed AS INTEGER		' The From color, red component.
GLOBAL FromGreen AS INTEGER		' The From color, green component.
GLOBAL FromBlue AS INTEGER		' The From color, blue component.
GLOBAL ToRed AS INTEGER			' The To color, red component.
GLOBAL ToGreen AS INTEGER		' The To color, green component.
GLOBAL ToBlue AS INTEGER			' The To color, blue component.
GLOBAL Width AS INTEGER			' The outline width.
GLOBAL ChosenUnit AS INTEGER		' The unit chosen by the user.

' Set up the fill descriptions.
GLOBAL FillDesc(4) AS STRING		' The fill type descriptions.
FillDesc$(1) = "Linear"
FillDesc$(2) = "Radial"
FillDesc$(3) = "Cônico"
FillDesc$(4) = "Quadrado"

' Set up the defaults.
FillType% = FILL_TYPE_LINEAR%
HorizOffset% = 0
VertOffset% = 0
Angle% = 0
Steps% = 50
Pad% = 0
ColorBlendType% = DRAW_BLEND_DIRECT%
Midpoint% = 50
FromRed% = 0 
FromGreen% = 0
FromBlue% = 255
ToRed% = 255
ToGreen% = 0
ToBlue% = 0
Width% = 10
ChosenUnit% = 4

BEGIN DIALOG OBJECT ParamDialog 238, 236, "Marcador de Traçado com Preenchimento", SUB ParamDialogEventHandler
	TEXT  12, 4, 214, 21, .Text1, "Esta ferramenta cria automaticamente um efeito de traçado com preenchimento gradiente para o objeto selecionado atualmente."
	GROUPBOX  12, 107, 214, 79, .GroupBox2, "Mistura em duas cores"
	DDLISTBOX  36, 26, 80, 78, .TypeListBox
	TEXT  22, 60, 37, 11, .HorizText, "Horizontal:"
	SPINCONTROL  60, 58, 37, 12, .HorizSpin
	TEXT  100, 60, 8, 11, .HorizPercentText, "%"
	TEXT  100, 80, 8, 11, .VertPercentText, "%"
	TEXT  22, 80, 30, 10, .VertText, "Vertical:"
	SPINCONTROL  60, 78, 37, 12, .VertSpin
	SPINCONTROL  173, 38, 37, 12, .AngleSpin
	TEXT  136, 41, 25, 11, .AngleText, "Ângulo:"
	TEXT  12, 28, 22, 11, .Text14, "Tipo:"
	GROUPBOX  13, 44, 104, 56, .GroupBox5, "Deslocamento centralizado"
	GROUPBOX  127, 22, 100, 78, .GroupBox6, "Opções"
	SPINCONTROL  173, 58, 37, 12, .StepsSpin
	TEXT  136, 60, 25, 11, .Text6, "Etapas:"
	SPINCONTROL  173, 78, 37, 12, .PadSpin
	TEXT  136, 77, 34, 15, .PadText, "Área de Transição:"
	TEXT  213, 80, 8, 9, .PadPercentText, "%"
	TEXT  22, 125, 22, 9, .Text11, "De:"
	PUSHBUTTON  56, 123, 57, 14, .FromButton, "Selecionar Cor"
	PUSHBUTTON  56, 143, 57, 14, .ToButton, "Selecionar Cor"
	TEXT  22, 163, 30, 16, .Text10, "Ponto Médio:"
	HSLIDER 53, 163, 79, 16, .MidSlider
	TEXT  22, 145, 22, 9, .Text13, "Até:"
	TEXTBOX  135, 161, 14, 14, .MidText
	BITMAPBUTTON  180, 124, 14, 14, .DirectButton
	BITMAPBUTTON  180, 138, 14, 14, .CCWButton
	BITMAPBUTTON  180, 152, 14, 14, .CWButton
	TEXT  140, 125, 36, 16, .Text16, "Tipo de mistura:"
	TEXT  198, 126, 20, 9, .Text17, "Direta"
	TEXT  198, 155, 20, 9, .Text19, "CW"
	TEXT  198, 141, 20, 9, .Text18, "CCW"
	TEXT  28, 191, 87, 16, .Text20, "Largura do traçado com preenchimento gradiente:"
	SPINCONTROL  119, 193, 27, 13, .WidthSpin
	DDLISTBOX  156, 193, 47, 138, .UnitsListBox
	TEXT  149, 195, 5, 11, .Text21, "x"
	PUSHBUTTON  71, 214, 48, 14, .OkButton, "OK"
	PUSHBUTTON  123, 214, 48, 14, .CancelButton, "Cancelar"
END DIALOG

SUB ParamDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.

	SELECT CASE Event%
	
		CASE EVENT_INITIALIZATION&

			' Set up the fill types list box.
			ParamDialog.TypeListbox.SetArray FillDesc$
			ParamDialog.TypeListbox.SetSelect FillType%
			UpdateDisabledControls
			
			' Set up the midpoint slider.
			ParamDialog.MidSlider.SetMinRange 1
			ParamDialog.MidSlider.SetMaxRange 99
			ParamDialog.MidSlider.SetIncrement 1
			ParamDialog.MidSlider.SetValue Midpoint%
			ParamDialog.MidText.SetText CSTR(Midpoint%)
		
			' Set up the offsets.
			ParamDialog.HorizSpin.SetValue HorizOffset%
			ParamDialog.VertSpin.SetValue VertOffset%
		
			' Set up the other options.
			ParamDialog.AngleSpin.SetValue Angle%
			ParamDialog.StepsSpin.SetValue Steps%
			ParamDialog.PadSpin.SetValue Pad%
		
			' Set up the blend type buttons.
			UpdateBlendButtons
			
			' Set up the outline width related controls.
			ParamDialog.WidthSpin.SetValue Width%
			ParamDialog.UnitsListBox.SetArray UnitsArray$
			ParamDialog.UnitsListBox.SetSelect ChosenUnit%
			
		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE ParamDialog.TypeListBox.GetID()
					FillType% = ParamDialog.TypeListBox.GetSelect()
					UpdateDisabledControls
						
				CASE ParamDialog.DirectButton.GetID()
					ColorBlendType% = DRAW_BLEND_DIRECT%
					UpdateBlendButtons
					
				CASE ParamDialog.CCWButton.GetID()
					ColorBlendType% = DRAW_BLEND_RAINBOW_CCW%
					UpdateBlendButtons
				
				CASE ParamDialog.CWButton.GetID()
					ColorBlendType% = DRAW_BLEND_RAINBOW_CW%
					UpdateBlendButtons
				
				CASE ParamDialog.MidSlider.GetID()
					Midpoint% = ParamDialog.MidSlider.GetValue()
					ParamDialog.MidText.SetText \\
					     CSTR(ParamDialog.MidSlider.GetValue())

				CASE ParamDialog.FromButton.GetID()
					GETCOLOR FromRed%, FromGreen%, FromBlue%

				CASE ParamDialog.ToButton.GetID()
					GETCOLOR ToRed%, ToGreen%, ToBlue%
					
				CASE ParamDialog.OkButton.GetID()
					ParamDialog.CloseDialog DIALOG_RETURN_OK%	
				
				CASE ParamDialog.CancelButton.GetID()
					ParamDialog.CloseDialog DIALOG_RETURN_CANCEL%
	
				CASE ParamDialog.UnitsListBox.GetID()
					ChosenUnit% = ParamDialog.UnitsListBox.GetSelect()
			
			END SELECT
		
		CASE EVENT_CHANGE_IN_CONTENT&
			SELECT CASE ControlID%
				CASE ParamDialog.WidthSpin.GetID()
					' Make sure the button does not allow values
					' less than or equal to 0 or greater than 99.
					IF (ParamDialog.WidthSpin.GetValue() <= 0) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de largura entre " + \\
                                                      "1 e 99.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.WidthSpin.SetValue 1
						Width% = 1
					ELSEIF (ParamDialog.WidthSpin.GetValue() > 99) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de largura entre " + \\
                                                      "1 e 99.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.WidthSpin.SetValue 99
						Width% = 99
					ELSE
						Width% = ParamDialog.WidthSpin.GetValue()
					ENDIF
			
				CASE ParamDialog.HorizSpin.GetID()
					' Make sure the horizontal offset spin button
					' does not allow invalid values.
					IF (ParamDialog.HorizSpin.GetValue() < -100) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento horizontal " + \\
                                                      "entre -100 e 100.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.HorizSpin.SetValue -100
						HorizOffset% = -100
					ELSEIF (ParamDialog.HorizSpin.GetValue() > 100) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento horizontal " + \\
                                                      "entre -100 e 100.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.HorizSpin.SetValue 100
						HorizOffset% = 100
					ELSE
						HorizOffset% = ParamDialog.HorizSpin.GetValue()
					ENDIF
					
				CASE ParamDialog.VertSpin.GetID()
					' Make sure the vertical offset spin button
					' does not allow invalid values.
					IF (ParamDialog.VertSpin.GetValue() < -100) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento vertical " + \\
                                                      "entre -100 e 100.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.VertSpin.SetValue -100
						VertOffset% = -100
					ELSEIF (ParamDialog.VertSpin.GetValue() > 100) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento vertical " + \\
                                                      "entre -100 e 100.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.VertSpin.SetValue 100
						VertOffset% = 100
					ELSE
						VertOffset% = ParamDialog.HorizSpin.GetValue()
					ENDIF
					
				CASE ParamDialog.AngleSpin.GetID()
					' Only allow angles from -360 to +360.
					IF (ParamDialog.AngleSpin.GetValue() < -360) THEN
						MsgReturn& = MESSAGEBOX("Digite um ângulo entre " + \\
                                                      "-360 e 360 graus.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.AngleSpin.SetValue -360
						Angle% = -360
					ELSEIF (ParamDialog.AngleSpin.GetValue() > 360) THEN
						MsgReturn& = MESSAGEBOX("Digite um ângulo entre " + \\
                                                      "-360 e 360 graus.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.AngleSpin.SetValue 360
						Angle% = 360
					ELSE
						Angle% = ParamDialog.AngleSpin.GetValue()
					ENDIF

				CASE ParamDialog.StepsSpin.GetID()
					' Only allow values from 2 to 256.
					IF (ParamDialog.StepsSpin.GetValue() < 2) THEN
						MsgReturn& = MESSAGEBOX("Digite um número de etapas " + \\
                                                      "entre 2 e 256.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.StepsSpin.SetValue 2
						Steps% = 2
					ELSEIF (ParamDialog.StepsSpin.GetValue() > 256) THEN
						MsgReturn& = MESSAGEBOX("Digite um número de etapas " + \\
                                                      "entre 2 e 256.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.StepsSpin.SetValue 256
						Steps% = 256
					ELSE
						Steps% = ParamDialog.StepsSpin.GetValue()
					ENDIF

				CASE ParamDialog.PadSpin.GetID()
					' Only allow values from 0 to 45.
					IF (ParamDialog.PadSpin.GetValue() < 0) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de transição " + \\
                                                      "entre 0 e 45.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.PadSpin.SetValue 0
						Pad% = 0
					ELSEIF (ParamDialog.PadSpin.GetValue() > 45) THEN
						MsgReturn& = MESSAGEBOX("Digite um valor de transição " + \\
                                                      "entre 0 e 45.", \\
                                                      TITLE_INFOBOX$, MB_INFORMATION_ICON%)
						ParamDialog.PadSpin.SetValue 45
						Pad% = 45
					ELSE
						Pad% = ParamDialog.PadSpin.GetValue()
					ENDIF
						
				CASE ParamDialog.MidText.GetID()
					DIM UserText AS STRING	' The text entered by the user.
					UserText$ = ParamDialog.MidText.GetText()
					IF LEN(UserText$) = 0 THEN
						' The user has not entered anything
						' yet.  Ignore it.
					ELSEIF NOT IsInteger(UserText$) THEN
						MsgReturn& = MESSAGEBOX( \\
						   "Digite um número.", \\
						   TITLE_ERRORBOX$, \\
						   MB_OK_ONLY& )
						ParamDialog.MidText.SetText CSTR(Midpoint%)
					ELSEIF (CINT(UserText$) > 99) OR \\
					       (CINT(UserText$) < 1) THEN
						MsgReturn& = MESSAGEBOX( \\
						   "Você digitou um valor " + \\
						   "inválido para o ponto médio." + NL2 + \\
						   "A faixa de valores permitidos vai de 1 a 99." + \\
						   NL2 + "Tente outra vez.", \\
						   TITLE_ERRORBOX$, \\
						   MB_OK_ONLY& )
						ParamDialog.MidText.SetText CSTR(Midpoint%)
					ELSE
						Midpoint% = CINT(UserText$)
						ParamDialog.MidSlider.SetValue Midpoint%
					ENDIF
					
				CASE ParamDialog.MidSlider.GetID()
					Midpoint% = ParamDialog.MidSlider.GetValue()
					ParamDialog.MidText.SetText \\
					     CSTR(ParamDialog.MidSlider.GetValue())
	
			END SELECT
	
	END SELECT

END SUB

'********************************************************************
'
'	Name:	UpdateDisabledControls (dialog subroutine)
'
'	Action:	Updates which of the dialog controls are enabled
'              or disabled based on the value of FillType.
'
'	Params:	None.  As this is intended to be a dialog function,
'              it makes use of the variable global to ParamDialog:
'              FillType.
'
'	Returns:	None.
'
'	Comments: None.
'
'********************************************************************
SUB UpdateDisabledControls()

	' Certain dialog items may need to be
	' enabled/disabled depending on the 
	' fill type.
	SELECT CASE FillType%
		CASE FILL_TYPE_LINEAR%
			ParamDialog.HorizSpin.Enable FALSE
			ParamDialog.HorizText.Enable FALSE
			ParamDialog.HorizPercentText.Enable FALSE
			ParamDialog.VertSpin.Enable FALSE
			ParamDialog.VertText.Enable FALSE
			ParamDialog.VertPercentText.Enable FALSE
			ParamDialog.AngleSpin.Enable TRUE
			ParamDialog.AngleText.Enable TRUE
			ParamDialog.PadSpin.Enable TRUE
			ParamDialog.PadText.Enable TRUE
			ParamDialog.PadPercentText.Enable TRUE
			
		CASE FILL_TYPE_RADIAL%
			ParamDialog.HorizSpin.Enable TRUE
			ParamDialog.HorizText.Enable TRUE
			ParamDialog.HorizPercentText.Enable TRUE
			ParamDialog.VertSpin.Enable TRUE
			ParamDialog.VertText.Enable TRUE
			ParamDialog.VertPercentText.Enable TRUE
			ParamDialog.AngleSpin.Enable FALSE
			ParamDialog.AngleText.Enable FALSE
			ParamDialog.PadSpin.Enable TRUE
			ParamDialog.PadText.Enable TRUE
			ParamDialog.PadPercentText.Enable TRUE
			
		CASE FILL_TYPE_CONICAL%
			ParamDialog.HorizSpin.Enable TRUE
			ParamDialog.HorizText.Enable TRUE
			ParamDialog.HorizPercentText.Enable TRUE
			ParamDialog.VertSpin.Enable TRUE
			ParamDialog.VertText.Enable TRUE
			ParamDialog.VertPercentText.Enable TRUE
			ParamDialog.AngleSpin.Enable TRUE
			ParamDialog.AngleText.Enable TRUE
			ParamDialog.PadSpin.Enable FALSE
			ParamDialog.PadText.Enable FALSE
			ParamDialog.PadPercentText.Enable FALSE

		CASE FILL_TYPE_SQUARE%
			ParamDialog.HorizSpin.Enable TRUE
			ParamDialog.HorizText.Enable TRUE
			ParamDialog.HorizPercentText.Enable TRUE
			ParamDialog.VertSpin.Enable TRUE
			ParamDialog.VertText.Enable TRUE
			ParamDialog.VertPercentText.Enable TRUE
			ParamDialog.AngleSpin.Enable TRUE
			ParamDialog.AngleText.Enable TRUE
			ParamDialog.PadSpin.Enable TRUE
			ParamDialog.PadText.Enable TRUE
			ParamDialog.PadPercentText.Enable TRUE
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

	' Normally, all buttons should appear to be up.
	Bitmaps$(1) = CurDir$ + COLOR_DIRECT_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_DIRECT_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_DIRECT_UNPRESSED_BITMAP$
	ParamDialog.DirectButton.SetArray Bitmaps$
	ParamDialog.DirectButton.SetStyle STYLE_IMAGE_CENTERED
	Bitmaps$(1) = CurDir$ + COLOR_CCW_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_CCW_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_CCW_UNPRESSED_BITMAP$
	ParamDialog.CCWButton.SetArray Bitmaps$
	ParamDialog.CCWButton.SetStyle STYLE_IMAGE_CENTERED
	Bitmaps$(1) = CurDir$ + COLOR_CW_UNPRESSED_BITMAP$
	Bitmaps$(2) = CurDir$ + COLOR_CW_PRESSED_BITMAP$
	Bitmaps$(3) = CurDir$ + COLOR_CW_UNPRESSED_BITMAP$
	ParamDialog.CWButton.SetArray Bitmaps$
	ParamDialog.CWButton.SetStyle STYLE_IMAGE_CENTERED

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

'/////CHOICE DIALOG///////////////////////////////////////////////

' What this dialog should return if the user wants to try again.
GLOBAL CONST DIALOG_RETURN_TRY_AGAIN% = 3

BEGIN DIALOG OBJECT ChoiceDialog 299, 84, "Marcador de Traçado com Preenchimento", SUB ChoiceDialogEventHandler
	TEXT  11, 24, 281, 44, .Text1, "Se você está satisfeito com o efeito, poderá torná-lo permanente pressionando o botão OK.  Você pode também cancelar o efeito, pressionando o botão Cancelar.  Caso deseje voltar e alterar as opções anteriores, pressione o botão Tentar Novamente."
	TEXT  11, 8, 172, 11, .Text2, "O traçado com preenchimento foi aplicado."
	PUSHBUTTON  47, 60, 59, 13, .OkButton, "OK"
	PUSHBUTTON  116, 60, 59, 13, .CancelButton, "Cancelar"
	PUSHBUTTON  186, 60, 70, 13, .TryAgainButton, "Tentar Novamente"
END DIALOG

SUB ChoiceDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_MOUSE_CLICK&
			
			SELECT CASE ControlID%
				CASE ChoiceDialog.OkButton.GetID()
					ChoiceDialog.CloseDialog DIALOG_RETURN_OK%

				CASE ChoiceDialog.CancelButton.GetID()
					ChoiceDialog.CloseDialog DIALOG_RETURN_CANCEL%

				CASE ChoiceDialog.TryAgainButton.GetID()
					ChoiceDialog.CloseDialog DIALOG_RETURN_TRY_AGAIN%
	
			END SELECT

	END SELECT

END SUB

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS LONG		' The return value of various routines.
DIM Valid AS BOOLEAN		' Whether the user's input was valid.
DIM IDOriginal AS LONG		' The CDRStaticID of the user's
						' originally selected object.
DIM IDFirst AS LONG			' The CDRStaticID of the duplicate.
DIM IDMiddle AS LONG          ' The CDRStaticID of the duplicate's non-contoured part.						
DIM IDContour AS LONG		' The CDRStaticID of the contoured object.
DIM FillParam AS INTEGER		' The first parameter of ApplyFountainFill.
DIM XPos AS LONG			' The x-coordinate of the original selection.
DIM YPos AS LONG			' The y-coordinate of the original selection.

' Check to see if CorelDRAW's automation object is available.
ON ERROR GOTO ErrorNoDrawHandler
WITHOBJECT OBJECT_DRAW

' Install the general error handler.
ON ERROR GOTO MainErrorHandler

' Retrieve the directory where the script was started.
CurDir$ = GETCURRFOLDER()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF

' Check to see whether anything is selected in DRAW.
IF NOT CheckForSelection() THEN
	MessageText$ = "Selecione um objeto no CorelDRAW " + \\
                    "antes de executar o Marcador de Traçado com Preenchimento." + \\
                    NL2 + "O efeito de traçado com preenchimento será aplicado " + \\
                    "aos objetos selecionados."
	GenReturn& = MESSAGEBOX(MessageText$, TITLE_INFOBOX$, \\
	                        MB_OK_ONLY& OR MB_INFORMATION_ICON&)
	STOP
ENDIF

' Check to see if we are allowed to apply contour to the object.
IF NOT CheckForContour() THEN
	MessageText$ = "Impossível adicionar um traçado com preenchimento ao " + \\
	               "objeto selecionado atualmente." + NL2 + "Os traçados com " + \\
	               "preenchimento só podem ser aplicados a objetos " + \\
	               "aos quais o efeito Contorno possa ser aplicado." + NL2 + \\
	               "Verifique se o objeto selecionado pode " + \\
	               "receber contorno e tente outra vez."
	GenReturn& = MESSAGEBOX(MessageText$, TITLE_INFOBOX$, \\
	                        MB_OK_ONLY& OR MB_INFORMATION_ICON&)
	STOP
ENDIF

' Show the dialog.
Start:
GenReturn& = DIALOG(ParamDialog)
IF (GenReturn& = DIALOG_RETURN_OK%) THEN

	' Retrieve the CDRStaticID of the selected object so we
	' can group it later.  Also get the location.
	IDOriginal& = .GetObjectsCDRStaticID()
	.GetPosition XPos&, YPos&	
	
	' Make a duplicate that we can work with and that will be
	' safe for undo purposes.
	.DuplicateObject
	IDFirst& = .GetObjectsCDRStaticID()
	.SetPosition XPos&, YPos&

	' Remove the existing outline.
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	
	' Apply an appropriately sized outside contour to a duplicate.
	.DuplicateObject
	IDMiddle& = .GetObjectsCDRStaticID()
	.SetPosition XPos&, YPos&	
	.OrderBackOne		
	.ApplyContour 2, Width% * ConversionFactors!(ChosenUnit%), 1
	
	' Separate the contoured object, so we can apply a fountain
	' fill to the contour part.
	.Separate
	.Ungroup	
	.Trim
	
	' Here we delete all but the outer contoured part.
	'.SelectNextObject TRUE
	.Ungroup
	IDContour& = .GetObjectsCDRStaticID()
	.SelectObjectOfCDRStaticID IDMiddle&
	.DeleteObject
	
	' Apply a fountain fill.
	.SelectObjectOfCDRStaticID IDContour&
	SELECT CASE FillType%
		CASE FILL_TYPE_LINEAR%
			FillParam% = DRAW_FOUNTAIN_LINEAR%
			HorizOffset% = 0
			VertOffset% = 0
		CASE FILL_TYPE_RADIAL%
			FillParam% = DRAW_FOUNTAIN_RADIAL%
			Angle% = 0
		CASE FILL_TYPE_CONICAL%
			FillParam% = DRAW_FOUNTAIN_CONICAL%
			Pad% = 0
		CASE FILL_TYPE_SQUARE%
			FillParam% = DRAW_FOUNTAIN_SQUARE%
	END SELECT
	.ApplyFountainFill FillParam%, \\
			         HorizOffset%, \\
			         VertOffset%, \\
			         Angle% * 10, \\
			         Steps%, \\
			         Pad%, \\
			         ColorBlendType%, \\
			         Midpoint
	
	' Set the start and end colors.
	.SetFountainFillColor 0, DRAW_COLORMODEL_RGB&, FromRed%, FromGreen%, FromBlue%, 0
	.SetFountainFillColor 100, DRAW_COLORMODEL_RGB&, ToRed%, ToGreen%, ToBlue%, 0

	' Group the newly coloured 'outline' with the original selection.
	.AppendObjectToSelection IDFirst&
	.Group

	' Give the user the chance to remove the fill if it is not
	' satisfactory.
	GenReturn& = DIALOG(ChoiceDialog)
	IF GenReturn& = DIALOG_RETURN_OK% THEN
		' The user is satisfied with the fill.  Delete the original.
		.SelectObjectOfCDRStaticID IDOriginal&
		.DeleteObject
		STOP
	ENDIF

	' Otherwise, we should remove the filled object since it 
	' is not what the user wanted.
	.DeleteObject
	.SelectObjectOfCDRStaticID IDOriginal&
	IF GenReturn& = DIALOG_RETURN_TRY_AGAIN% THEN
		GOTO Start
	ENDIF

ENDIF

VeryEnd:
	STOP
 
MainErrorHandler:
	IF ERRNUM > 0 THEN
		ERRNUM = 0
		MessageText$ = "Erro geral durante "
		MessageText$ = MessageText$ + "o processamento." + NL2
		MessageText$ = MessageText$ + "Tente outra vez."
		GenReturn& = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
		                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
	ENDIF
	RESUME AT VeryEnd
	
ErrorNoDrawHandler:
	' Failed to create the automation object.
	ERRNUM = 0
	GenReturn = MESSAGEBOX( "Impossível encontrar o CorelDRAW."+NL2+\\
					    "Se este erro continuar, poderá "+ \\
					    "ser necessário reinstalar "+      \\
					    "o CorelDRAW.",				 \\
       				    TITLE_ERRORBOX,				 \\
					    MB_OK_ONLY& OR MB_STOP_ICON& )
	RESUME AT VeryEnd
	STOP

'********************************************************************
'
'	Name:	IsInteger (function)
'
'	Action:	Determines if a given string contains an integer.
'
'	Params:	InString -- The string to test for integer-ness.
'
'	Returns:	TRUE if InString contains an integer (and would
'              not cause an overflow if converted to an integer),
'              and FALSE otherwise.
'
'	Comments: None.
'
'********************************************************************
FUNCTION IsInteger( InString AS STRING ) AS BOOLEAN

	DIM ReturnVal AS BOOLEAN		' The value to be returned.
	DIM Converted AS INTEGER		' The integer representation of
							' InString.

	' Set up an error handler to trap conversion errors.
	ON ERROR GOTO II_ConversionError

	' Attempt a conversion.
	Converted% = CINT( InString )
	ReturnVal = TRUE

	ExitPoint:
		IsInteger = ReturnVal
		EXIT FUNCTION

II_ConversionError:
	ERRNUM = 0
	ReturnVal = FALSE
	RESUME AT ExitPoint

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
