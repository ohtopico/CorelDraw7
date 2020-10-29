REM Assistente de Calendário
REM Cria um calendário

'********************************************************************
' 
'   Script:	Calendar.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to create calendars.
'                Has a wizard-style interface allowing the
'                user to customize the calendar.
' 
'********************************************************************

#addfol  "..\..\..\scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE SUB CreateText ( InText AS STRING, \\
		    		     InFontName AS STRING, \\
					InFontSize AS LONG, \\
		        		InBold AS BOOLEAN, \\
		        		InItalic AS BOOLEAN, \\
		        		InStrikeout AS BOOLEAN, \\
					InUnderline AS BOOLEAN, \\
			   		InRed AS INTEGER, \\
			   		InGreen AS INTEGER, \\
			   		InBlue AS INTEGER )
DECLARE FUNCTION GetWeekday( Wkd AS DATE ) AS INTEGER
DECLARE FUNCTION GetNumRows( InMonthNum AS INTEGER, InYear AS INTEGER ) \\
                         AS INTEGER
DECLARE FUNCTION GetNumDays( InMonthNum AS INTEGER, InYear AS INTEGER ) \\
                         AS INTEGER
DECLARE FUNCTION FileExists( InFileName AS STRING ) AS BOOLEAN
DECLARE SUB DoGraphics( 	InUsePicture AS BOOLEAN,       \\
                		InUseBorder AS BOOLEAN,        \\
                		InPictureFile AS STRING,       \\
			 		InBorderFile AS STRING,        \\
			 		BYREF InTopLeftX AS LONG,      \\
			 		BYREF InTopLeftY AS LONG,      \\
			 		BYREF InBottomRightX AS LONG,  \\
			 		BYREF InBottomRightY AS LONG )
DECLARE FUNCTION Min( Val1 AS LONG, Val2 AS LONG ) AS LONG
DECLARE SUB AddMargins( BYREF InTopLeftX AS LONG, \\
                        BYREF InTopLeftY AS LONG, \\
                        BYREF InBottomRightX AS LONG, \\
                        BYREF InBottomRightY AS LONG )
DECLARE FUNCTION CalcHowMany( InHowMany AS INTEGER, \\
                              InMonth AS INTEGER, \\
                              InYear AS INTEGER ) AS LONG

DECLARE FUNCTION CreateDC LIB "gdi32" (BYVAL lpDriverName AS STRING, \\
                                       BYVAL lpDeviceName AS LONG, \\
                                       BYVAL lpOutput AS LONG, \\
                                       BYVAL lpInitData AS LONG) AS LONG ALIAS "CreateDCA"
DECLARE FUNCTION GetDeviceCaps LIB "gdi32" (BYVAL hDC AS LONG, \\
                                            BYVAL nIndex AS LONG) AS LONG ALIAS "GetDeviceCaps"
DECLARE FUNCTION DeleteDC LIB "gdi32" (BYVAL hDC AS LONG) AS LONG ALIAS "DeleteDC"
DECLARE FUNCTION GetNumberOfDisplayColors( ) AS LONG

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST TITLE_ERRORBOX$      = "Erro no Assistente de Calendário"
GLOBAL CONST TITLE_INFOBOX$       = "Informações do Assistente de Calendário"
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
GLOBAL BITMAP_INTRODIALOG AS STRING
GLOBAL CONST BITMAP_PREVIEW_SIMPLE AS STRING   = "\Cal1.bmp"
GLOBAL CONST BITMAP_PREVIEW_LEFT AS STRING    = "\Cal2.bmp"
GLOBAL CONST BITMAP_PREVIEW_RIGHT AS STRING    = "\Cal3.bmp"
DIM NumColors AS LONG
NumColors& = GetNumberOfDisplayColors()
IF NumColors& <= 256 THEN
	BITMAP_INTRODIALOG$ = "\CalB16.bmp"
ELSE
	BITMAP_INTRODIALOG$ = "\CalB.bmp"
ENDIF

' The previous wizard page's position.
GLOBAL LastPageX AS LONG
GLOBAL LastPageY AS LONG
LastPageX& = -1
LastPageY& = -1

' The current directory when the script was started.
GLOBAL CurDir AS STRING

' The return value of various functions.
GLOBAL GenReturn& AS LONG

' Check to see if CorelDRAW's automation object is available.
ON ERROR RESUME NEXT
WITHOBJECT OBJECT_DRAW
	IF (ERRNUM > 0) THEN
		' Failed to create the automation object.
		ERRNUM = 0
		GenReturn& = MESSAGEBOX( "Impossível localizar o CorelDRAW."+NL2+\\
				 		     "Se este erro persistir, poderá "+ \\
						     "ser necessário reinstalar "+      \\
						     "o CorelDRAW.",				  \\
       					     TITLE_ERRORBOX,			  \\
						     MB_STOP_ICON )
		STOP
	ENDIF
ON ERROR EXIT

'/////INTRODUCTORY DIALOG//////////////////////////////////////////////

BEGIN DIALOG OBJECT IntroDialog 290, 180, "Assistente de Calendário", SUB IntroDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Bem-vindo ao Assistente de Calendário Corel."
	TEXT  93, 56, 187, 18, .Text3, "Para começar a criar o calendário, clique em Avançar."
	IMAGE  10, 10, 75, 130, .IntroImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 30, 189, 21, .Text4, "Este assistente guiará você pelas etapas necessárias para criar um calendário atraente."
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

'/////PAGE SIZE DIALOG//////////////////////////////////////////////

' Arrays of page sizes and dimensions.
GLOBAL ArrayPageNames$(6) : GLOBAL ArrayPageDim!(6, 2)
' Letter size
	ArrayPageNames$(1) 	= "Carta - 21,59 x 27,94 cm"
	ArrayPageDim!(1, 1)	= 8.50
	ArrayPageDim!(1, 2)	= 11.0
' Legal size
	ArrayPageNames$(2)	= "Ofício - 21,59 x 35,56 cm"
	ArrayPageDim!(2, 1) = 8.50
	ArrayPageDim!(2, 2) = 14.0
' Executive size
	ArrayPageNames$(3)	= "Executivo - 18,14 x 26,67 cm"
	ArrayPageDim!(3, 1)	= 7.25
	ArrayPageDim!(3, 2)	= 10.50
' A4 size
	ArrayPageNames$(4)	= "A4 - 21 x 29,7 cm"
	ArrayPageDim!(4, 1) = 8.26
	ArrayPageDim!(4, 2) = 11.69
' A5 size
	ArrayPageNames$(5)	= "A5 - 14,8 x 21 cm"
	ArrayPageDim!(5, 1)	= 5.83
	ArrayPageDim!(5, 2)	= 8.26
' B5 size
	ArrayPageNames$(6)	= "B5 - 18,2 x 25,7 cm"
	ArrayPageDim!(6, 1)	= 7.17
	ArrayPageDim!(6, 2) = 10.13

' Variables needed for the dialog.
GLOBAL PageSize AS INTEGER	' The user's selected page size.

' Set up the page size default.
PageSize% = 1

BEGIN DIALOG OBJECT SizeDialog 0, 0, 290, 180, "Assistente de Calendário", SUB SizeDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	LISTBOX  94, 23, 187, 81, .SizesList
	TEXT  94, 10, 186, 10, .Text1, "Selecione um tamanho de papel para o calendário."
	IMAGE  10, 10, 75, 130, .SizeImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
END DIALOG

SUB SizeDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			' Set up the page sizes list box.
			SizeDialog.SizesList.SetArray ArrayPageNames$		
			SizeDialog.SizesList.SetSelect PageSize%

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE SizeDialog.BackButton.GetID()
					LastPageX& = SizeDialog.GetLeftPosition()
					LastPageY& = SizeDialog.GetTopPosition()
					SizeDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE SizeDialog.NextButton.GetID()
					LastPageX& = SizeDialog.GetLeftPosition()
					LastPageY& = SizeDialog.GetTopPosition()	
					SizeDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE SizeDialog.CancelButton.GetID()
					SizeDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE SizeDialog.SizesList.GetID()
					PageSize% = SizeDialog.SizesList.GetSelect()					
			END SELECT
	END SELECT	

END SUB

'/////ORIENTATION DIALOG/////////////////////////////////////////

' Variables needed for the dialog.
GLOBAL Orient AS INTEGER	' The user's selected page orientation.

' Constants for the orientation.
GLOBAL CONST CAL_ORIENT_PORTRAIT% = 1
GLOBAL CONST CAL_ORIENT_LANDSCAPE% = 2

' Set up the orientation default.
Orient% = CAL_ORIENT_PORTRAIT%

BEGIN DIALOG OBJECT OrientDialog 0, 0, 290, 180, "Assistente de Calendário", SUB OrientDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  94, 10, 186, 20, .Text1, "Selecione uma orientação de página."
	IMAGE  10, 10, 75, 130, .OrientImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	OPTIONGROUP .OrientGroup
		OPTIONBUTTON  102, 32, 104, 11, .Portrait, "Vertical"
		OPTIONBUTTON  102, 46, 82, 12, .Landscape, "Horizontal"
END DIALOG

SUB OrientDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			' Set up the page orientation option buttons.
			IF Orient% = CAL_ORIENT_PORTRAIT% THEN
				OrientDialog.Portrait.SetValue TRUE
			ELSE
				OrientDialog.Landscape.SetValue TRUE
			ENDIF

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE OrientDialog.BackButton.GetID()
					LastPageX& = OrientDialog.GetLeftPosition()
					LastPageY& = OrientDialog.GetTopPosition()
					OrientDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE OrientDialog.NextButton.GetID()
					LastPageX& = OrientDialog.GetLeftPosition()
					LastPageY& = OrientDialog.GetTopPosition()		
					OrientDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE OrientDialog.CancelButton.GetID()
					OrientDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE OrientDialog.Portrait.GetID()
					Orient% = CAL_ORIENT_PORTRAIT%
				CASE OrientDialog.Landscape.GetID()
					Orient% = CAL_ORIENT_LANDSCAPE%					
			END SELECT
	END SELECT	

END SUB

'/////STYLE CHOICE DIALOG//////////////////////////////////////////////

' The calendar styles.
GLOBAL CONST CAL_STYLE_SIMPLE%   = 1
GLOBAL CONST CAL_STYLE_LEFT%     = 2
GLOBAL CONST CAL_STYLE_RIGHT%    = 3
GLOBAL CalChoices$(3)
CalChoices$(CAL_STYLE_SIMPLE%) = "Padrão"
CalChoices$(CAL_STYLE_LEFT%) = "Título no Lado Esquerdo"
CalChoices$(CAL_STYLE_RIGHT%) = "Título no Lado Direito"

' The default calendar style.
GLOBAL CONST CAL_DEFAULT_STYLE% = CAL_STYLE_SIMPLE%

' Variables needed for the dialog.
GLOBAL CalStyle AS INTEGER	' The selected calendar style.

' Set up defaults.
CalStyle = CAL_DEFAULT_STYLE%

BEGIN DIALOG OBJECT StyleDialog 0, 0, 290, 180, "Assistente de Calendário", SUB StyleDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .StyleImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	DDLISTBOX  113, 32, 131, 144, .StyleList
	IMAGE  135, 50, 89, 90, .PreviewImage
	TEXT  94, 10, 181, 17, .Text2, "Selecione um estilo para o calendário.  O estilo selecionado será visualizado no quadro abaixo."
END DIALOG

SUB StyleDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			StyleDialog.StyleList.SetArray CalChoices$
			StyleDialog.StyleList.SetSelect CalStyle%
			
			' Update the preview image.
			SELECT CASE CalStyle%
				CASE CAL_STYLE_SIMPLE%
					StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_SIMPLE$
				CASE CAL_STYLE_LEFT%
					StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_LEFT$
				CASE CAL_STYLE_RIGHT%
					StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_RIGHT$
			END SELECT
			StyleDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE StyleDialog.BackButton.GetID()
					LastPageX& = StyleDialog.GetLeftPosition()
					LastPageY& = StyleDialog.GetTopPosition()
					StyleDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE StyleDialog.NextButton.GetID()
					LastPageX& = StyleDialog.GetLeftPosition()
					LastPageY& = StyleDialog.GetTopPosition()
					StyleDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE StyleDialog.CancelButton.GetID()
					StyleDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE StyleDialog.StyleList.GetID()
					CalStyle% = StyleDialog.StyleList.GetSelect()
					
					' Update the preview image.
					SELECT CASE CalStyle%
						CASE CAL_STYLE_SIMPLE%
							StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_SIMPLE$
						CASE CAL_STYLE_LEFT%
							StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_LEFT$
						CASE CAL_STYLE_RIGHT%
							StyleDialog.PreviewImage.SetImage CurDir$ + BITMAP_PREVIEW_RIGHT$
					END SELECT

		END SELECT
	END SELECT

END FUNCTION

'/////FONT CHOICE DIALOG//////////////////////////////////////////////

' The text defaults.
GLOBAL CONST CAL_DEFAULT_TEXT_SIZE% = 24
GLOBAL CONST CAL_DEFAULT_TEXT_FONT$ = "Arial"
GLOBAL CONST CAL_DEFAULT_TEXT_STYLE$ = "Standard"

' Variables needed for the dialog.
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
FontName$ = CAL_DEFAULT_TEXT_FONT$
PointSize% = CAL_DEFAULT_TEXT_SIZE%
Red% = 0
Green% = 0
Blue% = 0
Weight% = FONT_NORMAL&
Strikeout = FALSE
Underline = FALSE
Bold = FALSE
Italic = FALSE

BEGIN DIALOG OBJECT FontDialog 0, 0, 290, 180, "Assistente de Calendário", SUB FontDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  96, 57, 116, 19, .Text1, "Dica:"
	IMAGE  10, 10, 75, 130, .FontImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	PUSHBUTTON  137, 36, 66, 14, .FontButton, "Selecionar Fonte"
	TEXT  94, 10, 181, 24, .Text2, "Você pode criar um layout especial para o calendário, selecionando uma fonte e uma cor ao pressionar o botão abaixo."
	TEXT  122, 57, 162, 39, .Text4, "Não se preocupe em escolher o tamanho da fonte.  O Assistente de Calendário selecionará automaticamente os tamanhos de fonte necessários."
END DIALOG

SUB FontDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM FontReturn AS INTEGER	' The return value of the font dialog.

	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			' Nothing to initialize.

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE FontDialog.BackButton.GetID()
					LastPageX& = FontDialog.GetLeftPosition()
					LastPageY& = FontDialog.GetTopPosition()
					FontDialog.CloseDialog DIALOG_RETURN_BACK%
				CASE FontDialog.NextButton.GetID()
					LastPageX& = FontDialog.GetLeftPosition()
					LastPageY& = FontDialog.GetTopPosition()
					FontDialog.CloseDialog DIALOG_RETURN_NEXT%
				CASE FontDialog.CancelButton.GetID()
					FontDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE FontDialog.FontButton.GetID()
	
					' Display the font dialog box.
					FontReturn% = GetFont(FontName$, 				\\
									  PointSize%, 				\\
									  Weight%, 				\\
									  Italic, 				\\
									  Underline, 				\\
									  Strikeout, 				\\
									  Red, 					\\
									  Green, 					\\
									  Blue) 
					IF NOT FontReturn% THEN
						' The user pressed cancel.  We should not have
						' to restore the defaults, but if GetFont
						' empties FontName and Style, we must.
						IF (LEN(FontName$) = 0) THEN
							FontName$ = CAL_DEFAULT_TEXT_FONT$
						ENDIF
						IF (PointSize% = 0) THEN
							PointSize% = CAL_DEFAULT_TEXT_SIZE%
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

'/////DATE CHOICE DIALOG///////////////////////////////////////////

' Set the months of the year.
GLOBAL Months$(12)
Months$(1) =  FORMATDATE(CDAT("01-01-1996"), "MMMM")
Months$(2) =  FORMATDATE(CDAT("01-02-1996"), "MMMM")
Months$(3) =  FORMATDATE(CDAT("01-03-1996"), "MMMM")
Months$(4) =  FORMATDATE(CDAT("01-04-1996"), "MMMM")
Months$(5) =  FORMATDATE(CDAT("01-05-1996"), "MMMM")
Months$(6) =  FORMATDATE(CDAT("01-06-1996"), "MMMM")
Months$(7) =  FORMATDATE(CDAT("01-07-1996"), "MMMM")
Months$(8) =  FORMATDATE(CDAT("01-08-1996"), "MMMM")
Months$(9) =  FORMATDATE(CDAT("01-09-1996"), "MMMM")
Months$(10) = FORMATDATE(CDAT("01-10-1996"), "MMMM")
Months$(11) = FORMATDATE(CDAT("01-11-1996"), "MMMM")
Months$(12) = FORMATDATE(CDAT("01-12-1996"), "MMMM")

' Set the days of the week.
GLOBAL Weekdays$(7)
Weekdays$(1) = FORMATDATE(CDAT("1996-01-07"), "dddd")
Weekdays$(2) = FORMATDATE(CDAT("1996-01-01"), "dddd")
Weekdays$(3) = FORMATDATE(CDAT("1996-01-02"), "dddd")
Weekdays$(4) = FORMATDATE(CDAT("1996-01-03"), "dddd")
Weekdays$(5) = FORMATDATE(CDAT("1996-01-04"), "dddd")
Weekdays$(6) = FORMATDATE(CDAT("1996-01-05"), "dddd")
Weekdays$(7) = FORMATDATE(CDAT("1996-01-06"), "dddd")

' Abbreviated days of the week.
GLOBAL WeekdaysShort$(7)
WeekdaysShort$(1) = FORMATDATE(CDAT("1996-01-07"), "ddd")
WeekdaysShort$(2) = FORMATDATE(CDAT("1996-01-01"), "ddd")
WeekdaysShort$(3) = FORMATDATE(CDAT("1996-01-02"), "ddd")
WeekdaysShort$(4) = FORMATDATE(CDAT("1996-01-03"), "ddd")
WeekdaysShort$(5) = FORMATDATE(CDAT("1996-01-04"), "ddd")
WeekdaysShort$(6) = FORMATDATE(CDAT("1996-01-05"), "ddd")
WeekdaysShort$(7) = FORMATDATE(CDAT("1996-01-06"), "ddd")

' Variables needed by the dialog.
GLOBAL Year AS INTEGER	 ' The year of the first calendar to generate.
GLOBAL Month AS INTEGER	 ' The month of the first calendar to generate.
GLOBAL HowMany AS INTEGER ' How many months to generate.

' Set up defaults.
Year% = 1996
Month% = 9 
HowMany% = 1

BEGIN DIALOG OBJECT DateDialog 0, 0, 290, 180, "Assistente de Calendário", SUB DateDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Terminar"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .DateImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  106, 37, 24, 10, .Text2, "Mês"
	DDLISTBOX  133, 35, 55, 168, .MonthList
	TEXT  94, 10, 181, 17, .Text5, "Selecione o primeiro mês e ano para os quais deseja criar um calendário."
	TEXT  201, 37, 17, 13, .Text4, "Ano"
	TEXT  94, 58, 181, 27, .Text9, "Digite quantos meses de calendário deseja gerar.  Para criar um calendário de ano inteiro, digite 12."
	TEXT  132, 91, 59, 12, .Text6, "Número de meses"
	SPINCONTROL  222, 35, 35, 13, .YearSpin
	SPINCONTROL  196, 88, 33, 13, .RepeatSpin
END DIALOG

SUB DateDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MBReturn AS INTEGER	' The return value of the MESSAGEBOX function.
	DIM TodayDate AS DATE	' Today's date (used to set the month and year).
	DIM TodayYear AS LONG	' The current year.
	DIM TodayMonth AS LONG	' The current month.
	DIM TodayDay AS LONG	' The current day.
	DIM TodayDW AS LONG		' Today's day of the week.
	
	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			' Use the current month and year as defaults.
			TodayDate = GETCURRDATE()
			GETDATEINFO TodayDate, TodayYear&, TodayMonth&, TodayDay&, TodayDW&
			Year% = TodayYear&
			Month% = TodayMonth&
		
			DateDialog.YearSpin.SetValue Year%
			DateDialog.RepeatSpin.SetValue HowMany%
			DateDialog.MonthList.SetArray Months$
			DateDialog.MonthList.SetSelect Month%
			
		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE DateDialog.BackButton.GetID()
					LastPageX& = DateDialog.GetLeftPosition()
					LastPageY& = DateDialog.GetTopPosition()
					IF (DateDialog.YearSpin.GetValue() < 1900) OR \\
					   (DateDialog.YearSpin.GetValue() > 2300) THEN
						MBReturn = MESSAGEBOX("Digite um ano entre " + \\
						                      "1900 e 2300 inclusive.",      \\
						                      TITLE_INFOBOX,                  \\
						                      MB_INFORMATION_ICON)
						DateDialog.YearSpin.SetValue Year%	
					ELSEIF (DateDialog.RepeatSpin.GetValue() < 1) OR \\
					       (DateDialog.RepeatSpin.GetValue() > 999) THEN
					     MBReturn = MESSAGEBOX("Digite um número de " + \\
					                           "meses entre 1 e 999 inclusive.",\\
					                           TITLE_INFOBOX, MB_INFORMATION_ICON)
						DateDialog.RepeatSpin.SetValue HowMany%
					ELSE
						Year% = DateDialog.YearSpin.GetValue()
						HowMany% = DateDialog.RepeatSpin.GetValue()
						DateDialog.CloseDialog DIALOG_RETURN_BACK%
					ENDIF
				CASE DateDialog.NextButton.GetID()
					LastPageX& = DateDialog.GetLeftPosition()
					LastPageY& = DateDialog.GetTopPosition()
					IF (DateDialog.YearSpin.GetValue() < 1900) OR \\
					   (DateDialog.YearSpin.GetValue() > 2300) THEN
						MBReturn = MESSAGEBOX("Digite um ano entre " + \\
						                      "1900 e 2300 inclusive.",      \\
						                      TITLE_INFOBOX,                   \\
						                      MB_INFORMATION_ICON)
						DateDialog.YearSpin.SetValue Year%	
					ELSEIF (DateDialog.RepeatSpin.GetValue() < 1) OR \\
					       (DateDialog.RepeatSpin.GetValue() > 18) THEN
					     MBReturn = MESSAGEBOX("Digite um número de " + \\
					                           "meses entre 1 e 18 inclusive.",\\
					                           TITLE_INFOBOX, MB_INFORMATION_ICON)
						DateDialog.RepeatSpin.SetValue HowMany%
					ELSE
						Year% = DateDialog.YearSpin.GetValue()
						HowMany% = DateDialog.RepeatSpin.GetValue()
						DateDialog.CloseDialog DIALOG_RETURN_NEXT%
					ENDIF
				CASE DateDialog.CancelButton.GetID()
					DateDialog.CloseDialog DIALOG_RETURN_CANCEL%
				CASE DateDialog.MonthList.GetID()
					Month% = DateDialog.MonthList.GetSelect()
			END SELECT
			
		CASE EVENT_CHANGE_IN_CONTENT&
			SELECT CASE ControlID%
				CASE DateDialog.YearSpin.GetID()
					IF (DateDialog.YearSpin.GetValue() < 1900) THEN
						MBReturn = MESSAGEBOX("Digite um ano entre " + \\
						                      "1900 e 2300 inclusive.",      \\
						                      TITLE_INFOBOX,                   \\
						                      MB_INFORMATION_ICON)
						DateDialog.YearSpin.SetValue 1900
					ELSEIF (DateDialog.YearSpin.GetValue() > 2300) THEN
						MBReturn = MESSAGEBOX("Digite um ano entre " + \\
						                      "1900 e 2300 inclusive.",      \\
						                      TITLE_INFOBOX,                   \\
						                      MB_INFORMATION_ICON)
						DateDialog.YearSpin.SetValue 2300
					ENDIF
				CASE DateDialog.RepeatSpin.GetID()
					IF (DateDialog.RepeatSpin.GetValue() < 1) THEN
					     MBReturn = MESSAGEBOX("Digite um número de " + \\
					                           "meses entre 1 e 18 inclusive.",\\
					                           TITLE_INFOBOX, MB_INFORMATION_ICON)
						DateDialog.RepeatSpin.SetValue 1
					ELSEIF (DateDialog.RepeatSpin.GetValue() > 18) THEN
					     MBReturn = MESSAGEBOX("Digite um número de " + \\
					                           "meses entre 1 e 18 inclusive.",\\
					                           TITLE_INFOBOX, MB_INFORMATION_ICON)
						DateDialog.RepeatSpin.SetValue 18
					ENDIF
				
			END SELECT
			
	END SELECT

END FUNCTION

'/////PICTURE AND BORDER CHOICE DIALOG///////////////////////////////

' Variables needed by the dialog.
GLOBAL UsePicture AS BOOLEAN	' Add a picture to the calendar?
GLOBAL UseBorder AS BOOLEAN   ' Add a border to the calendar?
GLOBAL PictureFile AS STRING  ' Name and path of the picture.
GLOBAL BorderFile AS STRING   ' Name and path of the border.
GLOBAL TmpFileName AS STRING  ' A temporary file name.

' Set up defaults.
UsePicture = FALSE
UseBorder  = FALSE
PictureFile$ = ""
BorderFile$ = ""

BEGIN DIALOG OBJECT PicDialog 0, 0, 290, 180, "Assistente de Calendário", SUB PicDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .PicImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  94, 110, 20, 11, .Text9, "Dica:"
	TEXT  94, 10, 181, 17, .Text5, "Você quer adicionar uma foto ao calendário?"
	CHECKBOX  95, 23, 100, 12, .PictureCheck, "Sim. O nome do arquivo é:"
	TEXTBOX  95, 35, 84, 13, .PicTextBox
	PUSHBUTTON  182, 35, 79, 13, .PictureButton, "Selecionar Arquivo"
	CHECKBOX  95, 82, 100, 12, .BorderCheck, "Sim. O nome do arquivo é:"
	TEXTBOX  95, 94, 84, 13, .BorderTextBox
	PUSHBUTTON  182, 94, 79, 13, .BorderButton, "Selecionar Arquivo"
	TEXT  94, 55, 181, 24, .Text6, "Você pode também adicionar uma borda ao calendário.  Para obter melhores resultados, selecione uma borda no diretório de clipart Borda/Molduras."
	TEXT  122, 110, 157, 35, .Text8, "Seu calendário ficará mais bonito se você selecionar pelo menos uma das opções acima.  Em caso contrário, pode não haver espaço suficiente na página para o calendário."
END DIALOG

SUB PicDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MBReturn AS INTEGER	' The return value of the MESSAGEBOX function.
	DIM NoGo AS BOOLEAN		' Whether the user is allowed to move to
						' another pane of the wizard.
	
	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&
			IF UsePicture THEN
				PicDialog.PictureCheck.SetValue 1
			ELSE
				PicDialog.PictureCheck.SetValue 0
			ENDIF
			PicDialog.PictureCheck.SetThreeState FALSE
			IF UseBorder THEN
				PicDialog.BorderCheck.SetValue 1
			ELSE
				PicDialog.BorderCheck.SetValue 0
			ENDIF
			PicDialog.BorderCheck.SetThreeState FALSE
			PicDialog.PicTextBox.SetText PictureFile$
			PicDialog.BorderTextBox.SetText BorderFile$
			IF PicDialog.PictureCheck.GetValue() THEN
				PicDialog.PicTextBox.Enable TRUE
				PicDialog.PictureButton.Enable TRUE
			ELSE
				PicDialog.PicTextBox.Enable FALSE
				PicDialog.PictureButton.Enable FALSE
			ENDIF
			IF PicDialog.BorderCheck.GetValue() THEN
				PicDialog.BorderTextBox.Enable TRUE
				PicDialog.BorderButton.Enable TRUE
			ELSE
				PicDialog.BorderTextBox.Enable FALSE
				PicDialog.BorderButton.Enable FALSE
			ENDIF					

		CASE EVENT_MOUSE_CLICK&
			SELECT CASE ControlID%
				CASE PicDialog.PictureCheck.GetID()
					IF PicDialog.PictureCheck.GetValue() THEN
						PicDialog.PicTextBox.Enable TRUE
						PicDialog.PictureButton.Enable TRUE
						UsePicture = TRUE
					ELSE
						PicDialog.PicTextBox.Enable FALSE
						PicDialog.PictureButton.Enable FALSE
						UsePicture = FALSE
					ENDIF
				CASE PicDialog.BorderCheck.GetID()
					IF PicDialog.BorderCheck.GetValue() THEN
						PicDialog.BorderTextBox.Enable TRUE
						PicDialog.BorderButton.Enable TRUE
						UseBorder = TRUE
					ELSE
						PicDialog.BorderTextBox.Enable FALSE
						PicDialog.BorderButton.Enable FALSE
						UseBorder = FALSE
					ENDIF					
				CASE PicDialog.PictureButton.GetID()
					TmpFileName$ = GETFILEBOX( \\
		               	"Todos os Arquivos|*.*", \\
		               	"Selecione uma figura", \\
		               	FILE_OPEN )
		               IF LEN(TmpFileName$) > 0 THEN
		               	PicDialog.PicTextBox.SetText TmpFileName$
		               ENDIF
				CASE PicDialog.BorderButton.GetID()
					TmpFileName$ = GETFILEBOX( \\
		               	"*.*", \\
		               	"Selecione uma borda", \\
		               	FILE_OPEN )
		               IF LEN(TmpFileName$) > 0 THEN
		               	PicDialog.BorderTextBox.SetText TmpFileName$
		               ENDIF				
				CASE PicDialog.BackButton.GetID()
					LastPageX& = PicDialog.GetLeftPosition()
					LastPageY& = PicDialog.GetTopPosition()
					NoGo = FALSE
					IF PicDialog.PictureCheck.GetValue() THEN
						IF (NOT FileExists( \\
						    PicDialog.PicTextBox.GetText())) THEN
						NoGo = TRUE
						ENDIF
					ELSEIF PicDialog.BorderCheck.GetValue() THEN
						IF (NOT FileExists( \\
						    PicDialog.BorderTextBox.GetText())) THEN
					     NoGo = TRUE
						ENDIF
					ENDIF
					IF PicDialog.PictureCheck.GetValue() AND \\
					   PicDialog.BorderCheck.GetValue() AND \\
					   Orient% = CAL_ORIENT_LANDSCAPE% THEN
						MBReturn% = MESSAGEBOX( "Não é possível " + \\
						               "criar um calendário com " + \\
						               "orientação horizontal que inclua " + \\
						               "uma figura e uma borda.  " + \\
						               "Não há espaço suficiente " + \\
						               "na página." + NL2 + \\
						               "Selecione uma figura ou " + \\
						               "uma borda, ou nenhuma das opções, e tente outra vez.", \\
						               TITLE_INFOBOX$, \\
						               MB_OK_ONLY& )
						NoGo = TRUE
					ENDIF
					IF NOT NoGo THEN
						PictureFile$ = PicDialog.PicTextBox.GetText()
						BorderFile$ = PicDialog.BorderTextBox.GetText()
						UsePicture = PicDialog.PictureCheck.GetValue()
						UseBorder = PicDialog.BorderCheck.GetValue()
						PicDialog.CloseDialog DIALOG_RETURN_BACK%
					ENDIF
				CASE PicDialog.NextButton.GetID()
					LastPageX& = PicDialog.GetLeftPosition()
					LastPageY& = PicDialog.GetTopPosition()
					NoGo = FALSE
					IF PicDialog.PictureCheck.GetValue() THEN
						IF (NOT FileExists( \\
						    PicDialog.PicTextBox.GetText())) THEN
						NoGo = TRUE
						ENDIF
					ELSEIF PicDialog.BorderCheck.GetValue() THEN
						IF (NOT FileExists( \\
						    PicDialog.BorderTextBox.GetText())) THEN
					     NoGo = TRUE
						ENDIF
					ENDIF
					IF PicDialog.PictureCheck.GetValue() AND \\
					   PicDialog.BorderCheck.GetValue() AND \\
					   Orient% = CAL_ORIENT_LANDSCAPE THEN
						MBReturn% = MESSAGEBOX( "Não é possível " + \\
						               "criar um calendário com " + \\
						               "orientação horizontal que inclua " + \\
						               "uma figura e uma borda.  " + \\
						               "Não há espaço suficiente " + \\
						               "na página." + NL2 + \\
						               "Selecione uma figura ou " + \\
						               "uma borda, ou nenhuma das opções, e tente outra vez.", \\
						               TITLE_INFOBOX$, \\
						               MB_OK_ONLY& )
						NoGo = TRUE
					ENDIF
					IF NOT NoGo THEN
						PictureFile$ = PicDialog.PicTextBox.GetText()
						BorderFile$ = PicDialog.BorderTextBox.GetText()
						UsePicture = PicDialog.PictureCheck.GetValue()
						UseBorder = PicDialog.BorderCheck.GetValue()
						PicDialog.CloseDialog DIALOG_RETURN_NEXT%
					ENDIF
				CASE PicDialog.CancelButton.GetID()
					DateDialog.CloseDialog DIALOG_RETURN_CANCEL%
			END SELECT
	END SELECT

END FUNCTION

'/////PROCESSING DIALOG/////////////////////////////////////////////////////

BEGIN DIALOG OBJECT ProcessingDialog 204, 50, "Assistente de Calendário - Processando", SUB ProcessingDialogEventHandler
	TEXT  39, 7, 143, 16, .Text5, "Seu calendário está sendo preparado.  Aguarde."
	PROGRESS 22, 27, 162, 11, .Progress
END DIALOG

SUB ProcessingDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
	DIM GenReturn AS INTEGER		' The return value of various routines.
	
	SELECT CASE Event%
		CASE EVENT_INITIALIZATION&

' <<<<< BEGIN REVERSE INDENT TO SAVE SPACE

' Initialize the progress bar.
ProcessingDialog.Progress.SETMINRANGE 0
ProcessingDialog.Progress.SETMAXRANGE CalcHowMany( HowMany%, Month%, Year% )
ProcessingDialog.Progress.SETINCREMENT 1

' Determine the necessary page dimensions.
DIM PageX AS LONG : DIM PageY AS LONG
IF (Orient% = CAL_ORIENT_PORTRAIT%) THEN
	PageX& = ArrayPageDim!(PageSize%, 1)
	PageY& = ArrayPageDim!(PageSize%, 2)
ELSE
	PageX& = ArrayPageDim!(PageSize%, 2)
	PageY& = ArrayPageDim!(PageSize%, 1)
ENDIF

' Connect to CorelDRAW, then create a new document for the calendar.
.FileNew
.SuppressPainting

' Loop through all the calendars we have to create, and build each one.
DIM Counter AS INTEGER
DIM WeekdayCounter AS INTEGER
DIM RowCounter AS INTEGER
DIM DayCounter AS INTEGER
DIM CurMonth AS INTEGER
CurMonth% = Month%
DIM CurYear AS INTEGER
CurYear% = Year%
DIM PageX_TM AS LONG	' The horizontal page size in tenths of a micron.
DIM PageY_TM AS LONG	' The vertical page size in tenths of a micron. 
DIM TitleX AS LONG		' The generated width of the title text.
DIM TitleY As LONG		' The generated height of the title text.
DIM DayX AS LONG		' The width of the text for a specific day.
DIM DayY AS LONG		' The height of the text for a specific day.
DIM NeededY AS LONG		' The required height for the weekday names.
DIM NumRows AS INTEGER	' The number of rows needed in this month.
DIM RowHeight AS LONG	' The height of a row.
DIM ColWidth AS LONG	' The width of a column.
DIM CurRow AS INTEGER	' The current row number being processed.
DIM CurCol AS INTEGER	' The current column number being processed.
DIM DaySize AS LONG		' The size (in points) we need for the numbers.
DIM WeekdayBarHeight AS LONG	' The height of the weekday bar.

FOR Counter% = 1 TO HowMany%

	' Create a new page.
	IF NOT (Counter% = 1) THEN
		.InsertPages 0, 1
	ENDIF
	
	' Set the page orientation.	
	IF (Orient% = CAL_ORIENT_PORTRAIT%) THEN
		.SetPageOrientation DRAW_ORIENT_PORTRAIT&
	ELSE
		.SetPageOrientation DRAW_ORIENT_LANDSCAPE&
	ENDIF

	' Set the size of the new page.	
	PageX_TM& = PageX&*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)
	PageY_TM& = PageY&*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)
	.SetPageSize PageX_TM&, PageY_TM&

	' Determine the boundaries within which we can draw the calendar.
	' These coordinates are relative to the center of the page.
	DIM TopLeftX AS LONG : DIM TopLeftY AS LONG	  ' The top left corner.
	DIM BottomRightX AS LONG : DIM BottomRightY AS LONG ' The bottom right corner.
	TopLeftX& = (PageX& / -2)*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)
	TopLeftY& = (PageY& / 2)*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)
	BottomRightX& = (PageX& / 2)*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)
	BottomRightY& = (PageY& / -2)*LENGTHCONVERT(LC_INCHES&, LC_TENTHS_OFA_MICRON&, 1)

	' Factor in the margins.
	AddMargins TopLeftX&, TopLeftY&, BottomRightX&, BottomRightY&

	' Draw the borders and/or picture, if necessary.
	' Adjust the calendar boundaries appropriately.
	DoGraphics UsePicture, \\
	           UseBorder, \\
	           PictureFile$, \\
	           BorderFile$, \\
	           TopLeftX&, \\
	           TopLeftY&, \\
	           BottomRightX&, \\
	           BottomRightY&

	' Create the title (the month and year).
	CreateText Months$(CurMonth%) + " " + CSTR(CurYear%), \\
	           FontName$,                                 \\
			 24,		                                  \\
	           Bold,                                      \\
	           Italic,                                    \\
	           Strikeout,                                 \\
			 Underline,						    \\
	           Red%,                                      \\
	           Green%,                                    \\
	           Blue%

	' Create the title differently depending on the style selected.
	IF CalStyle% = CAL_STYLE_SIMPLE% THEN
	
		' Make the text proportional to the size it should occupy
		' on the page.
		.GetSize TitleX&, TitleY&
		.SetSize BottomRightX& - TopLeftX&, \\
		         (BottomRightX& - TopLeftX&) * (TitleY& / TitleX&)
	
		' Add in some whitespace above and below for effect.
		.GetSize TitleX&, TitleY&
		.SetPosition TopLeftX&, TopLeftY&
		TopLeftY& = TopLeftY& - TitleY& - (0.3 * TitleY&)

	ELSEIF CalStyle% = CAL_STYLE_LEFT% THEN

		' Rotate the text by 90 degrees.
		.RotateObject 90 * 1000000, -1, 0,0

		' Make the text proportional to the size it should occupy
		' on the page.
		.GetSize TitleX&, TitleY&
		.SetSize (TopLeftY& - BottomRightY&) * (TitleX& / TitleY&), \\
                   TopLeftY& - BottomRightY&

		' Position the text along the left hand side.
		.SetPosition TopLeftX&, TopLeftY&
		.GetSize TitleX&, TitleY&
		TopLeftX& = TopLeftX& + TitleX& + (0.3 * TitleX&)

	ELSEIF CalStyle% = CAL_STYLE_RIGHT% THEN

		' Rotate the text back by 90 degrees.
		.RotateObject -90 * 1000000, -1, 0,0

		' Make the text proportional to the size it should occupy
		' on the page.
		.GetSize TitleX&, TitleY&
		.SetSize (TopLeftY& - BottomRightY&) * (TitleX& / TitleY&), \\
                   TopLeftY& - BottomRightY&

		' Position the text along the right hand side.
		.SetReferencePoint DRAW_REF_TOP_RIGHT&
		.SetPosition BottomRightX&, TopLeftY&
		.SetReferencePoint DRAW_REF_TOP_LEFT&
		.GetSize TitleX&, TitleY&
		BottomRightX& = BottomRightX& - TitleX& - (0.3 * TitleX&)

	ENDIF	

	ProcessingDialog.Progress.Step

	' Determine how big the weekday names need to be.
	CreateText "Quarta-feira",                               \\
	           FontName$,                                 \\
			 24,								    \\
	           Bold,                                      \\
	           Italic,                                    \\
	           Strikeout,                                 \\
			 Underline,						    \\
	           Red%,                                      \\
	           Green%,                                    \\
	           Blue%
	.GetSize DayX&, DayY&
	.SetSize (BottomRightX& - TopLeftX&)/7 * 0.8, \\
	         ((BottomRightX& - TopLeftX&)/7) * 0.8 * (DayY& / DayX&)
	.GetSize DayX&, DayY&
	NeededY& = DayY&
	.DeleteObject
	
	' Create a background rectangle.
	WeekdayBarHeight& = DayY& * 2
	.CreateRectangle TopLeftY&, \\
	                 TopLeftX&, \\
	                 TopLeftY& - WeekdayBarHeight&, \\
	                 BottomRightX&
	.ApplyUniformFillColor DRAW_COLORMODEL_RGB&, Red%, Green%, Blue%, 0
	.SetOutlineColor DRAW_COLORMODEL_RGB&, Red%, Green%, Blue%, 0

	' Create a rectangle enclosing the whole calendar.
	.CreateRectangle TopLeftY&, TopLeftX&, BottomRightY&, BottomRightX&
	.ApplyOutline LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 0.03), \\
              DRAW_OUTLINE_TYPE_SOLID, \\
              DRAW_OUTLINE_CAPS_BUTT,  \\
              DRAW_OUTLINE_JOIN_MITER, \\
              100, \\
              0, \\
              0, \\
              0, \\
              0, \\
              0
	.SetOutlineColor DRAW_COLORMODEL_RGB&, Red%, Green%, Blue%, 0
	ProcessingDialog.Progress.Step

	' Generate the weekday names.
	FOR WeekdayCounter% = 1 TO 7 
	
		' Create the text (in white), scale it, then position it.
		CreateText Weekdays$(WeekdayCounter),          \\
	                FontName$,                          \\
				 24,							  \\
	                Bold,                               \\
	                Italic,                             \\
	                Strikeout,                          \\
			      Underline,					  \\
	                255,                                \\
	                255,                                \\
	                255%
		.GetSize DayX&, DayY&
		.SetSize NeededY& * (DayX& / DayY&), NeededY&
		
		' Center the text vertically.
		.SetReferencePoint DRAW_REF_MIDDLE_LEFT&
		.SetPosition TopLeftX& + (WeekdayCounter% - 1)* \\
		             ((BottomRightX& - TopLeftX&)/7),   \\
		             TopLeftY& - (WeekdayBarHeight&/2)
		.SetReferencePoint DRAW_REF_TOP_LEFT&
		
		' Draw vertical rulings.
		.BeginDrawCurve  TopLeftX& + (WeekdayCounter%)* \\
		                 ((BottomRightX& - TopLeftX&)/7), TopLeftY&
		.DrawCurveLineTo TopLeftX& + (WeekdayCounter%)* \\
		                 ((BottomRightX& - TopLeftX&)/7), BottomRightY&
		.EndDrawCurve
		.ApplyOutline LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 0.03), \\
		              DRAW_OUTLINE_TYPE_SOLID, \\
		              DRAW_OUTLINE_CAPS_BUTT,  \\
		              DRAW_OUTLINE_JOIN_MITER, \\
		              100, \\
		              0, \\
		              0, \\
		              0, \\
		              0, \\
		              0
		.SetOutlineColor DRAW_COLORMODEL_RGB&, Red%, Green%, Blue%, 0
		ProcessingDialog.Progress.Step

	NEXT WeekdayCounter
	
	' Subtract the amount of space that was used by the weekdays bar.
	TopLeftY& = TopLeftY& - WeekdayBarHeight&
	
	' Determine how many rows we need for this month.
	NumRows% = GetNumRows(CurMonth, CurYear)

	' Calculate the height and width of the columns.
	RowHeight& = (TopLeftY& - BottomRightY&) / NumRows%
	ColWidth&  = (TopLeftX& - BottomRightX&) / 7
	
	' Draw in the row lines.
	FOR RowCounter% = 1 TO (NumRows% - 1)
	
		.BeginDrawCurve TopLeftX&, TopLeftY&-RowHeight&*RowCounter%
		.DrawCurveLineTo BottomRightX&, TopLeftY&-RowHeight&*RowCounter%
		.EndDrawCurve
		.ApplyOutline LENGTHCONVERT(LC_INCHES, LC_TENTHS_OFA_MICRON, 0.03), \\
		              DRAW_OUTLINE_TYPE_SOLID, \\
		              DRAW_OUTLINE_CAPS_BUTT,  \\
		              DRAW_OUTLINE_JOIN_MITER, \\
		              100, \\
		              0, \\
		              0, \\
		              0, \\
		              0, \\
		              0
		.SetOutlineColor DRAW_COLORMODEL_RGB&, Red%, Green%, Blue%, 0
	
	NEXT RowCounter%
	ProcessingDialog.Progress.Step

	' Due to the nature of typeface numerics, it would not be
	' aesthetically pleasing to do a proportional resize on the
	' day numbers.  So we will calculate an appropriate point size.
	DaySize& = LENGTHCONVERT( LC_TENTHS_OFA_MICRON&, \\
	                          LC_POINTS&, \\
	                          RowHeight& * 0.15 )

	' Draw in the day numbers.
	CurRow% = 1
	CurCol% = GetWeekday(CDAT( STR(CurYear%) + "-" + STR(CurMonth%) + "-1"))
	FOR DayCounter% = 1 TO GetNumDays( CurMonth%, CurYear% )
	
		' Create the day number.
		CreateText STR(DayCounter%),                 \\
	                FontName$,                        \\
				 DaySize&,  				 	\\
	                Bold,                             \\
	                Italic,                           \\
	                Strikeout,                        \\
			      Underline,					\\
	                Red%,                             \\
	                Green%,                           \\
	                Blue% 
		.SetPosition TopLeftX&-((CurCol%-1)*ColWidth&)-ColWidth&*0.07, \\
		             TopLeftY&-(CurRow%*RowHeight&)+RowHeight&*0.92

		' Update the current row and column.
		IF (CurCol% = 7) THEN
		   CurCol% = 1
		   CurRow% = CurRow% + 1
		ELSE
		   CurCol% = CurCol% + 1
		ENDIF

		' Update the progress bar.
		ProcessingDialog.Progress.Step
	
	NEXT DayCounter%
	
	' Update the year and month we are processing.
	IF CurMonth% = 12 THEN
		CurMonth% = 1
		CurYear% = CurYear% + 1
	ELSE
		CurMonth% = CurMonth% + 1
	ENDIF

NEXT Counter%

.ResumePainting

GenReturn% = MESSAGEBOX( "Terminando a criação do calendário!", \\
                         TITLE_INFOBOX$, \\
                         MB_OK_ONLY& )
ProcessingDialog.CloseDialog DIALOG_RETURN_OK%

' >>>>> END REVERSE INDENT
									
	END SELECT

END FUNCTION

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM CurStep AS INTEGER		' The user's current dialog number.

' Set up a general error handler.
ON ERROR GOTO MainErrorHandler

' Retrieve the directory where the script was started.
CurDir$ = GETCURRFOLDER()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF

CONST NS_FINISH%		 = 0
CONST NS_INTRODIALOG%     = 1
CONST NS_SIZEDIALOG%      = 2
CONST NS_ORIENTDIALOG%	 = 3
CONST NS_STYLEDIALOG%     = 4
CONST NS_DATEDIALOG%	 = 5
CONST NS_PICDIALOG%       = 6
CONST NS_FONTDIALOG%      = 7

' Loop, displaying dialogs in the required order.
CurStep% = NS_INTRODIALOG%
WHILE (CurStep% <> NS_FINISH%)

	SELECT CASE CurStep%
		CASE NS_INTRODIALOG%
			IF (LastPageX& <> -1) THEN
				IntroDialog.Move LastPageX&, LastPageY&
			ENDIF		
			IntroDialog.IntroImage.SetImage CurDir$ + BITMAP_INTRODIALOG$
			IntroDialog.IntroImage.SetStyle STYLE_SUNKEN
			IntroDialog.IntroImage.SetStyle STYLE_IMAGE_CENTERED
			IntroDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(IntroDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_SIZEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP		
				CASE ELSE
					CurStep% = NS_INTRODIALOG%
			END SELECT

		CASE NS_SIZEDIALOG%
			SizeDialog.Move LastPageX&, LastPageY&
			SizeDialog.SizeImage.SetImage CurDir$ + BITMAP_INTRODIALOG$
			SizeDialog.SizeImage.SetStyle STYLE_SUNKEN
			SizeDialog.SizeImage.SetStyle STYLE_IMAGE_CENTERED
			SizeDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(SizeDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_ORIENTDIALOG%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_INTRODIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_SIZEDIALOG%
			END SELECT

		CASE NS_ORIENTDIALOG%
			OrientDialog.Move LastPageX&, LastPageY&
			OrientDialog.OrientImage.SetImage CurDir$ + BITMAP_INTRODIALOG$
			OrientDialog.OrientImage.SetStyle STYLE_SUNKEN
			OrientDialog.OrientImage.SetStyle STYLE_IMAGE_CENTERED
			OrientDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(OrientDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_STYLEDIALOG%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_SIZEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_ORIENTDIALOG%
			END SELECT
			
		CASE NS_STYLEDIALOG%
			StyleDialog.Move LastPageX&, LastPageY&
			StyleDialog.StyleImage.SetImage CurDir$ + BITMAP_INTRODIALOG
			StyleDialog.StyleImage.SetStyle STYLE_SUNKEN
			StyleDialog.StyleImage.SetStyle STYLE_IMAGE_CENTERED
			StyleDialog.PreviewImage.SetStyle STYLE_SUNKEN
			StyleDialog.PreviewImage.SetStyle STYLE_IMAGE_CENTERED
			StyleDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(StyleDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_FONTDIALOG%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_ORIENTDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_STYLEDIALOG%
			END SELECT

		CASE NS_FONTDIALOG%
			FontDialog.Move LastPageX&, LastPageY&
			FontDialog.FontImage.SetImage CurDir$ + BITMAP_INTRODIALOG
			FontDialog.FontImage.SetStyle STYLE_SUNKEN
			FontDialog.FontImage.SetStyle STYLE_IMAGE_CENTERED
			FontDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(FontDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_PICDIALOG%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_STYLEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_FONTDIALOG%
			END SELECT

		CASE NS_DATEDIALOG%
			DateDialog.Move LastPageX&, LastPageY&
			DateDialog.DateImage.SetImage CurDir$ + BITMAP_INTRODIALOG$
			DateDialog.DateImage.SetStyle STYLE_SUNKEN
			DateDialog.DateImage.SetStyle STYLE_IMAGE_CENTERED
			DateDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(DateDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_FINISH%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_PICDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_DATEDIALOG%
			END SELECT

		CASE NS_PICDIALOG%
			PicDialog.Move LastPageX&, LastPageY&
			PicDialog.PicImage.SetImage CurDir$ + BITMAP_INTRODIALOG
			PicDialog.PicImage.SetStyle STYLE_SUNKEN
			PicDialog.PicImage.SetStyle STYLE_IMAGE_CENTERED
			PicDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn& = DIALOG(PicDialog)
			SELECT CASE GenReturn&
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_DATEDIALOG%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_FONTDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP							
				CASE ELSE
					CurStep% = NS_PICDIALOG%
			END SELECT

	END SELECT
WEND

' Create the calendars, then end.
GenReturn& = DIALOG(ProcessingDialog)
STOP

MainErrorHandler:
	ERRNUM = 0
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processamento do assistente." + NL2
	MessageText$ = MessageText$ + "Tente outra vez."
	GenReturn& = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)

	' Just to be safe, though DRAW is supposed to do it anyway if
	' a script terminates, re-enable painting.
	ON ERROR RESUME NEXT
	.ResumePainting
	ERRNUM = 0
	STOP

'********************************************************************
'
'	Name:	CreateText (subroutine)
'
'	Action:	Creates a string of artistic text within CorelDRAW.
'              Does not size it.
'
'	Params:	InMonth - The month of the calendar.
'              InYear  - The year of the calendar.
'              InFontName - The font to use.
'			InFontSize - The size of font (points).
'              InBold - Make the font bold?
'              InItalic - Make the font italic?
'              InStrikeout - Use strikeout?
'              InRed, InGreen, InBlue - Colour values.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB CreateText ( InText AS STRING, \\
		       InFontName AS STRING, \\
			  InFontSize AS LONG, \\
		       InBold AS BOOLEAN, \\
		       InItalic AS BOOLEAN, \\
		       InStrikeout AS BOOLEAN, \\
			  InUnderline AS BOOLEAN, \\
			  InRed AS INTEGER, \\
			  InGreen AS INTEGER, \\
			  InBlue AS INTEGER)

	DIM DrawStyleCode AS INTEGER ' The font style to send to DRAW.
	DIM DrawPointSize AS INTEGER ' The font size to send to DRAW.
	DIM DrawUnderline AS INTEGER ' The underline code to send to DRAW.
	DIM DrawStrikeout AS INTEGER ' The strikeout code to send to DRAW.

	' Create the title's text.
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
	DrawPointSize% = InFontSize * 10 
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
	.ApplyUniformFillColor DRAW_COLORMODEL_RGB&, InRed%, InGreen%, InBlue%, 0

END SUB

'********************************************************************
'
'	Name:	FileExists (function)
'
'	Action:	Determines if a given file exists.
'              If it does not exist, displays an error message.
'
'	Params:	InFileName - The file name and path to test.
'
'	Returns:	TRUE if the file exists.  FALSE otherwise, along
'              with displaying an error message.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION FileExists( InFileName AS STRING ) AS BOOLEAN

	DIM ReturnedSize AS LONG  ' The size of InFileName.
	DIM MsgResult AS LONG	 ' The result of the MESSAGEBOX call.
	
	' Grab the size of InFileName.
	ReturnedSize& = FILESIZE( InFileName$ )
	
	' If InFileName is empty, complain.
	IF LEN(InFileName$) = 0 THEN
		MsgResult = MESSAGEBOX("Para cada quadro marcado, "+\\
		                       "é necessário especificar um nome de arquivo. "+\\
		                       "Você não pode deixar o espaço em branco."+NL2+\\
		                       "Tente outra vez.", \\
		  	                  TITLE_ERRORBOX, \\
			                  MB_OK_ONLY)
		FileExists = FALSE
		EXIT FUNCTION
	ENDIF
	
	' If it doesn't exist, complain.
	IF (ReturnedSize& > 0) THEN
		FileExists = TRUE
	ELSE
		MsgResult = MESSAGEBOX("Impossível encontrar o arquivo '" + \\
		                       InFileName$ + "'." + NL2 + \\
		                       "Digite um novo nome de arquivo " + \\
		                       "e outro caminho.", \\
		  	                  TITLE_ERRORBOX, \\
			                  MB_OK_ONLY)
		FileExists = FALSE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	GetWeekday (function)
'
'	Action:	Returns a number which indicates which day of the
'              week a date refers to.  (Day 1 is Sunday.)
'
'	Params:	Wkd - The date to investigate.
'
'	Returns:	A number which indicates which day of the week the
'              date falls on.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION GetWeekday( Wkd AS DATE ) AS INTEGER

	CONST Offset% = 6  	 ' An offset to use in the calculations.
	DIM WeekTemp AS LONG ' A temporary variable in the calculations.
	
	' These calculations are based on the fact that all dates in
	' CorelSCRIPT are actually represented by the number of days
	' since December 31, 1899.
	WeekTemp& = INT(Wkd) + Offset%
	GetWeekday = (WeekTemp& MOD 7) + 1

END FUNCTION

'********************************************************************
'
'	Name:	GetNumRows (function)
'
'	Action:	Returns the number of rows needed in a calendar whose
'              first column is Sunday for a given month and year.
'
'	Params:	InMonthNum - The month number (January is 1).
'              InYearNum  - The year.
'
'	Returns:	Either 4, 5, or 6 depending on how many rows are needed
'              (4 is very rare -- happens in Feb. 1998, for example).
'
'	Comments:	Months$(12) must be global.
'
'********************************************************************
FUNCTION GetNumRows( InMonthNum AS INTEGER, InYear AS INTEGER ) AS INTEGER

	DIM RowCount AS INTEGER	' The number of rows used up so far.
	DIM CurDay AS INTEGER    ' The current day being processed.
	DIM CurDate AS DATE		' The current date being processed.
	
	' Loop through all the days in this month.
	RowCount% = 1
	CurDay% = 1
	WHILE CurDay% < GetNumDays(InMonthNum%, InYear%)
		CurDate = STR(CurDay%) + " " + Months$(InMonthNum%) + \\
		          " " + STR(InYear%)
		IF (GetWeekday(CurDate) = 7) THEN
			RowCount% = RowCount% + 1
		ENDIF
		CurDay% = CurDay% + 1
	WEND
	
	' Return the result.
	GetNumRows% = RowCount%

END FUNCTION

'********************************************************************
'
'	Name:	GetNumDays (function)
'
'	Action:	Returns the number of days in a given month for a
'              given year.
'
'	Params:	InMonthNum - The month number (January is 1).
'              InYearNum  - The year.
'
'	Returns:	A number from 28 to 31.
'
'	Comments:	Leap years are properly taken into account.
'
'********************************************************************
FUNCTION GetNumDays( InMonthNum AS INTEGER, InYear AS INTEGER ) AS INTEGER

	' The days in each month.
	DIM DaysInMonths%(12)
	DaysInMonths%(1) = 31		
	DaysInMonths%(2) = 28 ' Leap years are taken into account later.			
	DaysInMonths%(3) = 31
	DaysInMonths%(4) = 30
	DaysInMonths%(5) = 31
	DaysInMonths%(6) = 30
	DaysInMonths%(7) = 31
	DaysInMonths%(8) = 31
	DaysInMonths%(9) = 30
	DaysInMonths%(10) = 31
	DaysInMonths%(11) = 30
	DaysInMonths%(12) = 31	

	' Adjust for leap years.
	IF (InYear MOD 4 = 0 AND InYear MOD 100 <> 0) OR InYear MOD 400 = 0 THEN
		DaysInMonths%(2) = 29
	END IF

	' Return the proper number.
	GetNumDays% = DaysInMonths%(InMonthNum%)

END FUNCTION

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
FUNCTION Min( Val1 AS LONG, Val2 AS LONG ) AS LONG

	IF Val1& < Val2& THEN
		Min& = Val1&
	ELSE
		Min& = Val2&
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	DoGraphics (subroutine)
'
'	Action:	Draws a picture and/or a border if necessary on
'              the current page in CorelDRAW.  Adjusts the calendar
'              rectangle variables to account for the picture and/or
'              border.
'
'	Params:	UsePicture - Use a picture?
'              UseBorder  - Use a border?
'              PictureFile$ - The name of the picture file to use.
'              BorderFile$  - The name of the border file to use.
'              TopLeftX& - The top left-hand corner of the calendar
'                          rectangle;  X-coordinate.
'              TopLeftY& - The top left-hand corner of the calendar
'                          rectangle;  Y-coordinate.
'              BottomRightX& - The bottom right-hand corner of the
'                              calendar rectangle;  X-coordinate.
'              BottomRightY& - The bottom right-hand corner of the
'                              calendar rectangle;  Y-coordinate.  
'
'	Returns:	None.
'
'	Comments:	The 'calendar rectangle' reflects the space where
'              the actual 'calendar' part of the calendar will be
'              drawn (minus graphics and border).
'              May stop the wizard (with an appropriate error
'              message) if the border or picture is in a format
'              DRAW cannot recognize.
'
'********************************************************************
SUB DoGraphics( InUsePicture AS BOOLEAN,       \\
                InUseBorder AS BOOLEAN,        \\
                InPictureFile AS STRING,       \\
			 InBorderFile AS STRING,        \\
			 BYREF InTopLeftX AS LONG,      \\
			 BYREF InTopLeftY AS LONG,      \\
			 BYREF InBottomRightX AS LONG,  \\
			 BYREF InBottomRightY AS LONG )

	DIM CurFile AS STRING	' The current file we're trying to import.
	DIM BorderOffsetX AS LONG ' How much space to leave on the sides.
	DIM BorderOffsetY AS LONG' How much space to leave on the top and bottom.
	DIM PicXSize AS LONG	' The X size of the imported picture.
	DIM PicYSize AS LONG	' The Y size of the imported picture.
	DIM AvailableX AS LONG	' How much X space we have for the picture.
	DIM AvailableY AS LONG	' How much Y space we have for the picture.
	DIM NeededX AS LONG		' How big should the picture be?
	DIM NeededY AS LONG		' How big should the picture be?
	DIM TempTopLeftY AS LONG ' A temporary variable storing InTopLeftY.

	' Borders should be factored in first.
	IF InUseBorder THEN
		
		' Set up an error handler to capture file import errors.
		ON ERROR GOTO DG_Error_Import
		
		' Import the border.
		CurFile$ = InBorderFile$
		.FileImport CurFile$

		' Successfully finished the import.
		ON ERROR EXIT
		
		' For borders, we will resize to fit the page.  Aspect
		' ratio is not taken into account here, because most
		' borders look good even when distorted.
		.SetSize InBottomRightX& - InTopLeftX&, \\
		         InTopLeftY& - InBottomRightY&
		.SetPosition InTopLeftX&, InTopLeftY&

		' We have no way of knowing how wide the border is.
		' Conveniently, however, the borders in BORDERS\FRAMES
		' need about 1.4 inches on the sides and 1.5 on the top
		' and bottom.
		BorderOffsetX& = LENGTHCONVERT( LC_INCHES&, \\
		                               LC_TENTHS_OFA_MICRON&, \\
		                               1.4 )
		BorderOffsetY& = LENGTHCONVERT( LC_INCHES&, \\
		                               LC_TENTHS_OFA_MICRON&, \\
		                               1.5 )
		InTopLeftX& = InTopLeftX& + BorderOffsetX&
		InTopLeftY& = InTopLeftY& - BorderOffsetY&
		InBottomRightX& = InBottomRightX& - BorderOffsetX&
		InBottomRightY& = InBottomRightY& + BorderOffsetY&

	ENDIF
	
	' Next, we process graphics.  These should go inside the
	' border (if there is one) and take up the top half of
	' the calendar rectangle.
	IF InUsePicture THEN
		
		' Set up an error handler to capture file import errors.
		ON ERROR GOTO DG_Error_Import
		
		' Import the picture.
		CurFile$ = InPictureFile$
		.FileImport CurFile$

		' Successfully finished the import.
		ON ERROR EXIT
		
		' Calculate how much space we have for the picture.
		AvailableX& = InBottomRightX& - InTopLeftX&
		AvailableY& = (InTopLeftY& - InBottomRightY&) / 2
		
		' Pictures require an aspect ratio based resize so
		' that their proportions do not become distorted.
		.GetSize PicXSize&, PicYSize&
		TempTopLeftY& = InTopLeftY&
		IF (PicXSize& > PicYSize&) THEN
			NeededX& = AvailableX& 
			NeededY& = NeededX& * (PicYSize& / PicXSize&)

			' Make special provisions so that the calendar does
			' not get too small.
			IF (NeededY& > AvailableY&) THEN
				NeededY& = AvailableY& 
				NeededX& = NeededY& * (PicXSize& / PicYSize&)
			ENDIF

			' Recalculate the calendar space.
			InTopLeftY& = InTopLeftY& - \\
                             Min(CLNG((AvailableX& * (PicYSize& / PicXSize&))), \\
                                 AvailableY&)
		ELSE
			NeededY& = AvailableY&
			NeededX& = NeededY& * (PicXSize& / PicYSize&)

			' Recalculate the calendar space.
			InTopLeftY& = InTopLeftY& - AvailableY&
		ENDIF
		.SetSize NeededX&, NeededY&
		
		' Center the picture horizontally in the picture area.
		.SetReferencePoint DRAW_REF_TOP_MIDDLE&
		.SetPosition InTopLeftX& + (AvailableX& / 2), \\
				   TempTopLeftY&
		.SetReferencePoint DRAW_REF_TOP_LEFT&

		' Add in some extra margin space above the month name.
		InTopLeftY& = InTopLeftY& - LENGTHCONVERT( LC_INCHES&, \\
                                                     LC_TENTHS_OFA_MICRON&, \\
                                                     0.25 )

	ENDIF
	
	EXIT SUB
	
DG_Error_Import:
	ERRNUM = 0
	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.
	MsgReturn& = MESSAGEBOX( "Impossível importar o arquivo '" + \\
						CurFile$ + "'." + NL2 +     \\
						"Verifique se o CorelDRAW pode " + \\
						"importar esse tipo de arquivo gráfico " + \\
						"e execute o assistente outra vez.", \\
						TITLE_ERRORBOX$, \\
						MB_STOP_ICON& )
	STOP
	
END SUB

'********************************************************************
'
'	Name:	AddMargins (subroutine)
'
'	Action:	Reduces the size of the calendar rectangle on
'              all sides equivalent to a margin size that will
'              work with most printers (0.5 in.)
'
'	Params:	TopLeftX& - The top left-hand corner of the calendar
'                          rectangle;  X-coordinate.
'              TopLeftY& - The top left-hand corner of the calendar
'                          rectangle;  Y-coordinate.
'              BottomRightX& - The bottom right-hand corner of the
'                              calendar rectangle;  X-coordinate.
'              BottomRightY& - The bottom right-hand corner of the
'                              calendar rectangle;  Y-coordinate.  
'
'	Returns:	None.
'
'	Comments:	The 'calendar rectangle' reflects the space where
'              the actual 'calendar' part of the calendar will be
'              drawn (minus graphics and border).
'
'********************************************************************
SUB AddMargins( BYREF InTopLeftX AS LONG, \\
                BYREF InTopLeftY AS LONG, \\
                BYREF InBottomRightX AS LONG, \\
                BYREF InBottomRightY AS LONG )

	CONST ReductionInches! = 0.5  ' The reduction in inches.
	DIM ReductionAmount AS LONG	' How much to reduce each side by.

	' Calculate the reduction in tenths of a micron.	
	ReductionAmount& = LENGTHCONVERT( LC_INCHES&, \\
                                       LC_TENTHS_OFA_MICRON&, \\
                                       ReductionInches! )

	' Make the adjustments.
	InTopLeftX& = InTopLeftX& + ReductionAmount&
	InTopLeftY& = InTopLeftY& - ReductionAmount&
	InBottomRightX& = InBottomRightX& - ReductionAmount&
	InBottomRightY& = InBottomRightY& + ReductionAmount&

END SUB

'********************************************************************
'
'	Name:	CalcHowMany (function)
'
'	Action:	Calculates the number of ticks there should be
'              on the processing progress bar.
'
'	Params:	HowMany - The number of months we're generating.
'              Month - The first month we're generating.
'              Year - The first year we're generating. 
'
'	Returns:	A LONG number of ticks.
'
'	Comments:	This calculation assumes one tick per day, plus 10
'              extra ticks for each month.
'
'********************************************************************
FUNCTION CalcHowMany( InHowMany AS INTEGER, \\
                      InMonth AS INTEGER, \\
                      InYear AS INTEGER ) AS LONG

	CONST Offset& = 10		' A number to add for each month.

	DIM Counter AS INTEGER	' A counter for the loop.
	DIM Accum AS LONG		' An accumulator variable.
	DIM CurYear AS INTEGER	' The current year.
	DIM CurMonth AS INTEGER	' The current month.

	Accum& = 0
	CurMonth% = InMonth%
	CurYear% = InYear%
	FOR Counter% = 1 TO InHowMany%
		' Update the accumulator based on the number of days in
		' the current month.
		Accum& = Accum& + GetNumDays( CurMonth%, CurYear% ) + Offset&

		' Increment the month.
		IF CurMonth% = 12 THEN
			CurMonth% = 1
			CurYear% = CurYear% + 1
		ELSE
			CurMonth% = CurMonth% + 1
		ENDIF
	NEXT Counter%

	' Return the accumulated value.
	CalcHowMany& = Accum&

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
