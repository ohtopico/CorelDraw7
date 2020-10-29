REM Aplica um efeito de sombra
REM aos objetos selecionados.

'********************************************************************
' 
'   Script:	Shadow.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to apply a drop shadow to the
'                currently selected object(s).
' 
'********************************************************************

#addfol  "..\..\..\Scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE FUNCTION AnythingChanged() AS BOOLEAN
DECLARE FUNCTION ValidateInput() AS BOOLEAN
DECLARE FUNCTION CheckForSelection() AS BOOLEAN
DECLARE FUNCTION RemoveObject( InCDRStaticID AS LONG ) AS BOOLEAN
DECLARE SUB WarnUser()
DECLARE SUB WarnUserComplete()
DECLARE FUNCTION ApplyEffect( InID AS LONG, \\
                              InRed AS INTEGER, \\
                              InGreen AS INTEGER, \\
                              InBlue AS INTEGER, \\
                              InMakeTransparent AS BOOLEAN, \\
                              InPercent AS INTEGER, \\
                              InHorizOffset AS LONG, \\
                              InVertOffset AS LONG, \\
                              InHorizUnit AS INTEGER, \\
                              InVertUnit AS INTEGER) AS LONG
DECLARE FUNCTION StillThere( InCDRStaticID AS LONG ) AS BOOLEAN

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST TITLE_ERRORBOX$      = "Erro do Marcador de Sombra"
GLOBAL CONST TITLE_INFOBOX$       = "Informações do Marcador de Sombra"
GLOBAL NL AS STRING	     ' These must be declared as 
GLOBAL NL2 AS STRING     ' variables, not constants, because
NL$ = CHR(10) + CHR(13)	' we cannot assign expressions
NL2$ = NL + NL	     	' to constants.

' Constants for dialog return values.
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2

' The CDRStaticID of the selected object(s).
GLOBAL IDOriginal AS LONG

' The CDRStaticID of the duplicated object.
GLOBAL IDDuplicate AS LONG

'/////CHECK FOR CORELDRAW/////////////////////////////////////////////
ON ERROR GOTO ErrorNoDrawHandler
WITHOBJECT OBJECT_DRAW	' This will raise an error if Draw is not installed
					' or not available because of an OLE problem.
ON ERROR EXIT

'/////PARAMETERS DIALOG//////////////////////////////////////////////

' The array of possible units the user may select from.
GLOBAL UnitsArray(6) AS STRING
UnitsArray(1) = "1 pol."
UnitsArray(2) = "1/36 pol."
UnitsArray(3) = "0,001 pol."
UnitsArray(4) = "1 cm."
UnitsArray(5) = "0,001 cm."
UnitsArray(6) = "1 pt."

' Default constants for this dialog.
GLOBAL CONST HorizDefaultOffset& = 60
GLOBAL CONST HorizDefaultUnit& = 5
GLOBAL CONST VertDefaultOffset& = -60
GLOBAL CONST VertDefaultUnit& = 5
GLOBAL CONST PercentDefault& = 50
GLOBAL CONST RedDefault% = 0
GLOBAL CONST GreenDefault% = 0
GLOBAL CONST BlueDefault% = 0
GLOBAL CONST Proportion& = 500000   ' Used for setting the default
							 ' offset values.

' Variables needed for this dialog.
GLOBAL Red AS INTEGER	' The selected color's red component.
GLOBAL Green AS INTEGER	' The selected color's green component.
GLOBAL Blue AS INTEGER	' The selected color's blue component.
GLOBAL FirstTime AS BOOLEAN ' Whether the user has applied
					' anything yet.

' Variables needed to store the old values.
GLOBAL OldRed AS INTEGER
GLOBAL OldGreen AS INTEGER
GLOBAL OldBlue AS INTEGER
GLOBAL OldShadowCheck AS BOOLEAN
GLOBAL OldPercent AS LONG
GLOBAL OldHorizOffset AS LONG
GLOBAL OldVertOffset AS LONG
GLOBAL OldHorizUnit AS INTEGER
GLOBAL OldVertUnit AS INTEGER

' Set up the defaults.
Red% = RedDefault%
Green% = GreenDefault%
Blue% = BlueDefault%
FirstTime = TRUE

BEGIN DIALOG OBJECT ParamDialog 283, 179, "Marcador de Sombra", SUB ParamDialogEventHandler
	GROUPBOX  13, 109, 185, 61, .GroupBox1, "Efeitos Especiais"
	TEXT  12, 4, 271, 16, .Text1, "Esta ferramenta cria automaticamente uma sombra para o objeto selecionado atualmente."
	GROUPBOX  13, 20, 256, 81, .GroupBox2, "Localização da sombra"
	TEXT  24, 46, 65, 13, .Text2, "Horizontal"
	TEXT  24, 64, 27, 8, .Text3, "Vertical"
	SPINCONTROL  61, 45, 40, 12, .HorizSpin
	DDLISTBOX  114, 45, 54, 197, .HorizListBox
	SPINCONTROL  61, 63, 40, 12, .VertSpin
	DDLISTBOX  114, 63, 54, 178, .VertListBox
	TEXT  105, 46, 6, 11, .Text4, "x"
	TEXT  105, 64, 6, 11, .Text5, "x"
	CHECKBOX  25, 123, 58, 18, .ShadowCheck, "Fazer sombra "
	SPINCONTROL  86, 126, 35, 12, .PercentSpin
	TEXT  124, 125, 67, 16, .Text7, "porcento transparente"
	PUSHBUTTON  50, 147, 97, 13, .ShadowButton, "Selecionar a cor da sombra"
	PUSHBUTTON  214, 114, 50, 13, .ApplyButton, "&Aplicar"
	PUSHBUTTON  214, 138, 50, 13, .OkButton, "&OK"
	PUSHBUTTON  214, 156, 50, 13, .CancelButton, "&Cancelar"
	PUSHBUTTON  171, 51, 37, 19, .LeftButton, "Esquerda"
	PUSHBUTTON  207, 32, 30, 19, .UpButton, "Topo"
	PUSHBUTTON  237, 51, 30, 19, .RightButton, "Direita"
	PUSHBUTTON  207, 70, 30, 19, .DownButton, "Base"
	GROUPBOX  214, 129, 49, 5, .GroupBox4
END DIALOG

SUB ParamDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG

	IF Event% = EVENT_INITIALIZATION THEN
		' Set dialog defaults.
		ParamDialog.HorizListBox.SetArray UnitsArray$
		ParamDialog.VertListBox.SetArray UnitsArray$
		ParamDialog.HorizListBox.SetSelect HorizDefaultUnit&
		ParamDialog.VertListBox.SetSelect VertDefaultUnit&
		ParamDialog.PercentSpin.SetValue PercentDefault&
		ParamDialog.ShadowCheck.SetThreeState FALSE
		ParamDialog.ShadowCheck.SetValue FALSE
		ParamDialog.PercentSpin.Enable FALSE
		
		' To set the offset defaults, use the size of the
		' selected object.
		DIM XSize AS LONG
		DIM YSize AS LONG
		
		.GetSize XSize&, YSize&
		ParamDialog.HorizSpin.SetValue CLNG((XSize& * HorizDefaultOffset&) / Proportion&)
		ParamDialog.VertSpin.SetValue CLNG((YSize& * VertDefaultOffset&) / Proportion&)
		
	ELSEIF Event% = EVENT_MOUSE_CLICK THEN 	
		SELECT CASE ControlID%
			CASE ParamDialog.UpButton.GetID()
				ParamDialog.VertSpin.SetValue \\
				   	ParamDialog.VertSpin.GetValue() + 1
				IF (ParamDialog.VertSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue -999
				ELSEIF (ParamDialog.VertSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue 999
				ENDIF

			CASE ParamDialog.DownButton.GetID()
				ParamDialog.VertSpin.SetValue \\
				   ParamDialog.VertSpin.GetValue() - 1
				IF (ParamDialog.VertSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue -999
				ELSEIF (ParamDialog.VertSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue 999
				ENDIF
				
			CASE ParamDialog.LeftButton.GetID()
				ParamDialog.HorizSpin.SetValue \\
				   ParamDialog.HorizSpin.GetValue() - 1
				IF (ParamDialog.HorizSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue -999
				ELSEIF (ParamDialog.HorizSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue 999
				ENDIF
				
			CASE ParamDialog.RightButton.GetID()
				ParamDialog.HorizSpin.SetValue \\
				   ParamDialog.HorizSpin.GetValue() + 1
				IF (ParamDialog.HorizSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue -999
				ELSEIF (ParamDialog.HorizSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue 999
				ENDIF

			CASE ParamDialog.ShadowCheck.GetID()
				IF ParamDialog.ShadowCheck.GetValue() THEN
					ParamDialog.PercentSpin.Enable TRUE
				ELSE
					ParamDialog.PercentSpin.Enable FALSE
				ENDIF	
			CASE ParamDialog.ShadowButton.GetID()
				GETCOLOR Red%, Green%, Blue%
			CASE ParamDialog.ApplyButton.GetID()
				IF ValidateInput() THEN
					IF FirstTime THEN
						FirstTime = FALSE
						IDDuplicate& = ApplyEffect( IDOriginal&, \\
                                                          Red%, \\
                                                          Green%, \\
                                                          Blue%, \\
                                                          CBOL(ParamDialog.ShadowCheck.GetValue()), \\
                                                          CINT(ParamDialog.PercentSpin.GetValue()), \\
                                                          CLNG(ParamDialog.HorizSpin.GetValue()), \\
                                                          CLNG(ParamDialog.VertSpin.GetValue()), \\
                                                          CINT(ParamDialog.HorizListBox.GetSelect()), \\
                                                          CINT(ParamDialog.VertListBox.GetSelect()) )
					ELSE ' We will always perform an apply when
						' the apply button is hit.  This
						' is more reassuring for the user
						' than not doing anything if nothing
						' changed (though less efficient).
						' For efficiency, use:
						'   ELSEIF AnythingChanged() THEN
						IF (NOT StillThere(IDOriginal&)) THEN
							WarnUserComplete
							STOP
						ENDIF
						IF NOT StillThere(IDDuplicate&) THEN
							WarnUser
						ELSEIF NOT RemoveObject(IDDuplicate&) THEN
							WarnUser
						ENDIF
						IDDuplicate& = ApplyEffect( IDOriginal&, \\
                                                          Red%, \\
                                                          Green%, \\
                                                          Blue%, \\
                                                          CBOL(ParamDialog.ShadowCheck.GetValue()), \\
                                                          CINT(ParamDialog.PercentSpin.GetValue()), \\
                                                          CLNG(ParamDialog.HorizSpin.GetValue()), \\
                                                          CLNG(ParamDialog.VertSpin.GetValue()), \\
                                                          CINT(ParamDialog.HorizListBox.GetSelect()), \\
                                                          CINT(ParamDialog.VertListBox.GetSelect()) )
					ENDIF
				ENDIF
			CASE ParamDialog.OkButton.GetID()
				IF ValidateInput() THEN
					IF FirstTime THEN
						FirstTime = FALSE
						IDDuplicate& = ApplyEffect( IDOriginal&, \\
                                                          Red%, \\
                                                          Green%, \\
                                                          Blue%, \\
                                                          CBOL(ParamDialog.ShadowCheck.GetValue()), \\
                                                          CINT(ParamDialog.PercentSpin.GetValue()), \\
                                                          CLNG(ParamDialog.HorizSpin.GetValue()), \\
                                                          CLNG(ParamDialog.VertSpin.GetValue()), \\
                                                          CINT(ParamDialog.HorizListBox.GetSelect()), \\
                                                          CINT(ParamDialog.VertListBox.GetSelect()) )
					ELSEIF AnythingChanged() THEN
						IF (NOT StillThere(IDOriginal&)) THEN
							WarnUserComplete
							STOP
						ENDIF
						IF NOT StillThere(IDDuplicate&) THEN
							WarnUser						
						ELSEIF NOT RemoveObject(IDDuplicate&) THEN
							WarnUser
						ENDIF
						IDDuplicate& = ApplyEffect( IDOriginal&, \\
                                                          Red%, \\
                                                          Green%, \\
                                                          Blue%, \\
                                                          CBOL(ParamDialog.ShadowCheck.GetValue()), \\
                                                          CINT(ParamDialog.PercentSpin.GetValue()), \\
                                                          CLNG(ParamDialog.HorizSpin.GetValue()), \\
                                                          CLNG(ParamDialog.VertSpin.GetValue()), \\
                                                          CINT(ParamDialog.HorizListBox.GetSelect()), \\
                                                          CINT(ParamDialog.VertListBox.GetSelect()) )
					ENDIF
					ParamDialog.CloseDialog DIALOG_RETURN_OK%
				ENDIF
			CASE ParamDialog.CancelButton.GetID()
				IF NOT FirstTime THEN
					IF (NOT StillThere(IDOriginal&)) THEN
						WarnUserComplete
						STOP
					ENDIF
					IF NOT StillThere(IDDuplicate&) THEN
						WarnUser
					ELSEIF NOT RemoveObject(IDDuplicate&) THEN
						WarnUser
					ENDIF
				ENDIF
				ParamDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
		
	ELSEIF Event% = EVENT_CHANGE_IN_CONTENT THEN 	
		SELECT CASE ControlID%
			CASE ParamDialog.PercentSpin.GetID()
				' Do not let the user choose values less than 0 or
				' more than 100.
				IF ParamDialog.PercentSpin.GetValue() < 0 THEN
				   	MsgReturn& = MESSAGEBOX("Digite uma porcentagem " + \\
                                       		    "entre 0 e 100.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.PercentSpin.SetValue 0
				ELSEIF ParamDialog.PercentSpin.GetValue() > 100 THEN
				   	MsgReturn& = MESSAGEBOX("Digite uma porcentagem " + \\
                                       		    "entre 0 e 100.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.PercentSpin.SetValue 100
				ENDIF
				
			CASE ParamDialog.HorizSpin.GetID()
				IF (ParamDialog.HorizSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue -999
				ELSEIF (ParamDialog.HorizSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "horizontal entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.HorizSpin.SetValue 999
				ENDIF
			
			CASE ParamDialog.VertSpin.GetID()
				IF (ParamDialog.VertSpin.GetValue() < -999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue -999
				ELSEIF (ParamDialog.VertSpin.GetValue() > 999) THEN
				   	MsgReturn& = MESSAGEBOX("Digite um valor de deslocamento " + \\
                                       		    "vertical entre -999 e 999.", \\
                                                 TITLE_INFOBOX$, MB_INFORMATION_ICON&)
					ParamDialog.VertSpin.SetValue 999
				ENDIF
			
		END SELECT
	
	ENDIF

END SUB

'********************************************************************
'
'	Name:	AnythingChanged (dialog function)
'
'	Action:	Checks whether the user has changed any options
'              since the last time a drop shadow was applied.
'              If any options have indeed changed, update
'              the bank of Old* variables.
'
'	Params:	None.  As this is intended to be a dialog function,
'              it makes use of all variables global to ParamDialog.
'
'	Returns:	None.
'
'	Comments: None.
'
'********************************************************************
FUNCTION AnythingChanged() AS BOOLEAN

	DIM AnyDifference AS BOOLEAN ' Any difference detected so far?

	' Perform a quick check for debugging purposes.
	IF FirstTime THEN
		MESSAGE "Contexto de chamada inválido"
	ENDIF

	' Compare current dialog settings to previous ones.
	IF OldRed% <> Red% THEN
		AnyDifference = TRUE
		OldRed% = Red%
	ENDIF
	IF OldGreen% <> Green% THEN
		AnyDifference = TRUE
		OldGreen% = Green%
	ENDIF
	IF OldBlue% <> Blue% THEN
		AnyDifference = TRUE
		OldBlue% = Blue%
	ENDIF
	IF OldShadowCheck <> ParamDialog.ShadowCheck.GetValue() THEN
		AnyDifference = TRUE
		OldShadowCheck = ParamDialog.ShadowCheck.GetValue()
	ENDIF
	IF OldPercent& <> ParamDialog.PercentSpin.GetValue() THEN
		AnyDifference = TRUE
		OldPercent& = ParamDialog.PercentSpin.GetValue()
	ENDIF
	IF OldHorizOffset& <> ParamDialog.HorizSpin.GetValue() THEN
		AnyDifference = TRUE
		OldHorizOffset& = ParamDialog.HorizSpin.GetValue()
	ENDIF
	IF OldVertOffset& <> ParamDialog.VertSpin.GetValue() THEN
		AnyDifference = TRUE
		OldVertOffset& = ParamDialog.VertSpin.GetValue()
	ENDIF
	IF OldHorizUnit% <> ParamDialog.HorizListBox.GetSelect() THEN
		AnyDifference = TRUE
		OldHorizUnit% = ParamDialog.HorizListBox.GetSelect()
	ENDIF
	IF OldVertUnit% <> ParamDialog.VertListBox.GetSelect() THEN
		AnyDifference = TRUE
		OldVertUnit% = ParamDialog.VertListBox.GetSelect()
	ENDIF

	' Return TRUE if anything changed.
	AnythingChanged = AnyDifference

END FUNCTION

'********************************************************************
'
'	Name:	ValidateInput (dialog function)
'
'	Action:	Checks whether all fields in ParamDialog are valid.
'              If one is found to be invalid, displays an error message.
'
'	Params:	None.  As this is intended to be a dialog function,
'              it makes use of all variables global to ParamDialog.
'
'	Returns:	TRUE if all fields are valid.  FALSE otherwise,
'              along with an error message.
'
'	Comments: None.
'
'********************************************************************
FUNCTION ValidateInput() AS BOOLEAN

	DIM MsgReturn AS LONG	' The result of a call to MESSAGEBOX.
	DIM AvailableX AS LONG	' The width of the page.
	DIM AvailableY AS LONG	' The height of the page.
	DIM MoveX AS LONG		' The size of the horizontal offset in Draw units.
	DIM MoveY AS LONG		' The size of the vertical offset in Draw units.
	DIM HorizUnit AS INTEGER	' The horizontal unit chosen by the user.
	DIM VertUnit AS INTEGER	' The vertical unit chosen by the user.
	DIM HorizOffset AS LONG	' The horizontal offset.
	DIM VertOffset AS LONG	' The vertical offset.

	' Validate the shadow percentage.
	IF ParamDialog.ShadowCheck.GetValue() THEN
		IF (ParamDialog.PercentSpin.GetValue() < 0) OR \\
             (ParamDialog.PercentSpin.GetValue() > 100) THEN
			
			MsgReturn& = MESSAGEBOX("Digite uma porcentagem " + \\
                                       "de transparência entre 0 e 100.", \\
                                       TITLE_ERRORBOX$, \\
                                       MB_OK_ONLY&)
			ValidateInput = FALSE
			EXIT FUNCTION

		ENDIF
	ENDIF

	' Validate the offsets.
	.GetPageSize AvailableX&, AvailableY&
	HorizOffset& = ParamDialog.HorizSpin.GetValue()
	VertOffset& = ParamDialog.VertSpin.GetValue()
	HorizUnit% = ParamDialog.HorizListbox.GetSelect()
	VertUnit% = ParamDialog.VertListbox.GetSelect() 
	
	SELECT CASE HorizUnit%
	
		CASE 1 ' 1 in.
			MoveX& = HorizOffset& * 1 *                \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
					 	        1)
		CASE 2 ' 1/36 in.
			MoveX& = HorizOffset& * (1/36) * \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 3 ' 0.001 in.
			MoveX& = HorizOffset& * 0.001 *            \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
					             1)
		CASE 4 ' 1 cm.
			MoveX& = HorizOffset& * 1 *                \\
				    LENGTHCONVERT(LC_CENTIMETERS,       \\
					 		   LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 5 ' 0.001 cm.
			MoveX& = HorizOffset& * 0.001 *            \\
				    LENGTHCONVERT(LC_CENTIMETERS,       \\
							   LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 6 ' 1 pt.
			MoveX& = HorizOffset& * 1 *                \\
				    LENGTHCONVERT(LC_POINTS,            \\
					 		   LC_TENTHS_OFA_MICRON, \\
							   1)

	END SELECT
	SELECT CASE VertUnit%
	
		CASE 1 ' 1 in.
			MoveY& = VertOffset& * 1 *                 \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
					  		   1)
		CASE 2 ' 1/36 in.
			MoveY& = VertOffset& * (1/36) *            \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 3 ' 0.001 in.
			MoveY& = VertOffset& * 0.001 *             \\
				    LENGTHCONVERT(LC_INCHES,            \\
					             LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 4 ' 1 cm.
			MoveY& = VertOffset& * 1 *                 \\
				    LENGTHCONVERT(LC_CENTIMETERS,       \\
							   LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 5 ' 0.001 cm.
			MoveY& = VertOffset& * 0.001 *             \\
				    LENGTHCONVERT(LC_CENTIMETERS,       \\
					 		   LC_TENTHS_OFA_MICRON, \\
							   1)
		CASE 6 ' 1 pt.
			MoveY& = VertOffset& * 1 *                 \\
				    LENGTHCONVERT(LC_POINTS,            \\
					 		   LC_TENTHS_OFA_MICRON, \\
							   1)

	END SELECT
	
	' Complain if the shadow will be very far off the page.
	' (The legal area works out to be about twice the page size.)
	IF (ABS(MoveX&) > (AvailableX& / 2)) OR (ABS(MoveY&) > (AvailableY& / 2)) THEN
		MsgReturn& = MESSAGEBOX("Você irá muito além da página com os valores que selecionou." + \\
		        			    NL2 + "Defina valores menores para os deslocamentos e tente outra vez.", \\
						    TITLE_INFOBOX$, MB_EXCLAMATION_ICON%)
		ValidateInput = FALSE
		EXIT FUNCTION
	ENDIF
	
	' Return TRUE.
	ValidateInput = TRUE

END FUNCTION

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS LONG		' The return value of various routines.
DIM Selection AS BOOLEAN		' Whether any object is selected in draw.
DIM Valid AS BOOLEAN		' Whether the user's input was valid.
DIM RememberToUngroup AS BOOLEAN	' Whether we performed a group.

' Set up a general error handler.
ON ERROR GOTO MainErrorHandler

' Check to see whether anything is selected in DRAW.
IF NOT CheckForSelection() THEN
	MessageText$ = "Selecione um objeto (ou vários objetos) no " + \\
                    "CorelDRAW antes de executar o Marcador de Sombra." + \\
                    NL2 + "O efeito de sombra será aplicado aos " + \\
                    "objetos selecionados."
	GenReturn& = MESSAGEBOX(MessageText$, TITLE_INFOBOX$, \\
	                        MB_OK_ONLY& OR MB_INFORMATION_ICON&)
	STOP
ENDIF

' Prepare CorelDRAW for the shadowing operation by grouping
' the original selection.
ON ERROR RESUME NEXT
IF .GetObjectType() <> DRAW_OBJECT_TYPE_GROUP% THEN
	ERRNUM = 0
	.Group
	RememberToUngroup = TRUE
ELSE
	ERRNUM = 0
	RememberToUngroup = FALSE
ENDIF
ON ERROR GOTO MainErrorHandler
IDOriginal& = .GetObjectsCDRStaticID()

' Interact with the user.
GenReturn& = DIALOG(ParamDialog)

' Select the original object(s) and remove the grouping.
' If the user has deleted the original object(s), then do not complain.
ON ERROR RESUME NEXT
.SelectObjectOfCDRStaticID IDOriginal&
ERRNUM = 0
IF RememberToUngroup THEN
	IF .GetObjectType() = DRAW_OBJECT_TYPE_GROUP% THEN
		ERRNUM = 0
		.Ungroup
	ENDIF
ENDIF
ERRNUM = 0

VeryEnd:
	STOP

MainErrorHandler:
	ERRNUM = 0
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processamento do Marcador de Sombra." + NL2
	MessageText$ = MessageText$ + "Tente outra vez."
	GenReturn& = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
	RESUME AT VeryEnd
	
ErrorNoDrawHandler:
	' Failed to create the automation object.
	ERRNUM = 0
	GenReturn = MESSAGEBOX( "Impossível localizar o CorelDRAW."+NL2+\\
					    "Se este erro continuar, poderá "+ \\
					    "ser necessário reinstalar "+      \\
					    "o CorelDRAW.",				 \\
       				    TITLE_ERRORBOX,				 \\
					    MB_OK_ONLY& OR MB_STOP_ICON& )
	RESUME AT VeryEnd

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
'	Name:	RemoveObject (function)
'
'	Action:	Removes a specific object in CorelDRAW given its
'              CDRStaticID.
'
'	Params:	InCDRStaticID -- the ID of the object to remove
'
'	Returns:	If the object is found, deletes it and returns TRUE.
'              Otherwise returns FALSE.
'
'	Comments: None.
'
'********************************************************************
FUNCTION RemoveObject( InCDRStaticID AS LONG ) AS BOOLEAN
	
	ON ERROR GOTO RONotFoundError

	.SelectObjectOfCDRStaticID InCDRStaticID&
	.DeleteObject

	RemoveObject = TRUE

	ExitPart:
		EXIT FUNCTION

RONotFoundError:
	' The given object was not found.
	ERRNUM = 0
	RemoveObject = FALSE
	RESUME AT ExitPart

END FUNCTION

'********************************************************************
'
'	Name:	StillThere (function)
'
'	Action:	Checks to see if an object still exists in Draw,
'              given its CDRStaticID.
'
'	Params:	InCDRStaticID -- the ID of the object to look for.
'
'	Returns:	If the object is found, returns TRUE.
'              Otherwise returns FALSE.
'
'	Comments: None.
'
'********************************************************************
FUNCTION StillThere( InCDRStaticID AS LONG ) AS BOOLEAN
	
	
	DIM CurSelectedID AS LONG
	
	ON ERROR RESUME NEXT
	CurSelectedID& = .GetObjectsCDRStaticID()
	IF ERRNUM <> 0 THEN
		ERRNUM = 0
		CurSelectedID& = 0
	ENDIF
		
	ON ERROR GOTO STNotFoundError

	IF CurSelectedID = InCDRStaticID THEN
		' The desired object is already selected.
	ELSE
		' We need to select the object.
		.SelectObjectOfCDRStaticID InCDRStaticID&
		CurSelectedID& = .GetObjectsCDRStaticID()
		IF CurSelectedID& <> InCDRStaticID& THEN
			StillThere = FALSE
			EXIT FUNCTION
		ENDIF
	ENDIF

	StillThere = TRUE

	STExitPart:
		EXIT FUNCTION

STNotFoundError:
	' The given object was not found.
	ERRNUM = 0
	StillThere = FALSE
	RESUME AT STExitPart

END FUNCTION

'********************************************************************
'
'	Name:	WarnUser (subroutine)
'
'	Action:	Displays a message box warning the user not to
'              interfere with this program's operation.
'
'	Params:	None.
'
'	Returns:	None.
'
'	Comments: None.
'
'********************************************************************
SUB WarnUser()

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.
	MsgReturn& = MESSAGEBOX( "Impossível localizar a última sombra criada." \\
                              + NL2 + "Não interfica na " \\
                              + "operação do Marcador de Sombra " \\
                              + "excluindo objetos criados por ele."+ NL2 \\
                              + "O Marcador de Sombra executará sozinho " \\
                              + "todos os passos necessários.", \\
                              TITLE_INFOBOX$, \\
                              MB_INFORMATION_ICON& )

END SUB

'********************************************************************
'
'	Name:	WarnUserOriginal (subroutine)
'
'	Action:	Displays a message box warning the user not to
'              interfere with this program's operation.
'
'	Params:	None.
'
'	Returns:	None.
'
'	Comments: None.
'
'********************************************************************
SUB WarnUserComplete()

	DIM MsgReturn AS LONG	' The return value of MESSAGEBOX.
	MsgReturn& = MESSAGEBOX( "Impossível localizar o objeto que " + \\
                              "estava selecionado quando você iniciou o " + \\
                              "Marcador de Sombra pela primeira vez." + NL2 + \\
                              "Se você excluiu o objeto ou o combinou com outro " + \\
                              "objeto utilizando um recurso como a ferramenta Soldar," + NL + "evite " + \\
                              "fazer isso novamente no futuro, " +\\
                              "pois o Marcador de Sombra " + \\
                              "se encarrega de todas" + NL + "as operações necessárias " + \\
                              "automaticamente." + NL2 + \\
                              "O Marcador de Sombra está sendo desativado.", \\
                              TITLE_ERRORBOX$, \\
                              MB_STOP_ICON& )

END SUB

'********************************************************************
'
'	Name:	ApplyEffect (subroutine)
'
'	Action:	Duplicates the object that has a CDRStaticID of InID
'              and places the duplicate behind the original.  
'              Positions the duplicate relative to the original
'              as determined by InHorizOffset, InVertOffset,
'              InVertUnit, and InHorizUnit.  Applies a colour to
'              the duplicate and optionally makes it transparent.
'
'	Params:	InID - the CDRStaticID of an object to duplicate
'			InRed - the red component (RGB) of the color to apply
'              InGreen - the green component (RGB) of the color to apply
'              InBlue - the blue component (RGB) of the color to apply
'              InMakeTransparent - should the shadow be transparent?
'              InPercent - if transparent, by how much (0% is opaque,
'                          and 100% is wholly transparent)
'              InHorizOffset - the horizontal offset for the shadow
'              InVertOffset - the vertical offset for the shadow
'              InHorizUnit - what unit is specified by InHorizOffset?
'              InVertUnit - what unit is specified by InVertUnit?
'                           (the constants refer to the same units as
'                            UnitsArray)
'
'	Returns:	The CDRStaticID of the duplicate object (the shadow).
'
'	Comments: If InID is not found, displays an error message and 
'              stops the script.
'
'********************************************************************
FUNCTION ApplyEffect( InID AS LONG, \\
                      InRed AS INTEGER, \\
                      InGreen AS INTEGER, \\
                      InBlue AS INTEGER, \\
                      InMakeTransparent AS BOOLEAN, \\
                      InPercent AS INTEGER, \\
                      InHorizOffset AS LONG, \\
                      InVertOffset AS LONG, \\
                      InHorizUnit AS INTEGER, \\
                      InVertUnit AS INTEGER) AS LONG

	DIM IDCopied AS LONG	' The CDRStaticID of the shadow group.
	DIM InitialXPos AS LONG  ' The specified object's X coordinate.
	DIM InitialYPos AS LONG  ' The specified object's Y coordinate.
	DIM NewXPos AS LONG	     ' The shadow group's X coordinate.
	DIM NewYPos AS LONG	     ' The shadow group's Y coordinate.
	DIM Cyan AS LONG		' The provided color converted to CMYK.
	DIM Magenta AS LONG		' The provided color converted to CMYK.
	DIM Yellow AS LONG		' The provided color converted to CMYK.
	DIM Black AS LONG		' The provided color converted to CMYK.
	
	ON ERROR GOTO AENotFoundError

	' Make a duplicate of the specified object, remembering
	' the original position.
	.SelectObjectOfCDRStaticID InID&
	.GetPosition InitialXPos&, InitialYPos&
	.DuplicateObject
	
	' Store the duplicate's CDRStaticID.
	IDCopied& = .GetObjectsCDRStaticID()
	
	' Determine where the new object should go.
	SELECT CASE InHorizUnit%
	
		CASE 1 ' 1 in.
			NewXPos& = InitialXPos& +                      \\
                               InHorizOffset& * 1 *                \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 2 ' 1/36 in.
			NewXPos& = InitialXPos& +                      \\
                               InHorizOffset& * (1/36) *           \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 3 ' 0.001 in.
			NewXPos& = InitialXPos& +                      \\
                               InHorizOffset& * 0.001 *            \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 4 ' 1 cm.
			NewXPos& = InitialXPos& +                      \\
					 InHorizOffset& * 1 *                \\
					 LENGTHCONVERT(LC_CENTIMETERS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 5 ' 0.001 cm.
			NewXPos& = InitialXPos& +                       \\
					 InHorizOffset& * 0.001 *            \\
					 LENGTHCONVERT(LC_CENTIMETERS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 6 ' 1 pt.
			NewXPos& = InitialXPos& +                      \\
					 InHorizOffset& * 1 *                \\
					 LENGTHCONVERT(LC_POINTS,            \\
								LC_TENTHS_OFA_MICRON, \\
								1)

	END SELECT
	SELECT CASE InVertUnit%
	
		CASE 1 ' 1 in.
			NewYPos& = InitialYPos& +                      \\
                               InVertOffset& * 1 *                 \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 2 ' 1/36 in.
			NewYPos& = InitialYPos& +                      \\
                               InVertOffset& * (1/36) *            \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 3 ' 0.001 in.
			NewYPos& = InitialYPos& +                      \\
                               InVertOffset& * 0.001 *             \\
					 LENGTHCONVERT(LC_INCHES,            \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 4 ' 1 cm.
			NewYPos& = InitialYPos& +                      \\
					 InVertOffset& * 1 *                 \\
					 LENGTHCONVERT(LC_CENTIMETERS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 5 ' 0.001 cm.
			NewYPos& = InitialYPos& +                      \\
					 InVertOffset& * 0.001 *             \\
					 LENGTHCONVERT(LC_CENTIMETERS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 6 ' 1 pt.
			NewYPos& = InitialYPos& +                      \\
					 InVertOffset& * 1 *                 \\
					 LENGTHCONVERT(LC_POINTS,            \\
								LC_TENTHS_OFA_MICRON, \\
								1)

	END SELECT

	' Put the new object where it should go.
	.SetPosition NewXPos&, NewYPos&
	.OrderBackOne

	' Apply the appropriate shadow color.
	.ApplyUniformFillColor DRAW_COLORMODEL_RGB&, InRed%, \\
                                 InGreen%, InBlue%, 0

	' We do not want an outline on the shadow.
	.ApplyOutline 0, \\
	              DRAW_OUTLINE_TYPE_NONE&, \\
	              DRAW_OUTLINE_CAPS_BUTT&, \\
	              DRAW_OUTLINE_JOIN_MITER&, \\
	              100, \\
	              0, \\
	              0, \\
	              0, \\
	              0, \\
	              FALSE
						
	' If the shadow should be transparent, make it so.
	IF InMakeTransparent THEN
		
		' To illustrate the use of ConvertColor, we
		' will convert our input colors to CMYK.
		.ConvertColor DRAW_COLORMODEL_RGB&, \\
		              InRed%, \\
		              InGreen%, \\
		              InBlue%, \\
		              0, \\
		              DRAW_COLORMODEL_CMYK255&, \\
		              Cyan&, \\
		              Magenta&, \\
		              Yellow&, \\
		              Black&
	
		.ApplyLensEffect DRAW_TAB_AVERAGE&, \\
                           FALSE, \\
                           FALSE, \\
                           FALSE, \\
                           0, \\
                           0, \\
                           1000 - (InPercent% * 10), \\
					  DRAW_COLORMODEL_CMYK255&, \\
                           Cyan&, Magenta&, Yellow&, Black&

		' Since we've already set the color, the
		' other parameters of ApplyLensEffect do
		' not need to be provided.			

	ENDIF

	' Return the CDRStaticID of the shadow group.
	ApplyEffect& = IDCopied&

	ExitPart:
		EXIT FUNCTION

	StopPart:
		STOP

AENotFoundError:
	' The given object was not found.
	ERRNUM = 0
	DIM MsgReturn AS LONG  ' The result of a MESSAGEBOX call.
	MsgReturn& = MESSAGEBOX( "Impossível localizar o objeto que " + \\
                              "estava selecionado quando você iniciou o " + \\
                              "Marcador de Sombra pela primeira vez." + NL2 + \\
                              "Se você excluiu o objeto, evite " + \\
                              "fazer isso novamente no futuro, " +\\
                              "pois o Marcador de Sombra " + \\
                              "se encarrega automaticamente de todas as operações de " + \\
                              "exclusão de objetos necessárias." + NL2 + \\
                              "O Marcador de Sombra está sendo desativado.", \\
                              TITLE_ERRORBOX$, \\
                              MB_STOP_ICON& )
	RESUME AT StopPart

END FUNCTION

END WITHOBJECT
