REM Duplica ou clona repetidamente
REM o objeto atualmente selecionado.

'********************************************************************
' 
'   Script:	Replica.csc
' 
'   Copyright 1996 Corel Corporation.  All rights reserved.
' 
'   Description: CorelDRAW script to repeatedly duplicate or
'                clone the currently selected object.
' 
'********************************************************************

#addfol  "..\..\..\Scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"

'/////FUNCTION & SUBROUTINE DECLARATIONS/////////////////////////////
DECLARE FUNCTION CheckForSelection() AS BOOLEAN
DECLARE FUNCTION ValidateInput(OperationType AS INTEGER,		\\
				   		 BYREF Reps AS INTEGER,			\\
				   		 BYREF Horiz AS INTEGER,			\\
				   		 BYREF Vert AS INTEGER,			\\
				   		 HorizUnit AS INTEGER,			\\
				   		 VertUnit AS INTEGER) AS BOOLEAN
DECLARE SUB DoOperation(OperationType AS INTEGER,				\\
		      	    Reps AS INTEGER,					\\
			 	    Horiz AS INTEGER,					\\
			 	    Vert AS INTEGER,					\\
			 	    HorizUnit AS INTEGER,		     	\\
			 	    VertUnit AS INTEGER)

'/////GLOBAL VARIABLES & CONSTANTS///////////////////////////////////
GLOBAL CONST OPERATION_DUPLICATE% = 0
GLOBAL CONST OPERATION_CLONE%     = 1
GLOBAL CONST TITLE_ERRORBOX$      = "Erro de Replicação de Script"
GLOBAL CONST TITLE_INFOBOX$       = "Informações de Replicação de Scripts"
GLOBAL NL AS STRING	     ' These must be declared as 
GLOBAL NL2 AS STRING     ' variables, not constants, because
NL$ = CHR(10) + CHR(13)	' we cannot assign expressions
NL2$ = NL + NL	     	' to constants.

' Constants for dialog return values.
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2

'/////OPTIONS DIALOG/////////////////////////////////////////////////

' The array of possible units the user may select from.
DIM UnitsArray(6) AS STRING
UnitsArray(1) = "1 cm."
UnitsArray(2) = "0,001 cm."
UnitsArray(3) = "1 pt."
UnitsArray(4) = "1 pol."
UnitsArray(5) = "1/36 pol."
UnitsArray(6) = "0,001 pol."


' Set defaults for the dialog.
DIM OperationType AS INTEGER		' Duplicar ou clonar?
DIM Reps AS INTEGER				' Repetir quantas vezes?
DIM Horiz AS INTEGER			' Deslocalmento horizontal.
DIM Vert AS INTEGER				' Deslocalmento vertical.
DIM HorizUnit AS INTEGER			' Unidades de deslocamento horizontal.
DIM VertUnit  AS INTEGER			' Unidades de deslocamento vertical.
OperationType% = OPERATION_DUPLICATE%
Reps% = 3
Horiz% = 2
Vert% = 2
HorizUnit% = 1
VertUnit%  = 1

' This is the main options dialog.
BEGIN DIALOG OptionsDialog 207, 182, "Opções de Replicação"
	TEXT  10, 6, 175, 31, "Este script repetidamente duplica ou clona o objeto selecionado atualmente."
	OKBUTTON  47, 161, 50, 13
	CANCELBUTTON  107, 161, 50, 13
	OPTIONGROUP OperationType%
		OPTIONBUTTON  24, 42, 50, 15, "Duplicar"
		OPTIONBUTTON  24, 60, 40, 10, "Clonar"
	GROUPBOX  12, 90, 185, 60, "Posicionar duplicatas e clones"
	SPINCONTROL  132, 52, 54, 12, Reps%
	SPINCONTROL  66, 108, 54, 12, Horiz%
	DDLISTBOX  132, 108, 54, 197, UnitsArray$, HorizUnit%
	SPINCONTROL  66, 126, 54, 12, Vert%
	DDLISTBOX  132, 126, 54, 178, UnitsArray$, VertUnit%
	TEXT  24, 110, 35, 11, "Horizontal:"
	TEXT  24, 127, 35, 10, "Vertical:"
	GROUPBOX  12, 30, 186, 48, "Operação"
	TEXT  100, 54, 28, 12, "Quantos"
	TEXT  124, 109, 6, 11, "x"
	TEXT  124, 127, 6, 11, "x"
	TEXT  116, 163, 39, 9, "Cancelar"
END DIALOG

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS INTEGER		' The return value of various routines.
DIM Selection AS BOOLEAN		' Whether any object is selected in draw.
DIM Valid AS BOOLEAN		' Whether the user's options were valid.

' Check to see if CorelDRAW's automation object is available.
ON ERROR RESUME NEXT
WITHOBJECT OBJECT_DRAW
	IF (ERRNUM > 0) THEN
		' Failed to create the automation object.
		ERRNUM = 0
		GenReturn = MESSAGEBOX( "Impossível localizar o CorelDRAW."+NL2+\\
						    "Se este erro continuar, poderá "+ \\
						    "ser necessário reinstalar o "+      \\
						    "CorelDRAW.",				 \\
       					    TITLE_ERRORBOX,				 \\
						    MB_OK_ONLY )
		STOP
	ENDIF

' Set up a general error handler.
ON ERROR GOTO MainErrorHandler

' Check whether anything is selected.
Selection = CheckForSelection() 

IF NOT Selection THEN
	MessageText$ = "Antes de executar este script, "
	MessageText$ = MessageText$ + "selecione um objeto a ser replicado ou clonado."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_INFOBOX$, \\
	                        MB_OK_ONLY& OR MB_INFORMATION_ICON&)
	STOP
ENDIF

' Display the user-interface dialog.
DO

	GenReturn = DIALOG(OptionsDialog)
	SELECT CASE GenReturn

		CASE DIALOG_RETURN_OK
			Valid = ValidateInput(OperationType%,			\\
						       Reps%, 					\\
							  Horiz%,					\\
							  Vert%,					\\
							  HorizUnit%,				\\
							  VertUnit%)
			
		CASE DIALOG_RETURN_CANCEL
			STOP

		CASE ELSE
			FAIL ERR_USER_FIRST

	END SELECT

LOOP UNTIL Valid

' Perform the main processing.
DoOperation OperationType, Reps, Horiz, Vert, HorizUnit, VertUnit
STOP

MainErrorHandler:
	ERRNUM = 0
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processo de replicação." + NL2
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
'	Params:	None
'
'	Returns:	TRUE if an object is currently selected;  FALSE
'            otherwise.
'
'	Comments:	Never raises any errors. 
'
'********************************************************************
FUNCTION CheckForSelection AS BOOLEAN

	DIM ObjType AS LONG	 ' The currently selected object type.
	
	ON ERROR RESUME NEXT
	ObjType& = .GetObjectType()
	IF (ObjType& <= 0) OR (ERRNUM > 0) THEN
		ERRNUM = 0
		CheckForSelection = FALSE
	ELSE
		CheckForSelection = TRUE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	ValidateInput (function)
'
'	Action:	Checks whether the options the user entered make 
'              sense.
'
'	Params:	OperationType - Clone or duplicate?
'			Reps          - The number of repetitions.
'			Horiz         - The Horizontal offset distance.
'			Vert          - The vertical offset distance.
'			HorizUnit     - What unit is Horiz?
'			VertUnit      - What unit is Vert? 
'
'	Returns:	TRUE if the input makes sense, FALSE otherwise.
'
'	Comments:	Never raises any errors.
'              Does not ensure that all numbers are perfectly
'              valid (ie. Horiz may take the object off the page),
'              only that they are sane (ie. Reps is positive).
'
'********************************************************************
FUNCTION ValidateInput(OperationType AS INTEGER,				\\
				   BYREF Reps AS INTEGER,				\\
				   BYREF Horiz AS INTEGER,				\\
				   BYREF Vert AS INTEGER,				\\
				   HorizUnit AS INTEGER,					\\
				   VertUnit AS INTEGER) AS BOOLEAN

	DIM ReturnVal% AS INTEGER	' The return value of MESSAGEBOX.
	DIM AvailableX AS LONG		' The page width.
	DIM AvailableY AS LONG		' The page height.
	DIM FinalX AS LONG			' The final x position.
	DIM FinalY AS LONG			' The final y position.
	
	' This error handler ensures no error will ever propagate
	' out of this function.
	ON ERROR GOTO VIGeneralError
	
	' Check if Reps is positive.
	IF (Reps% < 1) THEN
		ReturnVal% = MESSAGEBOX("Você solicitou "+CSTR(Reps) + \\
                              " repetições.  Este não é um número "+ \\
                              "válido."+NL2+"Tente outra vez, "   + \\
                              "lembrando de escolher um número "    + \\
                              "maior que 0.", TITLE_ERRORBOX$,    \\
                              MB_OK_ONLY)
		Reps% = 1
		ValidateInput = FALSE
		EXIT FUNCTION
	ELSEIF (Reps% >= 32767) THEN
		ReturnVal% = MESSAGEBOX("Você solicitou um número muito grande de repetições." + \\
		                        NL + "Este número é grande demais." + NL2 + \\
						    "Tente outra vez, lembrando de escolher " + \\
						    "um número inferior a 100.", TITLE_ERRORBOX$, \\
						    MB_OK_ONLY)
		Reps% = 99
		ValidateInput = FALSE
		EXIT FUNCTION
	ELSEIF (Reps% > 99) THEN
		ReturnVal% = MESSAGEBOX("Você solicitou " + CSTR(Reps) + \\
						    " repetições.  Este número é grande demais." + NL2 + \\
						    "Tente outra vez, lembrando de escolher " + \\
						    "um número inferior a 100.", TITLE_ERRORBOX$, \\
						    MB_OK_ONLY)
		Reps% = 99
		ValidateInput = FALSE
		EXIT FUNCTION
	ENDIF

	' Check the range of Horiz.
	IF (ABS(Horiz%) > 999) THEN
		ReturnVal% = MESSAGEBOX("Você digitou um número grande demais ou pequeno demais" + NL + \\
		                        "para o deslocamento horizontal." + NL2 + \\
		                        "Os valores válidos estão entre -999 e 999." + NL + \\
						    "Tente outra vez, lembrando de escolher " + \\
						    "um número nessa faixa.", TITLE_ERRORBOX$, \\
						    MB_OK_ONLY)
		Horiz% = 0
		IF (ABS(Vert%) > 999) THEN
			Vert% = 0
		ENDIF
		ValidateInput = FALSE
		EXIT FUNCTION
	ENDIF

	' Check the range of Vert.
	IF (ABS(Vert%) > 999) THEN
		ReturnVal% = MESSAGEBOX("Você digitou um número grande demais ou pequeno demais" + NL + \\
		                        "para o deslocamento vertical." + NL2 + \\
		                        "Os valores válidos estão entre -999 e 999." + NL + \\
						    "Tente outra vez, lembrando de escolher " + \\
						    "um número" + NL + "nessa faixa.", TITLE_ERRORBOX$, \\
						    MB_OK_ONLY)
		Vert% = 0
		IF (ABS(Horiz%) > 999) THEN
			Vert% = 0
		ENDIF
		ValidateInput = FALSE
		EXIT FUNCTION
	ENDIF

	' Check the range.
	.GetPageSize AvailableX&, AvailableY&
	
	' Make sure we're never going off the page.
	SELECT CASE HorizUnit%
	
		CASE 1 ' 1 in.
			FinalX& = Horiz% * Reps% * 1 * \\
					 LENGTHCONVERT(LC_INCHES, \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 2 ' 1/36 in.
			FinalX& = Horiz% * Reps% * (1/36) *   \\
					 LENGTHCONVERT(LC_INCHES,       \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 3 ' 0.001 in.
			FinalX& = Horiz% * Reps% * 0.001 *    \\
					 LENGTHCONVERT(LC_INCHES,       \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 4 ' 1 cm.
			FinalX& = Horiz% * Reps% * 1 *        \\
					 LENGTHCONVERT(LC_CENTIMETERS,  \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 5 ' 0.001 cm.
			FinalX& = Horiz% * Reps% * 0.001 *    \\
					 LENGTHCONVERT(LC_CENTIMETERS,  \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 6 ' 1 pt.
			FinalX& = Horiz% * Reps% * 1 *        \\
					 LENGTHCONVERT(LC_POINTS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)

	END SELECT
	SELECT CASE VertUnit%
	
		CASE 1 ' 1 in.
			FinalY& = Vert% * Reps% * 1 *         \\
					 LENGTHCONVERT(LC_INCHES,       \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 2 ' 1/36 in.
			FinalY& = Vert% * Reps% * (1/36) *    \\
					 LENGTHCONVERT(LC_INCHES,       \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 3 ' 0.001 in.
			FinalY& = Vert% * Reps% * 0.001 * \\
					 LENGTHCONVERT(LC_INCHES,       \\
					               LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 4 ' 1 cm.
			FinalY& = Vert% * Reps% * 1 *         \\
					 LENGTHCONVERT(LC_CENTIMETERS,  \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 5 ' 0.001 cm.
			FinalY& = Vert% * Reps% * 0.001 *     \\
					 LENGTHCONVERT(LC_CENTIMETERS,  \\
								LC_TENTHS_OFA_MICRON, \\
								1)
		CASE 6 ' 1 pt.
			FinalY& = Vert% * Reps% * 1 *         \\
					 LENGTHCONVERT(LC_POINTS,       \\
								LC_TENTHS_OFA_MICRON, \\
								1)

	END SELECT

	IF (FinalX& > AvailableX&) OR (FinalY& > AvailableY&) THEN
		ReturnVal% = MESSAGEBOX("Você excederá muito a página com os valores que selecionou." + \\
		        			    NL2 + "Selecione um número menor de repetições ou deslocamentos menores e tente outra vez.", \\
						    TITLE_ERRORBOX$, MB_OK_ONLY)
		ValidateInput = FALSE
		EXIT FUNCTION
	ENDIF

	ValidateInput = TRUE
	
	VI_End:
	EXIT FUNCTION
	
VIGeneralError:
	ERRNUM = 0
	ValidateInput = FALSE
	RESUME AT VI_End

END FUNCTION

'********************************************************************
'
'	Name:	DoOperation (subroutine)
'
'	Action:	Actually performs the multiple duplication or cloning
'              operation.
'
'	Params:	OperationType - Clone or duplicate?
'			Reps          - The number of repetitions.
'			Horiz         - The Horizontal offset distance.
'			Vert          - The vertical offset distance.
'			HorizUnit     - What unit is Horiz?
'			VertUnit      - What unit is Vert? 
'
'	Returns:	Nothing.
'
'	Comments:	Propagates any errors encountered, so it would
'              be wise to call this subroutine within an error-
'              handling block.
'
'********************************************************************
SUB DoOperation(OperationType AS INTEGER,					\\
		      Reps AS INTEGER,							\\
			 Horiz AS INTEGER,							\\
			 Vert AS INTEGER,							\\
			 HorizUnit AS INTEGER,						\\
			 VertUnit AS INTEGER)

	DIM InitialXPos AS LONG ' The selected object(s)' X coordinate.
	DIM InitialYPos AS LONG ' The selected object(s)' Y coordinate.
	DIM NewXPos AS LONG	    ' The clone/duplicate's X coordinate.
	DIM NewYPos AS LONG	    ' The clone/duplicate's Y coordinate.
	DIM Counter AS INTEGER  ' A counter variable for loops.	
		
	.GetPosition InitialXPos&, InitialYPos&
	
	FOR Counter% = 1 TO Reps

		' Clone or duplicate.
		IF (OperationType% = OPERATION_DUPLICATE) THEN
			.DuplicateObject
		ELSE ' Clone.
			.CloneObject
		ENDIF

		' Determine where the new object should go.
		SELECT CASE HorizUnit
		
			CASE 1 ' 1 in.
				NewXPos& = InitialXPos& +                 \\
                                    Horiz% * Counter% * 1 *        \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 2 ' 1/36 in.
				NewXPos& = InitialXPos& +                 \\
                                    Horiz% * Counter% * (1/36) *   \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 3 ' 0.001 in.
				NewXPos& = InitialXPos& +                 \\
                                    Horiz% * Counter% * 0.001 *    \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 4 ' 1 cm.
				NewXPos& = InitialXPos& +                 \\
						 Horiz% * Counter% * 1 *        \\
						 LENGTHCONVERT(LC_CENTIMETERS,  \\
									LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 5 ' 0.001 cm.
				NewXPos& = InitialXPos& +                 \\
						 Horiz% * Counter% * 0.001 *    \\
						 LENGTHCONVERT(LC_CENTIMETERS,  \\
									LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 6 ' 1 pt.
				NewXPos& = InitialXPos& +                 \\
						 Horiz% * Counter% * 1 *        \\
						 LENGTHCONVERT(LC_POINTS,       \\
									LC_TENTHS_OFA_MICRON, \\
									1)

		END SELECT
		SELECT CASE VertUnit
		
			CASE 1 ' 1 in.
				NewYPos& = InitialYPos& +                 \\
                                    Vert% * Counter% * 1 *         \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 2 ' 1/36 in.
				NewYPos& = InitialYPos& +                 \\
                                    Vert% * Counter% * (1/36) *    \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 3 ' 0.001 in.
				NewYPos& = InitialYPos& +                 \\
                                    Vert% * Counter% * 0.001 *     \\
						 LENGTHCONVERT(LC_INCHES,       \\
						               LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 4 ' 1 cm.
				NewYPos& = InitialYPos& +                 \\
						 Vert% * Counter% * 1 *         \\
						 LENGTHCONVERT(LC_CENTIMETERS,  \\
									LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 5 ' 0.001 cm.
				NewYPos& = InitialYPos& +                 \\
						 Vert% * Counter% * 0.001 *     \\
						 LENGTHCONVERT(LC_CENTIMETERS,  \\
									LC_TENTHS_OFA_MICRON, \\
									1)
			CASE 6 ' 1 pt.
				NewYPos& = InitialYPos& +                 \\
						 Vert% * Counter% * 1 *         \\
						 LENGTHCONVERT(LC_POINTS,       \\
									LC_TENTHS_OFA_MICRON, \\
									1)

		END SELECT

		' Put the new object where it should go.
		.SetPosition NewXPos&, NewYPos&

	NEXT Counter

END SUB

END WITHOBJECT
