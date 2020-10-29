REM Computer guesses your animals and learns them.
REM Animals.csc August 10, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

' FUNCTION declarations
DECLARE SUB Intro()
DECLARE SUB EndMessage()
DECLARE SUB LoadDatabase( filename$ )
DECLARE SUB SaveDatabase( filename$ )
DECLARE FUNCTION QuestionUser() AS BOOLEAN
DECLARE SUB ShowSuggestion()
DECLARE FUNCTION Guess( a% ) AS INTEGER
DECLARE SUB FindAnimal()

' GLOBAL variables and constants
GLOBAL CONST MAXDATA%=999       ' Size of database
GLOBAL CONST YES%=6             ' Messagebox yes value
GLOBAL CONST YESNOBUTTONS%=4    ' messagebox YES/NO buttons
GLOBAL CONST TITLE$="Animal Game" ' Game title
GLOBAL anim(MAXDATA) AS STRING  ' holds animal database
GLOBAL animsize AS INTEGER      ' Size of animal database				

' local main variable
CONST FILENAME$ = "animals.gme" ' name of the file

'==========================================================
' Display intro
Intro
' Fill up databASe
LoadDatabase(FILENAME)
' question loop
DO 
LOOP WHILE QuestionUser()

IF MESSAGEBOX("Do you want to save this game?",TITLE,YESNOBUTTONS)=YES THEN
	' Save database
	SaveDatabase(FILENAME)
END IF
' end message
EndMessage

'==========================================================
' Display introduction message
SUB Intro
	DIM temp AS STRING	' holds temporary string
	temp = "Play GUESS THE ANIMAL with Corel SCRIPT" + CHR(13)
	temp = temp + "Think of an animal and the computer will try to guess it..."
	MESSAGE temp
END SUB

'==========================================================
' Display end message
SUB EndMessage
	DIM temp AS STRING	' holds temporary string
	temp = "Thank you for playing."
	MESSAGE  temp 
END SUB

'==========================================================
' Try to load database from file.
' if file is currupted or not present, assign default values
SUB LoadDatabase( filename$ )
	ON ERROR GOTO errorhandler
	DIM a AS INTEGER		' loop var

	OPEN filename FOR INPUT AS 1
	INPUT #1, animsize
	FOR a=1 TO animsize
		INPUT #1, anim(a)
	NEXT a
	CLOSE #1
	
	subend:
	EXIT SUB
	errorhandler:
		' We could not load database
		' Assign default values
		CLOSE #1
		animsize=3
		anim(1)="?002003Does it swim?"
		anim(2)="!Gold fish"
		anim(3)="!Hawk"
		resume at subend
END SUB

'==========================================================
' Try to save database to file.
SUB SaveDatabase( filename$ )
	ON ERROR GOTO errorhandler
	DIM a AS INTEGER		' loop var

	OPEN filename FOR OUTPUT AS 1
	WRITE #1, animsize
	FOR a = 1 TO animsize
		WRITE #1, anim(a)
	NEXT a
	CLOSE #1
	
	subend:
	EXIT SUB
	errorhandler:
		' We could not save database
		CLOSE #1
		MESSAGE "Error saving game!"
		RESUME AT subend
END SUB

'==========================================================
' Question user on a animal
FUNCTION QuestionUser AS BOOLEAN
	DIM ans AS INTEGER			' holds the answer value

	ans = MESSAGEBOX("Are you thinking of an animal?",TITLE,YESNOBUTTONS)
	IF ans=YES THEN
		' answer is YES
		FindAnimal
	ELSE
		' answer is NO
		ans = MESSAGEBOX("Can I give you some suggestions?",TITLE,YESNOBUTTONS)
		IF ans=YES THEN ShowSuggestion
	END IF	
	
	' Decide IF we want to continue
	IF ans<>YES THEN 
		QuestionUser=FALSE
	ELSE
		QuestionUser = TRUE
	END IF
END FUNCTION

'==========================================================
' Prints suggestion list
SUB ShowSuggestion
	DIM mess AS STRING	' Message buffer
	DIM a AS INTEGER		' loop counter
	DIM num AS INTEGER  ' number of elements in array
	DIM ani AS INTEGER  ' number of animals found
	
	ani=0
	mess = "Here are some suggestions:" + CHR(13) + CHR(13) + CHR(10)
	
	' Prints all animals
	FOR a = 1 TO animsize
		IF LEFT( anim(a),1)="!" THEN 
			mess = mess + MID( anim(a),2)
			ani=ani+1
	
			' Format string
			IF ani MOD 5 = 0 THEN
				mess = mess + CHR(13)
			ELSE
				mess = mess + CHR(9)
			END IF
		END IF
	NEXT a
	MESSAGE mess
END SUB

'==========================================================
' Try to guess animal
FUNCTION Guess( question% ) AS INTEGER
	IF MESSAGEBOX(MID(anim(question),8),TITLE,YESNOBUTTONS)=YES THEN
		Guess = CINT(MID(anim(question),2,3))
	ELSE
		Guess = CINT(MID(anim(question),5,3))
	END IF
END FUNCTION

'==========================================================
' Find next question and guess
SUB FindAnimal
	DIM mess AS STRING      ' Message buffer
	DIM g AS INTEGER        ' guess
	DIM answer AS INTEGER   ' tempo answer
	DIM newval AS INTEGER   ' next empty space
	DIM animal AS STRING    ' player animal
	DIM question AS STRING  ' player question

	' Start guessing with first question
	g = 1
	' find animal
	WHILE LEFT(anim(g),1) = "?"
		g = Guess(g)			
	WEND
	' Verify guess
	answer=MESSAGEBOX("The animal you were thinking of was a " + MID(anim(g),2) + "?", TITLE,YESNOBUTTONS)
	IF answer=YES OR animsize>MAXDATA-2 THEN
		' We have it
		MESSAGE "Why not think of another animal?"
	ELSE
		' Enter in database
		DO
			animal=INPUTBOX("This animal you were thinking of was a ")
		LOOP WHILE animal=""
		mess = "Please enter a question that would distinguish a " 
		mess = mess + animal + " from a " + MID(anim(g),2)
		DO
			question=INPUTBOX(mess)
		LOOP WHILE question=""
		newval = animsize + 1
		answer = MESSAGEBOX("For a " + animal + " the answer would be?",TITLE,YESNOBUTTONS)
		IF answer=YES THEN
			anim(newval) = "!" + animal
			anim(newval+1) = anim(g)
		ELSE
			anim(newval+1) = "!" + animal
			anim(newval) = anim(g)
		END IF
		'  Make sure we have leading 0
		anim(g) = "?" + RIGHT(newval+1000,3) + RIGHT(newval+1001,3) + question
		animsize = newval+1
	END IF
END SUB

