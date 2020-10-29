REM Assistente de Personalização de Modelos
REM 

'********************************************************************
' 
'   Script:	TempWiz.csc
' 
'   Copyright 1996 Corel Corporation.  Todos os direitos reservados.
' 
'   Description: Script do CorelDRAW que permite configurar o arquivo
'                TempWiz.  Permite que o usuário acrescente, renomeie
'                e remova os modelos da lista que o Draw apresenta
'                ao usuário quando um novo documento baseado em
'                modelo é criado.
' 
'********************************************************************

#addfol  "..\..\..\Scripts"
#include "ScpConst.csi"
#include "DrwConst.csi"
#define NL  CHR(10) + CHR(13)
#define NL2 CHR(10) + CHR(13) + CHR(10) + CHR(13)

'/////COMANDOS DE FUNÇÃO E SUBROTINA/////////////////////////////

' Funções do sistema.
DECLARE FUNCTION GetPrivateProfileString LIB "kernel32" (BYVAL lpApplicationName AS STRING, \\
											  BYVAL lpKeyName AS STRING, \\
											  BYVAL lpDefault AS STRING, \\
											  BYVAL lpReturnedString AS STRING, \\ 
											  BYVAL nSize AS LONG, \\
											  BYVAL lpFileName AS STRING) AS LONG ALIAS "GetPrivateProfileStringA" 
DECLARE FUNCTION GetPrivateProfileSection LIB "kernel32" (BYVAL lpAppName AS STRING, \\
											   BYVAL lpReturnedString AS STRING, \\
											   BYVAL nSize AS LONG, \\
											   BYVAL lpFileName AS STRING) AS LONG ALIAS "GetPrivateProfileSectionA" 
DECLARE FUNCTION GetPrivateProfileInt LIB "kernel32" (BYVAL lpApplicationName AS STRING, \\
										    BYVAL lpKeyName AS STRING, \\
										    BYVAL nDefault AS LONG, \\
										    BYVAL lpFileName AS STRING) AS LONG ALIAS "GetPrivateProfileIntA"
DECLARE FUNCTION WritePrivateProfileSection LIB "kernel32" (BYVAL lpAppName AS STRING, \\
												BYVAL lpString AS STRING, \\
												BYVAL lpFileName AS STRING) AS LONG ALIAS "WritePrivateProfileSectionA"
DECLARE FUNCTION WritePrivateProfileString LIB "kernel32" (BYVAL lpApplicationName AS STRING, \\
											    BYVAL lpKeyName AS STRING, \\
											    BYVAL lpString AS STRING, \\
											    BYVAL lpFileName AS STRING) AS LONG ALIAS "WritePrivateProfileStringA"
DECLARE FUNCTION WritePrivateProfileStringNULLS LIB "kernel32" (	BYVAL lpApplicationName AS LONG, \\
											  		BYVAL lpKeyName AS LONG, \\
											    		BYVAL lpString AS LONG, \\
											    		BYVAL lpFileName AS STRING) AS LONG ALIAS "WritePrivateProfileStringA"
DECLARE FUNCTION CreateDC LIB "gdi32" (BYVAL lpDriverName AS STRING, \\
                                       BYVAL lpDeviceName AS LONG, \\
                                       BYVAL lpOutput AS LONG, \\
                                       BYVAL lpInitData AS LONG) AS LONG ALIAS "CreateDCA"
DECLARE FUNCTION GetDeviceCaps LIB "gdi32" (BYVAL hDC AS LONG, \\
                                            BYVAL nIndex AS LONG) AS LONG ALIAS "GetDeviceCaps"
DECLARE FUNCTION DeleteDC LIB "gdi32" (BYVAL hDC AS LONG) AS LONG ALIAS "DeleteDC"

' Funções de extensão de script.
DECLARE FUNCTION EXTGetNumberOfEntries LIB "scpext" (BYVAL szSectionName AS STRING, BYVAL szFileName AS STRING) AS LONG ALIAS "EXTGetNumberOfEntries"
DECLARE FUNCTION EXTGetEntry LIB "scpext" (BYVAL lEntryIndex AS LONG, BYVAL szSectionName AS STRING, BYVAL szBuffer AS STRING, BYVAL lBufferSize AS LONG, BYVAL szFileName AS STRING) AS LONG ALIAS "EXTGetEntry"

' Funções de script.
DECLARE FUNCTION ReadSettings ( InFile AS STRING ) AS BOOLEAN
DECLARE FUNCTION BigEmptyString() AS STRING
DECLARE FUNCTION ExtractFirstItem ( BYREF Buffer AS STRING, \\
                                    BYREF BufferSize AS LONG ) AS STRING
DECLARE SUB GiveSizeWarning( InFile AS STRING )
DECLARE FUNCTION ExtractEqual( InString AS STRING ) AS STRING
DECLARE FUNCTION ReadCategories( InMaster AS STRING, \\
                                 InFile AS STRING ) AS BOOLEAN
DECLARE FUNCTION ReadSubCategories ( InCategory AS STRING, \\
		  			            InMaster AS STRING, \\
                                     InFile AS STRING ) AS BOOLEAN
DECLARE SUB UpdateSelectListBox()
DECLARE FUNCTION ConvertVisibleToDataIndex( VisibleIndex AS LONG ) AS LONG
DECLARE SUB ToggleOpen( DataIndex AS LONG )
DECLARE FUNCTION FindDuplicates( InString AS STRING, CurPD AS STRING ) AS BOOLEAN
DECLARE FUNCTION FindIllegalCharacters( InString AS STRING ) AS BOOLEAN
DECLARE SUB RenameItem( ItemNum AS LONG )
DECLARE SUB SetDisplayText( ItemNum AS LONG )
DECLARE SUB ReplaceAll( InNew AS STRING, InOld AS STRING, CurMaster AS STRING )
DECLARE FUNCTION WriteTemplateSettingsFile( OutFilePath AS STRING ) AS BOOLEAN
DECLARE SUB AddNewSubCategory( InCategory AS STRING, \\
                               InMaster AS STRING, \\
						 InChosenFile AS STRING )
DECLARE SUB AddCategoryUnder( ItemNum AS LONG )
DECLARE FUNCTION ExtractFileName ( FilePath AS STRING ) AS STRING
DECLARE FUNCTION AlreadyPresent ( FileName AS STRING ) AS BOOLEAN
DECLARE FUNCTION ExtractDirectory ( FilePath AS STRING ) AS STRING	
DECLARE SUB RemoveItem( ItemNum AS LONG )
DECLARE SUB AskForSelection()
DECLARE SUB ConvertDataToVisibleIndex( DataIndex AS LONG, BYREF VisibleIndex AS LONG, BYREF AlreadyVisible AS BOOLEAN )
DECLARE SUB UpdateSingle ( NumIndex AS LONG )
DECLARE FUNCTION GetNumVisible() AS LONG
DECLARE SUB UpdateEverythingAfter( ItemNum AS LONG )
DECLARE FUNCTION GetNumberOfDisplayColors( ) AS LONG

'/////COMANDOS DE CONSTANTES//////////////////////////////////////////

' Gráficos utilizados para a figura grande do assistente em cada quadro de diálogo.
GLOBAL BITMAP_INTRODIALOG AS STRING
GLOBAL BITMAP_CHOICEDIALOG AS STRING
GLOBAL BITMAP_SELECTDIALOG AS STRING
GLOBAL BITMAP_COMMITDIALOG AS STRING
GLOBAL BITMAP_ADDCHOICEDIALOG AS STRING
GLOBAL BITMAP_ADDFILEDIALOG AS STRING
DIM NumColors AS LONG
NumColors& = GetNumberOfDisplayColors()
IF NumColors& <= 256 THEN
	BITMAP_INTRODIALOG$     = "\TempCB16.bmp"
	BITMAP_CHOICEDIALOG$    = "\TempCB16.bmp"
	BITMAP_SELECTDIALOG$    = "\TempCB16.bmp"
	BITMAP_COMMITDIALOG$    = "\TempCB16.bmp"
	BITMAP_ADDCHOICEDIALOG$ = "\TempCB16.bmp"
	BITMAP_ADDFILEDIALOG$   = "\TempCB16.bmp"
ELSE
	BITMAP_INTRODIALOG$     = "\TempCB.bmp"
	BITMAP_CHOICEDIALOG$    = "\TempCB.bmp"
	BITMAP_SELECTDIALOG$    = "\TempCB.bmp"
	BITMAP_COMMITDIALOG$    = "\TempCB.bmp"
	BITMAP_ADDCHOICEDIALOG$ = "\TempCB.bmp"
	BITMAP_ADDFILEDIALOG$   = "\TempCB.bmp"
ENDIF

' Texto na barra de título para os quadros de mensagem.
GLOBAL CONST TITLE_ERRORBOX$      = "Erro no Assistente de Personalização de Modelos"
GLOBAL CONST TITLE_INFOBOX$       = "Informações do Assistente de Personalização de Modelos"

' Chaves para pesquisa no registro.
CONST REG_CORELDRAW_PATH$ = "SOFTWARE\Corel\CorelDRAW\7.0"
CONST REG_CORELDRAW_MAIN_DIR_KEY$ = "Destination"
								
' Informações do arquivo de configurações de modelos do CorelDRAW:
CONST TEMPLATE_FILE_NAME$ = "Template.ini" 
CONST TEMPLATE_DIR_NAME$ = "Draw" ' Subdiretório (abaixo do diretório
						    ' principal do CorelDRAW) onde se
						    ' localiza o arquivo de modelo. Se 
						    ' for uma string vazia, assume-se o
						    ' diretório principal do
						    ' CorelDRAW.
CONST TEMPLATE_STORE_DIR_NAME$ = "Draw\Template"

' Constantes para valores de retorno de diálogo.
GLOBAL CONST DIALOG_RETURN_OK%     = 1
GLOBAL CONST DIALOG_RETURN_CANCEL% = 2
GLOBAL CONST DIALOG_RETURN_NEXT% = 3
GLOBAL CONST DIALOG_RETURN_BACK% = 4

' Um buffer muito grande (ligeiramente maior que 10.000 caracteres).
GLOBAL CONST BIG_BUFFER_SIZE& = 10000
GLOBAL CONST BYTES100$ = "                                                                                                    "
GLOBAL BIG_EMPTY_BUFFER$ AS STRING
BIG_EMPTY_BUFFER$ = BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
				BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
				BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
				BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
				BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
				BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ + BYTES100$ + BYTES100$ + BYTES100$ + \\
                    BYTES100$ 
			
' Texto endentado para os tipos de item.
GLOBAL CONST TM_INDENT_LABEL$ = ""
GLOBAL CONST TM_INDENT_CATEGORY_OPEN$   = "   - "
GLOBAL CONST TM_INDENT_CATEGORY_CLOSED$ = "   + "
GLOBAL CONST TM_INDENT_SUBCATEGORY$   	= "         "
			
'/////COMANDOS GERAIS DE VARIÁVEIS///////////////////////////////////

' Contém todas as informações que estão no arquivo de informações
' de modelos (Template.ini).  Cada fileira representa um item no arquivo INI.
GLOBAL DataTable( 1, 6 ) AS STRING
GLOBAL DisplayTable( 1 ) AS STRING
GLOBAL NumRows AS LONG
NumRows& = 0

' Diretório atual onde começa o script.
GLOBAL CurDir AS STRING

' Colunas da tabela.
' Qual é o tipo deste item? (Categoria/Subcategoria/Caminho_de_arquivo)
GLOBAL CONST TM_COL_TYPE% = 1
' Qual categoria o item reflete?
GLOBAL CONST TM_COL_CATEGORY% = 2
' Qual subcategoria, se houver, este item reflete?
GLOBAL CONST TM_COL_SUBCATEGORY% = 3
' Informações especiais (a qual categoria principal este item pertence?).
' Possíveis categorias principais são Modelos do CorelDRAW, Modelos de Gráficos
' e Texto PaperDirect, e Modelos Somente Texto PaperDirect.
GLOBAL CONST TM_COL_MASTER% = 4
' Este item deve ser aberto ou fechado?
GLOBAL CONST TM_COL_STATE% = 5
' Este item deve ser visivel?
GLOBAL CONST TM_COL_VISIBLE% = 6

' Constantes para os tipos de item do modelo.
GLOBAL CONST TM_TYPE_CATEGORY$ = "Categoria"
GLOBAL CONST TM_TYPE_SUBCATEGORY$ = "Subcategoria"
GLOBAL CONST TM_TYPE_LABEL$ = "Etiqueta"

' Constantes para as informações abertas/fechadas.
GLOBAL CONST TM_STATE_OPEN$ = "Aberta"
GLOBAL CONST TM_STATE_CLOSED$ = "Fechada"

' Constantes para visibilidade.
GLOBAL CONST TM_VISIBLE$ = "Visível"
GLOBAL CONST TM_INVISIBLE$ = "Invisível"
			
' Constantes para os tipos de principal.
GLOBAL CONST TM_MASTER_CORELDRAW$   = "Modelo do CorelDRAW"
GLOBAL CONST TM_MASTER_PD_GRAPHICS$ = "Modelo de Gráficos e Texto Paper Direct"
GLOBAL CONST TM_MASTER_PD_TEXTONLY$ = "Modelo Somente Texto Paper Direct"

' Posição da página anterior do assistente.
GLOBAL LastPageX AS LONG
GLOBAL LastPageY AS LONG
LastPageX& = -1
LastPageY& = -1
			
'/////QUADRO DE DIÁLOGO DE APRESENTAÇÃO//////////////////////////////////////////////

BEGIN DIALOG OBJECT IntroDialog 290, 180, "Assistente de Personalização de Modelos", SUB IntroDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 20, .Text1, "Bem-vindo ao Assistente de Personalização de Modelos Corel."
	TEXT  93, 65, 189, 24, .Text2, "As alterações que você fizer terão efeito na próxima vez que você tentar criar um documento baseado em modelo no CorelDRAW."
	TEXT  94, 94, 187, 18, .Text3, "Para começar a personalizar seus modelos, clique em Avançar."
	IMAGE  10, 10, 75, 130, .IntroImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 28, 189, 33, .Text4, "Este assistente guiará você através das etapas necessárias para acrescentar, remover ou renomear modelos com base na lista de modelos que você vê sempre que cria um novo documento baseado em modelo."
END DIALOG

SUB IntroDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_INITIALIZATION THEN 		
		IntroDialog.BackButton.Enable FALSE 
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Evento de clicar com o mouse.
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

'/////QUADRO DE DIÁLOGO DE OPÇÃO//////////////////////////////////////////////

' Constantes necessárias para este quadro de diálogo.
GLOBAL CONST ACTION_RENAME% = 1
GLOBAL CONST ACTION_ADD%    = 2
GLOBAL CONST ACTION_REMOVE% = 3

' Variáveis necessárias para este quadro de diálogo.
GLOBAL CurrentAction AS INTEGER	' Para adicionar, renomear ou remover.

' Definir defaults.
CurrentAction% = ACTION_ADD%

BEGIN DIALOG OBJECT ChoiceDialog 290, 180, "Assistente de Personalização de Modelos", SUB ChoiceDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 16, .Text1, "Você pode adicionar seus próprios modelos, remover modelos existentes ou renomear modelos e categorias."
	IMAGE  10, 10, 75, 130, .ChoiceImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	GROUPBOX  112, 37, 114, 65, .GroupBox2, "O que você quer fazer?"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  129, 52, 71, 11, .AddOption, "Adicionar"
		OPTIONBUTTON  129, 79, 75, 11, .RenameOption, "Renomear"
		OPTIONBUTTON  129, 65, 81, 11, .RemoveOption, "Remover"
END DIALOG

SUB ChoiceDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_INITIALIZATION THEN 		
		SELECT CASE CurrentAction%
			CASE ACTION_RENAME%
				ChoiceDialog.RenameOption.SetValue TRUE
			CASE ACTION_ADD%
				ChoiceDialog.AddOption.SetValue TRUE
			CASE ACTION_REMOVE%
				ChoiceDialog.RemoveOption.SetValue TRUE
		END SELECT
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Evento de clicar com o mouse.
		SELECT CASE ControlID%
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
			CASE ChoiceDialog.AddOption.GetID()
				CurrentAction% = ACTION_ADD%
			CASE ChoiceDialog.RenameOption.GetID()
				CurrentAction% = ACTION_RENAME%
			CASE ChoiceDialog.RemoveOption.GetID()
				CurrentAction% = ACTION_REMOVE%
		END SELECT
	ENDIF

END FUNCTION

'/////ADDCHOICE DIALOG///////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL CreateNewCategory AS BOOLEAN ' Whether to add a new category
                                    ' as well.

' Set defaults.
CreateNewCategory = FALSE

BEGIN DIALOG OBJECT AddChoiceDialog 290, 180, "Assistente de Personalização de Modelos", SUB AddChoiceDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 28, .Text1, "Ao adicionar um novo modelo, você poderá colocá-lo em uma categoria já existente ou criar uma nova categoria para ele."
	IMAGE  10, 10, 75, 130, .AddChoiceImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	GROUPBOX  112, 44, 136, 50, .GroupBox2, "O que você deseja fazer?"
	OPTIONGROUP .OptionGroup1Val%
		OPTIONBUTTON  119, 59, 125, 11, .AddOption, "Adicionar a uma categoria existente"
		OPTIONBUTTON  119, 72, 120, 11, .CreateOption, "Criar uma nova categoria"
END DIALOG

SUB AddChoiceDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_INITIALIZATION THEN 	
		IF CreateNewCategory THEN
			AddChoiceDialog.CreateOption.SetValue TRUE
		ELSE
			AddChoiceDialog.AddOption.SetValue TRUE	
		ENDIF
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK THEN 	' Evento de clicar com o mouse.
		SELECT CASE ControlID%
			CASE AddChoiceDialog.NextButton.GetID()
				LastPageX& = AddChoiceDialog.GetLeftPosition()
				LastPageY& = AddChoiceDialog.GetTopPosition()
				AddChoiceDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE AddChoiceDialog.BackButton.GetID()
				LastPageX& = AddChoiceDialog.GetLeftPosition()
				LastPageY& = AddChoiceDialog.GetTopPosition()
				AddChoiceDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE AddChoiceDialog.CancelButton.GetID()
				AddChoiceDialog.CloseDialog DIALOG_RETURN_CANCEL%
			CASE AddChoiceDialog.AddOption.GetID()
				CreateNewCategory = FALSE
			CASE AddChoiceDialog.CreateOption.GetID()
				CreateNewCategory = TRUE
		END SELECT
	ENDIF

END FUNCTION

'/////SELECT DIALOG//////////////////////////////////////////////

' Purposes for this dialog.
GLOBAL CONST SD_PURPOSE_RENAME% = 1
GLOBAL CONST SD_PURPOSE_ADD_ADD_CATEGORY% = 2
GLOBAL CONST SD_PURPOSE_ADD_SELECT_CATEGORY% = 3
GLOBAL CONST SD_PURPOSE_REMOVE% = 4

' Variables needed for this dialog.
GLOBAL SelectDialogPurpose AS INTEGER
GLOBAL SelectedDataItem AS LONG
GLOBAL RenameFileFirstTime AS BOOLEAN

' Set Defaults.
RenameFileFirstTime = TRUE

BEGIN DIALOG OBJECT SelectDialog 290, 180, "Assistente de Personalização de Modelos", SUB SelectDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 10, 181, 16, .InstructionText, "Selecione o modelo ou categoria que deseja renomear e, em seguida, pressione o botão Renomear."
	IMAGE  10, 10, 75, 130, .SelectImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	LISTBOX  94, 31, 186, 76, .SelectListBox
	PUSHBUTTON  224, 111, 56, 14, .RenameButton, "Renomear"
	PUSHBUTTON  224, 111, 56, 14, .RemoveButton, "Remover"
	PUSHBUTTON  224, 111, 56, 14, .AddButton, "Adicionar"
	TEXT  111, 110, 117, 40, .AddTipText, "Você pode adicionar quantas categorias desejar.  Lembre-se de selecionar a categoria onde deseja incluir seus modelos antes de pressionar Avançar."
	TEXT  111, 110, 117, 40, .RemoveTipText, "Depois de removido, o modelo não aparecerá como opção na próxima vez que você criar um documento baseado em modelo.  Ele não será excluído do disco."
	TEXT  93, 110, 18, 11, .TipText, "Dica:"
END DIALOG

SUB SelectDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM MsgReturn AS LONG
	DIM CurSelection AS STRING
	DIM CurSelNum AS LONG
	DIM CurDataIndex AS LONG

	IF Event% = EVENT_INITIALIZATION& THEN 	
		SELECT CASE SelectDialogPurpose%
			CASE SD_PURPOSE_RENAME%
				SelectDialog.RenameButton.SetStyle STYLE_VISIBLE
				SelectDialog.RemoveButton.SetStyle STYLE_INVISIBLE
				SelectDialog.AddButton.SetStyle STYLE_INVISIBLE
				SelectDialog.TipText.SetStyle STYLE_INVISIBLE
				SelectDialog.AddTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.InstructionText.SetText \\
					"Selecione o modelo ou categoria que deseja renomear; em seguida, pressione o botão Renomear."
			CASE SD_PURPOSE_ADD_ADD_CATEGORY%
				SelectDialog.RenameButton.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveButton.SetStyle STYLE_INVISIBLE
				SelectDialog.AddButton.SetStyle STYLE_VISIBLE
				SelectDialog.TipText.SetStyle STYLE_VISIBLE
				SelectDialog.AddTipText.SetStyle STYLE_VISIBLE
				SelectDialog.RemoveTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.InstructionText.SetText \\
					"Selecione o item sob o qual deseja adicionar uma nova categoria; em seguida, pressione o botão Adicionar."
			CASE SD_PURPOSE_ADD_SELECT_CATEGORY%
				SelectDialog.RenameButton.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveButton.SetStyle STYLE_INVISIBLE
				SelectDialog.AddButton.SetStyle STYLE_INVISIBLE
				SelectDialog.TipText.SetStyle STYLE_INVISIBLE
				SelectDialog.AddTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.InstructionText.SetText \\
					"Selecione a categoria à qual deseja adicionar o modelo."
			CASE SD_PURPOSE_REMOVE%
				SelectDialog.RenameButton.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveButton.SetStyle STYLE_VISIBLE
				SelectDialog.AddButton.SetStyle STYLE_INVISIBLE
				SelectDialog.TipText.SetStyle STYLE_VISIBLE
				SelectDialog.AddTipText.SetStyle STYLE_INVISIBLE
				SelectDialog.RemoveTipText.SetStyle STYLE_VISIBLE
				SelectDialog.InstructionText.SetText \\
					"Selecione o modelo ou categoria que deseja remover; em seguida, pressione o botão Remover."
		END SELECT
		UpdateSelectListBox
		SelectDialog.SelectListbox.SetSelect 1
	ENDIF
	IF Event% = EVENT_MOUSE_CLICK& THEN 	' Evento de clicar com o mouse.
		SELECT CASE ControlID%
			CASE SelectDialog.NextButton.GetID()
				LastPageX& = SelectDialog.GetLeftPosition()
				LastPageY& = SelectDialog.GetTopPosition()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				' If no selection was made, and the dialog does not require a
				' selection, just choose a default.
				IF (SelectDialogPurpose% = SD_PURPOSE_RENAME) OR \\
                       (SelectDialogPurpose% = SD_PURPOSE_REMOVE) THEN
					IF CurSelNum& <= 0 THEN
						CurSelNum& = 1
					ENDIF	
				ENDIF
				IF (CurSelNum& <= 0) THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					IF (SelectDialogPurpose% = SD_PURPOSE_ADD_SELECT_CATEGORY%) OR \\
					   (SelectDialogPurpose% = SD_PURPOSE_ADD_ADD_CATEGORY%) THEN
						IF (DataTable(CurDataIndex&, TM_COL_TYPE%) = TM_TYPE_CATEGORY$) THEN
							SelectedDataItem& = CurDataIndex&
							SelectDialog.CloseDialog DIALOG_RETURN_NEXT%
						ELSE
							MsgReturn& = MESSAGEBOX( "Não é possível " +\\
							                         "adicionar arquivos de modelo ao " +\\
							                         "item selecionado." +NL2+\\
							                         "Você só pode adicionar modelos " +\\
							                         "a categorias localizadas " +\\
							                         "dois níveis abaixo." + NL + "Por exemplo, 'Modelos do CorelDRAW\" + \\
							                         "Anúncios' seria uma " + \\
							                         "categoria à qual você poderia adicionar itens." + \\
							                         NL2 + "Tente outra vez.", \\
							                         TITLE_INFOBOX$, \\
							                         MB_EXCLAMATION_ICON& )
						ENDIF
					ELSE
						SelectDialog.CloseDialog DIALOG_RETURN_NEXT%
					ENDIF
				ENDIF
			CASE SelectDialog.BackButton.GetID()
				LastPageX& = SelectDialog.GetLeftPosition()
				LastPageY& = SelectDialog.GetTopPosition()
				SelectDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE SelectDialog.CancelButton.GetID()
				SelectDialog.CloseDialog DIALOG_RETURN_CANCEL%
			CASE SelectDialog.RenameButton.GetID()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				IF CurSelNum& <= 0 THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					IF RenameFileFirstTime AND (DataTable(CurDataIndex&, TM_COL_TYPE%) = TM_TYPE_SUBCATEGORY$) THEN
						MsgReturn& = MESSAGEBOX("Este botão não renomeia o arquivo de modelos " + \\
						                        "em seu disco.  Utilize o Windows Explorer para renomeá-lo.  " + \\
						                        "Por outro lado, este botão permite que você substitua uma referência " + \\
						                        "existente a um arquivo de modelo com uma outra referência.  " + \\
						                        "É útil para atualizar a lista de modelos do CorelDRAW quando " + \\
						                        "você renomeou alguns modelos ou os moveu para outro " + \\
						                        "diretório." + NL2 + \\
						                        "Caso não deseje fazer isso, pressione Cancelar quando solicitado " + \\
						                        "a indicar um arquivo de substituição.", TITLE_INFOBOX$, MB_INFORMATION_ICON&)
						RenameFileFirstTime = FALSE
					ENDIF
					RenameItem CurDataIndex&
				ENDIF
			CASE SelectDialog.SelectListBox.GetID()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				IF CurSelNum& <= 0 THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					SELECT CASE DataTable(CurDataIndex&, TM_COL_TYPE%)
						CASE TM_TYPE_CATEGORY$
							SelectDialog.RenameButton.SetText "Renomear"
							SelectDialog.RenameButton.Enable TRUE
						CASE TM_TYPE_SUBCATEGORY$
							SelectDialog.RenameButton.SetText "Alterar Arquivo"
							SelectDialog.RenameButton.Enable TRUE
						CASE TM_TYPE_LABEL$
							SelectDialog.RenameButton.SetText "Renomear"
					END SELECT
				ENDIF
			CASE SelectDialog.AddButton.GetID()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				IF CurSelNum& <= 0 THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					AddCategoryUnder CurDataIndex&
				ENDIF
			CASE SelectDialog.RemoveButton.GetID()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				IF CurSelNum& <= 0 THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					RemoveItem CurDataIndex&
				ENDIF
		END SELECT
	ENDIF
	IF Event% = EVENT_DBL_MOUSE_CLICK& THEN
		SELECT CASE ControlID%
			CASE SelectDialog.SelectListBox.GetID()
				CurSelNum& = SelectDialog.SelectListBox.GetSelect()
				IF CurSelNum& <= 0 THEN
					AskForSelection
				ELSE
					CurDataIndex& = ConvertVisibleToDataIndex( CurSelNum& )
					SELECT CASE DataTable(CurDataIndex&, TM_COL_TYPE%)
						CASE TM_TYPE_CATEGORY$
							ToggleOpen CurDataIndex& 
							' Update the list box.
							UpdateEverythingAfter CurDataIndex&
					END SELECT	
				ENDIF
		END SELECT
	ENDIF

END FUNCTION

SUB UpdateSelectListBox

	DIM Counter AS LONG
	
	SelectDialog.SelectListbox.Reset
	
	FOR Counter& = 1 TO NumRows&
		IF (DataTable(Counter&, TM_COL_VISIBLE%) = TM_VISIBLE$) THEN
			SelectDialog.SelectListbox.AddItem DisplayTable(Counter&)
		ENDIF
	NEXT Counter&

END SUB

'/////COMMIT DIALOG//////////////////////////////////////////////

BEGIN DIALOG OBJECT CommitDialog 290, 180, "Assistente de Personalização de Modelos", SUB CommitDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .FinishButton, "&Terminar"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	TEXT  93, 49, 181, 47, .Text1, "Para manter as alterações, pressione o botão Terminar.  Estas alterações passarão a ser efetivas na próxima vez que você criar um novo documento baseado em modelo."
	IMAGE  10, 10, 75, 130, .CommitImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  93, 10, 181, 10, .Text2, "Parabéns!"
	TEXT  93, 25, 181, 19, .Text3, "Você configurou com êxito as configurações de modelos do CorelDRAW."
	TEXT  93, 81, 181, 31, .Text4, "Caso não esteja satisfeito com as alterações, pressione o botão Cancelar para eliminá-las."
END DIALOG

SUB CommitDialogEventHandler(BYVAL ControlID%, BYVAL Event%)
	IF Event% = EVENT_MOUSE_CLICK& THEN 	' Evento de clicar com o mouse.
		SELECT CASE ControlID% 
			CASE CommitDialog.FinishButton.GetID()
				LastPageX& = CommitDialog.GetLeftPosition()
				LastPageY& = CommitDialog.GetTopPosition()
				CommitDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE CommitDialog.BackButton.GetID()
				LastPageX& = CommitDialog.GetLeftPosition()
				LastPageY& = CommitDialog.GetTopPosition()
				CommitDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE CommitDialog.CancelButton.GetID()
				CommitDialog.CloseDialog DIALOG_RETURN_CANCEL%
		END SELECT
	ENDIF	
END SUB

'/////ADDFILE DIALOG//////////////////////////////////////////////

' Variables needed for this dialog.
GLOBAL LastSelection AS STRING ' If these change, then
GLOBAL LastMaster AS STRING    ' we will refresh the file list box.
GLOBAL TemplateStoreDir AS STRING ' The full path to where templates
						 ' are stored.
GLOBAL CopyFiles AS BOOLEAN	 ' Should we copy templates to the CorelDRAW
						 ' templates directory?
						 
' Set defaults.
LastSelection$ = ""
LastMaster$ = ""
CopyFiles = FALSE

BEGIN DIALOG OBJECT AddFileDialog 290, 180, "Assistente de Personalização de Modelos", SUB AddFileDialogEventHandler
	PUSHBUTTON  181, 160, 46, 14, .NextButton, "&Avançar >"
	PUSHBUTTON  135, 160, 46, 14, .BackButton, "< &Voltar"
	PUSHBUTTON  234, 160, 46, 14, .CancelButton, "Cancelar"
	IMAGE  10, 10, 75, 130, .AddFileImage
	GROUPBOX  10, 150, 270, 5, .LineGroupBox
	TEXT  94, 69, 181, 9, .Text1, "Arquivos adicionados:"
	TEXT  94, 10, 181, 10, .IntroText, "Você selecionou a categoria XXX.XXX."
	TEXT  94, 24, 181, 25, .Text2, "Para cada modelo que deseje adicionar a esta categoria, pressione o botão Adicionar Arquivo e selecione um arquivo de modelo do CorelDRAW."
	PUSHBUTTON  200, 49, 76, 14, .AddFileButton, "Adicionar Arquivo..."
	LISTBOX  94, 79, 183, 46, .FileListBox
	CHECKBOX  94, 130, 190, 11, .CopyCheck, "Copiar arq. para o diret. de modelos CorelDRAW"
END DIALOG

SUB AddFileDialogEventHandler(BYVAL ControlID%, BYVAL Event%)

	DIM ChosenFile AS STRING
	DIM MsgReturn AS LONG
	DIM CurCategory AS STRING
	DIM CurSubCategory AS STRING
	DIM CurMaster AS STRING
	
	IF Event% = EVENT_INITIALIZATION& THEN
		CurCategory$ = DataTable(SelectedDataItem&, TM_COL_CATEGORY%)
		CurSubCategory$ = DataTable(SelectedDataItem&, TM_COL_SUBCATEGORY%)
		CurMaster$ = DataTable(SelectedDataItem&, TM_COL_MASTER%)
		IF (LastSelection$ <> CurCategory$) OR \\
		   (LastMaster$ <> CurMaster$) THEN
			' Clear the list of files.
			AddFileDialog.FileListBox.Reset
		ENDIF
		AddFileDialog.IntroText.SetText \\
			"Você selecionou a categoria '" + CurCategory$ + "' ."
		LastSelection$ = CurSubCategory$
		LastMaster$ = CurMaster$
		
		' Currently, the 'Copy files to template directory' option is
		' always on.
		AddFileDialog.CopyCheck.SetThreeState FALSE
		IF CopyFiles THEN
			AddFileDialog.CopyCheck.SetValue 1
		ELSE
			AddFileDialog.CopyCheck.SetValue 0
		ENDIF
		
	ELSEIF Event% = EVENT_MOUSE_CLICK& THEN 	' Evento de clicar com o mouse.
		SELECT CASE ControlID% 
			CASE AddFileDialog.CopyCheck.GetID()
				IF (AddFileDialog.CopyCheck.GetValue() = 1) THEN
					CopyFiles = TRUE
				ELSE
					CopyFiles = FALSE
				ENDIF
			CASE AddFileDialog.NextButton.GetID()
				LastPageX& = AddFileDialog.GetLeftPosition()
				LastPageY& = AddFileDialog.GetTopPosition()
				AddFileDialog.CloseDialog DIALOG_RETURN_NEXT%
			CASE AddFileDialog.BackButton.GetID()
				LastPageX& = AddFileDialog.GetLeftPosition()
				LastPageY& = AddFileDialog.GetTopPosition()			
				AddFileDialog.CloseDialog DIALOG_RETURN_BACK%
			CASE AddFileDialog.CancelButton.GetID()
				AddFileDialog.CloseDialog DIALOG_RETURN_CANCEL%
			CASE AddFileDialog.AddFileButton.GetID()
				ChosenFile$ = GETFILEBOX("Modelo do CorelDRAW (*.cdt)|*.cdt", \\
			                              "Selecione um arquivo de modelo", \\
			                              0, \\
								     , \\
			                              , \\
			                              , \\
			                              "&OK" )
				IF (LEN(ChosenFile$) <= 0) THEN
					' The user selected nothing or pressed Cancel.
				ELSEIF (FILESIZE(ChosenFile$) <= 0) THEN
					MsgReturn& = MESSAGEBOX( "O arquivo selecionado " + \\
				                              "não existe." + NL2 + \\
				                              "O Assistente de Personalização " + \\
				                              "de Modelos só pode adicionar " + \\
				                              "arquivos que consegue encontrar.  Talvez seja " + \\
				                              "uma boa idéia tentar novamente " + \\
				                              "com outro nome de arquivo.", \\
				                         	TITLE_ERRORBOX$, \\
				                         	MB_EXCLAMATION_ICON& )
				ELSEIF AlreadyPresent(ExtractFileName(ChosenFile$)) THEN
					
					' Before we complain, check to make sure that
					' the file chosen was not in the template directory.
					IF UCASE(ExtractDirectory(ChosenFile$)) = \\
					   UCASE(TemplateStoreDir$) THEN
						GOTO Okay
					ENDIF
					
					MsgReturn& = MESSAGEBOX( "Um arquivo de modelo " + \\
					                         "com o nome " + \\
										ExtractFileName(ChosenFile$) + \\
										" já está no diretório " + \\
										"de modelos do " + \\
										"CorelDRAW." + NL2 + \\
										"Selecione outro modelo " + \\
										"e tente outra vez.", \\
										TITLE_ERRORBOX$, \\
										MB_STOP_ICON& )
				ELSE
				
					Okay:
				
					' Currently, we do not check for duplicates.
					
					IF CopyFiles THEN
						COPY ChosenFile$, TemplateStoreDir$ + "\" + ExtractFileName(ChosenFile$)
					ENDIF
					
					' Add the file to this category.
					CurCategory$ = DataTable(SelectedDataItem&, TM_COL_CATEGORY%)
					CurMaster$ = DataTable(SelectedDataItem&, TM_COL_MASTER%)
					
					IF CopyFiles THEN
						ChosenFile$ = ".\Modelo\" + ExtractFileName(ChosenFile$)
					ENDIF
					
					AddNewSubCategory CurCategory$, \\
					                  CurMaster$, \\
					                  ChosenFile$
					
					' Add to the list box.
					AddFileDialog.FileListbox.AddItem ChosenFile$
					
				ENDIF
				
		END SELECT
	ENDIF	
END SUB

'********************************************************************
' MAIN
'
'
'********************************************************************

'/////LOCAL VARIABLES////////////////////////////////////////////////
DIM MessageText AS STRING	' Text to use in a MESSAGEBOX.
DIM GenReturn AS INTEGER		' The return value of various routines.
DIM CurStep AS INTEGER		' The current dialog box being displayed.
DIM MainDrawDir AS STRING     ' The path to the main CorelDRAW directory.
					     ' (Doesn't end with a '\'.)
DIM TemplateFileAndPath AS STRING ' The name and path of the 
					         ' template settings file.
DIM WriteSuccess AS BOOLEAN	' Whether the template-writing succeeded.
DIM BeforeCommit AS INTEGER	' The dialog that was displayed before the
						' commit dialog.
		
' Retrieve the current directory.
CurDir$ = GetCurrFolder()
IF MID(CurDir$, LEN(CurDir$), 1) = "\" THEN
	' Make sure CurDir does not end with a backslash, since we
	' will add one.
	CurDir$ = LEFT(CurDir$, LEN(CurDir$) - 1)
ENDIF
		
' Trap any registry-related problems specifically.
ON ERROR GOTO RegistryKeyMissing

' Retrieve the main CorelDRAW directory and path from the registry.
MainDrawDir$ = REGISTRYQUERY (HKEY_LOCAL_MACHINE&, \\
                              REG_CORELDRAW_PATH$, \\
                              REG_CORELDRAW_MAIN_DIR_KEY$)
GOTO GotDrawDir

RegistryKeyMissing:
	ERRNUM = 0
	GenReturn% = MESSAGEBOX("Impossível ler a localização do diretório " + \\
                             "do CorelDRAW no Registro do Windows." + NL2 + \\
					    "Verifique se o identificador HKEY_LOCAL_MACHINE\SOFTWARE\Corel\" + \\
                             "CorelDRAW\7.0\Destination está presente no Registro do Windows " + \\
                             "e se ele contém a localização do " + \\
                             "diretório principal do CorelDRAW." + NL2 + \\
                             "Caso você reinstale o CorelDRAW, o programa de instalação " + \\
                             "assumirá a tarefa de criar este identificador adequadamente para você.", \\
                             TITLE_ERRORBOX$, \\
                             MB_STOP_ICON& )
	RESUME AT VeryEnd

' Prepare the name and path of the template settings file.
GotDrawDir:
TemplateFileAndPath$ = MainDrawDir$ + "\" + \\
                       TEMPLATE_DIR_NAME$ + "\" + \\
                       TEMPLATE_FILE_NAME$

' Prepare the path of where all the templates are stored.
TemplateStoreDir$ = MainDrawDir$ + "\" + TEMPLATE_STORE_DIR_NAME$

ON ERROR GOTO MainErrorHandler

' Read in all of the information in the template settings file.
IF NOT ReadSettings(TemplateFileAndPath$) THEN
	MessageText$ = "Há um problema com '" + \\
				TemplateFileAndPath$ + "'." + NL2 + \\
				"Este é o arquivo que armazena todas as suas " + \\
				"informações de modelos.  Se o problema " + \\
				"persistir, poderá ser necessário " + \\
				"reinstalar o CorelDRAW."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_STOP_ICON&)
	STOP

ENDIF

REM MyStr$ = "                                                             "
REM RetVal& = GetPrivateProfileString("Modelo do CorelDRAW", "Categoria - Brochuras", "", MyStr$, 100, TemplateFileAndPath$)
REM MESSAGE CSTR(RetVal&)
REM MESSAGE LEFT(MyStr$, RetVal&)

' Set up the pages of the wizard.
CONST NS_FINISH%		 = 0
CONST NS_INTRODIALOG%     = 1
CONST NS_GETCHOICEDIALOG% = 2
CONST NS_RENAMEDIALOG%    = 3
CONST NS_ADDCATEGORYDIALOG% = 5
CONST NS_SELECTCATEGORYDIALOG% = 6
CONST NS_COMMITDIALOG%    = 4
CONST NS_ADDCHOICEDIALOG% = 7
CONST NS_ADDFILEDIALOG%   = 8
CONST NS_ADDFILEDIALOG_AFTER_ADD% = 9
CONST NS_REMOVEDIALOG%	= 10

' Loop, displaying dialogs in the required order.
CurStep% = NS_INTRODIALOG%
LoopBegin:
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
			GenReturn% = DIALOG(IntroDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_GETCHOICEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP										
			END SELECT

		CASE NS_GETCHOICEDIALOG%
			ChoiceDialog.Move LastPageX&, LastPageY&		
			ChoiceDialog.ChoiceImage.SetImage CurDir$ + BITMAP_CHOICEDIALOG$
			ChoiceDialog.ChoiceImage.SetStyle STYLE_SUNKEN
			ChoiceDialog.ChoiceImage.SetStyle STYLE_IMAGE_CENTERED
			ChoiceDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(ChoiceDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_INTRODIALOG%
				CASE DIALOG_RETURN_NEXT%
					SELECT CASE CurrentAction%
						CASE ACTION_RENAME%
							CurStep% = NS_RENAMEDIALOG%
						CASE ACTION_ADD%
							CurStep% = NS_ADDCHOICEDIALOG%
						CASE ACTION_REMOVE%
							CurStep% = NS_REMOVEDIALOG%
					END SELECT
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE NS_ADDCHOICEDIALOG%
			AddChoiceDialog.Move LastPageX&, LastPageY&	
			AddChoiceDialog.AddChoiceImage.SetImage CurDir$ + BITMAP_ADDCHOICEDIALOG$
			AddChoiceDialog.AddChoiceImage.SetStyle STYLE_SUNKEN
			AddChoiceDialog.AddChoiceImage.SetStyle STYLE_IMAGE_CENTERED
			AddChoiceDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(AddChoiceDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_GETCHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					IF CreateNewCategory THEN
						CurStep% = NS_ADDCATEGORYDIALOG%	
					ELSE
						CurStep% = NS_SELECTCATEGORYDIALOG%
					ENDIF
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

		CASE NS_RENAMEDIALOG%
			SelectDialog.Move LastPageX&, LastPageY&	
			SelectDialog.SelectImage.SetImage CurDir$ + BITMAP_SELECTDIALOG$
			SelectDialog.SelectImage.SetStyle STYLE_SUNKEN
			SelectDialog.SelectImage.SetStyle STYLE_IMAGE_CENTERED
			SelectDialog.SetStyle STYLE_NOMINIMIZEBOX

			SelectDialogPurpose% = SD_PURPOSE_RENAME%
			GenReturn% = DIALOG(SelectDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_GETCHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					BeforeCommit% = NS_RENAMEDIALOG%
					CurStep% = NS_COMMITDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT

		CASE NS_REMOVEDIALOG%
			SelectDialog.Move LastPageX&, LastPageY&
			SelectDialog.SelectImage.SetImage CurDir$ + BITMAP_SELECTDIALOG$
			SelectDialog.SelectImage.SetStyle STYLE_SUNKEN
			SelectDialog.SelectImage.SetStyle STYLE_IMAGE_CENTERED
			SelectDialog.SetStyle STYLE_NOMINIMIZEBOX

			SelectDialogPurpose% = SD_PURPOSE_REMOVE%
			GenReturn% = DIALOG(SelectDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_GETCHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					BeforeCommit% = NS_REMOVEDIALOG%
					CurStep% = NS_COMMITDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
		
		CASE NS_ADDCATEGORYDIALOG%
			SelectDialog.Move LastPageX&, LastPageY&			
			SelectDialog.SelectImage.SetImage CurDir$ + BITMAP_SELECTDIALOG$
			SelectDialog.SelectImage.SetStyle STYLE_SUNKEN
			SelectDialog.SelectImage.SetStyle STYLE_IMAGE_CENTERED
			SelectDialog.SetStyle STYLE_NOMINIMIZEBOX
			
			SelectDialogPurpose% = SD_PURPOSE_ADD_ADD_CATEGORY%
			GenReturn% = DIALOG(SelectDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_ADDCHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_ADDFILEDIALOG_AFTER_ADD%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE NS_SELECTCATEGORYDIALOG%
			SelectDialog.Move LastPageX&, LastPageY&			
			SelectDialog.SelectImage.SetImage CurDir$ + BITMAP_SELECTDIALOG$
			SelectDialog.SelectImage.SetStyle STYLE_SUNKEN
			SelectDialog.SelectImage.SetStyle STYLE_IMAGE_CENTERED
			SelectDialog.SetStyle STYLE_NOMINIMIZEBOX

			SelectDialogPurpose% = SD_PURPOSE_ADD_SELECT_CATEGORY%
			GenReturn% = DIALOG(SelectDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_ADDCHOICEDIALOG%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_ADDFILEDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
			
		CASE NS_COMMITDIALOG%
			CommitDialog.Move LastPageX&, LastPageY&			
			CommitDialog.CommitImage.SetImage CurDir$ + BITMAP_COMMITDIALOG$
			CommitDialog.CommitImage.SetStyle STYLE_SUNKEN
			CommitDialog.CommitImage.SetStyle STYLE_IMAGE_CENTERED
			CommitDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(CommitDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = BeforeCommit%
				CASE DIALOG_RETURN_NEXT%
					CurStep% = NS_FINISH%
				CASE DIALOG_RETURN_CANCEL%
					STOP
			END SELECT
		
		CASE NS_ADDFILEDIALOG%
			AddFileDialog.Move LastPageX&, LastPageY&			
			AddFileDialog.AddFileImage.SetImage CurDir$ + BITMAP_ADDFILEDIALOG$
			AddFileDialog.AddFileImage.SetStyle STYLE_SUNKEN
			AddFileDialog.AddFileImage.SetStyle STYLE_IMAGE_CENTERED
			AddFileDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(AddFileDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_SELECTCATEGORYDIALOG%
				CASE DIALOG_RETURN_NEXT%
					BeforeCommit% = NS_ADDFILEDIALOG%
					CurStep% = NS_COMMITDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP			
			END SELECT
			
		CASE NS_ADDFILEDIALOG_AFTER_ADD%
			AddFileDialog.Move LastPageX&, LastPageY&			
			AddFileDialog.AddFileImage.SetImage CurDir$ + BITMAP_ADDFILEDIALOG$
			AddFileDialog.AddFileImage.SetStyle STYLE_SUNKEN
			AddFileDialog.AddFileImage.SetStyle STYLE_IMAGE_CENTERED
			AddFileDialog.SetStyle STYLE_NOMINIMIZEBOX
			GenReturn% = DIALOG(AddFileDialog)
			SELECT CASE GenReturn%
				CASE DIALOG_RETURN_BACK%
					CurStep% = NS_ADDCATEGORYDIALOG%
				CASE DIALOG_RETURN_NEXT%
					BeforeCommit% = NS_ADDFILEDIALOG_AFTER_ADD%
					CurStep% = NS_COMMITDIALOG%
				CASE DIALOG_RETURN_CANCEL%
					STOP			
			END SELECT

	END SELECT

WEND

' Erase the existing template and write out a new one based
' on any changes that were made.
WriteSuccess = WriteTemplateSettingsFile( TemplateFileAndPath$ )
IF NOT WriteSuccess THEN
	MessageText$ = "Impossível escrever no arquivo de configurações " + \\
	               "do modelo, '" + TemplateFileAndPath$ + "'." + NL2 + \\
	               "Talvez o arquivo esteja protegido contra gravação ou " + \\
	               "localizado em uma unidade de disco à qual você " + \\
	               "não possui direitos de gravação." + NL2 + \\
	               "Caso possa solucionar o problema, " + \\
	               "pressione Terminar para tentar outra vez.  Caso contrário, " + \\
	               "pressione Cancelar para sair sem salvar as alterações."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_STOP_ICON& )
	CurStep% = NS_COMMITDIALOG%
	GOTO LoopBegin
ENDIF

VeryEnd:
STOP

MainErrorHandler:
	ERRNUM = 0
	MessageText$ = "Erro geral durante o "
	MessageText$ = MessageText$ + "processamento do assistente." + NL2
	MessageText$ = MessageText$ + "Pode ser uma boa idéia tentar outra vez."
	GenReturn% = MESSAGEBOX(MessageText$, TITLE_ERRORBOX$, \\
	                        MB_OK_ONLY& OR MB_EXCLAMATION_ICON&)
	RESUME AT VeryEnd
	STOP
	
'********************************************************************
'
'	Name:	ReadSettings (function)
'
'	Action:	Reads all of the template information in
'			InFile and stores it in the global variables
'              DataTable and DisplayTable.  Alters 
'              NumRows (global) to reflect
'              the new sizes.
'
'	Params:	InFile - the filename and path of the template
'                       information file
'
'	Returns:	FALSE if an error occurs.  TRUE otherwise. 
'
'	Comments:	Erases any information currently in DataTable.
'              We access NumRows globally in order to avoid
'              the memory overhead associated with passing
'              a variable size array as a VARIANT.
'
'********************************************************************
FUNCTION ReadSettings ( InFile AS STRING ) AS BOOLEAN

	' Add a label to indicate CorelDRAW templates.
	NumRows& = 1
	REDIM DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM DisplayTable( 1 TO NumRows& )
	DisplayTable(NumRows&) = TM_INDENT_LABEL$ + "CorelDRAW Templates"
	DataTable(NumRows&, TM_COL_TYPE)    = TM_TYPE_LABEL$
	DataTable(NumRows&, TM_COL_CATEGORY)= ""
	DataTable(NumRows&, TM_COL_SUBCATEGORY) = ""
	DataTable(NumRows&, TM_COL_MASTER) = TM_MASTER_CORELDRAW$
	DataTable(NumRows&, TM_COL_STATE) = TM_STATE_OPEN$
	DataTable(NumRows&, TM_COL_VISIBLE) = TM_VISIBLE$
	
	' Read in all of the normal templates.
	IF NOT ReadCategories( TM_MASTER_CORELDRAW$, InFile$ ) THEN
		ReadSettings = FALSE
		EXIT FUNCTION
	ENDIF
	
	' Add a label to indicate PaperDirect Graphics templates.
	NumRows& = NumRows& + 1
	REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM PRESERVE DisplayTable( 1 TO NumRows& )
	DisplayTable(NumRows&) = TM_INDENT_LABEL$ + "Paper Direct Graphics & Text Templates"
	DataTable(NumRows&, TM_COL_TYPE)    = TM_TYPE_LABEL$
	DataTable(NumRows&, TM_COL_CATEGORY)= ""
	DataTable(NumRows&, TM_COL_SUBCATEGORY) = ""
	DataTable(NumRows&, TM_COL_MASTER) = TM_MASTER_PD_GRAPHICS$
	DataTable(NumRows&, TM_COL_STATE) = TM_STATE_OPEN$
	DataTable(NumRows&, TM_COL_VISIBLE) = TM_VISIBLE$	
	
	' Read in the PaperDirect Graphics templates.
	IF NOT ReadCategories( TM_MASTER_PD_GRAPHICS, InFile$ ) THEN
		ReadSettings = FALSE
		EXIT FUNCTION
	ENDIF

	' Add a label to indicate PaperDirect Text Only templates.
	NumRows& = NumRows& + 1
	REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM PRESERVE DisplayTable( 1 TO NumRows& )
	DisplayTable(NumRows&) = TM_INDENT_LABEL$ + "Paper Direct Text Only Templates"
	DataTable(NumRows&, TM_COL_TYPE)    = TM_TYPE_LABEL$
	DataTable(NumRows&, TM_COL_CATEGORY)= ""
	DataTable(NumRows&, TM_COL_SUBCATEGORY) = ""
	DataTable(NumRows&, TM_COL_MASTER) = TM_MASTER_PD_TEXTONLY$
	DataTable(NumRows&, TM_COL_STATE) = TM_STATE_OPEN$
	DataTable(NumRows&, TM_COL_VISIBLE) = TM_VISIBLE$	
	
	' Read in the PaperDirect Graphics templates.
	IF NOT ReadCategories( TM_MASTER_PD_TEXTONLY$, InFile$ ) THEN
		ReadSettings = FALSE
		EXIT FUNCTION
	ENDIF
	
	ReadSettings = TRUE
	
END FUNCTION

FUNCTION ReadCategories( InMaster AS STRING, \\
                         InFile AS STRING ) AS BOOLEAN

	CONST MainSectionName$       = "CorelDRAW Templates"
	CONST PDGraphicsSectionName$ = "Paper Direct Graphics & Text Templates"
	CONST PDTextOnlySectionName$ = "Paper Direct Text Only Templates"

	DIM RetVal AS LONG	      ' The return value of various functions.
	DIM Buffer AS STRING	 ' A buffer to read into.
	DIM SearchKey AS STRING	 ' The key to use to search the INI file.
	DIM CurCategory AS LONG	 ' The category number being processed.
	DIM CurCategoryName AS STRING ' The current category name.
	DIM NumCategories AS LONG ' The number of categories.
	DIM ReadSuccess AS LONG	 ' The return value of our call to flush the INI buffer.
	
	' Do a sanity check on InFile.  This will also make sure
	' InFile exists.
	IF (FILESIZE( InFile ) <= 0) THEN
		ReadCategories = FALSE
		EXIT FUNCTION
	ENDIF

	' Force Windows to flush the cache on this INI file so that
	' we see the most recent version.
	ReadSuccess& = WritePrivateProfileStringNULLS( 0, 0, 0, InFile$ )
	
	' Read in the number of categories.
	SELECT CASE InMaster$
		CASE TM_MASTER_CORELDRAW$
			SearchKey$ = MainSectionName$ 
		CASE TM_MASTER_PD_GRAPHICS$
			SearchKey$ = PDGraphicsSectionName$
		CASE TM_MASTER_PD_TEXTONLY$
			SearchKey$ = PDTextOnlySectionName$
	END SELECT
	NumCategories& = EXTGetNumberOfEntries( SearchKey$, InFile$ )
	IF NumCategories& < 0 THEN
		ReadCategories = FALSE
		EXIT FUNCTION
	ENDIF
	
	' Read in each category.
	FOR CurCategory& = 1 TO NumCategories&

		' Get the category name.
		Buffer$ = BIG_EMPTY_BUFFER$
		RetVal& = EXTGetEntry( CurCategory&, \\
		                       SearchKey$, \\
		                       Buffer$, \\
		                       BIG_BUFFER_SIZE&, \\
		                       InFile$ )
		IF (RetVal& <= 0) THEN
			ReadCategories = FALSE
			EXIT FUNCTION
		ENDIF
		SELECT CASE InMaster$
			CASE TM_MASTER_CORELDRAW$
				CurCategoryName$ = ExtractEqual(MID(Buffer$, 14, RetVal& - 14))
			CASE TM_MASTER_PD_GRAPHICS$
				CurCategoryName$ = ExtractEqual(MID(Buffer$, 16, RetVal& - 16))
			CASE TM_MASTER_PD_TEXTONLY$
				CurCategoryName$ = ExtractEqual(MID(Buffer$, 16, RetVal& - 16))
		END SELECT
		IF (LEN(CurCategoryName$) <= 0) THEN		
			ReadCategories = FALSE
			EXIT FUNCTION
		ENDIF
				
		' Add this category to DataTable.
		NumRows& = NumRows& + 1
		REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
		REDIM PRESERVE DisplayTable( 1 TO NumRows& )
		DisplayTable(NumRows&) = TM_INDENT_CATEGORY_CLOSED$ + CurCategoryName$
		DataTable(NumRows&, TM_COL_TYPE)    = TM_TYPE_CATEGORY$
		DataTable(NumRows&, TM_COL_CATEGORY)= CurCategoryName$
		DataTable(NumRows&, TM_COL_SUBCATEGORY) = ""
		SELECT CASE InMaster$
			CASE TM_MASTER_CORELDRAW$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_CORELDRAW$
			CASE TM_MASTER_PD_GRAPHICS$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_PD_GRAPHICS$
			CASE TM_MASTER_PD_TEXTONLY$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_PD_TEXTONLY$
		END SELECT
		DataTable(NumRows&, TM_COL_STATE) = TM_STATE_CLOSED$
		DataTable(NumRows&, TM_COL_VISIBLE) = TM_VISIBLE$
		
		' Read in the subcategories of this category.
		IF NOT ReadSubCategories( CurCategoryName$, InMaster$, InFile$ ) THEN
			ReadCategories = FALSE
			EXIT FUNCTION
		ENDIF

	NEXT CurCategory&
	
	ReadCategories = TRUE
	
END FUNCTION

FUNCTION ReadSubCategories ( InCategory AS STRING, \\
					    InMaster AS STRING, \\
                             InFile AS STRING ) AS BOOLEAN

	DIM RetVal AS LONG	     ' The return value of various functions.
	DIM Buffer AS STRING	' A buffer to read into.
	DIM SearchKey AS STRING	' The key we are searching for in the
						' INI file.
	DIM CurSubCategory AS LONG' The subcategory number being processed.
	DIM CurSubCategoryName AS STRING ' The current subcategory name.
	DIM NumSubCategories AS LONG ' The number of categories.

	' Read in the number of sub categories.
	SELECT CASE InMaster$
		CASE TM_MASTER_CORELDRAW$
			SearchKey$ = "CDCategory - " + InCategory$
		CASE TM_MASTER_PD_GRAPHICS$
			SearchKey$ = "PDGTCategory - " + InCategory$
		CASE TM_MASTER_PD_TEXTONLY$
			SearchKey$ = "PDTOCategory - " + InCategory$
	END SELECT
	NumSubCategories& = EXTGetNumberOfEntries( SearchKey$, InFile$ )
	IF NumSubCategories& < 0 THEN
		ReadSubCategories = FALSE
		EXIT FUNCTION
	ENDIF
	
	' Read in each subcategory.
	FOR CurSubCategory& = 1 TO NumSubCategories&

		' Get the subcategory name.
		Buffer$ = BIG_EMPTY_BUFFER$
		RetVal& = EXTGetEntry( CurSubCategory&, \\
		                       SearchKey$, \\
		                       Buffer$, \\
		                       BIG_BUFFER_SIZE&, \\
		                       InFile$ )
		IF (RetVal& <= 0) THEN
			ReadSubCategories = FALSE
			EXIT FUNCTION
		ENDIF
		SELECT CASE InMaster$
			CASE TM_MASTER_CORELDRAW$
				CurSubCategoryName$ = ExtractEqual(MID(Buffer$, 1, RetVal& - 1))
			CASE TM_MASTER_PD_GRAPHICS$
				CurSubCategoryName$ = ExtractEqual(MID(Buffer$, 1, RetVal& - 1))
			CASE TM_MASTER_PD_TEXTONLY$
				CurSubCategoryName$ = ExtractEqual(MID(Buffer$, 1, RetVal& - 1))
		END SELECT
		IF (LEN(CurSubCategoryName$) <= 0) THEN		
			ReadSubCategories = FALSE
			EXIT FUNCTION
		ENDIF
				
		' Add this subcategory to DataTable.
		NumRows& = NumRows& + 1
		REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
		REDIM PRESERVE DisplayTable( 1 TO NumRows& )
		DisplayTable(NumRows&) = TM_INDENT_SUBCATEGORY$ + CurSubCategoryName$
		DataTable(NumRows&, TM_COL_TYPE)    = TM_TYPE_SUBCATEGORY$
		DataTable(NumRows&, TM_COL_CATEGORY)= InCategory$
		DataTable(NumRows&, TM_COL_SUBCATEGORY) = CurSubCategoryName$
		SELECT CASE InMaster$
			CASE TM_MASTER_CORELDRAW$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_CORELDRAW$ 
			CASE TM_MASTER_PD_GRAPHICS$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_PD_GRAPHICS$
			CASE TM_MASTER_PD_TEXTONLY$
				DataTable(NumRows&, TM_COL_MASTER%) = TM_MASTER_PD_TEXTONLY$
		END SELECT
		DataTable(NumRows&, TM_COL_STATE) = TM_STATE_CLOSED$
		DataTable(NumRows&, TM_COL_VISIBLE) = TM_INVISIBLE$
		
	NEXT CurSubCategory&

	ReadSubCategories = TRUE

END FUNCTION

'********************************************************************
'
'	Name:	ExtractEqual (function)
'
'	Action:	Removes the '=X' part from the end of an INI entry.
'
'	Params:	InString - the string to remove the '=X' part from.
'
'	Returns:	InString minus all characters after and including '='.
'			If there is no such character, returns InString.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ExtractEqual( InString AS STRING ) AS STRING

	DIM EqualPos AS LONG
	
	EqualPos& = INSTR( InString, "=" )
	IF (EqualPos& = 0) THEN
		ExtractEqual$ = InString$
	ELSE
		ExtractEqual$ = MID(InString, 1, EqualPos& - 1)
	ENDIF
	
END FUNCTION

'********************************************************************
'
'	Name:	GiveSizeWarning (subroutine)
'
'	Action:	Displays an error message stating that the template
'              settings file has gotten too large to handle.
'
'	Params:	InFile - the name and path of the template settings
'				    file
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB GiveSizeWarning( InFile AS STRING )

	DIM MsgReturn AS LONG
	
	MsgReturn& = MESSAGEBOX( "O arquivo de configurações do modelo, '" + \\
	                         InFile$ + "', é grande demais para " + \\
	                         "ser processado pelo " + \\
	                         "Assistente de Personalização de Modelos." + NL2 + \\
	                         "Caso este erro persista, poderá ser necessário " + \\
	                         "reinstalar o CorelDRAW.", \\
	                         TITLE_ERRORBOX$, \\
	                         MB_OK_ONLY& )

END SUB

'********************************************************************
'
'	Name:	ExtractFirstItem (function)
'
'	Action:	Extracts the first item from a buffer consisting
'              of null-terminated strings concatenated together.
'
'	Params:	Buffer - The buffer to extract the item from.
'                       Its size will be reduced after the item is extracted.
'			BufferSize - The buffer size (will also be modified).
'
'	Returns:	The item extracted from buffer.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ExtractFirstItem ( BYREF Buffer AS STRING, \\
                            BYREF BufferSize AS LONG ) AS STRING

	DIM Counter AS LONG
	DIM Found AS BOOLEAN
	DIM CurChar AS STRING

	MESSAGE MID(Buffer, 30, 200)
stop
	' Loop through Buffer, looking for the first null.
	Found = FALSE
	Counter = 1 
	WHILE (Counter <= BufferSize) AND (NOT Found)
	
		CurChar$ = MID(Buffer$, Counter&, 1)
	
		IF CurChar$ = CHR(0) THEN
			Found = TRUE
		ELSE
			Counter& = Counter& + 1
		ENDIF
	
	WEND
	
	IF NOT Found THEN
		ExtractFirstItem$ = ""
	ELSE
		ExtractFirstItem$ = LEFT( Buffer$, Counter& - 1 )
		Buffer$ = MID(Buffer$, Counter + 1)
		BufferSize& = BufferSize& - Counter&
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	ConvertDataToVisibleIndex (subroutine)
'
'	Action:	Converts the index of an item in the data table
'              to the index of that same item in SelectDialog's list
'              box.  
'
'	Params:	DataIndex - The index of an item in the data table.
'
'	Returns:	VisibleIndex - The equivalent index in the list box.
'						If the item with DataIndex is not visible,
'                             returns the position it would be in if it
'                             were visible.
'			AlreadyVisible - Whether the item with DataIndex has
'                             its visible property set.
'
'	Comments:	None.
'
'********************************************************************
SUB ConvertDataToVisibleIndex( DataIndex AS LONG, BYREF VisibleIndex AS LONG, BYREF AlreadyVisible AS BOOLEAN )

	DIM Counter AS LONG
	DIM VisibleFoundSoFar AS LONG
	
	' Count all of the visible items before DataIndex.
	VisibleFoundSoFar& = 0
	FOR Counter& = 1 TO DataIndex& - 1
		IF DataTable(Counter&, TM_COL_VISIBLE%) = TM_VISIBLE$ THEN
			VisibleFoundSoFar& = VisibleFoundSoFar& + 1
		ENDIF
	NEXT Counter&
	VisibleIndex& = VisibleFoundSoFar&
	
	' Check whether the given item was already visible.
	IF DataTable(DataIndex&, TM_COL_VISIBLE%) = TM_VISIBLE$ THEN
		AlreadyVisible = TRUE
		VisibleIndex& = VisibleIndex& + 1
	ELSE
		AlreadyVisible = FALSE
	ENDIF

END SUB

'********************************************************************
'
'	Name:	ConvertVisibleToDataIndex (function)
'
'	Action:	Converts the index of an item in SelectDialog's list
'              box to its corresponding index in DataTable.
'
'	Params:	VisibleIndex - The index of an item in the listbox.
'
'	Returns:	The corresponding index in DataTable.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ConvertVisibleToDataIndex( VisibleIndex AS LONG ) AS LONG

	DIM Counter AS LONG
	DIM Found AS BOOLEAN
	DIM NumVisibleMetSoFar AS LONG
	
	Found = FALSE
	NumVisibleMetSoFar& = 0
	Counter& = 1
	WHILE (Counter& <= NumRows&) AND (NOT Found)
		IF DataTable( Counter&, TM_COL_VISIBLE% ) = TM_VISIBLE$ THEN
			NumVisibleMetSoFar& = NumVisibleMetSoFar& + 1
			IF (NumVisibleMetSoFar& = VisibleIndex&) THEN
				Found = TRUE
			ENDIF
		ENDIF
		Counter& = Counter& + 1
	WEND
	
	IF Found THEN
		ConvertVisibleToDataIndex& = Counter& - 1
	ELSE
		ConvertVisibleToDataIndex& = 0
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	ToggleOpen (subroutine)
'
'	Action:	Toggles the open/closed state of an item in DataTable
'              and updates all items dependent on it as well.
'
'	Params:	DataIndex - The index of an item in DataTable.
'
'	Returns:	None.
'
'	Comments:	Does not update SelectListbox.  You must
'              do this after calling ToggleOpen.
'
'********************************************************************
SUB ToggleOpen( DataIndex AS LONG )

	DIM NewState AS STRING
	DIM Counter AS LONG
	DIM SearchKey AS STRING
	DIM SearchMaster AS STRING

	IF (DataIndex <= 0) OR (DataIndex > NumRows) THEN
		' There is nothing to do.
	ENDIF
	
	SELECT CASE DataTable(DataIndex&, TM_COL_TYPE%)
		CASE TM_TYPE_CATEGORY$
		CASE ELSE
			EXIT SUB
	END SELECT
		
	IF DataTable( DataIndex&, TM_COL_STATE% ) = TM_STATE_OPEN$ THEN
		NewState$ = TM_STATE_CLOSED$
	ELSE
		NewState$ = TM_STATE_OPEN$
	ENDIF
	DataTable( DataIndex&, TM_COL_STATE% ) = NewState$	
	
	SELECT CASE DataTable(DataIndex&, TM_COL_TYPE%)
		CASE TM_TYPE_CATEGORY$
			' Update the visual opened/closed indicator.
			IF NewState$ = TM_STATE_CLOSED$ THEN
				DisplayTable( DataIndex& ) = TM_INDENT_CATEGORY_CLOSED$ + \\
				       DataTable( DataIndex&, TM_COL_CATEGORY% )
			ELSE
				DisplayTable( DataIndex& ) = TM_INDENT_CATEGORY_OPEN$ + \\
				       DataTable( DataIndex&, TM_COL_CATEGORY% )
			ENDIF
			
			' Search through the entire data table, and make
			' visible/invisible all subcategories under this
			' category.
			SearchKey$ = DataTable(DataIndex&, TM_COL_CATEGORY%)
			SearchMaster$  = DataTable(DataIndex&, TM_COL_MASTER%)
			FOR Counter& = 1 TO NumRows&
				IF (DataTable( Counter&, TM_COL_CATEGORY% ) = \\
				   SearchKey$) AND \\
				   (DataTable( Counter&, TM_COL_MASTER% ) = \\
				   SearchMaster$) THEN
					SELECT CASE DataTable( Counter&, TM_COL_TYPE% )
						CASE TM_TYPE_SUBCATEGORY$
							IF NewState$ = TM_STATE_OPEN$ THEN
								DataTable( Counter&, TM_COL_VISIBLE% ) = TM_VISIBLE$
								IF DataTable( Counter&, TM_COL_STATE% ) = TM_STATE_OPEN$ THEN
									' We will call ToggleOpen recursively, so
									' set the open flag to the opposite of what we desire.
									DataTable( Counter&, TM_COL_STATE% ) = TM_STATE_CLOSED$
									ToggleOpen Counter&
								ENDIF
							ELSE
								DataTable( Counter&, TM_COL_VISIBLE% ) = TM_INVISIBLE$
							ENDIF
					END SELECT
				ENDIF
			NEXT Counter&
			
	END SELECT
	
	' Since this routine is accessed recursively, do not update the list box here.
	' If we do, it may end up being updated twice.

END SUB

'********************************************************************
'
'	Name:	RenameItem (subroutine)
'
'	Action:	Prompts the user for a new name for the item at
'              ItemNum in DataTable.  If the user does not cancel,
'              performs all necessary steps to rename the given item.
'
'	Params:	ItemNum - The index of an item in DataTable.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB RenameItem( ItemNum AS LONG )

	DIM MsgReturn AS LONG
	DIM MsgTitle AS STRING
	DIM FileReturn AS STRING
	DIM NewName AS STRING
	DIM CurName AS STRING
	DIM CurCategory AS STRING
	DIM CurSubCategory AS STRING
	DIM CurMaster AS STRING

	' Do a sanity check on ItemNum.
	IF (ItemNum& <= 0) OR (ItemNum& > NumRows&) THEN
		EXIT SUB	
	ENDIF

	' Perform a different operation depending on the
	' type of item selected.
	SELECT CASE DataTable( ItemNum&, TM_COL_TYPE% )
		CASE TM_TYPE_LABEL$
			' Cannot rename these.
			MsgReturn& = MESSAGEBOX("Impossível renomear o item selecionado." + NL2 + \\
			                        "Selecione uma categoria (por exemplo, " + NL + \\
			                        "'Publicidade' ou 'Brochuras') ou um " + NL + \\
			                        "arquivo de modelo.", \\
			                        TITLE_INFOBOX$, \\
			                        MB_INFORMATION_ICON&)
			EXIT SUB

		CASE TM_TYPE_CATEGORY$
			CurName$ = DataTable( ItemNum&, TM_COL_CATEGORY% )
			CurMaster$ = DataTable( ItemNum&, TM_COL_MASTER% )
			NewName$ = INPUTBOX("Digite um novo nome para '" + \\
			                    CurName$ + "'.")
			IF (LEN(NewName$) <= 0) THEN
				' The user did not enter anything or pressed Cancel.
				EXIT SUB
			ELSEIF FindDuplicates(NewName$, CurMaster$) THEN
				MsgReturn& = MESSAGEBOX("Outra categoria " + \\
				                        "com o nome '" + NewName$ + "' já " + \\
				                        "existe no grupo '" + CurMaster$ + "' ." + NL2 + \\
				                        "Várias categorias com o mesmo nome podem " + \\
				                        "confundir; portanto, selecione um nome " + \\
				                        "que não seja utilizado atualmente." + NL2 + \\
				                        "Pressione o botão Renomear novamente para " + \\
				                        "tentar outra vez.", \\
				                        TITLE_INFOBOX$, \\
				                        MB_OK_ONLY&)
				EXIT SUB
			ELSEIF FindIllegalCharacters(CurName$) THEN
				MsgReturn& = MESSAGEBOX("O nome digitado contém " + \\
				                        "caracteres ilegais." + NL2 + \\
				                        "Pressione o botão Renomear para " + \\
				                        "tentar outra vez.", \\
				                        TITLE_INFOBOX$, \\
				                        MB_OK_ONLY&)
				EXIT SUB
			ENDIF	
			DataTable( ItemNum&, TM_COL_CATEGORY% ) = NewName$
			SetDisplayText ItemNum&
			UpdateSingle ItemNum&
			
			' Now search through, and replace all references to the
			' old name with the new name.
			ReplaceAll NewName$, CurName$, CurMaster$ 
			
			EXIT SUB
				
		CASE TM_TYPE_SUBCATEGORY$
			CurCategory$ = DataTable( ItemNum&, TM_COL_CATEGORY% )
			CurName$ = DataTable( ItemNum&, TM_COL_SUBCATEGORY% )
			CurMaster$ = DataTable( ItemNum&, TM_COL_MASTER% )
			
			' Open a file selection box.
			MsgTitle$ = "Selecione um arquivo para substituir '" + CurName$ + "'"
			ON ERROR GOTO UseSimplerDialog
				FileReturn$ = GETFILEBOX("Modelo do CorelDRAW (*.cdt)|*.cdt", \\
				                         MsgTitle$, \\
				                         0, \\
									CurName$, \\
				                         , \\
				                         , \\
				                         "&OK" )
				' If we survived the GetFileBox call, then skip the next step.
				GOTO GotFile

				' If we did not survive, the default filename provided was
				' invalid.
				UseSimplerDialog:
					ERRNUM = 0
					ON ERROR EXIT
					FileReturn$ = GETFILEBOX("Modelo do CorelDRAW (*.cdt)|*.cdt", \\
					                         MsgTitle$, \\
					                         0, \\
										, \\
					                         , \\
					                         , \\
					                         "&OK" )
					RESUME AT GotFile

			ON ERROR EXIT
			GotFile:
			IF (LEN(FileReturn$) <= 0) THEN
				' The user selected nothing or pressed Cancel.
				EXIT SUB
			ELSEIF (FILESIZE(FileReturn$) <= 0) THEN
				MsgReturn& = MESSAGEBOX( "O arquivo selecionado " + \\
				                         "não existe." + NL2 + \\
				                         "O Assistente de Personalização " + \\
				                         "de Modelos só pode adicionar arquivos " + \\
				                         "que ele consegue localizar. Pode ser " + \\
				                         "uma boa idéia tentar outra vez " + \\
				                         "com outro nome de arquivo.", \\
				                         TITLE_ERRORBOX$, \\
				                         MB_EXCLAMATION_ICON& )
				EXIT SUB
			END IF
			
			' Currently we do not check for duplicates.
			
			' The file name is valid.
			DataTable( ItemNum&, TM_COL_SUBCATEGORY% ) = FileReturn$
			SetDisplayText ItemNum&
			UpdateSingle ItemNum&
		
	END SELECT

END SUB

'********************************************************************
'
'	Name:	ReplaceAll (subroutine)
'
'	Action:	Searches through DataTable and replaces all Category
'              items that have a given string with a new string.
'
'	Params:	InNew - The string to replace old strings with.
'              InOld - The string to search for and get replaced.
'              CurMaster - One of TM_MASTER_CORELDRAW$,
'					  TM_MASTER_PD_GRAPHICS$, or TM_MASTER_PD_TEXTONLY$.
'                      	  The category of items to search through.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB ReplaceAll( InNew AS STRING, InOld AS STRING, CurMaster AS STRING )

	DIM Counter AS LONG

	FOR Counter& = 1 TO NumRows&
		IF (UCASE(DataTable(Counter&, TM_COL_CATEGORY%)) = UCASE(InOld$)) AND \\
		   (DataTable(Counter&, TM_COL_MASTER%) = CurMaster$) THEN
			DataTable(Counter&, TM_COL_CATEGORY%) = InNew$
			UpdateSingle Counter&
		ENDIF
	NEXT Counter&	

END SUB

'********************************************************************
'
'	Name:	FindDuplicates (function)
'
'	Action:	Determines if a given string already exists as a 
'              Category name in DataTable.
'              
'	Params:	InString - The string to search for.
'              CurMaster - One of TM_MASTER_CORELDRAW,
'					  TM_MASTER_PD_GRAPHICS, TM_MASTER_PD_TEXTONLY.
'	                      The category of items to search through.
'
'	Returns:	TRUE if item(s) exist with the given string.
'              FALSE otherwise.
'
'	Comments:	The search is not case sensitive.
'
'********************************************************************
FUNCTION FindDuplicates( InString AS STRING, CurMaster AS STRING ) AS BOOLEAN

	DIM Counter AS LONG

	FOR Counter& = 1 TO NumRows&
		IF (DataTable( Counter, TM_COL_MASTER% ) = CurMaster$) THEN
			IF (UCASE( DataTable( Counter&, TM_COL_CATEGORY% ) ) = \\
			    UCASE( InString$ )) THEN
				FindDuplicates = TRUE
				EXIT FUNCTION
			ENDIF
		ENDIF
	NEXT Counter&

	FindDuplicates = FALSE

END FUNCTION

'********************************************************************
'
'	Name:	FindIllegalCharacters (function)
'
'	Action:	Determines if a given string contains characters
'              that are not legal in a Category or Subcategory name.
'              
'	Params:	InString - The string to search through.
'
'	Returns:	TRUE if the name is not legal.  FALSE otherwise.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION FindIllegalCharacters( InString AS STRING ) AS BOOLEAN

	' The only illegal character, currently, is '='.
	IF (INSTR(InString, "=") <> 0) THEN
		FindIllegalCharacters = TRUE
	ELSE
		FindIllegalCharacters = FALSE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	SetDisplayText (subroutine)
'
'	Action:	Looks at the current state of an item in DataTable
'              and updates its representation in DisplayTable appropriately.
'              (For instance, the item may be open, so its display item
'              should have a prefix with a "-" sign in it.)
'              
'	Params:	ItemNum - The index of the item to update in both tables.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB SetDisplayText( ItemNum AS LONG )

	' Do a sanity check on ItemNum.
	IF (ItemNum& <= 0) OR (ItemNum& > NumRows&) THEN
		EXIT SUB	
	ENDIF
	
	' Depending on the type and state, use different prefixes.
	SELECT CASE DataTable( ItemNum&, TM_COL_TYPE% )
		CASE TM_TYPE_CATEGORY$	
			IF (DataTable( ItemNum&, TM_COL_STATE% ) = TM_STATE_OPEN$) THEN
				DisplayTable( ItemNum& ) = TM_INDENT_CATEGORY_OPEN$ + DataTable( ItemNum&, TM_COL_CATEGORY% )
			ELSE
				DisplayTable( ItemNum& ) = TM_INDENT_CATEGORY_CLOSED$ + DataTable( ItemNum&, TM_COL_CATEGORY% )
			ENDIF
	
		CASE TM_TYPE_SUBCATEGORY$
			DisplayTable( ItemNum& ) = TM_INDENT_SUBCATEGORY$ + DataTable( ItemNum&, TM_COL_SUBCATEGORY% )
			
		CASE TM_TYPE_LABEL$
			' No need to ever change labels.
	END SELECT

END SUB

'********************************************************************
'
'	Name:	AddCategoryUnder (subroutine)
'
'	Action:	Takes the index of an item in DataTable that has type
'              TM_TYPE_LABEL$ and attempts to add a new category under it.
'			Prompts the user for the name of the new item.  The user 
'			may select Cancel and nothing will be done.
'              
'	Params:	ItemNum - The index of the item in DataTable to try and
'                        add a category under.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB AddCategoryUnder( ItemNum AS LONG )

	DIM CurType AS STRING
	DIM CurCategory AS STRING
	DIM CurSubCategory AS STRING
	DIM CurLabel AS STRING
	DIM CurMaster AS STRING
	DIM MsgReturn AS LONG
	DIM MsgText AS STRING
	DIM NewName AS STRING
	DIM ShiftCounter AS LONG
	DIM VisibleIndex AS LONG
	DIM AlreadyVisible AS BOOLEAN

	' Retrieve the type of the selected item.
	CurType$ = DataTable( ItemNum&, TM_COL_TYPE% )
	IF (CurType$ <> TM_TYPE_LABEL$) THEN

			MsgText$ = "Não é possível adicionar categorias abaixo do nível que você selecionou." + NL2 + \\
					 "As categorias só podem ser adicionadas abaixo de 'Modelos do CorelDRAW', " + NL + \\
                          "'Modelos de Gráficos e Texto Paper Direct' e 'Modelos Somente Texto " + NL + \\
                          "Paper Direct'." + NL2 + \\
                          "Por exemplo, caso você deseje adicionar uma nova categoria denominada " + NL + \\
                          "'Informativa' e exibi-la como 'Modelos do " + NL + \\
                          "CorelDRAW\Informativa', selecione o item 'Modelos " + NL + \\
                          "do CorelDRAW'." + NL2 + "Tente outra vez."
			MsgReturn& = MESSAGEBOX( MsgText$, TITLE_INFOBOX$, MB_EXCLAMATION_ICON& )
			EXIT SUB

	ENDIF

	' Ask the user for the name of the new category.
	NewName$ = INPUTBOX("Digite um nome para a nova categoria.")
	IF LEN(NewName$) <= 0 THEN
		' The user pressed Cancel or entered nothing.
		EXIT SUB
	ENDIF
	
	' Retrieve full information about the selected item.
	CurCategory$ = DataTable( ItemNum&, TM_COL_CATEGORY% )
	CurSubCategory$ = DataTable( ItemNum&, TM_COL_SUBCATEGORY% )
	CurMaster$ = DataTable( ItemNum&, TM_COL_MASTER% )
	CurLabel$ = DisplayTable( ItemNum& )
	
	' Make sure we do not add any duplicate categories 
	' to the table.  Duplicates are only permitted across master
	' divisions (ie. PaperDirect/CorelDRAW).
	IF FindDuplicates(NewName$, CurMaster$) THEN
		MsgText$ = "Uma categoria denominada '" + NewName$ + "' existe " + \\
		           "atualmente em '" + CurMaster$ + "'." + NL2 + \\
		           "Possuir dois nomes idênticos embaixo de '" + CurMaster$ + "' originaria confusão, " + \\
		           "portanto, não é permitido.  Escolha um novo nome " + \\
		           "e tente outra vez."
		MsgReturn& = MESSAGEBOX( MsgText$, TITLE_ERRORBOX$, MB_EXCLAMATION_ICON& )
		EXIT SUB
	ENDIF
	
	' Increase the size of the data table, then shift everything 
	' after ItemNum down by one.
	NumRows& = NumRows& + 1
	REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM PRESERVE DisplayTable( 1 TO NumRows& )
	FOR ShiftCounter& = NumRows& TO (ItemNum& + 2) STEP -1
		DataTable( ShiftCounter&, TM_COL_TYPE% ) = DataTable( ShiftCounter& - 1, TM_COL_TYPE% )
		DataTable( ShiftCounter&, TM_COL_CATEGORY% ) = DataTable( ShiftCounter& - 1, TM_COL_CATEGORY% )
		DataTable( ShiftCounter&, TM_COL_SUBCATEGORY% ) = DataTable( ShiftCounter& - 1, TM_COL_SUBCATEGORY% )
		DataTable( ShiftCounter&, TM_COL_MASTER% ) = DataTable( ShiftCounter& - 1, TM_COL_MASTER% )
		DataTable( ShiftCounter&, TM_COL_STATE% ) = DataTable( ShiftCounter& - 1, TM_COL_STATE% )
		DataTable( ShiftCounter&, TM_COL_VISIBLE% ) = DataTable( ShiftCounter& - 1, TM_COL_VISIBLE% )
		DisplayTable( ShiftCounter& ) = DisplayTable( ShiftCounter& - 1)
	NEXT ShiftCounter&

	' Add in the new row.
	IF CurType$ = TM_TYPE_LABEL$ THEN
		DataTable( ItemNum& + 1, TM_COL_TYPE% ) = TM_TYPE_CATEGORY$
		DataTable( ItemNum& + 1, TM_COL_CATEGORY% ) = NewName$
		DataTable( ItemNum& + 1, TM_COL_SUBCATEGORY% ) = ""
		DisplayTable( ItemNum& + 1 ) = TM_INDENT_CATEGORY_OPEN$ + NewName$
	ELSE
		DataTable( ItemNum& + 1, TM_COL_TYPE% ) = TM_TYPE_SUBCATEGORY$
		DataTable( ItemNum& + 1, TM_COL_CATEGORY% ) = CurCategory$
		DataTable( ItemNum& + 1, TM_COL_SUBCATEGORY% ) = NewName$
		DisplayTable( ItemNum& + 1) = TM_INDENT_SUBCATEGORY$ + NewName$
	ENDIF
	DataTable( ItemNum& + 1, TM_COL_MASTER% ) = CurMaster$
	DataTable( ItemNum& + 1, TM_COL_STATE% ) = TM_STATE_OPEN$
	
	' Use the parent's information to obtain visibility info.
	IF DataTable( ItemNum&, TM_COL_STATE% ) = TM_STATE_OPEN$ THEN
		DataTable( ItemNum& + 1, TM_COL_VISIBLE% ) = TM_VISIBLE$
	ELSE
		DataTable( ItemNum& + 1, TM_COL_VISIBLE% ) = TM_INVISIBLE$
	ENDIF

	' If the item is visible, add it to the list box.
	IF DataTable( ItemNum& + 1, TM_COL_VISIBLE% ) = TM_VISIBLE$ THEN
		ConvertDataToVisibleIndex ItemNum& + 1, VisibleIndex&, AlreadyVisible
		SelectDialog.SelectListbox.AddItem DisplayTable(ItemNum& + 1), VisibleIndex&
	ENDIF

END SUB

'********************************************************************
'
'	Name:	WriteTemplateSettingsFile (function)
'
'	Action:	Dumps the contents of DataTable to OutFilePath, deleting
'              any file that is already there (if any).
'              
'	Params:	OutFilePath - the filename and path to write to.
'
'	Returns:	TRUE if successful, FALSE if an error occurs.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION WriteTemplateSettingsFile( OutFilePath AS STRING ) AS BOOLEAN

	DIM WriteSuccess AS BOOLEAN
	DIM Counter AS LONG
	DIM CurCategory AS STRING
	DIM CurSubCategory AS STRING
	DIM CurMaster AS STRING
	DIM WriteAppName AS STRING
	DIM WriteKeyName AS STRING
	DIM WriteKeyVal AS STRING

	' Check to see if a file already exists at OutFilePath.
	IF (FILESIZE(OutFilePath) > 0) THEN

		ON ERROR GOTO DeleteError

		KILL OutFilePath$
		GOTO SurvivedDelete

		DeleteError:
			ERRNUM = 0
			WriteTemplateSettingsFile = FALSE
			RESUME AT ExitPoint
			ExitPoint:
			EXIT FUNCTION

		SurvivedDelete:
		ON ERROR EXIT
	ENDIF

	' Force Windows to flush the cache on this INI file so that
	' we see the most recent version.
	WriteSuccess = WritePrivateProfileStringNULLS( 0, 0, 0, OutFilePath$ )

	' Attempt to write a header to the output file.
	WriteSuccess = WritePrivateProfileString("Informações do Arquivo de Modelos", \\
	                                         "Criador", \\
	                                         "Assistente de Personalização de Modelos do CorelDraw 7.0", \\
	                                         OutFilePath$)
	IF NOT WriteSuccess THEN
		WriteTemplateSettingsFile = FALSE
		EXIT FUNCTION
	ENDIF
	
	' Write the 'Template Types' section, which is always the same.
	' (No one is allowed to add template types.)
	WriteSuccess = WritePrivateProfileString("Tipos de Modelos", \\
	                                         "Modelos do CorelDRAW", \\
	                                         "1", \\
	                                         OutFilePath$)
	IF NOT WriteSuccess THEN
		WriteTemplateSettingsFile = FALSE
		EXIT FUNCTION
	ENDIF
	WriteSuccess = WritePrivateProfileString("Tipos de Modelos", \\
	                                         "Modelos de Gráficos e Texto Paper Direct", \\
	                                         "1", \\
	                                         OutFilePath$)
	IF NOT WriteSuccess THEN
		WriteTemplateSettingsFile = FALSE
		EXIT FUNCTION
	ENDIF
	WriteSuccess = WritePrivateProfileString("Tipos de Modelos", \\
	                                         "Modelos Somente Texto Paper Direct", \\
	                                         "1", \\
	                                         OutFilePath$)
	IF NOT WriteSuccess THEN
		WriteTemplateSettingsFile = FALSE
		EXIT FUNCTION
	ENDIF

	' Loop through each row of DataTable and write it to OutFilePath.
	FOR Counter& = 1 TO NumRows&
	
		SELECT CASE DataTable( Counter&, TM_COL_TYPE% )

			CASE TM_TYPE_CATEGORY$
				CurCategory$ = DataTable( Counter&, TM_COL_CATEGORY% )
				CurMaster$ = DataTable( Counter&, TM_COL_MASTER% )
				SELECT CASE CurMaster$
					CASE TM_MASTER_CORELDRAW$
						WriteAppName$ = "CorelDRAW Templates"
						WriteKeyName$ = "CDCategory - " + CurCategory$
					CASE TM_MASTER_PD_GRAPHICS$
						WriteAppName$ = "Paper Direct Graphics & Text Templates"
						WriteKeyName$ = "PDGTCategory - " + CurCategory$
					CASE TM_MASTER_PD_TEXTONLY$
						WriteAppName$ = "Paper Direct Text Only Templates"
						WriteKeyName$ = "PDTOCategory - " + CurCategory$
				END SELECT
				WriteKeyVal$ = "1"
				WriteSuccess = WritePrivateProfileString( WriteAppName$, \\
				                                          WriteKeyName$, \\
				                                          WriteKeyVal$, \\
				                                          OutFilePath$ )
				IF NOT WriteSuccess THEN
					WriteTemplateSettingsFile = FALSE
					EXIT FUNCTION
				ENDIF
								 
			CASE TM_TYPE_SUBCATEGORY$
				CurCategory$ = DataTable( Counter&, TM_COL_CATEGORY% )
				CurSubCategory$ = DataTable( Counter&, TM_COL_SUBCATEGORY% )
				CurMaster$ = DataTable( Counter&, TM_COL_MASTER% )
				SELECT CASE CurMaster$
					CASE TM_MASTER_CORELDRAW$
						WriteAppName$ = "CDCategory - " + CurCategory$
					CASE TM_MASTER_PD_GRAPHICS$
						WriteAppName$ = "PDGTCategory - " + CurCategory$
					CASE TM_MASTER_PD_TEXTONLY$
						WriteAppName$ = "PDTOCategory - " + CurCategory$
				END SELECT
				WriteKeyName$ = CurSubCategory$
				WriteKeyVal$  = "1"
				WriteSuccess = WritePrivateProfileString( WriteAppName$, \\
				                                          WriteKeyName$, \\
				                                          WriteKeyVal$, \\
				           						  OutFilePath$ )
				IF NOT WriteSuccess THEN
					WriteTemplateSettingsFile = FALSE
					EXIT FUNCTION
				ENDIF

		END SELECT
	
	NEXT Counter&
	
	' Force Windows to flush the cache on this INI file so that
	' future calls see the most recent version.
	WriteSuccess = WritePrivateProfileStringNULLS( 0, 0, 0, OutFilePath$ )

	' Return successfully.
	WriteTemplateSettingsFile = TRUE

END FUNCTION

'********************************************************************
'
'	Name:	AddNewSubcategory (subroutine)
'
'	Action:	Adds a new Subcategory item to DataTable.  Finds the
'              appropriate place to insert it.
'              
'	Params:	InCategory - The category of the new FilePath.
'              InMaster - One of TM_MASTER_CORELDRAW%, 
'                         TM_MASTER_PD_GRAPHICS%, or TM_MASTER_PD_TEXTONLY%.
'					 This is the group to which InCategory belongs.
'              InChosenFile - The actual file and path to insert
'						as a subcategory.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB AddNewSubcategory( InCategory AS STRING, \\
                       InMaster AS STRING, \\
				   InChosenFile AS STRING )

	DIM Counter AS LONG
	DIM Found AS BOOLEAN
	DIM CurCategory AS STRING
	DIM CurMaster AS STRING
	DIM ShiftCounter AS LONG
	
	' Loop through the data table, and find the first row of the
	' required category.
	Counter& = 1
	Found = FALSE
	WHILE (Counter& <= NumRows&) AND (NOT Found)

		' Retrieve what is in this row in the data table.
		CurCategory$ = DataTable( Counter&, TM_COL_CATEGORY% )
		CurMaster$ = DataTable( Counter&, TM_COL_MASTER% )

		' Check for a match.
		IF (CurCategory$ = InCategory$) AND \\
		   (CurMaster$ = InMaster$) THEN
			Found = TRUE
		ENDIF

		Counter& = Counter& + 1
	
	WEND
	
	' If we don't find a match, then the category was not found.
	' This error should have been caught before, but just for
	' safety do nothing.
	IF NOT Found THEN
		EXIT SUB
	ENDIF

	' Increase the size of the data table, then shift everything down
	' by one.
	NumRows& = NumRows& + 1
	REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM PRESERVE DisplayTable( 1 TO NumRows& )
	FOR ShiftCounter& = NumRows& TO (Counter& + 1) STEP -1
		DataTable( ShiftCounter&, TM_COL_TYPE% ) = DataTable( ShiftCounter& - 1, TM_COL_TYPE% )
		DataTable( ShiftCounter&, TM_COL_CATEGORY% ) = DataTable( ShiftCounter& - 1, TM_COL_CATEGORY% )
		DataTable( ShiftCounter&, TM_COL_SUBCATEGORY% ) = DataTable( ShiftCounter& - 1, TM_COL_SUBCATEGORY% )
		DataTable( ShiftCounter&, TM_COL_MASTER% ) = DataTable( ShiftCounter& - 1, TM_COL_MASTER% )
		DataTable( ShiftCounter&, TM_COL_STATE% ) = DataTable( ShiftCounter& - 1, TM_COL_STATE% )
		DataTable( ShiftCounter&, TM_COL_VISIBLE% ) = DataTable( ShiftCounter& - 1, TM_COL_VISIBLE% )
		DisplayTable( ShiftCounter& ) = DisplayTable( ShiftCounter& - 1)
	NEXT ShiftCounter&

	' Add in the new row.
	DataTable( Counter&, TM_COL_TYPE% ) = TM_TYPE_SUBCATEGORY$
	DataTable( Counter&, TM_COL_CATEGORY% ) = InCategory$
	DataTable( Counter&, TM_COL_SUBCATEGORY% ) = InChosenFile$
	DataTable( Counter&, TM_COL_MASTER% ) = InMaster$
	DisplayTable( Counter& ) = TM_INDENT_SUBCATEGORY$ + InChosenFile$

	' Use the subcategory information to obtain visibility info.
	DataTable( Counter&, TM_COL_STATE% ) = TM_STATE_CLOSED$
	IF DataTable( Counter& - 1, TM_COL_STATE% ) = TM_STATE_OPEN$ THEN
		DataTable( Counter&, TM_COL_VISIBLE% ) = TM_VISIBLE$
	ELSE
		DataTable( Counter&, TM_COL_VISIBLE% ) = TM_INVISIBLE$
	ENDIF

END SUB

'********************************************************************
'
'	Name:	AlreadyPresent (function)
'
'	Action:	Determines if we will have a problem copying files
'              to the CorelDRAW templates directory.
'              
'	Params:	FileName - The name (not path) of a file.
'
'	Returns:	TRUE if CopyFiles is TRUE and there is already a
'              file in the CorelDRAW templates directory with the name
'              FileName.  FALSE otherwise.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION AlreadyPresent ( FileName AS STRING ) AS BOOLEAN

	' If we're not copying files to the CorelDRAW templates directory,
	' we do not have to worry about overwriting.
	IF NOT CopyFiles THEN
		AlreadyPresent = FALSE
		EXIT FUNCTION
	ENDIF

	IF (FILESIZE( TemplateStoreDir$ + "\" + FileName$ ) > 0) THEN
		AlreadyPresent = TRUE
	ELSE
		AlreadyPresent = FALSE
	ENDIF

END FUNCTION

'********************************************************************
'
'	Name:	ExtractFileName (function)
'
'	Action:	Takes a full filename and path and returns the filename
'              component.
'              
'	Params:	FilePath - A full path to a specific file.
'
'	Returns:	The filename.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ExtractFileName ( FilePath AS STRING ) AS STRING

	DIM LastSlash AS LONG
	DIM Counter AS LONG
	
	LastSlash = 1
	FOR Counter& = 1 TO LEN(FilePath$)
		IF MID(FilePath$, Counter&, 1) = "\" THEN
			LastSlash& = Counter&
		ENDIF
	NEXT Counter&

	ExtractFileName$ = MID(FilePath, LastSlash& + 1)

END FUNCTION

'********************************************************************
'
'	Name:	ExtractDirectory (function)
'
'	Action:	Takes a full filename and path and returns the path
'              component.
'              
'	Params:	FilePath - A full path to a specific file.
'
'	Returns:	The path (with no trailing backslash).
'
'	Comments:	None.
'
'********************************************************************
FUNCTION ExtractDirectory ( FilePath AS STRING ) AS STRING	

	DIM LastSlash AS LONG
	DIM Counter AS LONG
	
	LastSlash = 1
	FOR Counter& = 1 TO LEN(FilePath$)
		IF MID(FilePath$, Counter&, 1) = "\" THEN
			LastSlash& = Counter&
		ENDIF
	NEXT Counter&

	ExtractDirectory$ = MID(FilePath, 1, LastSlash& - 1)

END FUNCTION

'********************************************************************
'
'	Name:	RemoveItem (subroutine)
'
'	Action:	Attempts to remove a given item from DataTable.
'              If applicable, also removes all items dependent on it
'              (ie. subcategories under a removed category).
'              
'	Params:	ItemNum - The index of the item in DataTable to remove.
'
'	Returns:	None.
'
'	Comments:	Updates SelectDialog.SelectListBox.
'
'********************************************************************
SUB RemoveItem( ItemNum AS LONG )

	DIM CurType AS STRING
	DIM MsgReturn AS LONG
	DIM MsgText AS STRING
	DIM CurCategory AS STRING
	DIM CurSubCategory AS STRING
	DIM CurLabel AS STRING
	DIM CurMaster AS STRING
	DIM Counter AS LONG
	DIM AnythingChanged AS BOOLEAN
	DIM ShiftCounter AS LONG
	DIM ShiftFactor AS LONG
	
	' Retrieve the type of the selected item.
	CurType$ = DataTable( ItemNum&, TM_COL_TYPE% )
	IF (CurType$ = TM_TYPE_LABEL$) THEN
		MsgText$ = "Não é permitido apagar as " + \\
		           "categorias principais." + NL2 + \\	
				 "Tente outra vez."
		MsgReturn& = MESSAGEBOX( MsgText$, TITLE_INFOBOX$, \\
		                         MB_EXCLAMATION_ICON& )
		EXIT SUB
	ENDIF
	
	' Retrieve full information about the selected item.
	CurCategory$ = DataTable( ItemNum&, TM_COL_CATEGORY% )
	CurSubCategory$ = DataTable( ItemNum&, TM_COL_SUBCATEGORY% )
	CurMaster$ = DataTable( ItemNum&, TM_COL_MASTER% )
	CurLabel$ = DisplayTable( ItemNum& )
	
	' Confirm removal.
	SELECT CASE CurType$
		CASE TM_TYPE_CATEGORY$
			MsgText$ = "Deseja realmente remover '" + \\
			           CurCategory$ + "' e tudo o que estiver abaixo?"
		CASE TM_TYPE_SUBCATEGORY$
			MsgText$ = "Deseja realmente remover '" + \\
			           CurSubCategory$ + "'?"
	END SELECT
	MsgReturn& = MESSAGEBOX( MsgText$, "É necessário confirmar", \\
	                         MB_YES_NO& OR MB_QUESTION_ICON& )
	IF MsgReturn& <> MSG_YES& THEN
		EXIT SUB
	ENDIF
	
	' Actually perform the removal.
	Counter& = ItemNum& + 1
	AnythingChanged = FALSE
	WHILE (Counter& <= NumRows&) AND (NOT AnythingChanged)

		' If we've got a subcategory, we only remove one row from the
		' data table.
		IF (CurType$ = TM_TYPE_SUBCATEGORY$) THEN
			AnythingChanged = TRUE
		ENDIF
		
		' If we've got a category, we stop removing soon
		' as the category changes.
		IF (CurType$ = TM_TYPE_CATEGORY$) AND \\
		   (CurCategory$ <> DataTable(Counter&, TM_COL_CATEGORY%)) THEN
			AnythingChanged = TRUE
		ENDIF

		IF NOT AnythingChanged THEN
			Counter = Counter + 1
		ENDIF

	WEND
	
	' Shift everything that remains down.
	ShiftFactor& = Counter& - ItemNum&
	FOR ShiftCounter& = ItemNum& TO NumRows& - ShiftFactor&

		DataTable( ShiftCounter&, TM_COL_TYPE% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_TYPE% )
		DataTable( ShiftCounter&, TM_COL_CATEGORY% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_CATEGORY% )
		DataTable( ShiftCounter&, TM_COL_SUBCATEGORY% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_SUBCATEGORY% )
		DataTable( ShiftCounter&, TM_COL_MASTER% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_MASTER% )
		DataTable( ShiftCounter&, TM_COL_STATE% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_STATE% )
		DataTable( ShiftCounter&, TM_COL_VISIBLE% ) = DataTable( ShiftCounter& + ShiftFactor&, TM_COL_VISIBLE% )
		DisplayTable( ShiftCounter& ) = DisplayTable( ShiftCounter& + ShiftFactor&)
			
	NEXT ShiftCounter&

	' Resize the tables.
	NumRows& = NumRows& - ShiftFactor&
	REDIM PRESERVE DataTable( 1 TO NumRows&, 1 TO 6)
	REDIM PRESERVE DisplayTable( 1 TO NumRows& )

	' Update the list box.
	UpdateEverythingAfter ItemNum&

END SUB

'********************************************************************
'
'	Name:	AskForSelection (subroutine)
'
'	Action:	Displays a small messagebox asking the user to select
'              something.
'              
'	Params:	None.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB AskForSelection()

	DIM MsgReturn AS LONG
	DIM MsgText AS STRING
	
	MsgText$ = "Selecione algo."
	MsgReturn& = MESSAGEBOX( MsgText$, "", MB_OK_ONLY& )

END SUB

'********************************************************************
'
'	Name:	UpdateEverythingAfter (subroutine)
'
'	Action:	Takes the index of an item in DataTable and
'              updates every item in SelectDialog's list box 
'              with index >= the given index.
'              This is useful whenever a change you make to
'              DataTable potentially affects many items below
'              the item you changed (ie. when you delete a
'              category or when you collapse/open a category, etc).
'              
'	Params:	ItemNum - The item number in DataTable.
'
'	Returns:	None.
'
'	Comments:	None.
'
'********************************************************************
SUB UpdateEverythingAfter( ItemNum AS LONG )

	DIM VisibleIndex AS LONG
	DIM AlreadyVisible AS BOOLEAN
	DIM Counter AS LONG

	' Loop through and update the list box.
	ConvertDataToVisibleIndex ItemNum&, VisibleIndex&, AlreadyVisible	
	FOR Counter& = VisibleIndex& TO SelectDialog.SelectListBox.GetItemCount()
		SelectDialog.SelectListBox.RemoveItem SelectDialog.SelectListBox.GetItemCount()
	NEXT Counter&	

	' Since some rows may have disappeared completely, the size of the
	' list box may have shrunk.
	FOR Counter& = ItemNum& TO NumRows&
		IF DataTable( Counter&, TM_COL_VISIBLE% ) = TM_VISIBLE$ THEN
			SelectDialog.SelectListBox.AddItem DisplayTable(Counter&)
		ENDIF	
	NEXT Counter&

END SUB

'********************************************************************
'
'	Name:	UpdateSingle (subroutine)
'
'	Action:	Updates SelectDialog's list box for a single item
'              in DataTable.
'              
'	Params:	NumIndex - The index of the item in DataTable that
'                         needs updating.
'
'	Returns:	None.
'
'	Comments:	Call this when you've changed the display attribute
'              of a single item in DataTable and want the changes
'              to take effect.
'
'********************************************************************
SUB UpdateSingle ( NumIndex AS LONG )

	DIM IsVisible AS BOOLEAN
	DIM VisibleIndex AS LONG
	
	ConvertDataToVisibleIndex NumIndex&, VisibleIndex&, IsVisible
	IF IsVisible THEN
		SelectDialog.SelectListBox.RemoveItem VisibleIndex&
		SelectDialog.SelectListBox.AddItem DisplayTable(NumIndex&), VisibleIndex&
	ENDIF

END SUB

'********************************************************************
'
'	Name:	GetNumVisible (function)
'
'	Action:	Looks through DataTable and finds out how many items
'              should currently be visible in SelectDialog's list box.
'              
'	Params:	None.
'
'	Returns:	The count of items that have their visible flag set.
'
'	Comments:	None.
'
'********************************************************************
FUNCTION GetNumVisible() AS LONG

	DIM Counter AS LONG
	DIM NumVisibleFoundSoFar AS LONG
	
	' Count how many items should be visible.
	NumVisibleFoundSoFar = 0
	FOR Counter& = 1 TO NumRows&
		IF DataTable( Counter&, TM_COL_VISIBLE% ) = TM_VISIBLE$ THEN
			NumVisibleFoundSoFar = NumVisibleFoundSoFar + 1
		ENDIF
	NEXT Counter&
	
	GetNumVisible = NumVisibleFoundSoFar

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
