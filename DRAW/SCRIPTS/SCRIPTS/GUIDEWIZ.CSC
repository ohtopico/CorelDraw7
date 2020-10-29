REM Assistente Automático de Linhas-Guia
REM 

'********************************************************************
' 
'   Script:	GuideWiz.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to automatically set up the
'                guidelines on the current page based on a set
'                of options chosen by the user.
' 
'********************************************************************

#addfol  "..\..\..\Scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"
#define NL  CHR(10) + CHR(13)
#define NL2 NL + NL

WITHOBJECT OBJECT_DRAW

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE SUB UpdatePreviewImage ( ChoiceNum AS INTEGER, UsePreset AS BOOLEAN )
DECLARE FUNCTION CalculateDistanceApart( NumGridlines AS LONG, InAvailable AS LONG ) AS STRING
DECLARE SUB UpdateGridFreqControls()
DECLARE SUB UpdateMarginControls()
DECLARE SUB UpdateCrossImage ( InChoiceNum AS INTEGER )
DECLARE SUB UpdateColumnDialog()
DECLARE FUNCTION ConvertToDrawUnits( InLength AS LONG, InUnit AS INTEGER ) AS LONG
DECLARE SUB DoGuidelineEffect()
DECLARE SUB DoMarginsEffect()
DECLARE SUB DoGridEffect()
DECLARE SUB DoCrossHairsEffect()
DECLARE FUNCTION CalculateHeightAfterMargins() AS LONG
DECLARE FUNCTION CalculateWidthAfterMargins() AS LONG
DECLARE SUB ApplyRotation( BYVAL DegreeAngle AS INTEGER, \\
	 		 	       BYREF Point1X AS LONG,	\\
			    		  BYREF Point1Y AS LONG, \\
			    		  BYREF Point2X AS LONG, \\
			    		  BYREF Point2Y AS LONG )
DECLARE SUB CreateCrossHairAt( PointX AS LONG, PointY AS LONG )
DECLARE SUB DoPresetEffect()

DECLARE FUNCTION CreateDC LIB "gdi32" (BYVAL lpDriverName AS STRING, \\
                                       BYVAL lpDeviceName AS LONG, \\
                                       BYVAL lpOutput AS LONG, \\
                                       BYVAL lpInitData AS LONG) AS LONG ALIAS "CreateDCA"
DECLARE FUNCTION GetDeviceCaps LIB "gdi32" (BYVAL hDC AS LONG, \\
                                            BYVAL nIndex AS LONG) AS LONG ALIAS "GetDeviceCaps"
DECLARE FUNCTION DeleteDC LIB "gdi32" (BYVAL hDC AS LONG) AS LONG ALIAS "DeleteDC"
DECLARE FUNCTION GetNumberOfDisplayColors( ) AS LONG

'/////CONSTANT DECLARATIONS//////////////////////////////////////////

' The graphics used for the large wizard picture on each dialog.
GLOBAL BITMAP_INTRODIALOG AS STRING
GLOBAL BITMAP_REMOVEDIALOG AS STRING
GLOBAL BITMAP_STYLEDIALOG AS STRING
GLOBAL BITMAP_CHOICEDIALOG AS STRING
GLOBAL BITMAP_ANGLEDIALOG AS STRING
GLOBAL BITMAP_GRIDFREQDIALOG AS STRING
GLOBAL BITMAP_LOCKDIALOG AS STRING
GLOBAL BITMAP_MARGINSDIALOG AS STRING
GLOBAL BITMAP_FINISHDIALOG AS STRING
GLOBAL BITMAP_CROSSDIALOG AS STRING
GLOBAL BITMAP_CENTERCROSSDIALOG AS STRING
GLOBAL BITMAP_COLUMNSDIALOG AS STRING
DIM NumColors AS LONG
NumColors& = GetNumberOfDisplayColors()
IF NumColors& <= 256 THEN
	BITMAP_INTRODIALOG$		= "\GuideB16.bmp"
	BITMAP_REMOVEDIALOG$	= "\GuideB16.bmp"
	BITMAP_STYLEDIALOG$		= "\GuideB16.bmp"
	BITMAP_CHOICEDIALOG$	= "\GuideB16.bmp"
	BITMAP_ANGLEDIALOG$		= "\GuideB16.bmp"
	BITMAP_GRIDFREQDIALOG$	= "\GuideB16.bmp"
	BITMAP_LOCKDIALOG$		= "\GuideB16.bmp"
	BITMAP_MARGINSDIALOG$	= "\GuideB16.bmp"
	BITMAP_FINISHDIALOG$	= "\GuideB16.bmp"
	BITMAP_CROSSDIALOG$		= "\GuideB16.bmp"
	BITMAP_CENTERCROSSDIALOG$= "\GuideB16.bmp"
	BITMAP_COLUMNSDIALOG$	= "\GuideB16.bmp"
ELSE
	BITMAP_INTRODIALOG$		= "\GuideB.bmp"
	BITMAP_REMOVEDIALOG$	= "\GuideB.bmp"
	BITMAP_STYLEDIALOG$		= "\GuideB.bmp"
	BITMAP_CHOICEDIALOG$	= "\GuideB.bmp"
	BITMAP_ANGLEDIALOG$		= "\GuideB.bmp"
	BITMAP_GRIDFREQDIALOG$	= "\GuideB.bmp"
	BITMAP_LOCKDIALOG$		= "\GuideB.bmp"
	BITMAP_MARGINSDIALOG$	= "\GuideB.bmp"
	BITMAP_FINISHDIALOG$	= "\GuideB.bmp"
	BITMAP_CROSSDIALOG$		= "\GuideB.bmp"
	BITMAP_CENTERCROSSDIALOG$= "\GuideB.bmp"
	BITMAP_COLUMNSDIALOG$	= "\GuideB.bmp"
ENDIF

' Title bar text for the message boxes.
GLOBAL CONST TITLE_ERRORBOX$      = "Erro do Assistente Automático de Linhas-Guia"
GLOBAL CONST TITLE_INFOBOX$       = "Informações do Assistente Automático de Linhas-Guia"
								
' Constants for dialog return values.
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2
GLOBAL CONST DIALOG_RETURN_NEXT% 	= 3
GLOBAL CONST DIALOG_RETURN_BACK% 	= 4
						
'/////GENERAL VARIABLE DECLARATIONS///////////////////////////////////

' The current directory when the script starts.
GLOBAL CurDir AS STRING

' The dimensions of the area we have available for drawing
' the guides (within the margins).
GLOBAL AvailableX AS LONG
GLOBAL AvailableY AS LONG

' The previous wizard page's position.
GLOBAL LastPageX AS LONG
GLOBAL LastPageY AS LONG
LastPageX& = -1
LastPageY& = -1
			
'/////INTRODUCTORY DIALOG//////////////////////////////////////////////
BEGIN DIALOG OBJECT IntroDialog 290, 180, "Assistente Automático de Linhas-Guia", SUB IntroDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Bem-vindo ao Assistente Automático de Linhas-Guia Corel."
	TEXT  94, 70, 187, 18, .Text3, "Para começar a criar linhas-guia, clique em Avançar."
	IMAGE  10, 10, 75, 130, .IntroImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 28, 185, 33, .Text4, "Este assistente guiará você através das etapas necessárias para configurar linhas-guia automaticamente na sua página.  Você poderá criar facilmente e com precisão as margens, colunas, grades ou linhas cruzadas."
END DIALOG

SUB IntroDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_INITIALIZATION THEN 		
		IntroDialog.BackButton.Enable FALSE 
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE IntroDialog.NextButton.GetID()
				LastPageX& = IntroDialog.GetLeftPosition()
				LastPageY& = IntroDialog.GetTopPosition()
				IntroDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE IntroDialog.CancelButton.GetID()
				IntroDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'/////FINISH DIALOG//////////////////////////////////////////////
BEGIN DIALOG OBJECT FinishDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB FinishDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .FinishButton, "&Terminar"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Parabéns!"
	IMAGE  10, 10, 75, 130, .FinishImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 28, 185, 33, .Text4, "O Assistente Automático de Linhas-Guia possui informações suficientes para criar seu efeito de linha-guia.  Para aplicá-lo, pressione Terminar."
END DIALOG

SUB FinishDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE FinishDialog.BackButton.GetID()
				LastPageX& = FinishDialog.GetLeftPosition()
				LastPageY& = FinishDialog.GetTopPosition()
				FinishDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE FinishDialog.FinishButton.GetID()
				LastPageX& = FinishDialog.GetLeftPosition()
				LastPageY& = FinishDialog.GetTopPosition()
				FinishDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE FinishDialog.CancelButton.GetID()
				FinishDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF
END FUNCTION

'/////REMOVE DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL RemoveExisting AS BOOLEAN	' Whether to remove any existing
							' guidelines before creating new ones.

' Set up defaults.
RemoveExisting = TRUE

BEGIN DIALOG OBJECT RemoveDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB RemoveDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Já há algumas linhas-guia na página atual."
	IMAGE  10, 10, 75, 130, .RemoveImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 28, 185, 33, .Text4, "Este assistente pode remover todas as linhas-guia existentes antes de criar as novas.  Caso você prefira, ele pode também manter as linhas-guia intactas e simplesmente adicionar novas."
	GROUPBOX  94, 62, 177, 54, .GroupBox2, "O que você deseja que o assistente faça?"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  109, 79, 124, 11, .RemoveOption, "Remova as linhas-guia existentes"
		OPTIONBUTTON  109, 93, 124, 11, .LeaveOption, "Mantenha as linhas-guia existentes"
END DIALOG

SUB RemoveDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	IF Event% = EVENT_INITIALIZATION THEN 		
		' Set up the delete option button.
		IF RemoveExisting THEN
			RemoveDialog.RemoveOption.SetValue TRUE
		ELSE
			RemoveDialog.RemoveOption.SetValue TRUE
		ENDIF
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE RemoveDialog.RemoveOption.GetID()
				RemoveExisting = TRUE
			CASE RemoveDialog.LeaveOption.GetID()
				RemoveExisting = FALSE
			CASE RemoveDialog.NextButton.GetID()
				LastPageX& = RemoveDialog.GetLeftPosition()
				LastPageY& = RemoveDialog.GetTopPosition()
				RemoveDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE RemoveDialog.BackButton.GetID()
				LastPageX& = RemoveDialog.GetLeftPosition()
				LastPageY& = RemoveDialog.GetTopPosition()
				RemoveDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE RemoveDialog.CancelButton.GetID()
				RemoveDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'/////STYLE DIALOG//////////////////////////////////////////////

' The array of possible choices for non-preset guideline types.
GLOBAL CONST GW_TYPE_MARGINS% = 1
GLOBAL CONST GW_TYPE_GRID%    = 2
GLOBAL CONST GW_TYPE_CROSS%   = 3
GLOBAL ChoiceArray(3) AS STRING
ChoiceArray$(GW_TYPE_MARGINS%) = "Margens e Colunas"
ChoiceArray$(GW_TYPE_GRID%) = "Grade"
ChoiceArray$(GW_TYPE_CROSS%) = "Linhas Cruzadas"

' The array of preview images.
GLOBAL ChoicePreviewArray(3) AS STRING
ChoicePreviewArray$(1) = "\GuideT1.bmp"
ChoicePreviewArray$(2) = "\GuideT2.bmp"
ChoicePreviewArray$(3) = "\GuideT3.bmp"

' The array of possible choices for preset guideline types.
GLOBAL CONST GW_PRESET_ONE_INCH_MARGINS% = 1
GLOBAL CONST GW_PRESET_THREE_COLUMN_NEWSLETTER% = 2
GLOBAL CONST GW_PRESET_BASIC_GRID% = 3
GLOBAL CONST GW_PRESET_UPPER_LEFT_GRID% = 4
GLOBAL CONST GW_PRESET_SINGLE_CROSS_HAIR% = 5
GLOBAL CONST GW_PRESET_DOUBLE_STARBURST% = 6
GLOBAL CONST GW_PRESET_RIGHT_CORNER_STARBURST% = 7

' The array of possible choices for preset types.
GLOBAL PresetArray(7) AS STRING
PresetArray$(1) = "Margens de uma polegada"
PresetArray$(2) = "Boletim em três colunas"
PresetArray$(3) = "Grade Básica"
PresetArray$(4) = "Grade Superior Esquerda"
PresetArray$(5) = "Linha Cruzada Simples"
PresetArray$(6) = "Rajada Dupla"
PresetArray$(7) = "Rajada à Direita"

' The array of preview images.
GLOBAL ChoicePresetArray(7) AS STRING
ChoicePresetArray$(1) = "\GuideP1.bmp"
ChoicePresetArray$(2) = "\GuideP2.bmp"
ChoicePresetArray$(3) = "\GuideP3.bmp"
ChoicePresetArray$(4) = "\GuideP4.bmp"
ChoicePresetArray$(5) = "\GuideP5.bmp"
ChoicePresetArray$(6) = "\GuideP6.bmp"
ChoicePresetArray$(7) = "\GuideP7.bmp"

' Variables needed for this dialog.
GLOBAL ChoiceNum AS INTEGER		' The number of the user's selection.

' Set up defaults.
ChoiceNum% = GW_TYPE_MARGINS%

' Variables needed for this dialog.
GLOBAL UsePreset AS BOOLEAN	' Whether the user wants a preset (as opposed
						' to creating his/her custom guideline style).

' Set up defaults.
UsePreset = FALSE

BEGIN DIALOG OBJECT StyleDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB StyleDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  92, 45, 181, 24, .Text1, "Caso prefira, você poderá selecionar a partir de uma lista de estilos de linhas-guia predefinidas, que não será necessário personalizar."
	IMAGE  10, 10, 75, 130, .StyleImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	GROUPBOX  94, 76, 177, 53, .GroupBox2, "O que você deseja fazer?"
	TEXT  92, 10, 181, 32, .Text2, "Você pode selecionar um tipo de linha-guia e personalizá-lo.  Por exemplo, se optar por criar linhas-guia de margem, precisará informar qual largura de margem deve ser criada."
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  109, 105, 139, 12, .PresetOption, "Selecione um predefinido"
		OPTIONBUTTON  109, 92, 139, 12, .CustomOption, "Selecione um tipo de linha-guia personalizável"
END DIALOG

SUB StyleDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	IF Event% = EVENT_INITIALIZATION THEN 	
		' Update the use presets option group.
		IF UsePreset THEN
			StyleDialog.PresetOption.SetValue 1
		ELSE
			StyleDialog.CustomOption.SetValue 1
		ENDIF
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE StyleDialog.PresetOption.GetID()
				UsePreset = TRUE
			CASE StyleDialog.CustomOption.GetID()
				UsePreset = FALSE
			CASE StyleDialog.NextButton.GetID()
				LastPageX& = StyleDialog.GetLeftPosition()
				LastPageY& = StyleDialog.GetTopPosition()
			
				' If the user is going from presets to non-presets, \
				' the range for possible ChoiceNum values is much less.
				IF ChoiceNum% > 3 THEN
					ChoiceNum% = GW_TYPE_MARGINS%
				ENDIF
				StyleDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE StyleDialog.BackButton.GetID()
				LastPageX& = StyleDialog.GetLeftPosition()
				LastPageY& = StyleDialog.GetTopPosition()
				StyleDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE StyleDialog.CancelButton.GetID()
				StyleDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'/////CHOICE DIALOG//////////////////////////////////////////////

BEGIN DIALOG OBJECT ChoiceDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB ChoiceDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .ChoiceImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 14, .SelectionText, "Selecione XXXXXXXXXX"
	DDLISTBOX  127, 27, 113, 151, .SelectionListBox
	IMAGE  136, 52, 95, 87, .PreviewImage
END DIALOG

SUB ChoiceDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	IF Event% = EVENT_INITIALIZATION THEN 	
		ChoiceDialog.PreviewImage.SetStyle STYLE_SUNKEN
		ChoiceDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED
		ChoiceDialog.PreviewImage.SetStyle STYLE_SUNKEN
		ChoiceDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED

		' Load the list box with the available choices.
		IF UsePreset THEN
			ChoiceDialog.SelectionText.SetText "Selecione um estilo de linha-guia predefinido."
			ChoiceDialog.SelectionListBox.SetArray PresetArray$
			ChoiceDialog.SelectionListBox.SetSelect 1
			ChoiceNum% = 1
		ELSE
			ChoiceDialog.SelectionText.SetText "Selecione um tipo de linha-guia."
			ChoiceDialog.SelectionListBox.SetArray ChoiceArray$
			ChoiceDialog.SelectionListBox.SetSelect ChoiceNum%
		ENDIF
		UpdatePreviewImage ChoiceNum%, UsePreset
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE ChoiceDialog.SelectionListBox.GetID()
				ChoiceNum% = ChoiceDialog.SelectionListBox.GetSelect()
				UpdatePreviewImage ChoiceNum%, UsePreset
			CASE ChoiceDialog.NextButton.GetID()
				LastPageX& = ChoiceDialog.GetLeftPosition()
				LastPageY& = ChoiceDialog.GetTopPosition()
				ChoiceDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE ChoiceDialog.BackButton.GetID()
				LastPageX& = ChoiceDialog.GetLeftPosition()
				LastPageY& = ChoiceDialog.GetTopPosition()
				ChoiceDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE ChoiceDialog.CancelButton.GetID()
				ChoiceDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	UpdatePreviewImage (dialog subroutine)
'
'	Action:	Changes the image on the choice dialog to reflect
'			the user's current choice of guideline types or
'              presets.
'
'	Params:	InChoiceNum - The index number of the user's choice.
'			InUsePreset - Whether the user selected from the preset list.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdatePreviewImage ( InChoiceNum AS INTEGER, InUsePreset AS BOOLEAN )

	IF InUsePreset THEN
		
		ChoiceDialog.PreviewImage.SetImage \\
			CurDir$ + ChoicePresetArray$(InChoiceNum%)
		
	ELSE
	
		ChoiceDialog.PreviewImage.SetImage \\
		      CurDir$ + ChoicePreviewArray$(InChoiceNum%)
		
	ENDIF

	' Add a sunken, centred look to the preview image.
	ChoiceDialog.PreviewImage.SetStyle STYLE_SUNKEN
	ChoiceDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED
	ChoiceDialog.PreviewImage.SetStyle STYLE_SUNKEN
	ChoiceDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED
	
END SUB

'/////ANGLE DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL ChosenAngle AS INTEGER		' The angle in degress of the
							' guidelines.
GLOBAL NumSpokes AS INTEGER		' The number of spokes for a cross-hair
							' guideline style.

' Set up defaults.
ChosenAngle% = 0
NumSpokes% = 2

BEGIN DIALOG OBJECT AngleDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB AngleDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .AngleImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  166, 29, 38, 10, .Text3, "Graus"
	SPINCONTROL  130, 28, 31, 13, .AngleSpin
	TEXT  96, 10, 181, 16, .AngleText, "Caso deseje, você poderá girar a linha-guia "
	TEXT  96, 29, 15, 11, .Text1, "Girar:"
	TEXT  96, 51, 180, 32, .SpokesText1, "Você pode também selecionar o número de linhas através de cada linha cruzada.  O default fornecerá um efeito simples, enquanto números mais altos gerarão um efeito de rajada."
	TEXT  96, 89, 79, 12, .SpokesText2, "Número de linhas:"
	SPINCONTROL  172, 88, 27, 13, .SpokesSpin
END DIALOG

SUB AngleDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX calls.

	IF Event% = EVENT_INITIALIZATION THEN 	
		' Depending on the type of guidelines being generated, update
		' the AngleText.
		SELECT CASE ChoiceNum%
			CASE GW_TYPE_GRID%
				AngleDialog.AngleText.SetText \\
					"Caso deseje, poderá gerar uma grade girada."
				AngleDialog.SpokesText1.SetStyle STYLE_INVISIBLE
				AngleDialog.SpokesText2.SetStyle STYLE_INVISIBLE
				AngleDialog.SpokesSpin.SetStyle STYLE_INVISIBLE
			CASE GW_TYPE_CROSS%
				AngleDialog.AngleText.SetText \\
					"Caso deseje, poderá gerar um conjunto girado de linhas cruzadas."
				AngleDialog.SpokesText1.SetStyle STYLE_VISIBLE
				AngleDialog.SpokesText2.SetStyle STYLE_VISIBLE
				AngleDialog.SpokesSpin.SetStyle STYLE_VISIBLE
		END SELECT

		' Update the angle spin control.
		AngleDialog.AngleSpin.SetValue ChosenAngle%
		
		' Update the spokes control.
		AngleDialog.SpokesSpin.SetValue NumSpokes%
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE AngleDialog.AngleSpin.GetID()
				ChosenAngle% = AngleDialog.AngleSpin.GetValue()
			CASE AngleDialog.NextButton.GetID()
				LastPageX& = AngleDialog.GetLeftPosition()
				LastPageY& = AngleDialog.GetTopPosition()
				AngleDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE AngleDialog.BackButton.GetID()
				LastPageX& = AngleDialog.GetLeftPosition()
				LastPageY& = AngleDialog.GetTopPosition()
				AngleDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE AngleDialog.CancelButton.GetID()
				AngleDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF
	IF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%
			CASE AngleDialog.AngleSpin.GetID()
				IF AngleDialog.AngleSpin.GetValue() < -180 THEN
					MsgReturn& = MESSAGEBOX("Selecione um ângulo entre -180 e 180 graus.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ChosenAngle% = -180
					AngleDialog.AngleSpin.SetValue ChosenAngle%
				ELSEIF AngleDialog.AngleSpin.GetValue() > 180 THEN
					MsgReturn& = MESSAGEBOX("Selecione um ângulo entre -180 e 180 graus.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ChosenAngle% = 180
					AngleDialog.AngleSpin.SetValue ChosenAngle%
				ELSE
					ChosenAngle% = AngleDialog.AngleSpin.GetValue()
				ENDIF
			CASE AngleDialog.SpokesSpin.GetID()
				IF AngleDialog.SpokesSpin.GetValue() < 2 THEN
					MsgReturn& = MESSAGEBOX("Selecione um número de raios entre 2 e 30.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumSpokes% = 2
					AngleDialog.SpokesSpin.SetValue NumSpokes%
				ELSEIF AngleDialog.SpokesSpin.GetValue() > 30 THEN
					MsgReturn& = MESSAGEBOX("Selecione um número de raios entre 2 e 30.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumSpokes% = 30
					AngleDialog.SpokesSpin.SetValue NumSpokes%
				ELSE
					NumSpokes% = AngleDialog.SpokesSpin.GetValue()
				ENDIF				
		END SELECT
	ENDIF

END FUNCTION

'/////GRIDFREQ DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL NumVGuidelines AS LONG	  ' The number of vertical guidelines.
GLOBAL NumHGuidelines AS LONG   ' The number of horizontal guidelines.
GLOBAL VGuidelinesOn AS BOOLEAN ' Whether vertical guidelines are turned on.
GLOBAL HGuidelinesOn AS BOOLEAN ' Whether horizontal guidelines are turned on.

' Set up defaults.
NumVGuidelines& = 10
NumHGuidelines& = 10
VGuidelinesOn = TRUE
HGuidelinesOn = TRUE

BEGIN DIALOG OBJECT GridFreqDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB GridFreqDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .GridFreqImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 18, .AngleText, "Selecione o número de linhas horizontais e verticais que você deseja na grade."
	SPINCONTROL  136, 47, 27, 13, .HorizSpin
	GROUPBOX  95, 34, 184, 50, .GroupBox3, "Horizontal"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  106, 64, 137, 13, .HorizOff, "Não inclua linhas de grade horizontais"
		OPTIONBUTTON  106, 47, 27, 13, .HorizOn, "Utilize "
	OPTIONGROUP .OptionGroup2Val%
		OPTIONBUTTON  106, 120, 137, 13, .VertOff, "Não inclua linhas de grade vertical"
		OPTIONBUTTON  106, 103, 27, 13, .VertOn, "Utilize "
	TEXT  168, 45, 86, 16, .HorizFreqText, "linhas XXX polegadas afastadas"
	SPINCONTROL  136, 103, 27, 13, .VertSpin
	GROUPBOX  95, 90, 184, 50, .GroupBox4, "Vertical"
	TEXT  168, 101, 86, 16, .VertFreqText, "linhas XXX polegadas afastadas"
END DIALOG

SUB GridFreqDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM CurVValue AS LONG
	DIM CurHValue AS LONG
	DIM MsgReturn AS LONG
	
	IF Event% = EVENT_INITIALIZATION THEN 	
		UpdateGridFreqControls
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE GridFreqDialog.HorizOn.GetID()
				HGuidelinesOn = TRUE
				UpdateGridFreqControls
			CASE GridFreqDialog.HorizOff.GetID()
				HGuidelinesOn = FALSE
				UpdateGridFreqControls
			CASE GridFreqDialog.VertOn.GetID()
				VGuidelinesOn = TRUE
				UpdateGridFreqControls
			CASE GridFreqDialog.VertOff.GetID()
				VGuidelinesOn = FALSE
				UpdateGridFreqControls
			CASE GridFreqDialog.NextButton.GetID()
				LastPageX& = GridFreqDialog.GetLeftPosition()
				LastPageY& = GridFreqDialog.GetTopPosition()
				GridFreqDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE GridFreqDialog.BackButton.GetID()
				LastPageX& = GridFreqDialog.GetLeftPosition()
				LastPageY& = GridFreqDialog.GetTopPosition()
				GridFreqDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE GridFreqDialog.CancelButton.GetID()
				GridFreqDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%
			CASE GridFreqDialog.VertSpin.GetID()
				CurVValue& = GridFreqDialog.VertSpin.GetValue()
				IF (CurVValue& < 2) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de linhas verticais entre 2 e 50.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumVGuidelines& = 2
					GridFreqDialog.VertSpin.SetValue NumVGuidelines&
				ELSEIF (CurVValue& > 50) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de linhas verticais entre 2 e 50.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumVGuidelines& = 50
					GridFreqDialog.VertSpin.SetValue NumVGuidelines&
				ELSE
					NumVGuidelines& = CurVValue&	
				ENDIF				
			CASE GridFreqDialog.HorizSpin.GetID()
				CurHValue& = GridFreqDialog.HorizSpin.GetValue()
				IF (CurHValue& < 2) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de linhas horizontais entre 2 e 50.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumHGuidelines& = 2
					GridFreqDialog.HorizSpin.SetValue NumHGuidelines&
				ELSEIF (CurHValue& > 50) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de linhas horizontais entre 2 e 50.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumHGuidelines& = 50
					GridFreqDialog.HorizSpin.SetValue NumHGuidelines&
				ELSE
					NumHGuidelines& = CurHValue&
				ENDIF	
		END SELECT
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	UpdateGridFreqControls (dialog subroutine)
'
'	Action:	Updates and enables/disables all the appropriate
'			controls on GridFreqDialog based on the values of
'              NumVGuidelines, NumHGuidelines, VGuidelinesOn,
'			HGuidelinesOn.
'
'	Params:	None.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateGridFreqControls()

	' Update the frequencies.
	GridFreqDialog.HorizSpin.SetValue NumHGuidelines&
	GridFreqDialog.HorizFreqText.SetText "linhas " + \\
	     CalculateDistanceApart(NumHGuidelines&, CalculateWidthAfterMargins()) + " mm afastadas"
	GridFreqDialog.VertSpin.SetValue NumVGuidelines&
	GridFreqDialog.VertFreqText.SetText "linhas " + \\
	     CalculateDistanceApart(NumVGuidelines&, CalculateHeightAfterMargins()) + " mm afastadas"

	' Update which controls are active.
	IF HGuidelinesOn THEN
		GridFreqDialog.HorizSpin.Enable TRUE
		GridFreqDialog.HorizOn.SetValue 1
	ELSE
		GridFreqDialog.HorizSpin.Enable FALSE
		GridFreqDialog.HorizOff.SetValue 1
	ENDIF
	IF VGuidelinesOn THEN
		GridFreqDialog.VertSpin.Enable TRUE
		GridFreqDialog.VertOn.SetValue 1
	ELSE
		GridFreqDialog.VertSpin.Enable FALSE
		GridFreqDialog.VertOff.SetValue 1
	ENDIF

	' Update the angle spin control.
	AngleDialog.AngleSpin.SetValue ChosenAngle%

END SUB

'/////LOCK DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL LockGuidelines AS BOOLEAN	' Whether the created guidelines should be locked.

' Set up defaults.
LockGuidelines = FALSE

BEGIN DIALOG OBJECT LockDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB LockDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .LockImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 11, 185, 33, .Text4, "Quando esse assistente cria novas linhas-guia, pode bloqueá-las automaticamente para que não possam ser movidas por acidente."
	GROUPBOX  94, 43, 177, 54, .GroupBox2, "O que você deseja que o assistente faça?"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  109, 60, 124, 11, .LockOption, "Bloqueie as novas linhas-guia"
		OPTIONBUTTON  109, 75, 124, 11, .UnlockOption, "Não bloqueie as novas linhas-guia"
END DIALOG

SUB LockDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	IF Event% = EVENT_INITIALIZATION THEN 		
		' Set up the lock guidelines button.
		IF LockGuidelines THEN
			LockDialog.LockOption.SetValue 1
		ELSE
			LockDialog.UnlockOption.SetValue 1
		ENDIF
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE LockDialog.LockOption.GetID()
				LockGuidelines = TRUE
			CASE LockDialog.UnlockOption.GetID()
				LockGuidelines = FALSE
			CASE LockDialog.NextButton.GetID()
				LastPageX& = LockDialog.GetLeftPosition()
				LastPageY& = LockDialog.GetTopPosition()
				LockDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE LockDialog.BackButton.GetID()
				LastPageX& = LockDialog.GetLeftPosition()
				LastPageY& = LockDialog.GetTopPosition()
				LockDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE LockDialog.CancelButton.GetID()
				LockDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'/////MARGINS DIALOG//////////////////////////////////////////////

' The array of possible units the user may select from.
GLOBAL UnitsArray(7) AS STRING
GLOBAL CONST GW_UNIT_1_INCH% = 1
GLOBAL CONST GW_UNIT_01_INCH% = 2
GLOBAL CONST GW_UNIT_136_INCH% = 3
GLOBAL CONST GW_UNIT_0001_INCH% = 4
GLOBAL CONST GW_UNIT_1_CM% = 5
GLOBAL CONST GW_UNIT_0001_CM% = 6
GLOBAL CONST GW_UNIT_1_PT% = 7
UnitsArray(GW_UNIT_1_INCH%) = "1 pol."
UnitsArray(GW_UNIT_01_INCH%) = "0,1 pol."
UnitsArray(GW_UNIT_136_INCH%) = "1/36 pol."
UnitsArray(GW_UNIT_0001_INCH%) = "0,001 pol."
UnitsArray(GW_UNIT_1_CM%) = "1 cm."
UnitsArray(GW_UNIT_0001_CM%) = "0,001 cm."
UnitsArray(GW_UNIT_1_PT%) = "1 pt."

' Variables needed for this dialog.
GLOBAL TopMargin AS LONG
GLOBAL TopUnit AS INTEGER
GLOBAL BottomMargin AS LONG
GLOBAL BottomUnit AS INTEGER
GLOBAL LeftMargin AS LONG
GLOBAL LeftUnit AS INTEGER
GLOBAL RightMargin AS LONG
GLOBAL RightUnit AS INTEGER
GLOBAL MirrorOn AS LONG	' Whether top/bottom and left/right values are
					' being mirrored.

' Set up defaults.
MirrorOn = TRUE
TopMargin& = 2
TopUnit% = 5
BottomMargin& = 2
BottomUnit% = 5
LeftMargin& = 2
LeftUnit% = 5
RightMargin& = 2
RightUnit% = 5

BEGIN DIALOG OBJECT MarginsDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB MarginsDialogEventHandler
	PUSHBUTTON  180, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  134, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  233, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .MarginsImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 11, 185, 20, .IntroText, ""
	GROUPBOX  101, 35, 160, 105, .MarginGroup, "Margens"
	CHECKBOX  110, 122, 76, 11, .MirrorCheck, "Espelhar margens"
	TEXT  110, 51, 26, 12, .TopText, "Topo:"
	SPINCONTROL  148, 49, 33, 13, .TopSpin
	TEXT  184, 51, 5, 10, .TopX, "x"
	DDLISTBOX  191, 49, 52, 85, .TopListBox
	SPINCONTROL  148, 67, 33, 13, .BottomSpin
	DDLISTBOX  191, 67, 52, 85, .BottomListBox
	TEXT  184, 69, 5, 10, .BottomX, "x"
	TEXT  110, 69, 26, 12, .BottomText, "Base:"
	SPINCONTROL  148, 85, 33, 13, .LeftSpin
	DDLISTBOX  191, 85, 52, 85, .LeftListBox
	TEXT  184, 87, 5, 10, .LeftX, "x"
	TEXT  110, 87, 35, 12, .LeftText, "Esquerda:"
	TEXT  110, 106, 26, 12, .RightText, "Direita:"
	SPINCONTROL  148, 104, 33, 13, .RightSpin
	TEXT  184, 106, 5, 10, .RightX, "x"
	DDLISTBOX  191, 104, 52, 85, .RightListBox
END DIALOG

SUB MarginsDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG	' The return value of the messagebox.

	IF Event% = EVENT_INITIALIZATION THEN 		
		' Set up all the controls.
		MarginsDialog.MirrorCheck.SetThreeState FALSE
		MarginsDialog.TopListBox.SetArray UnitsArray$
		MarginsDialog.BottomListBox.SetArray UnitsArray$
		MarginsDialog.LeftListBox.SetArray UnitsArray$
		MarginsDialog.RightListBox.SetArray UnitsArray$
		UpdateMarginControls
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE MarginsDialog.MirrorCheck.GetID()
				IF (MarginsDialog.MirrorCheck.GetValue() = 1) THEN
					MirrorOn = TRUE
					BottomMargin& = MarginsDialog.TopSpin.GetValue()
					BottomUnit% = MarginsDialog.TopListbox.GetSelect()
					RightMargin& = MarginsDialog.LeftSpin.GetValue()
					RightUnit% = MarginsDialog.LeftListbox.GetSelect()
				ELSE
					MirrorOn = FALSE
				ENDIF
				UpdateMarginControls
			CASE MarginsDialog.TopListbox.GetID()
				TopUnit% = MarginsDialog.TopListbox.GetSelect()
				IF MirrorOn THEN
					BottomUnit% = MarginsDialog.TopListbox.GetSelect()
					MarginsDialog.BottomListbox.SetSelect BottomUnit%
				ENDIF
			CASE MarginsDialog.BottomListbox.GetID()
				BottomUnit% = MarginsDialog.BottomListbox.GetSelect()
			CASE MarginsDialog.LeftListbox.GetID()
				LeftUnit% = MarginsDialog.LeftListbox.GetSelect()
				IF MirrorOn THEN
					RightUnit% = MarginsDialog.LeftListbox.GetSelect()
					MarginsDialog.RightListbox.SetSelect RightUnit%
				ENDIF
			CASE MarginsDialog.RightListbox.GetID()
				RightUnit% = MarginsDialog.RightListbox.GetSelect()
			CASE MarginsDialog.NextButton.GetID()
				LastPageX& = MarginsDialog.GetLeftPosition()
				LastPageY& = MarginsDialog.GetTopPosition()
				IF (CalculateWidthAfterMargins() <= 0) THEN
					' These margins are too wide.
					MsgReturn& = MESSAGEBOX( "As margens esquerda e direita selecionadas são largas demais." + NL2 + \\
					                         "Lembre-se, sua página tem apenas " + CSTR(TOINCHES(AvailableX&)) + \\
					                         " polegadas de largura.  Tente outra vez.", TITLE_ERRORBOX$, MB_OK_ONLY )
				ELSEIF (CalculateHeightAfterMargins() <= 0) THEN
					' These margins are too large on the top and bottom.
					MsgReturn& = MESSAGEBOX( "As margens esquerda e direita selecionadas são largas demais." + NL2 + \\
					                         "Lembre-se, sua página tem apenas " + CSTR(TOINCHES(AvailableY&)) + \\
					                         " polegadas de largura.  Tente outra vez.", TITLE_ERRORBOX$, MB_OK_ONLY )					
				ELSE
					MarginsDialog.CloseDialog DIALOG_RETURN_NEXT%
				ENDIF
			CASE MarginsDialog.BackButton.GetID()
				LastPageX& = MarginsDialog.GetLeftPosition()
				LastPageY& = MarginsDialog.GetTopPosition()
				MarginsDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE MarginsDialog.CancelButton.GetID()
				MarginsDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%
			CASE MarginsDialog.TopSpin.GetID()
				IF (MarginsDialog.TopSpin.GetValue() < 0) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem superior entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					TopMargin& = 0
					MarginsDialog.TopSpin.SetValue 0
				ELSEIF (MarginsDialog.TopSpin.GetValue() > 999) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem superior entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					TopMargin& = 999
					MarginsDialog.TopSpin.SetValue 999
				ELSE 
					TopMargin& = MarginsDialog.TopSpin.GetValue()
				ENDIF
				IF MirrorOn THEN
					BottomMargin& = MarginsDialog.TopSpin.GetValue()
					MarginsDialog.BottomSpin.SetValue BottomMargin&
				ENDIF
			CASE MarginsDialog.BottomSpin.GetID()
				IF (MarginsDialog.BottomSpin.GetValue() < 0) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem inferior entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					BottomMargin& = 0
					MarginsDialog.BottomSpin.SetValue 0
				ELSEIF (MarginsDialog.BottomSpin.GetValue() > 999) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem inferior entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					BottomMargin& = 999
					MarginsDialog.BottomSpin.SetValue 999
				ELSE 
					BottomMargin& = MarginsDialog.BottomSpin.GetValue()
				ENDIF
			CASE MarginsDialog.LeftSpin.GetID()
				IF (MarginsDialog.LeftSpin.GetValue() < 0) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem esquerda entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					LeftMargin& = 0
					MarginsDialog.LeftSpin.SetValue 0
				ELSEIF (MarginsDialog.LeftSpin.GetValue() > 999) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem esquerda entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)		
					LeftMargin& = 999
					MarginsDialog.LeftSpin.SetValue 999
				ELSE 
					LeftMargin& = MarginsDialog.LeftSpin.GetValue()
				ENDIF
				IF MirrorOn THEN
					RightMargin& = MarginsDialog.LeftSpin.GetValue()
					MarginsDialog.RightSpin.SetValue RightMargin&
				ENDIF
			CASE MarginsDialog.RightSpin.GetID()
				IF (MarginsDialog.RightSpin.GetValue() < 0) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem direita entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					RightMargin& = 0
					MarginsDialog.RightSpin.SetValue 0
				ELSEIF (MarginsDialog.RightSpin.GetValue() > 999) THEN
					MsgReturn& = MESSAGEBOX("Digite um tamanho de margem direita entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)			
					RightMargin& = 999
					MarginsDialog.RightSpin.SetValue 999
				ELSE 
					RightMargin& = MarginsDialog.RightSpin.GetValue()
				ENDIF
			CASE MarginsDialog.MirrorCheck.GetID()
				IF MarginsDialog.MirrorCheck.GetValue() THEN
					MirrorOn = TRUE
				ELSE
					MirrorOn = FALSE
				ENDIF
				UpdateMarginControls
		END SELECT
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	UpdateMarginControls (dialog subroutine)
'
'	Action:	Updates and enables/disables all the appropriate
'			controls on MarginsDialog based on the values of
'              the global dialog variables.
'
'	Params:	None.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateMarginControls()

	' Depending on the type of guidelines the user is making,
	' we need to change the intro text.
	SELECT CASE ChoiceNum%
		CASE GW_TYPE_MARGINS%
			MarginsDialog.IntroText.SetText "Selecione as margens da página."
		CASE GW_TYPE_GRID%
			MarginsDialog.IntroText.SetText "Caso não deseje que a grade " + \\
									  "ocupe toda a página, você pode adicionar margens."
		CASE GW_TYPE_CROSS%
			' Do nothing.
	END SELECT

	' Update all controls with the current values. 
	MarginsDialog.TopSpin.SetValue TopMargin&
	MarginsDialog.BottomSpin.SetValue BottomMargin&
	MarginsDialog.LeftSpin.SetValue LeftMargin&
	MarginsDialog.RightSpin.SetValue RightMargin&
	MarginsDialog.TopListbox.SetSelect TopUnit%
	MarginsDialog.BottomListbox.SetSelect BottomUnit%
	MarginsDialog.LeftListbox.SetSelect LeftUnit%
	MarginsDialog.RightListbox.SetSelect RightUnit%
	IF MirrorOn THEN
		MarginsDialog.MirrorCheck.SetValue 1
	ELSE
		MarginsDialog.MirrorCheck.SetValue 0
	ENDIF
	
	' Depending whether mirroring is on, we need to disable various
	' controls.
	MarginsDialog.BottomSpin.Enable (NOT MirrorOn)
	MarginsDialog.BottomListbox.Enable (NOT MirrorOn)
	MarginsDialog.BottomX.Enable (NOT MirrorOn)
	MarginsDialog.BottomText.Enable (NOT MirrorOn)
	MarginsDialog.RightSpin.Enable (NOT MirrorOn)
	MarginsDialog.RightListbox.Enable (NOT MirrorOn)
	MarginsDialog.RightX.Enable (NOT MirrorOn)
	MarginsDialog.RightText.Enable (NOT MirrorOn)

END SUB

'/////CROSS DIALOG//////////////////////////////////////////

' The array of possible choices for cross-hair types.
GLOBAL CONST GW_CROSS_SINGLE%     = 1
GLOBAL CONST GW_CROSS_HORIZ_PAIR% = 2
GLOBAL CONST GW_CROSS_VERT_PAIR%  = 3
GLOBAL CONST GW_CROSS_TRIANGLE%   = 4
GLOBAL CONST GW_CROSS_SQUARE%     = 5
GLOBAL CrossArray(5) AS STRING
CrossArray$(GW_CROSS_SINGLE%)     = "Simples"
CrossArray$(GW_CROSS_HORIZ_PAIR%) = "Par Horizontal"
CrossArray$(GW_CROSS_VERT_PAIR%)  = "Par Vertical"
CrossArray$(GW_CROSS_TRIANGLE%)   = "Triângulo"
CrossArray$(GW_CROSS_SQUARE%)     = "Quadrado"

' The array of preview images.
GLOBAL CrossPreviewArray(5) AS STRING
CrossPreviewArray$(1) = "\GuideC1.bmp"
CrossPreviewArray$(2) = "\GuideC2.bmp"
CrossPreviewArray$(3) = "\GuideC3.bmp"
CrossPreviewArray$(4) = "\GuideC4.bmp"
CrossPreviewArray$(5) = "\GuideC5.bmp"

' Variables needed for this dialog.
GLOBAL CrossNum AS INTEGER		' The number of the user's selection.

' Set up defaults.
CrossNum% = GW_CROSS_SINGLE%

BEGIN DIALOG OBJECT CrossDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB CrossDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .CrossImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 14, .SelectionText, "Selecione um estilo de linhas cruzadas."
	DDLISTBOX  127, 27, 113, 96, .SelectionListBox
	IMAGE  136, 52, 95, 87, .PreviewImage
END DIALOG

SUB CrossDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	IF Event% = EVENT_INITIALIZATION THEN 	
		' Load the list box with the available choices.
		CrossDialog.SelectionListBox.SetArray CrossArray$
		CrossDialog.SelectionListBox.SetSelect CrossNum%
		UpdateCrossImage CrossNum%
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE CrossDialog.SelectionListBox.GetID()
				CrossNum% = CrossDialog.SelectionListBox.GetSelect()
				UpdateCrossImage CrossNum%
			CASE CrossDialog.NextButton.GetID()
				LastPageX& = CrossDialog.GetLeftPosition()
				LastPageY& = CrossDialog.GetTopPosition()
				CrossDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE CrossDialog.BackButton.GetID()
				LastPageX& = CrossDialog.GetLeftPosition()
				LastPageY& = CrossDialog.GetTopPosition()
				CrossDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE CrossDialog.CancelButton.GetID()
				CrossDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	UpdateCrossImage (dialog subroutine)
'
'	Action:	Changes the image on the cross dialog to reflect
'			the user's current choice of cross-hair types.
'
'	Params:	InChoiceNum - The index number of the user's choice.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateCrossImage ( InChoiceNum AS INTEGER )

	CrossDialog.PreviewImage.SetImage \\
	      CurDir$ + CrossPreviewArray$(InChoiceNum%)

	' Add a sunken, centred look to the preview image.
	CrossDialog.PreviewImage.SetStyle STYLE_SUNKEN
	CrossDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED

END SUB

'/////CENTERCROSS DIALOG/////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL CrossXOffset AS LONG
GLOBAL CrossXUnit AS INTEGER
GLOBAL CrossYOffset AS LONG
GLOBAL CrossYUnit AS INTEGER

' Set up defaults.
CrossXOffset& = 0
CrossYOffset& = 0
CrossXUnit% = 1   ' This means inches.  See UnitsArray above.
CrossYUnit% = 1

BEGIN DIALOG OBJECT CenterCrossDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB CenterCrossDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .CenterCrossImage
	GROUPBOX  9, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 28, .AngleText, "Por default, o Assistente Automático de Linhas-Guia centralizará as linhas cruzadas na página.  Caso você deseje, poderá alterar o centro do efeito."
	GROUPBOX  102, 43, 165, 59, .GroupBox2, "Mover o efeito"
	SPINCONTROL  110, 59, 34, 13, .HorizSpin
	DDLISTBOX  154, 59, 51, 64, .HorizListbox
	SPINCONTROL  110, 78, 34, 13, .VertSpin
	DDLISTBOX  154, 78, 51, 64, .VertListbox
	TEXT  147, 80, 5, 10, .TextX2, "x"
	TEXT  147, 60, 5, 10, .TextX1, "x"
	TEXT  210, 79, 52, 11, .Text6, "verticalmente"
	TEXT  210, 61, 52, 11, .Text7, "horizontalmente"
END DIALOG

SUB CenterCrossDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM GenReturn AS LONG

	IF Event% = EVENT_INITIALIZATION THEN 
		' Set up all the controls.
		CenterCrossDialog.HorizListbox.SetArray UnitsArray$
		CenterCrossDialog.VertListbox.SetArray UnitsArray$
		CenterCrossDialog.HorizListbox.SetSelect CrossXUnit%
		CenterCrossDialog.VertListbox.SetSelect CrossYUnit%
		CenterCrossDialog.HorizSpin.SetValue CrossXOffset&
		CenterCrossDialog.VertSpin.SetValue CrossYOffset&
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE CenterCrossDialog.HorizListbox.GetID()
				CrossXUnit% = CenterCrossDialog.HorizListbox.GetSelect()
			CASE CenterCrossDialog.VertListbox.GetID()
				CrossYUnit% = CenterCrossDialog.VertListbox.GetSelect()
			CASE CenterCrossDialog.NextButton.GetID()
				LastPageX& = CenterCrossDialog.GetLeftPosition()
				LastPageY& = CenterCrossDialog.GetTopPosition()
						
				' Make sure the center has not been moved off the page.
				IF (ABS(ConvertToDrawUnits( CrossXOffset&, CrossXUnit% )) > (AvailableX&)) OR \\
                       (ABS(ConvertToDrawUnits( CrossYOffset&, CrossYUnit% )) > (AvailableY&)) THEN
					GenReturn& = MESSAGEBOX( "Os valores selecionados posicionarão " + \\
                                                  "o centro do efeito de linhas-guia muito " + \\
                                                  "fora da página." + NL2 + \\
                                                  "Selecione valores menores e tente outra vez.", \\
                                                  TITLE_ERRORBOX$, MB_EXCLAMATION_ICON )
				ELSE
					CenterCrossDialog.CloseDialog DIALOG_RETURN_NEXT%
				ENDIF
			CASE CenterCrossDialog.BackButton.GetID()
				LastPageX& = CenterCrossDialog.GetLeftPosition()
				LastPageY& = CenterCrossDialog.GetTopPosition()
				CenterCrossDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE CenterCrossDialog.CancelButton.GetID()
				CenterCrossDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%		
			CASE CenterCrossDialog.HorizSpin.GetID()
				IF (CenterCrossDialog.HorizSpin.GetValue() > 999) THEN
					GenReturn& = MESSAGEBOX("Digite um valor de deslocamento horizontal entre 1999 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					CrossXOffset& = 999
					CenterCrossDialog.HorizSpin.SetValue CrossXOffset&
				ELSEIF (CenterCrossDialog.HorizSpin.GetValue() < -999) THEN
					GenReturn& = MESSAGEBOX("Digite um valor de deslocamento horizontal entre 1999 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					CrossXOffset& = -999
					CenterCrossDialog.HorizSpin.SetValue CrossXOffset&
				ELSE
					CrossXOffset& = CenterCrossDialog.HorizSpin.GetValue()
				ENDIF
			CASE CenterCrossDialog.VertSpin.GetID()
				IF (CenterCrossDialog.VertSpin.GetValue() > 999) THEN
					GenReturn& = MESSAGEBOX("Digite um valor de deslocamento vertical entre 1999 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					CrossYOffset& = 999
					CenterCrossDialog.VertSpin.SetValue CrossYOffset&
				ELSEIF (CenterCrossDialog.HorizSpin.GetValue() < -999) THEN
					GenReturn& = MESSAGEBOX("Digite um valor de deslocamento vertical entre 1999 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					CrossYOffset& = -999
					CenterCrossDialog.VertSpin.SetValue CrossYOffset&
				ELSE
					CrossYOffset& = CenterCrossDialog.VertSpin.GetValue()
				ENDIF
		END SELECT
	ENDIF

END FUNCTION

'/////COLUMN DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL UseColumns AS BOOLEAN	' Whether the user wants columns.
GLOBAL NumColumns AS INTEGER	' The desired number of columns.
GLOBAL Gutter AS LONG		' The distance between columns.
GLOBAL GutterUnit AS INTEGER	' The unit used in Gutter.

' Set up defaults.
UseColumns = FALSE
NumColumns% = 2
Gutter& = 6
GutterUnit% = 5 	' 1 cm

BEGIN DIALOG OBJECT ColumnDialog 0, 0, 290, 180, "Assistente Automático de Linhas-Guia", SUB ColumnDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .ColumnImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 10, .Text1, "Você pode dividir sua página em várias colunas."
	TEXT  127, 87, 51, 16, .GutterText, "Distância de separação:"
	GROUPBOX  95, 26, 179, 84, .ColumnGroup, "Você deseja colunas?"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  112, 55, 83, 13, .YesColumnsOption, "Sim"
		OPTIONBUTTON  112, 42, 83, 13, .NoColumnsOption, "Não"
	TEXT  127, 71, 66, 12, .ColumnText, "Número de colunas:"
	SPINCONTROL  195, 70, 27, 13, .ColumnSpin
	TEXT  208, 91, 5, 8, .XText, "x"
	SPINCONTROL  179, 90, 27, 13, .GutterSpin
	DDLISTBOX  214, 90, 47, 139, .GutterListbox
END DIALOG

SUB ColumnDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG

	IF Event% = EVENT_INITIALIZATION THEN 	
		ColumnDialog.GutterListbox.SetArray UnitsArray$
		UpdateColumnDialog
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Mouse click event.
		SELECT CASE ControlID%
			CASE ColumnDialog.NextButton.GetID()
				LastPageX& = ColumnDialog.GetLeftPosition()
				LastPageY& = ColumnDialog.GetTopPosition()
				IF (CalculateWidthAfterMargins() / (NumColumns% - 1)) <= \\
				   (ConvertToDrawUnits(Gutter&, GutterUnit%)) THEN
					MsgReturn& = MESSAGEBOX("Você selecionou um espaço entre colunas " + \\
                                                 "largo demais para o espaço dentro das " + \\
                                                 "margens." + NL2 + \\
                                                 "Reduza o espaço entre as colunas ou " + \\
                                                 "reduza o número de colunas e tente outra vez.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON%)
				ELSE
					ColumnDialog.CloseDialog DIALOG_RETURN_NEXT%
				ENDIF
			CASE ColumnDialog.BackButton.GetID()
				LastPageX& = ColumnDialog.GetLeftPosition()
				LastPageY& = ColumnDialog.GetTopPosition()
				ColumnDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE ColumnDialog.CancelButton.GetID()
				ColumnDialog.CloseDialog DIALOG_RETURN_CANCEL%
			CASE ColumnDialog.YesColumnsOption.GetID()
				UseColumns = TRUE
				UpdateColumnDialog
			CASE ColumnDialog.NoColumnsOption.GetID()
				UseColumns = FALSE
				UpdateColumnDialog
			CASE ColumnDialog.YesColumnsOption.GetID()
				UseColumns = TRUE
				UpdateColumnDialog
			CASE ColumnDialog.GutterListbox.GetID()
				GutterUnit% = ColumnDialog.GutterListbox.GetSelect()
				UpdateColumnDialog			
		END SELECT
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT& THEN
		SELECT CASE ControlID%		
			CASE ColumnDialog.ColumnSpin.GetID()
				IF (ColumnDialog.ColumnSpin.GetValue() < 2) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de colunas entre 2 e 10.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumColumns% = 2
					ColumnDialog.ColumnSpin.SetValue NumColumns%
				ELSEIF (ColumnDialog.ColumnSpin.GetValue() > 10) THEN
					MsgReturn& = MESSAGEBOX("Digite um número de colunas entre 2 e 10.", \\
									    TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					NumColumns% = 10
					ColumnDialog.ColumnSpin.SetValue NumColumns%
				ELSE
					NumColumns% = ColumnDialog.ColumnSpin.GetValue()
				ENDIF
			CASE ColumnDialog.GutterSpin.GetID()
				IF (ColumnDialog.GutterSpin.GetValue() < 0) THEN
					MsgReturn& = MESSAGEBOX("Digite uma distância de separação entre 0 e 999.", \\
					                        TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					Gutter& = 0
					ColumnDialog.GutterSpin.SetValue Gutter&
				ELSEIF (ColumnDialog.GutterSpin.GetValue() > 999) THEN
					MsgReturn& = MESSAGEBOX("Digite uma distância de separação entre 0 e 999.", \\
									    TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					Gutter& = 0
					ColumnDialog.GutterSpin.SetValue Gutter&
				ELSE
					Gutter& = ColumnDialog.GutterSpin.GetValue()
				ENDIF
		END SELECT
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	UpdateColumnDialog (dialog subroutine)
'
'	Action:	Updates all controls on the column dialog to reflect
'			their current values and enabled/disabled state.
'
'	Params:	None.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateColumnDialog()
	
	' Refresh the values in all controls.
	IF UseColumns THEN
		ColumnDialog.YesColumnsOption.SetValue 1
	ELSE
		ColumnDialog.NoColumnsOption.SetValue 1
	ENDIF
	ColumnDialog.ColumnSpin.SetValue NumColumns%
	ColumnDialog.GutterSpin.SetValue Gutter&
	ColumnDialog.GutterListbox.SetSelect GutterUnit%

	' Disable the column-specific controls if the user
	' does not want columns.
	ColumnDialog.ColumnText.Enable UseColumns
	ColumnDialog.ColumnSpin.Enable UseColumns
	ColumnDialog.XText.Enable UseColumns
	ColumnDialog.GutterSpin.Enable UseColumns
	ColumnDialog.GutterListbox.Enable UseColumns
	ColumnDialog.GutterText.Enable UseColumns

END SUB

'********************************************************************
'
' MAIN
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS INTEGER		' The return value of various routines.
DIM CurStep AS INTEGER		' The current dialog box being displayed.
DIM VisitedRemove AS BOOLEAN	' Whether TW_REMOVEDIALOG has been shown.
		
' Retrieve the current directory.
CurDir$ = GetCurrFolder()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	' Make sure CurDir does not end with a backslash, since we
	' will add one.
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF

' Retrieve the size of the current page in CorelDRAW.
ERRNUM = 0
ON ERROR RESUME NEXT
.GetPageSize AvailableX&, AvailableY&
IF ERRNUM <> 0 THEN
	GenReturn% = MESSAGEBOX("Você não possui documentos abertos no CorelDRAW." + NL2 + \\
	                        "O Assistente Automático de Linhas-Guia criará linhas-guia na " + \\
					    "página atual e, " + NL + "portanto, é necessário abrir um documento " + \\
					    "antes de executar o assistente." + NL2 + \\
					    "Crie ou abra um documento e tente outra vez.", \\
					    TITLE_INFOBOX$, \\
					    MB_INFORMATION_ICON)
	ERRNUM = 0
	STOP
ENDIF
ON ERROR GOTO MainErrorHandler
		
' Set up the pages of the wizard.
CONST TW_FINISH%		   = 0
CONST TW_INTRODIALOG%       = 1
CONST TW_REMOVEDIALOG%	   = 2
CONST TW_STYLEDIALOG%	   = 3
CONST TW_CHOICEDIALOG%	   = 4
CONST TW_ANGLEDIALOG%	   = 5
CONST TW_GRIDFREQDIALOG%	   = 6
CONST TW_LOCKDIALOG%	   = 7
CONST TW_MARGINSDIALOG%	   = 8
CONST TW_FINISHDIALOG%	   = 9
CONST TW_CROSSDIALOG%	   = 10
CONST TW_CENTERCROSSDIALOG% = 11
CONST TW_COLUMNSDIALOG%     = 12

' Loop, displaying dialogs in the required order.
CurStep% = TW_INTRODIALOG%
VisitedRemove = FALSE
LoopBegin:
WHILE (CurStep% <> TW_FINISH%)

	SELECT CASE CurStep%
		CASE TW_INTRODIALOG%
			IF (LastPageX& <> -1) THEN
				IntroDialog.Move LastPageX&, LastPageY&
			ENDIF		
			IntroDialog.IntroImage.SetImage CurDir$ + BITMAP_INTRODIALOG$
			IntroDialog.IntroImage.SetStyle STYLE_SUNKEN
			IntroDialog.IntroImage.SetStyle STYLE_IMAGE_CENTERED
			IntroDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(IntroDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_NEXT%
					IF .GetNumberOfGuidelines() > 0 THEN
						CurStep% = TW_REMOVEDIALOG%
					ELSE
						CurStep% = TW_STYLEDIALOG%
					ENDIF
				CASE DIALOG_RETURN_CANCEL%
					STOP										
			END SELECT
			
		CASE TW_FINISHDIALOG%
			FinishDialog.Move LastPageX&, LastPageY&
			FinishDialog.FinishImage.SetImage CurDir$ + BITMAP_FINISHDIALOG$
			FinishDialog.FinishImage.SetStyle STYLE_SUNKEN

			FinishDialog.FinishImage.SetStyle STYLE_IMAGE_CENTERED
			FinishDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(FinishDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					IF UsePreset THEN
						CurStep% = TW_LOCKDIALOG%
					ELSE
						SELECT CASE ChoiceNum%
							CASE GW_TYPE_MARGINS%
								CurStep% = TW_LOCKDIALOG%
							CASE GW_TYPE_GRID%
								CurStep% = TW_LOCKDIALOG%
							CASE GW_TYPE_CROSS%
								CurStep% = TW_LOCKDIALOG%
						END SELECT
					ENDIF
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_FINISH%
				CASE DIALOG_RETURN_CANCEL%
					STOP	
			END SELECT									
			
		CASE TW_REMOVEDIALOG%
			RemoveDialog.Move LastPageX&, LastPageY&		
			VisitedRemove = TRUE
			RemoveDialog.RemoveImage.SetImage CurDir$ + BITMAP_REMOVEDIALOG$
			RemoveDialog.RemoveImage.SetStyle STYLE_SUNKEN
			RemoveDialog.RemoveImage.SetStyle STYLE_IMAGE_CENTERED
			RemoveDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(RemoveDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_INTRODIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_STYLEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE TW_STYLEDIALOG%
			StyleDialog.Move LastPageX&, LastPageY&		
			StyleDialog.StyleImage.SetImage CurDir$ + BITMAP_STYLEDIALOG$
			StyleDialog.StyleImage.SetStyle STYLE_SUNKEN
			StyleDialog.StyleImage.SetStyle STYLE_IMAGE_CENTERED
			StyleDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(StyleDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					IF VisitedRemove THEN
						CurStep% = TW_REMOVEDIALOG%
					ELSE
						CurStep% = TW_INTRODIALOG%
					ENDIF
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_CHOICEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

		CASE TW_CHOICEDIALOG%
			ChoiceDialog.Move LastPageX&, LastPageY&		
			ChoiceDialog.ChoiceImage.SetImage CurDir$ + BITMAP_CHOICEDIALOG$
			ChoiceDialog.ChoiceImage.SetStyle STYLE_SUNKEN
			ChoiceDialog.ChoiceImage.SetStyle STYLE_IMAGE_CENTERED
			ChoiceDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(ChoiceDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_STYLEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					IF UsePreset THEN
						CurStep% = TW_LOCKDIALOG%
					ELSE
						SELECT CASE ChoiceNum%
							CASE GW_TYPE_MARGINS%
								CurStep% = TW_MARGINSDIALOG%
							CASE GW_TYPE_GRID%
								CurStep% = TW_MARGINSDIALOG%
							CASE GW_TYPE_CROSS%
								CurStep% = TW_CROSSDIALOG%
						END SELECT
					ENDIF
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

		CASE TW_CROSSDIALOG%
			CrossDialog.Move LastPageX&, LastPageY&
			CrossDialog.CrossImage.SetImage CurDir$ + BITMAP_CROSSDIALOG$
			CrossDialog.CrossImage.SetStyle STYLE_SUNKEN
			CrossDialog.CrossImage.SetStyle STYLE_IMAGE_CENTERED
			CrossDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(CrossDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_CHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_ANGLEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE TW_CENTERCROSSDIALOG%
			CenterCrossDialog.Move LastPageX&, LastPageY&
			CenterCrossDialog.CenterCrossImage.SetImage CurDir$ + BITMAP_CENTERCROSSDIALOG$
			CenterCrossDialog.CenterCrossImage.SetStyle STYLE_SUNKEN
			CenterCrossDialog.CenterCrossImage.SetStyle STYLE_IMAGE_CENTERED
			CenterCrossDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(CenterCrossDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_ANGLEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_LOCKDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

		CASE TW_ANGLEDIALOG%
			AngleDialog.Move LastPageX&, LastPageY&
			AngleDialog.AngleImage.SetImage CurDir$ + BITMAP_ANGLEDIALOG$
			AngleDialog.AngleImage.SetStyle STYLE_SUNKEN
			AngleDialog.AngleImage.SetStyle STYLE_IMAGE_CENTERED
			AngleDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(AngleDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					SELECT CASE ChoiceNum%
						CASE GW_TYPE_MARGINS%
							
						CASE GW_TYPE_GRID%
							CurStep% = TW_GRIDFREQDIALOG%
						CASE GW_TYPE_CROSS%
							CurStep% = TW_CROSSDIALOG%
					END SELECT
				CASE DIALOG_RETURN_NEXT%
					SELECT CASE ChoiceNum%
						CASE GW_TYPE_MARGINS%
							
						CASE GW_TYPE_GRID%
							CurStep% = TW_LOCKDIALOG%
						CASE GW_TYPE_CROSS%
							CurStep% = TW_CENTERCROSSDIALOG%
					END SELECT
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE TW_GRIDFREQDIALOG%
			GridFreqDialog.Move LastPageX&, LastPageY&
			GridFreqDialog.GridFreqImage.SetImage CurDir$ + BITMAP_GRIDFREQDIALOG$
			GridFreqDialog.GridFreqImage.SetStyle STYLE_SUNKEN
			GridFreqDialog.GridFreqImage.SetStyle STYLE_IMAGE_CENTERED
			GridFreqDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(GridFreqDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_MARGINSDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_LOCKDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
		
		CASE TW_LOCKDIALOG%
			LockDialog.Move LastPageX&, LastPageY&
			LockDialog.LockImage.SetImage CurDir$ + BITMAP_LOCKDIALOG$
			LockDialog.LockImage.SetStyle STYLE_SUNKEN
			LockDialog.LockImage.SetStyle STYLE_IMAGE_CENTERED
			LockDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(LockDialog)
			IF UsePreset THEN
				SELECT CASE GenReturn%
					CASE DIALOG_RETURN_BACK%
						CurStep% = TW_CHOICEDIALOG%
					CASE DIALOG_RETURN_NEXT%
						CurStep% = TW_FINISHDIALOG%
					CASE DIALOG_RETURN_CANCEL%
						STOP
				END SELECT
			ELSE
				SELECT CASE GenReturn%
					CASE DIALOG_RETURN_BACK%
						SELECT CASE ChoiceNum%
							CASE GW_TYPE_MARGINS%
								CurStep% = TW_COLUMNSDIALOG%
							CASE GW_TYPE_GRID%
								CurStep% = TW_GRIDFREQDIALOG%
							CASE GW_TYPE_CROSS%
								CurStep% = TW_CENTERCROSSDIALOG%
						END SELECT
	
					CASE DIALOG_RETURN_NEXT%
						SELECT CASE ChoiceNum%
							CASE GW_TYPE_MARGINS%
								CurStep% = TW_FINISHDIALOG%
							CASE GW_TYPE_GRID%
								CurStep% = TW_FINISHDIALOG%
							CASE GW_TYPE_CROSS%
								CurStep% = TW_FINISHDIALOG%
						END SELECT
					CASE DIALOG_RETURN_CANCEL%
						STOP
				END SELECT
			ENDIF

		CASE TW_MARGINSDIALOG%
			MarginsDialog.Move LastPageX&, LastPageY&
			MarginsDialog.MarginsImage.SetImage CurDir$ + BITMAP_MARGINSDIALOG$
			MarginsDialog.MarginsImage.SetStyle STYLE_SUNKEN
			MarginsDialog.MarginsImage.SetStyle STYLE_IMAGE_CENTERED
			MarginsDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(MarginsDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					SELECT CASE ChoiceNum%
						CASE GW_TYPE_MARGINS%
							CurStep% = TW_CHOICEDIALOG%
						CASE GW_TYPE_GRID%
							CurStep% = TW_CHOICEDIALOG%
						CASE GW_TYPE_CROSS%
						
					END SELECT
				CASE DIALOG_RETURN_NEXT%
					SELECT CASE ChoiceNum%
						CASE GW_TYPE_MARGINS%
							CurStep% = TW_COLUMNSDIALOG%
						CASE GW_TYPE_GRID%
							CurStep% = TW_GRIDFREQDIALOG%
						CASE GW_TYPE_CROSS%
						
					END SELECT
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE TW_COLUMNSDIALOG%
			ColumnDialog.Move LastPageX&, LastPageY&
			ColumnDialog.ColumnImage.SetImage CurDir$ + BITMAP_COLUMNSDIALOG$
			ColumnDialog.ColumnImage.SetStyle STYLE_SUNKEN
			ColumnDialog.ColumnImage.SetStyle STYLE_IMAGE_CENTERED
			ColumnDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(ColumnDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = TW_MARGINSDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = TW_LOCKDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

	END SELECT

WEND

' Apply the guideline effect.
DoGuidelineEffect

VeryEnd:
STOP

MainErrorHandler:
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processamento do assistente." + NL2
	MessageText$ = MessageText$ + "Tente outra vez."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
	ERRNUM = 0
	RESUME AT VeryEnd
	STOP

FUNCTION CalculateDistanceApart( NumGridlines AS LONG, InAvailable AS LONG ) AS STRING

	DIM Distance AS STRING ' An unformatted string representation of the distance.
	DIM DistFmt AS STRING  ' A formatted string representation of the distance.
	DIM Decimal AS STRING  ' The character this locale uses as a decimal place
					   ' separator.

	' There can be no fewer than 2 grid lines.
	IF (NumGridlines& < 2) THEN
		
		CalculateDistanceApart$ = "0"
		
	ELSE
	
		' Determine this locale's decimal character.
		Decimal$ = MID(CSTR(0.1), 2, 1)
	
		Distance$ = CSTR(TOINCHES(InAvailable& / (NumGridlines& - 1)))
		IF TOINCHES(InAvailable& / (NumGridlines& - 1)) < 0.1 THEN
			' This is a simple check to avoid exponential.
			DistFmt$ = "< 0" + Decimal$ + "1"		
		ELSEIF INSTR(Distance$, Decimal$) THEN
			' Pull out everything after the second decimal place
			' for aesthetic reasons.
			DistFmt$ = MID(Distance$, 1, INSTR(Distance$, Decimal$) + 4)
		ELSE
			DistFmt$ = Distance$
		ENDIF
		CalculateDistanceApart$ = DistFmt$
	
	ENDIF	
	EXIT FUNCTION

END FUNCTION

FUNCTION ConvertToDrawUnits( InLength AS LONG, InUnit AS INTEGER ) AS LONG

	DIM ConversionFactor AS SINGLE  ' The conversion factor for units.

	SELECT CASE InUnit%

		CASE GW_UNIT_1_INCH%
			ConversionFactor! = FROMINCHES(1)

		CASE GW_UNIT_01_INCH%
			ConversionFactor! = FROMINCHES(0.1)

		CASE GW_UNIT_136_INCH%
			ConversionFactor! = FROMINCHES(1/36)

		CASE GW_UNIT_0001_INCH%
			ConversionFactor! = FROMINCHES(0.001)

		CASE GW_UNIT_1_CM%
			ConversionFactor! = FROMCENTIMETERS(1)

		CASE GW_UNIT_0001_CM%
			ConversionFactor! = FROMCENTIMETERS(0.001)

		CASE GW_UNIT_1_PT%
			ConversionFactor! = FROMPOINTS(1)

		CASE ELSE
			ConversionFactor! = 0

	END SELECT

	' Actually perform the conversion.
	ConvertToDrawUnits& = InLength& * ConversionFactor!

END FUNCTION

SUB DoGuidelineEffect()

	' Depending on the type of guideline effect we're generating, call an 
	' appropriate subroutine.
	.StartOfRecording	' This 'groups' everything until EndOfRecording
					' as one big undoable block.
	IF UsePreset THEN
		DoPresetEffect
	ELSE
		SELECT CASE ChoiceNum%
			CASE GW_TYPE_MARGINS%
				DoMarginsEffect
			CASE GW_TYPE_GRID%
				DoGridEffect
			CASE GW_TYPE_CROSS%
				DoCrossHairsEffect
		END SELECT
	ENDIF
	.EndOfRecording	' This ends our big undoable block.

END SUB

SUB DoMarginsEffect()

	' The point which will be used to generate the current guideline.
	DIM PointX AS LONG
	DIM PointY AS LONG

	' Coordinates of two corners of the current page.
	DIM PageTopLeftX AS LONG
	DIM PageTopLeftY AS LONG
	DIM PageBottomRightX AS LONG
	DIM PageBottomRightY AS LONG
	
	' The width of each column, taking gutter into account.
	DIM RealColWidth AS LONG
	
	' The width remaining for the columns after we add margins to the page.
	DIM WidthRemaining AS LONG
	
	' The gutter in tenths of a micron.
	DIM GutterDraw AS LONG
	
	DIM Counter AS LONG
	
	IF RemoveExisting THEN
		.RemoveAllGuidelines
	ENDIF
	
	' Calculate the page's corners based on the page size.
	PageTopLeftX& = -1 * (AvailableX& / 2)
	PageTopLeftY& =  1 * (AvailableY& / 2)
	PageBottomRightX& =  1 * (AvailableX& / 2)
	PageBottomRightY& = -1 * (AvailableY& / 2)

	' Draw the basic margins.
	' >> Left
		PointX& = PageTopLeftX& + ConvertToDrawUnits(LeftMargin&, LeftUnit%)
		PointY& = 0
		.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX&, PointY& + 10, LockGuidelines
	' >> Right
		PointX& = PageBottomRightX& - ConvertToDrawUnits(RightMargin&, RightUnit%)
		PointY& = 0
		.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX&, PointY& + 10, LockGuidelines
	' >> Up
		PointX& = 0
		PointY& = PageTopLeftY& - ConvertToDrawUnits(TopMargin&, TopUnit%)
		.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX& + 10, PointY&, LockGuidelines
	' >> Down
		PointX& = 0
		PointY& = PageBottomRightY& + ConvertToDrawUnits(BottomMargin&, BottomUnit%)
		.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX& + 10, PointY&, LockGuidelines

	IF UseColumns THEN

		WidthRemaining& = CalculateWidthAfterMargins()
		GutterDraw& = ConvertToDrawUnits( Gutter&, GutterUnit% )
		RealColWidth& = (WidthRemaining& - (NumColumns% - 1)*GutterDraw&) / NumColumns%

		' Draw each column's guides.
		PointY& = 0
		PointX& = PageTopLeftX& + ConvertToDrawUnits(LeftMargin&, LeftUnit%)
		FOR Counter& = 1 TO (NumColumns% - 1)
		
			' The line before the gutter.
			PointX& = PointX& + RealColWidth&
			.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX&, PointY& + 10, LockGuidelines

			' If there's a gutter, we have one more guideline to add.
			IF (Gutter& <> 0) THEN
				PointX& = PointX& + GutterDraw&
				.CreateGuidelineUsingTwoPoints PointX&, PointY&, PointX&, PointY& + 10, LockGuidelines
			ENDIF
		
		NEXT Counter&
			
	ENDIF

END SUB

SUB DoGridEffect()

	' The points which will be used to generate the current guideline.
	DIM Point1X AS LONG
	DIM Point1Y AS LONG
	DIM Point2X AS LONG
	DIM Point2Y AS LONG

	' Coordinates of two corners of the guideline area (non-rotated).
	DIM TopLeftX AS LONG
	DIM TopLeftY AS LONG
	DIM BottomRightX AS LONG
	DIM BottomRightY AS LONG
	
	' The distance between each grid line.
	DIM HorizSpacing AS LONG
	DIM VertSpacing AS LONG
		
	' A counter for the loops.
	DIM Counter AS LONG

	IF RemoveExisting THEN
		.RemoveAllGuidelines
	ENDIF
	
	' Calculate the guideline area's corners based on the page size and margins.
	TopLeftX& = -1 * (AvailableX& / 2) + ConvertToDrawUnits(LeftMargin&, LeftUnit%)
	TopLeftY& =  1 * (AvailableY& / 2) - ConvertToDrawUnits(TopMargin&, TopUnit%)
	BottomRightX& =  1 * (AvailableX& / 2) - ConvertToDrawUnits(RightMargin&, RightUnit%)
	BottomRightY& = -1 * (AvailableY& / 2) + ConvertToDrawUnits(BottomMargin&, BottomUnit%)

	' Calculate the distances between grid lines.
	IF VGuidelinesOn THEN
		VertSpacing& = (BottomRightX& - TopLeftX&) / (NumVGuidelines& - 1) 
	ENDIF
	IF HGuidelinesOn THEN
		HorizSpacing& = (TopLeftY& - BottomRightY&) / (NumHGuidelines& - 1)
	ENDIF

	' Draw the vertical guidelines.
	Point1X& = TopLeftX&
	Point1Y& = TopLeftY&
	Point2X& = TopLeftX&
	Point2Y& = BottomRightY&
	IF VGuidelinesOn THEN	
		FOR Counter& = 1 TO NumVGuidelines
			ApplyRotation ChosenAngle%, Point1X&, Point1Y&, Point2X&, Point2Y&
			.CreateGuidelineUsingTwoPoints Point1X&, Point1Y&, Point2X&, Point2Y&, LockGuidelines
			
			' Advance the location.
			Point1X& = Point1X& + VertSpacing&
			Point2X& = Point1X&
		NEXT Counter&
	ENDIF
	
	' Draw the horizontal guidelines.
	Point1X& = TopLeftX&
	Point1Y& = BottomRightY&
	Point2X& = BottomRightX&
	Point2Y& = BottomRightY&
	IF HGuidelinesOn THEN
		FOR Counter& = 1 TO NumHGuidelines
			ApplyRotation ChosenAngle%, Point1X&, Point1Y&, Point2X&, Point2Y&
			.CreateGuidelineUsingTwoPoints Point1X&, Point1Y&, Point2X&, Point2Y&, LockGuidelines
			
			' Advance the location.
			Point1Y& = Point1Y& + HorizSpacing&
			Point2Y& = Point1Y&
		NEXT Counter&
	ENDIF

END SUB

SUB DoCrossHairsEffect()

	' The points which will be used to generate the current guideline.
	DIM Point1X AS LONG
	DIM Point1Y AS LONG
	DIM Point2X AS LONG
	DIM Point2Y AS LONG
	
	' The center of the guideline effect (for instance, a triangular set of
	' cross-hairs will have this point right in between all three cross-hairs).
	DIM MiddleX AS LONG
	DIM MiddleY AS LONG
		
	IF RemoveExisting THEN
		.RemoveAllGuidelines
	ENDIF
	
	' Calculate the center of the effect.
	MiddleX& = 0 + ConvertToDrawUnits( CrossXOffset&, CrossXUnit% )
	MiddleY& = 0 + ConvertToDrawUnits( CrossYOffset&, CrossYUnit% )

	SELECT CASE CrossNum%

		CASE GW_CROSS_SINGLE%
			CreateCrossHairAt MiddleX&, MiddleY&

		CASE GW_CROSS_HORIZ_PAIR%
			CreateCrossHairAt CLNG(MiddleX& - (AvailableX&/4)), MiddleY&
			CreateCrossHairAt CLNG(MiddleX& + (AvailableX&/4)), MiddleY&

		CASE GW_CROSS_VERT_PAIR%
			CreateCrossHairAt MiddleX&, CLNG(MiddleY& + (AvailableY&/4))
			CreateCrossHairAt MiddleX&, CLNG(MiddleY& - (AvailableY&/4))

		CASE GW_CROSS_TRIANGLE%
			CreateCrossHairAt MiddleX&, CLNG(MiddleY& + (AvailableY&/4))
			CreateCrossHairAt CLNG(MiddleX& - (AvailableX&/4)), CLNG(MiddleY& - (AvailableY&/4))
			CreateCrossHairAt CLNG(MiddleX& + (AvailableX&/4)), CLNG(MiddleY& - (AvailableY&/4))

		CASE GW_CROSS_SQUARE%
			CreateCrossHairAt CLNG(MiddleX& - (AvailableX&/4)), CLNG(MiddleY& + (AvailableY&/4))
			CreateCrossHairAt CLNG(MiddleX& - (AvailableX&/4)), CLNG(MiddleY& - (AvailableY&/4))
			CreateCrossHairAt CLNG(MiddleX& + (AvailableX&/4)), CLNG(MiddleY& + (AvailableY&/4))
			CreateCrossHairAt CLNG(MiddleX& + (AvailableX&/4)), CLNG(MiddleY& - (AvailableY&/4))

	END SELECT

END SUB

SUB DoPresetEffect()

	SELECT CASE ChoiceNum%
	
		CASE GW_PRESET_ONE_INCH_MARGINS%
			LeftMargin& = 1
			LeftUnit% = GW_UNIT_1_INCH%
			RightMargin& = 1
			RightUnit% = GW_UNIT_1_INCH%
			BottomMargin& = 1
			BottomUnit% = GW_UNIT_1_INCH%
			TopMargin& = 1
			TopUnit% = GW_UNIT_1_INCH%
			UseColumns = FALSE
			DoMarginsEffect
			
		CASE GW_PRESET_THREE_COLUMN_NEWSLETTER%
			LeftMargin& = 5
			LeftUnit% = GW_UNIT_01_INCH%
			RightMargin& = 5
			RightUnit% = GW_UNIT_01_INCH%
			BottomMargin& = 5
			BottomUnit% = GW_UNIT_01_INCH%
			TopMargin& = 5
			TopUnit% = GW_UNIT_01_INCH%
			UseColumns = TRUE
			NumColumns% = 3
			Gutter& = 2
			GutterUnit% = GW_UNIT_01_INCH%
			DoMarginsEffect
			
		CASE GW_PRESET_BASIC_GRID%
			LeftMargin& = 1
			LeftUnit% = GW_UNIT_1_INCH%
			RightMargin& = 1
			RightUnit% = GW_UNIT_1_INCH%
			BottomMargin& = 1
			BottomUnit% = GW_UNIT_1_INCH%
			TopMargin& = 1
			TopUnit% = GW_UNIT_1_INCH%
			VGuidelinesOn = TRUE
			NumVGuidelines& = 11
			HGuidelinesOn = TRUE			
			NumHGuidelines& = 11
			ChosenAngle% = 0
			DoGridEffect
			
		CASE GW_PRESET_UPPER_LEFT_GRID%
			LeftMargin& = 0
			LeftUnit% = GW_UNIT_1_INCH%
			RightMargin& = 1000 * TOINCHES(AvailableX& / 2)
			RightUnit% = GW_UNIT_0001_INCH%
			BottomMargin& = 1000 * TOINCHES(AvailableY& / 2)
			BottomUnit% = GW_UNIT_0001_INCH%
			TopMargin& = 0
			TopUnit% = GW_UNIT_1_INCH%
			VGuidelinesOn = TRUE
			NumVGuidelines& = 6
			HGuidelinesOn = TRUE			
			NumHGuidelines& = 6
			ChosenAngle% = 0
			DoGridEffect
					
		CASE GW_PRESET_SINGLE_CROSS_HAIR%
			CrossNum% = GW_CROSS_SINGLE%
			ChosenAngle% = 0
			NumSpokes% = 2
			CrossXOffset& = 0
			CrossXUnit% = GW_UNIT_1_INCH%
			CrossYOffset& = 0
			CrossYUnit% = GW_UNIT_1_INCH%
			DoCrossHairsEffect
		
		CASE GW_PRESET_DOUBLE_STARBURST%
			CrossNum% = GW_CROSS_HORIZ_PAIR%
			ChosenAngle% = 0
			NumSpokes% = 10
			CrossXOffset& = 0
			CrossXUnit% = GW_UNIT_1_INCH%
			CrossYOffset& = 0
			CrossYUnit% = GW_UNIT_1_INCH%
			DoCrossHairsEffect
				
		CASE GW_PRESET_RIGHT_CORNER_STARBURST%
			CrossNum% = GW_CROSS_SINGLE%
			ChosenAngle% = 0
			NumSpokes% = 15
			CrossXOffset& = 1000 * TOINCHES(AvailableX& / 2)
			CrossXUnit% = GW_UNIT_0001_INCH%
			CrossYOffset& = 1000 * TOINCHES(AvailableY& / 2)
			CrossYUnit% = GW_UNIT_0001_INCH%
			DoCrossHairsEffect
	
	END SELECT

END SUB

SUB CreateCrossHairAt( PointX AS LONG, PointY AS LONG )

	CONST DRAW_DEGREE& = 1000000

	DIM Counter AS LONG		' A counter for the loops.
	DIM CurAngle AS SINGLE	' The current angle in degrees.
	DIM Turn AS SINGLE		' The angle (degrees) between each spoke.

	' Calculate the angle between each spoke.
	Turn! = 360 / (NumSpokes% * 2)	
	
	CurAngle! = ChosenAngle%
	FOR Counter& = 1 TO NumSpokes%
		' Draw this guideline.
		.CreateGuidelineUsingAngle PointX&, PointY&, CLNG(CurAngle!) * DRAW_DEGREE&, LockGuidelines	

		' Increment the angle.
		CurAngle! = CurAngle! + Turn!
	NEXT Counter&

END SUB

SUB ApplyRotation( BYVAL DegreeAngle AS INTEGER, \\
		 	    BYREF Point1X AS LONG, \\
			    BYREF Point1Y AS LONG, \\
			    BYREF Point2X AS LONG, \\
			    BYREF Point2Y AS LONG )

	CONST PI! = 3.141592654

	DIM NewPoint1X AS SINGLE
	DIM NewPoint1Y AS SINGLE
	DIM NewPoint2X AS SINGLE
	DIM NewPoint2Y AS SINGLE

	' Convert DegreeAngle to radians.
	DIM RadianAngle AS SINGLE
	RadianAngle! = (PI!/180) * DegreeAngle%
						
	' Apply the standard mathematical rotation about the origin.
REM 	NewPoint1X! = CSNG(Point1X&) * COS(RadianAngle!) - CSNG(Point1Y&) * SIN(RadianAngle!)
REM 	NewPoint1Y! = CSNG(Point1X&) * SIN(RadianAngle!) + CSNG(Point1Y&) * COS(RadianAngle!)
REM 	NewPoint2X! = CSNG(Point2X&) * COS(RadianAngle!) - CSNG(Point2Y&) * SIN(RadianAngle!)
REM 	NewPoint2Y! = CSNG(Point2X&) * SIN(RadianAngle!) + CSNG(Point2Y&) * COS(RadianAngle!)

	' Update the BYREF parameters.
REM 	Point1X& = CLNG(NewPoint1X!)
REM 	Point1Y& = CLNG(NewPoint1Y!)
REM 	Point2X& = CLNG(NewPoint2X!)
REM 	Point2Y& = CLNG(NewPoint2Y!)
	Point1X& = CLNG(Point1X&)
	Point1Y& = CLNG(Point1Y&)
	Point2X& = CLNG(Point2X&)
	Point2Y& = CLNG(Point2Y&)

END SUB
			    
FUNCTION CalculateWidthAfterMargins() AS LONG

	' Coordinates of two corners of the current page.
	DIM PageTopLeftX AS LONG
	DIM PageBottomRightX AS LONG
	
	' Calculate the page's corners based on the page size.
	PageTopLeftX& = -1 * (AvailableX& / 2)
	PageBottomRightX& =  1 * (AvailableX& / 2)

	CalculateWidthAfterMargins& = (PageBottomRightX& - ConvertToDrawUnits(RightMargin&, RightUnit%)) - \\
				   			(PageTopLeftX& + ConvertToDrawUnits(LeftMargin&, LeftUnit%))

END FUNCTION

FUNCTION CalculateHeightAfterMargins() AS LONG

	' Coordinates of two corners of the current page.
	DIM PageTopLeftY AS LONG
	DIM PageBottomRightY AS LONG
	
	' Calculate the page's corners based on the page size.
	PageTopLeftY& =  1 * (AvailableY& / 2)
	PageBottomRightY& = -1 * (AvailableY& / 2)

	CalculateHeightAfterMargins& = (PageTopLeftY& - ConvertToDrawUnits(TopMargin&, TopUnit%)) - \\
	                               (PageBottomRightY& + ConvertToDrawUnits(BottomMargin&, BottomUnit%))
	
END FUNCTION

FUNCTION CalculateColumnWidth( ) AS LONG

	' The page width left after margins.
	DIM WidthRemaining AS LONG

	' Coordinates of two corners of the current page.
	DIM PageTopLeftX AS LONG
	DIM PageTopLeftY AS LONG
	DIM PageBottomRightX AS LONG
	DIM PageBottomRightY AS LONG
	
	' Calculate the page's corners based on the page size.
	PageTopLeftX& = -1 * (AvailableX& / 2)
	PageTopLeftY& =  1 * (AvailableY& / 2)
	PageBottomRightX& =  1 * (AvailableX& / 2)
	PageBottomRightY& = -1 * (AvailableY& / 2)

	' Calculate the amount of width remaining after margins.
	WidthRemaining& = (PageBottomRightX& - ConvertToDrawUnits(RightMargin&, RightUnit%)) - \\
				   (PageTopLeftX& + ConvertToDrawUnits(LeftMargin&, LeftUnit%))
	
	

END FUNCTION

'********************************************************************
'
'	Name:	GetNumberOfDisplayColors (function)
'
'	Action:	Returns the number of colors the user's screen
'              currently supports.
'
'	Params:	None.  
'
'	Returns:	None.
'
'	Comments:	To avoid overflows, this routine never returns
'              a number of colors greater than 16777216.  If there
'              are more colors, it returns this maximum.
'
'********************************************************************
FUNCTION GetNumberOfDisplayColors( ) AS LONG

	' Constants to send to GetDeviceCaps.
	CONST BITSPIXEL& = 12	' Gets the number of color bits per pixel.
	CONST PLANES& = 14		' Gets the number of color planes.
	
	DIM hDC AS LONG		' A display DC to query.
	DIM NumColors AS SINGLE	' The retrieved number of colors.	
	DIM NumPlanes AS LONG	' The retrieved number of planes.
	DIM NumBitsPixel AS LONG ' The retrieved number of bits per pixel.
	DIM RetVal AS LONG		
	
	' Create a DC, then query it for the number of colors.
	hDC& = CreateDC("DISPLAY", 0, 0, 0)
	NumPlanes& = GetDeviceCaps(hDC, Planes&)
	NumBitsPixel& = GetDeviceCaps(hDC, BitsPixel&)
	NumColors! = CSNG(2) ^ CSNG(CSNG(NumPlanes&) * CSNG(NumBitsPixel&))
	RetVal& = DeleteDC(hDC)
	
	' To avoid overflows with really high color displays, the
	' maximum will be 24 bit color.
	IF NumColors! > 16777216 THEN
		GetNumberOfDisplayColors = 16777216
	ELSE
		GetNumberOfDisplayColors = NumColors!
	ENDIF
	
END FUNCTION

END WITHOBJECT


