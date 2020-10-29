REM Assistente de Efeitos de Néon
REM Aplica um efeito néon interativo.

'********************************************************************
' 
'   Script:	NeonWiz.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to apply a neon effect to the
'                currently selected object or to text that the
'                user enters.
' 
'********************************************************************

#addfol  "..\..\..\Scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE FUNCTION CheckForSelection() AS BOOLEAN
DECLARE FUNCTION ValidateInput(InText AS STRING) AS BOOLEAN
DECLARE FUNCTION CheckSelectedForBlend() AS BOOLEAN
DECLARE SUB CreateText(InText AS STRING, InFontName AS STRING, InPointSize AS INTEGER, \\
                       InStrikeout AS BOOLEAN, InUnderline AS BOOLEAN, \\
                       InBold AS BOOLEAN, InItalic AS BOOLEAN)
DECLARE SUB ApplyEffect(InApplyCenterColor AS BOOLEAN, \\
				    InRed AS INTEGER, InGreen AS INTEGER, InBlue AS INTEGER, \\
				    InWidth AS INTEGER)

DECLARE FUNCTION CreateDC LIB "gdi32" (BYVAL lpDriverName AS STRING, \\
                                       BYVAL lpDeviceName AS LONG, \\
                                       BYVAL lpOutput AS LONG, \\
                                       BYVAL lpInitData AS LONG) AS LONG ALIAS "CreateDCA"
DECLARE FUNCTION GetDeviceCaps LIB "gdi32" (BYVAL hDC AS LONG, \\
                                            BYVAL nIndex AS LONG) AS LONG ALIAS "GetDeviceCaps"
DECLARE FUNCTION DeleteDC LIB "gdi32" (BYVAL hDC AS LONG) AS LONG ALIAS "DeleteDC"
DECLARE FUNCTION GetNumberOfDisplayColors( ) AS LONG

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST TITLE_ERRORBOX$      = "Erro no Assistente de Efeitos de Néon"
GLOBAL CONST TITLE_INFOBOX$       = "Informações do Assistente de Efeitos de Néon"
GLOBAL NL AS STRING	     ' These must be declared as 
GLOBAL NL2 AS STRING     ' variables, not constants, because
NL$ = CHR(10) + CHR(13)	' we cannot assign expressions
NL2$ = NL + NL	     	' to constants.

'Constants for Dialog Return Values
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2
GLOBAL CONST DIALOG_RETURN_NEXT% = 3
GLOBAL CONST DIALOG_RETURN_BACK% = 4

' The bitmap graphic names.
GLOBAL CONST BITMAP_PARAMSDIALOG_ORIGINAL$ = "\NeonOrig.bmp"
GLOBAL CONST BITMAP_PARAMSDIALOG_BLUE$     = "\NeonBlue.bmp"
GLOBAL CONST BITMAP_PARAMSDIALOG_BLACK$    = "\NeonBlak.bmp"
GLOBAL BITMAP_INTRODIALOG AS STRING
GLOBAL BITMAP_COLORDIALOG AS STRING
GLOBAL BITMAP_WIDTHDIALOG AS STRING
GLOBAL BITMAP_TEXTDIALOG AS STRING
GLOBAL BITMAP_PARAMSDIALOG AS STRING
DIM NumColors AS LONG
NumColors& = GetNumberOfDisplayColors()
IF NumColors& <= 256 THEN
	BITMAP_INTRODIALOG$ = "\NeonB16.bmp"
	BITMAP_COLORDIALOG$ = "\NeonB16.bmp"
	BITMAP_WIDTHDIALOG$ = "\NeonB16.bmp"
	BITMAP_TEXTDIALOG$ = "\NeonB16.bmp"
	BITMAP_PARAMSDIALOG$ = "\NeonB16.bmp"
ELSE
	BITMAP_INTRODIALOG$ = "\NeonB.bmp"
	BITMAP_COLORDIALOG$ = "\NeonB.bmp"
	BITMAP_WIDTHDIALOG$ = "\NeonB.bmp"
	BITMAP_TEXTDIALOG$ = "\NeonB.bmp"
	BITMAP_PARAMSDIALOG$ = "\NeonB.bmp"
ENDIF

' The current directory when the script starts.
GLOBAL CurDir AS STRING

' The previous wizard page's position.
GLOBAL LastPageX AS LONG
GLOBAL LastPageY AS LONG
LastPageX& = -1
LastPageY& = -1

'/////INTRODUCTORY DIALOG//////////////////////////////////////////////

BEGIN DIALOG OBJECT IntroDialog 290, 180, "Assistente de Efeitos de Néon", SUB IntroDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Bem-vindo ao Assistente de Efeitos de Néon Corel."
	TEXT  94, 54, 189, 36, .Text2, "Se você selecionou um objeto no CorelDRAW antes de executar este assistente, o efeito de néon será aplicado ao objeto. Caso contrário, você será solicitado a digitar o texto que deseja gerar com um efeito de néon."
	TEXT  93, 96, 187, 18, .Text3, "Para começar a criar o efeito, clique em Avançar."
	IMAGE  10, 10, 75, 130, .IntroImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 28, 189, 21, .Text4, "Este assistente guiará você através das etapas necessárias para criar um vistoso efeito de néon."
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

'/////TEXT ENTRY DIALOG//////////////////////////////////////////////
' The text defaults.
GLOBAL CONST NS_DEFAULT_TEXT_SIZE% = 24
GLOBAL CONST NS_DEFAULT_TEXT_FONT$ = "Arial"
GLOBAL CONST NS_DEFAULT_TEXT_STYLE$ = "Regular"

' Variables needed for the dialog.
GLOBAL EffectText AS STRING	' The text entered by the user.
GLOBAL FontName AS STRING	' The selected font name.
GLOBAL PointSize AS INTEGER	' The selected font size.
GLOBAL Red AS INTEGER		' The selected font's red component.
GLOBAL Green AS INTEGER		' The selected font's green component.
GLOBAL Blue AS INTEGER		' The selected font's blue component.
GLOBAL Weight AS INTEGER		' The selected font's weight.
GLOBAL StrikeOut AS BOOLEAN	' The selected font's strikeout setting.
GLOBAL Underline AS BOOLEAN	' The selected font's underline setting.
GLOBAL Bold AS BOOLEAN		' The selected font's bold setting.
GLOBAL Italic AS BOOLEAN		' The selected font's italic setting.

' Set up defaults.
EffectText$ = ""
FontName$ = NS_DEFAULT_TEXT_FONT$
PointSize% = NS_DEFAULT_TEXT_SIZE%
Red% = 0
Green% = 0
Blue% = 255
Weight% = FONT_NORMAL&
Strikeout = FALSE
Underline = FALSE
Bold = FALSE
Italic = FALSE

BEGIN DIALOG OBJECT GetTextDialog 290, 180, "Assistente de Efeitos de Néon", SUB GetTextDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  94, 10, 181, 24, .Text1, "Digite o texto que deseja exibir em néon e, em seguida, pressione o botão Selecionar Fonte para escolher uma fonte e cor:"
	IMAGE  10, 10, 75, 130, .GetTextImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	PUSHBUTTON  223, 37, 65, 14, .FontButton, "Selecionar Fonte"
	TEXTBOX  95, 37, 123, 14, .EffectTextBox
	TEXT  113, 80, 166, 34, .Text3, "Para fazer isso, pressione Cancelar e, em seguida, selecione um objeto no CorelDRAW e execute esse assistente novamente."
	TEXT  95, 57, 18, 11, .Text2, "Dica:"
	TEXT  113, 57, 166, 19, .Text4, "Você pode aplicar este assistente a um objeto que já exista no desenho, em vez de utilizar um novo texto."
END DIALOG

SUB GetTextDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM FontReturn AS INTEGER	' The return value of the font dialog.

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			GetTextDialog.EffectTextBox.SetText EffectText$

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE GetTextDialog.BackButton.GetID()
					LastPageX& = GetTextDialog.GetLeftPosition()
					LastPageY& = GetTextDialog.GetTopPosition()				
					EffectText$ = GetTextDialog.EffectTextBox.GetText()
					GetTextDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE GetTextDialog.NextButton.GetID()
					LastPageX& = GetTextDialog.GetLeftPosition()
					LastPageY& = GetTextDialog.GetTopPosition()				
					EffectText$ = GetTextDialog.EffectTextBox.GetText()
					IF ValidateInput(EffectText$) THEN
						GetTextDialog.CloseDialog DIALOG_RETURN_NEXT%
					ENDIF
				CASE GetTextDialog.CancelButton.GetID()
					GetTextDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE GetTextDialog.FontButton.GetID()
	
					' Display the font dialog box.
					FontReturn% = GetFont(FontName$, 				\\
									  PointSize%, 				\\
									  Weight%, 				\\
									  Italic, 				\\
									  Underline, 				\\
									  Strikeout, 				\\
									  Red%, 					\\
									  Green%, 					\\
									  Blue%) 
					IF NOT FontReturn% THEN
						' The user pressed cancel.  We should not have
						' to restore the defaults, but if GetFont
						' empties FontName and Style, we must.
						IF (LEN(FontName$) = 0) THEN
							FontName$ = NS_DEFAULT_TEXT_FONT$
						ENDIF
						IF (PointSize% = 0) THEN
							PointSize% = NS_DEFAULT_TEXT_SIZE%
						ENDIF
					ENDIF
					' Convert the weight value to either bold or non-bold.
					IF (Weight% > FONT_NORMAL&) THEN
						Bold = TRUE
					ELSE
						Bold = FALSE
					ENDIF
					
		END SELECT
	END SELECT

END FUNCTION

'/////EFFECTS PARAMETERS DIALOG//////////////////////////////////////

' Variables needed for the dialog.
GLOBAL ApplyCenterColor AS BOOLEAN	' Whether to apply color to the
							' center of the selection.

' Set up defaults.
ApplyCenterColor = TRUE

BEGIN DIALOG OBJECT GetParamsDialog 290, 180, "Assistente de Efeitos de Néon", SUB GetParamsDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  96, 10, 181, 31, .Text1, "Você pode personalizar o efeito de néon, definindo se deverá ser aplicado apenas ao traçado ou ao objeto inteiro."
	IMAGE  10, 10, 75, 130, .GetParamsImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	GROUPBOX  96, 77, 182, 63, .GroupBox2, "Aplicar efeito de néon onde?"
	OPTIONGROUP .OptionGroup1
		OPTIONBUTTON  196, 91, 67, 11, .OptionButtonEntire, "Ao objeto inteiro"
		OPTIONBUTTON  110, 91, 72, 11, .OptionButtonOutline, "Apenas ao traçado"
	IMAGE  107, 105, 75, 26, .ImageBlack
	IMAGE  192, 105, 75, 26, .ImageBlue
	IMAGE  136, 42, 75, 26, .ImageOrig
	TEXT  97, 42, 35, 10, .Text2, "Exemplo:"
END DIALOG

SUB GetParamsDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			IF ApplyCenterColor THEN
				GetParamsDialog.OptionButtonEntire.SetValue TRUE
			ELSE
				GetParamsDialog.OptionButtonOutline.SetValue TRUE
			ENDIF

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE GetParamsDialog.BackButton.GetID()
					LastPageX& = GetParamsDialog.GetLeftPosition()
					LastPageY& = GetParamsDialog.GetTopPosition()				
					IF GetParamsDialog.OptionButtonEntire.GetValue() = 1 THEN
						ApplyCenterColor = TRUE
					ELSE
						ApplyCenterColor = FALSE
					ENDIF
					GetParamsDialog.CloseDialog DIALOG_RETURN_BACK%

				CASE GetParamsDialog.NextButton.GetID()
					LastPageX& = GetParamsDialog.GetLeftPosition()
					LastPageY& = GetParamsDialog.GetTopPosition()				
					IF GetParamsDialog.OptionButtonEntire.GetValue() = 1 THEN
						ApplyCenterColor = TRUE
					ELSE
						ApplyCenterColor = FALSE
					ENDIF
					GetParamsDialog.CloseDialog DIALOG_RETURN_NEXT%

				CASE GetParamsDialog.CancelButton.GetID()
					STOP
	
		END SELECT
	END SELECT

END SUB

'/////WIDTH SELECTION DIALOG/////////////////////////////////////////

' Variables needed for the dialog.
GLOBAL Width AS INTEGER	' The width of the requested neon effect.

' Set up defaults.
Width% = 50

BEGIN DIALOG OBJECT GetWidthDialog 290, 180, "Assistente de Efeitos de Néon", SUB GetWidthDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Terminar"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  94, 9, 181, 23, .Text1, "Você pode utilizar o controle deslizante abaixo para ajustar a largura do efeito de néon."
	IMAGE  10, 10, 75, 130, .GetWidthImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  113, 72, 166, 16, .Text3, "Na maioria dos casos, o default fornecerá um efeito agradável."
	TEXT  95, 72, 18, 11, .Text2, "Dica:"
	HSLIDER 108, 31, 151, 16, .WidthSlider
	TEXT  236, 49, 34, 16, .Text4, "Muito Largo"
	TEXT  104, 49, 25, 11, .Text5, "Estreito"
END DIALOG

SUB GetWidthDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			GetWidthDialog.WidthSlider.SetMinRange 5
			GetWidthDialog.WidthSlider.SetMaxRange 100
			GetWidthDialog.WidthSlider.SetIncrement 1
			GetWidthDialog.WidthSlider.SetValue Width%

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE GetWidthDialog.BackButton.GetID()
					LastPageX& = GetWidthDialog.GetLeftPosition()
					LastPageY& = GetWidthDialog.GetTopPosition()				
					GetWidthDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE GetWidthDialog.NextButton.GetID()
					LastPageX& = GetWidthDialog.GetLeftPosition()
					LastPageY& = GetWidthDialog.GetTopPosition()				
					GetWidthDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE GetWidthDialog.CancelButton.GetID()
					GetWidthDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE GetWidthDialog.WidthSlider.GetID()
					Width% = GetWidthDialog.WidthSlider.GetValue()
		END SELECT
	END SELECT

END FUNCTION

'/////COLOR SELECTION DIALOG/////////////////////////////////////////

BEGIN DIALOG OBJECT GetColorDialog 290, 180, "Assistente de Efeitos de Néon", SUB GetColorDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  94, 9, 181, 23, .Text1, "O efeito de néon será aplicado ao objeto selecionado atualmente no CorelDRAW."
	IMAGE  10, 10, 75, 130, .GetColorImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	PUSHBUTTON  154, 54, 56, 14, .ColorButton, "Selecionar Cor"
	TEXT  113, 85, 166, 24, .Text3, "Caso não deseje aplicar o efeito de néon ao objeto selecionado no CorelDRAW, você poderá aplicá-lo a um texto de sua escolha."
	TEXT  95, 85, 18, 11, .Text2, "Dica:"
	TEXT  113, 113, 166, 24, .Text4, "Para fazer isso, pressione Cancelar, desselecione o objeto atual no CorelDRAW e, em seguida, execute este assistente novamente."
	TEXT  94, 32, 181, 19, .Text5, "Você pode selecionar a cor que desejar para o efeito de néon, pressionando o botão Selecionar Cor abaixo."
END DIALOG

SUB GetColorDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE GetColorDialog.BackButton.GetID()
					LastPageX& = GetColorDialog.GetLeftPosition()
					LastPageY& = GetColorDialog.GetTopPosition()				
					GetColorDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE GetColorDialog.NextButton.GetID()
					LastPageX& = GetColorDialog.GetLeftPosition()
					LastPageY& = GetColorDialog.GetTopPosition()				
					GetColorDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE GetColorDialog.CancelButton.GetID()
					GetColorDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE GetColorDialog.ColorButton.GetID()
					GetColor Red%, Green%, Blue%
		END SELECT
	END SELECT

END FUNCTION

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS INTEGER		' The return value of various routines.
DIM Selection AS BOOLEAN		' Whether any object is selected in draw.
DIM Valid AS BOOLEAN		' Whether the user's input was valid.
DIM CurStep AS INTEGER		' The user's current dialog number.
DIM FirstTime AS BOOLEAN		' Is this the user's first time through?

' Retrieve the directory where the script was started.
CurDir$ = GETCURRFOLDER()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF

' Check to see if CorelDRAW's automation object is available.
ON ERROR RESUME NEXT
WITHOBJECT OBJECT_DRAW
	IF (ERRNUM > 0) THEN
		' Failed to create the automation object.
		ERRNUM = 0
		GenReturn% = MESSAGEBOX( "Não foi possível localizar o CorelDRAW."+NL2+\\
						     "Se este erro continuar, poderá "+ \\
						     "ser necessário reinstalar "+      \\
						     "o CorelDRAW.",				 \\
       					     TITLE_ERRORBOX,			 \\
						     MB_OK_ONLY )
		STOP
	ENDIF

' Set up a general error handler.
ON ERROR GOTO MainErrorHandler

CONST NS_FINISH%		 = 0
CONST NS_INTRODIALOG%     = 1
CONST NS_GETTEXTDIALOG%   = 2
CONST NS_GETPARAMSDIALOG% = 3
CONST NS_GETCOLORDIALOG%  = 4
CONST NS_GETWIDTHDIALOG%  = 5

' Loop, displaying dialogs in the required order.
CurStep% = NS_INTRODIALOG%
FirstTime = TRUE
WHILE (CurStep% <> NS_FINISH%)

	SELECT CASE CurStep%
		CASE NS_INTRODIALOG
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
					IF FirstTime THEN
						' Check whether anything is selected.
						Selection = CheckForSelection() 
					ENDIF
					IF Selection AND FirstTime THEN
					
						IF NOT CheckSelectedForBlend() THEN
					
							GenReturn = MESSAGEBOX( "Impossível adicionar um efeito de néon ao(s) "+\\
											    "objeto(s) selecionado(s) atualmente."+NL2+\\
											    "Este assistente só suporta os "+\\
											    "objetos suportados pela ferramenta " +\\
											    "Mistura. Por exemplo, blocos "  +\\
											    "de parágrafo, texto "            +\\
											    "bitmaps, objetos OLE e "+\\
											    "grupos contendo tais objetos " +\\
											    "não são suportados. Porém, o "   +\\
											    "Texto Artístico é suportado."+NL2+\\
											    "Se você selecionou vários "+   \\
											    "objetos, deverá agrupá-los "+ \\
										         "antes de executar este assistente.",     \\
											    TITLE_ERRORBOX,                    \\
											    MB_OK_ONLY )
							STOP		
					
						ENDIF
						CurStep% = NS_GETCOLORDIALOG%
					
					ELSEIF Selection THEN
						CurStep% = NS_GETCOLORDIALOG%

					ELSE 
						CurStep% = NS_GETTEXTDIALOG%
					ENDIF
					
				CASE ELSE
					STOP
			END SELECT

		CASE NS_GETTEXTDIALOG%
			GetTextDialog.Move LastPageX&, LastPageY&
			FirstTime = FALSE
			GetTextDialog.GetTextImage.SetImage CurDir$ + BITMAP_TEXTDIALOG$
			GetTextDialog.GetTextImage.SetStyle STYLE_SUNKEN
			GetTextDialog.GetTextImage.SetStyle STYLE_IMAGE_CENTERED
			GetTextDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(GetTextDialog)
			SELECT CASE GenReturn%

				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_GETPARAMSDIALOG%					
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_INTRODIALOG%
				CASE ELSE
					STOP

			END SELECT

		CASE NS_GETPARAMSDIALOG%
			GetParamsDialog.Move LastPageX&, LastPageY&
			GetParamsDialog.GetParamsImage.SetImage CurDir$ + BITMAP_PARAMSDIALOG$
			GetParamsDialog.ImageBlack.SetImage CurDir$ + BITMAP_PARAMSDIALOG_BLACK
			GetParamsDialog.ImageOrig.SetImage CurDir$ + BITMAP_PARAMSDIALOG_ORIGINAL
			GetParamsDialog.ImageBlue.SetImage CurDir$ + BITMAP_PARAMSDIALOG_BLUE
			GetParamsDialog.GetParamsImage.SetStyle STYLE_SUNKEN
			GetParamsDialog.GetParamsImage.SetStyle STYLE_IMAGE_CENTERED
			GetParamsDialog.ImageBlack.SetStyle STYLE_IMAGE_CENTERED
			GetParamsDialog.ImageBlack.SetStyle STYLE_SUNKEN
			GetParamsDialog.ImageOrig.SetStyle STYLE_IMAGE_CENTERED
			GetParamsDialog.ImageOrig.SetStyle STYLE_SUNKEN
			GetParamsDialog.ImageBlue.SetStyle STYLE_IMAGE_CENTERED
			GetParamsDialog.ImageBlue.SetStyle STYLE_SUNKEN
			GetParamsDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(GetParamsDialog)
			SELECT CASE GenReturn%

				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_GETWIDTHDIALOG%					
				CASE DIALOG_RETURN_BACK%
					IF Selection THEN
						CurStep% = NS_GETCOLORDIALOG%
					ELSE
						CurStep% = NS_GETTEXTDIALOG%
					ENDIF
				CASE ELSE
					STOP

			END SELECT

		CASE NS_GETCOLORDIALOG%
			GetColorDialog.Move LastPageX&, LastPageY&
			FirstTime = FALSE
			GetColorDialog.GetColorImage.SetImage CurDir$ + BITMAP_COLORDIALOG$
			GetColorDialog.GetColorImage.SetStyle STYLE_SUNKEN
			GetColorDialog.GetColorImage.SetStyle STYLE_IMAGE_CENTERED
			GetColorDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(GetColorDialog)
			SELECT CASE GenReturn%

				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_GETPARAMSDIALOG%				
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_INTRODIALOG%
				CASE ELSE
					STOP

			END SELECT
		
		CASE NS_GETWIDTHDIALOG%
			GetWidthDialog.Move LastPageX&, LastPageY&			
			GetWidthDialog.GetWidthImage.SetImage CurDir$ + BITMAP_WIDTHDIALOG$
			GetWidthDialog.GetWidthImage.SetStyle STYLE_SUNKEN
			GetWidthDialog.GetWidthImage.SetStyle STYLE_IMAGE_CENTERED
			GetWidthDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(GetWidthDialog)
			SELECT CASE GenReturn%

				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_FINISH%				
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_GETPARAMSDIALOG%
				CASE ELSE
					STOP

			END SELECT
	
	END SELECT

WEND

' Create the user's text, if needed.
IF NOT Selection THEN
	CreateText EffectText$, FontName$, PointSize%, Strikeout, Underline, Bold, Italic
ENDIF

' Finish off script execution by applying the neon effect.
ApplyEffect ApplyCenterColor, Red%, Green%, Blue%, Width%
STOP

MainErrorHandler:
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processamento do assistente." + NL2
	MessageText$ = MessageText$ + "Tente outra vez."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
	STOP

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

	ON ERROR RESUME NEXT
	
	ObjType& = .GetObjectType()
	IF (ObjType& <= DRAW_OBJECT_TYPE_RESERVED) OR (ERRNUM > 0) THEN
		ERRNUM = 0
		CheckForSelection = FALSE
	ELSE
		CheckForSelection = TRUE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	CheckSelectedForBlend (function)
'
'	Action:	Checks whether the currently selected object in
'              CorelDRAW can have a blend operation applied to it.
'
'	Params:	None.
'
'	Returns:	FALSE if no object is selected in CorelDRAW.  If an
'              object is selected, returns TRUE if it can have a
'              blend applied to it and FALSE otherwise.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION CheckSelectedForBlend AS BOOLEAN

	DIM ReturnVal AS BOOLEAN	' The return value of this function.

	' Make sure an object was selected.
	IF NOT CheckForSelection() THEN
		CheckSelectedForBlend = False
		EXIT FUNCTION
	ENDIF

	' Prepare for a blend by making a duplicate of the
	' selected object.
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 
	.RecorderSelectObjectByIndex TRUE, 2
	
	' Try to apply a simple blend.  If this fails, then the
	' object is not blendable.
	ON ERROR GOTO ErrorInBlending
	ReturnVal = TRUE
	.RecorderSelectObjectsByIndex TRUE, 1, 2, -1, -1, -1
	.ApplyBlend TRUE, 1, 0, FALSE, 0, FALSE, FALSE, 0, 0, 0, TRUE, TRUE, FALSE, FALSE, 0, 0, 0, 0
	.Undo
	.ResumePainting 
	.EndOfRecording 
	CheckSelectedForBlend = ReturnVal
	EXIT FUNCTION

	ErrorInBlending:
		ERRNUM = 0
		ReturnVal = FALSE
		RESUME NEXT

END FUNCTION

'********************************************************************
'
'	Name:	ValidateInput (function)
'
'	Action:	Makes sure the user entered some text.
'
'	Params:	EffectText
'
'	Returns:	TRUE if EffectText is empty, FALSE otherwise.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ValidateInput(InText AS STRING) AS BOOLEAN

	DIM ReturnVal% AS INTEGER	' The return value of MESSAGEBOX.

	IF (LEN(InText$) <= 0) THEN
		ReturnVal% = MESSAGEBOX("É necessário digitar algum texto ou "+\\
						    "pressionar Cancelar.", TITLE_ERRORBOX$,    \\
                                  MB_OK_ONLY)	
		ValidateInput = FALSE
	ELSE
		ValidateInput = TRUE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	CreateText (subroutine)
'
'	Action:	Creates a text string in CorelDRAW with a set of given
'              parameters related to font, color, etc.
'
'	Params:	InText - The text to create.
'			InFontName - The font to use.
'			InPointSize - The font's point size.
'			InStrikeout - Use strikeout?
'			InUnderline - Use underline?
'			InBold      - Use bold?
'			InItalic    - Use italic?
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB CreateText(InText AS STRING, InFontName AS STRING, InPointSize AS INTEGER, \\
                       InStrikeout AS BOOLEAN, InUnderline AS BOOLEAN, \\
                       InBold AS BOOLEAN, InItalic AS BOOLEAN)

	DIM DrawStyleCode AS INTEGER ' The font style to send to DRAW.
	DIM DrawPointSize AS INTEGER ' The font size to send to DRAW.
	DIM DrawUnderline AS INTEGER ' The underline code to send to DRAW.
	DIM DrawStrikeout AS INTEGER ' The strikeout code to send to DRAW.

	' Create the user's text.
	.CreateArtisticText InText$, 0, 0

	' Determine the settings to send to DRAW.
	IF InBold AND InItalic THEN
		DrawStyleCode% = DRAW_FONT_STYLE_BOLD_ITALIC%
	ELSEIF Bold THEN
		DrawStyleCode% = DRAW_FONT_STYLE_BOLD%
	ELSEIF Italic THEN
		DrawStyleCode% = DRAW_FONT_STYLE_NORMAL_ITALIC%
	ELSE
		DrawStyleCode% = DRAW_FONT_STYLE_NORMAL%
	ENDIF 
	DrawPointSize% = InPointSize% * 10
	IF InUnderline THEN
		DrawUnderline% = DRAW_FONT_UNDERLINE_SINGLE_THICK%
	ELSE
		DrawUnderline% = DRAW_FONT_UNDERLINE_NONE%
	ENDIF
	IF InStrikeout THEN
		DrawStrikeout% = DRAW_FONT_STRIKEOUT_SINGLE_THICK%
	ELSE
		DrawStrikeout% = DRAW_FONT_STRIKEOUT_NONE%
	ENDIF

	' Apply the formatting.
	.SetCharacterAttributes 0, \\
					    30000, \\
					    InFontName$, \\
					    DrawStyleCode%, \\
					    DrawPointSize%, \\
					    DrawUnderline%, \\
					    DRAW_FONT_OVERLINE_NONE%, \\
					    DrawStrikeout%, \\
					    DRAW_FONT_PLACEMENT_NORMAL%, \\
					    0,    \\ 
					    1000, \\ 
					    1000, \\
					    DRAW_FONT_ALIGNMENT_NONE%

END SUB

'********************************************************************
'
'	Name:	ApplyEffect (subroutine)
'
'	Action:	Applies a neon effect to the currently selected
'			object(s) in CorelDRAW.
'
'	Params:	InApplyCenterColor - Should we apply the neon
'							 color to the whole object?
'			InRed - The red component of the desired color.
'			InGreen - The green component of the desired color.
'			InBlue - The blue component of the desired color.
'			InWidth - The width of the neon effect desired.
'
'	Returns:	None.
'
'	Comments:	There must be currently selected object(s) in
'              CorelDRAW when this routine is called, and
'              they must support blending.
'
'********************************************************************
SUB ApplyEffect(InApplyCenterColor AS BOOLEAN, \\
			 InRed AS INTEGER, InGreen AS INTEGER, InBlue AS INTEGER, \\
			 InWidth AS INTEGER)

	CONST NeonF! = 0.4		' The color darkening factor for the neon edges.
	CONST XIdeal& = 991578	' The ideal object width (x-direction).
	CONST YIdeal& = 286869	' The ideal object height (y-direction).
	CONST BigOIdeal& = 84582	' The big outline to use if we have an ideal object.
	CONST LittleOIdeal& = 7112	' The little outline to use if we have an ideal object.

	DIM Proportion AS SINGLE	' The multiplicative factor relative to the ideal.
	DIM ObjX AS LONG		' The width of the current CorelDRAW selection.
	DIM ObjY AS LONG		' The height of the current CorelDRAW selection.
	DIM WidthAdj AS SINGLE	' The multiplicative factor to adjust for the user's
						' width selection.
	DIM XPos AS LONG		' The x-coordinate of the current CorelDRAW selection.
	DIM YPos AS LONG		' The y-coordinate of the current CorelDRAW selection.

	' Calculate the proportionality constant.  This is so that we do
	' not apply a thick outline to very small objects.
	.GetSize ObjX&, ObjY&
	IF ObjX > ObjY THEN
		Proportion! = ObjY& / YIdeal&
	ELSE
		Proportion! = ObjX& / XIdeal&
	ENDIF		

	' Calculate the width adjustment based on the user's selection.
	WidthAdj! = (InWidth% * 2) /100

	' Apply the neon effect.
 	.StartOfRecording 
 	.SuppressPainting 
 	.RecorderStorePreselectedObjects FALSE
 	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline CLNG(BigOIdeal& * Proportion! * WidthAdj!), 1, 1, 1, 100, -900, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor DRAW_COLORMODEL_RGB&, CINT(InRed% * NeonF!), \\
				  CINT(InGreen%*NeonF!), CINT(InBlue%*NeonF!), 0
	.RecorderSelectObjectByIndex TRUE, 1
	.GetPosition XPos&, YPos&
	.DuplicateObject 
	.SetPosition XPos&, YPos&
 	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 2
 	.ApplyOutline CLNG(LittleOIdeal& * Proportion! * WidthAdj!), 1, 1, 1, 100, -900, 0, -1, -1, FALSE, 2, 0, TRUE
 	.SetOutlineColor DRAW_COLORMODEL_RGB&, InRed%, InGreen%, InBlue%, 0
	.RecorderSelectObjectsByIndex TRUE, 1, 2, -1, -1, -1
 	.ApplyBlend TRUE, 20, 0, FALSE, 0, FALSE, FALSE, 0, 0, 0
 	.ResumePainting 
	.EndOfRecording 

	' If we are neon-ing the whole object, apply a uniform fill in the neon color.
	IF InApplyCenterColor THEN
		.ApplyUniformFillColor DRAW_COLORMODEL_RGB&, InRed%, InGreen%, InBlue%, 0
	ENDIF

END SUB

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
