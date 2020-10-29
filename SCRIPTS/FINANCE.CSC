REM Calculates mortgages
REM Finance.csc  August 20, 1996
REM Copyright 1996 Corel Corporation. All rights reserved.

REM ***************************************************************
REM * Global Data                                                 *
REM ***************************************************************

'Standard constants
#include "ScpConst.CSI"

REM ***************************************************************
REM * Main Dialog                                                 *
REM ***************************************************************
BEGIN DIALOG OBJECT Calculator 511, 217, "Financial Calculator", SUB CalculatorSub
	PUSHBUTTON  16, 200, 46, 14, .Calculate, "Calculate"
	PUSHBUTTON  69, 200, 46, 14, .ExitButton, "Exit"
	TEXT  8, 16, 44, 8, .Text1, "Initial Capital"
	SPINCONTROL  67, 15, 67, 12, .Capital
	TEXT  8, 30, 44, 8, .Text2, "Interest Rate"
	SPINCONTROL  67, 29, 67, 12, .Interest
	TEXT  8, 44, 58, 8, .Text3, "Number of Periods"
	SPINCONTROL  67, 43, 67, 12, .Periods
	TEXT  8, 58, 44, 8, .Text5, "Payment"
	SPINCONTROL  67, 57, 67, 12, .Payment
	GROUPBOX  8, 97, 130, 42, .GroupBox1, "Interest compounded"
	OPTIONGROUP .CompoundWhen
		OPTIONBUTTON  17, 109, 110, 10, .StartPeriod, "at start of period"
		OPTIONBUTTON  17, 121, 110, 10, .EndPeriod, "at end of period"
	GROUPBOX  8, 151, 130, 42, .GroupBox2, "Obtain"
	OPTIONGROUP .ObtainWhat
		OPTIONBUTTON  17, 163, 114, 10, .ObtainPayment, "payment from number of periods"
		OPTIONBUTTON  17, 175, 116, 10, .ObtainPeriod, "number of periods from payment"
	TEXT  174, 16, 29, 8, .Text7, "Period"
	LISTBOX  174, 26, 31, 191, .PeriodList
	TEXT  209, 16, 50, 8, .Text8, "Intial Capital"
	LISTBOX  209, 26, 71, 191, .CapitalBeforeList
	TEXT  285, 16, 50, 8, .InterestText, "Interest"
	LISTBOX  285, 26, 71, 191, .InterestList
	TEXT  361, 16, 50, 8, .PaymentText, "Payment"
	LISTBOX  361, 26, 71, 191, .PaymentList
	TEXT  437, 16, 62, 8, .Text11, "Remaining Capital"
	LISTBOX  437, 26, 71, 191, .CapitalAfterList
END DIALOG

REM ***************************************************************
REM * Main Program                                                *
REM ***************************************************************
'Initialize data
WITH Calculator
	.Capital.SetMinRange 0
	.Capital.SetMaxRange 1000000000
	.Capital.SetDoubleMode TRUE
	.Capital.SetPrecision 2
	.Capital.SetIncrement 1000
	.Capital.SetValue 25000
	.Interest.SetMinRange 0.5
	.Interest.SetMaxRange 50.0
	.Interest.SetDoubleMode TRUE
	.Interest.SetPrecision 2
	.Interest.SetIncrement .5
	.Interest.SetValue 8
	.Periods.SetMinRange 3
	.Periods.SetMaxRange 200
	.Periods.SetDoubleMode FALSE
	.Periods.SetIncrement 1
	.Periods.SetValue 20
	.Payment.SetMinRange 0
	.Payment.SetMaxRange 100000000000
	.Payment.SetDoubleMode TRUE
	.Payment.SetPrecision 2
	.Payment.SetIncrement 1
	.Payment.SetValue 0
	
	.SetStyle STYLE_MINIMIZEBOX
END WITH

'Call the dialog (it does all the work)
DIALOG Calculator

REM ***************************************************************
REM * MakeString: Makes a string with two decimal places out of a *
REM * currency value.                                             *
REM ***************************************************************
FUNCTION MakeString (Value AS CURRENCY) AS STRING
	DIM ReturnVal AS STRING
	ReturnVal$ = CSTR(Value)
	IF INT(Value) = Value THEN
		ReturnVal$ = ReturnVal$ + ".00"
	ELSEIF INT(Value * 10) = Value * 10 THEN
		ReturnVal$ = ReturnVal$ + "0"
	ENDIF
	MakeString = ReturnVal$
END FUNCTION

REM ***************************************************************
REM * CalculatorSub: Event handler for the main dialog. This SUB  *
REM * handles all of the user commands; it is, in effect, the     *
REM * heart of the program.                                       *
REM ***************************************************************
SUB CalculatorSub (BYVAL ControlID%, BYVAL Event%)
	DIM PaymentValue AS DOUBLE
	DIM DistanceValue AS CURRENCY
	DIM CurrentCapital AS CURRENCY
	DIM CurrentInterest AS CURRENCY
	DIM CurrentPayment AS CURRENCY
	DIM Period AS INTEGER
	DIM ToAdd AS STRING
	WITH Calculator
		IF Event% = EVENT_MOUSE_CLICK THEN
			'Exit
			IF ControlID% = .ExitButton.GetID() THEN .CloseDialog MSG_CANCEL
			
			'Calculate
			IF ControlID% = .Calculate.GetID() THEN
				'Check for validity
				IF .ObtainWhat.GetValue() = 1 AND .Payment.GetValue() = 0 THEN
					MESSAGE "Must have a payment greater than 0"
					EXIT SUB
				ENDIF
				IF .Capital.GetValue() = 0 THEN
					MESSAGE "Must have a capital greater than 0"
					EXIT SUB
				ENDIF
				'Calculate payment from periods if necessary
				IF .ObtainWhat.GetValue() = 0 THEN
					DistanceValue = .Capital.GetValue()
					IF .CompoundWhen.GetValue() = 0 THEN
						'Compound at start of period (before payment)
						PaymentValue = (DistanceValue * (.Interest.GetValue() / 100.0))
						PaymentValue = PaymentValue / (1.0 - ((1.0 + (.Interest.GetValue() / 100.0))^(-(.Periods.GetValue()))))
					ELSE
						'Compound at end of period (after payment)
						PaymentValue = ((DistanceValue) * (.Interest.GetValue() / 100.0))
						PaymentValue = PaymentValue / (1.0 - ((1.0 + (.Interest.GetValue() / 100.0))^(-(.Periods.GetValue() - 1.0)))+ (.Interest.GetValue() / 100.0))
					ENDIF
					'Adjust payment for rounding errors
					IF PaymentValue * 100 - INT(PaymentValue * 100) > 0 THEN
						PaymentValue = INT(PaymentValue * 100) / 100 + .01
					ENDIF
					'Set it in the dialog
					.Payment.SetValue PaymentValue
				ENDIF
				'Empty all list boxes
				.PeriodList.Reset
				.CapitalBeforeList.Reset
				.InterestList.Reset
				.PaymentList.Reset
				.CapitalAfterList.Reset
				'Move the boxes around corresponding to the compund time
				IF .CompoundWhen.GetValue() = 0 THEN
					'Move the list so the interest is before the payment
					.InterestText.Move 285,16
					.InterestList.Move 285,26
					.PaymentText.Move 361, 16
					.PaymentList.Move 361, 26
					CurrentCapital = .Capital.GetValue()
					Period% = 1
					DO WHILE CurrentCapital > 0
						'Calculate each payment and result
						
						'Period number
						.PeriodList.AddItem Period%
						
						'Current capital
						ToAdd$ = MakeString (CurrentCapital)
						.CapitalBeforeList.AddItem ToAdd$
						
						'Interest
						CurrentInterest = CurrentCapital * (.Interest.GetValue() / 100.0)
						'Adjust for rounding errors
						IF CurrentInterest * 100 - INT(CurrentInterest * 100) > 0 THEN
							CurrentInterest = INT(CurrentInterest * 100.0) / 100.0
						ENDIF
						CurrentCapital = CurrentCapital + CurrentInterest
						ToAdd$ = MakeString (CurrentInterest)
						.InterestList.AddItem ToAdd$
						
						'Payment
						CurrentPayment = .Payment.GetValue()
						'Adjust for rounding errors
						IF CurrentPayment * 100 - INT(CurrentPayment * 100) > 0 THEN
							CurrentPayment = INT(CurrentPayment * 100) / 100 + .01
						ENDIF
						'Make sure we never pay too much
						IF CurrentPayment > CurrentCapital THEN CurrentPayment = CurrentCapital
						ToAdd$ = MakeString (CurrentPayment)
						.PaymentList.AddItem ToAdd$
						
						'Resulting capital
						CurrentCapital = CurrentCapital - CurrentPayment
						ToAdd$ = MakeString (CurrentCapital)
						.CapitalAfterList.AddItem ToAdd$
						Period% = Period% + 1
					LOOP				
				ELSE
					'Move the list so the payment is before the interest
					.PaymentText.Move 285,16
					.PaymentList.Move 285,26
					.InterestText.Move 361, 16
					.InterestList.Move 361, 26
					CurrentCapital = .Capital.GetValue()
					Period% = 1
					DO WHILE CurrentCapital > 0
						'Calculate each payment and result
						
						'Period number
						.PeriodList.AddItem Period%
						
						'Current capital
						ToAdd$ = MakeString (CurrentCapital)
						.CapitalBeforeList.AddItem ToAdd$
						
						'Payment
						CurrentPayment = .Payment.GetValue()
						'Adjust for rounding errors
						IF CurrentPayment * 100 - INT(CurrentPayment * 100) > 0 THEN
							CurrentPayment = INT(CurrentPayment * 100) / 100 + .01
						ENDIF
						'Make sure we never pay too much
						IF CurrentPayment > CurrentCapital THEN CurrentPayment = CurrentCapital
						ToAdd$ = MakeString (CurrentPayment)
						.PaymentList.AddItem ToAdd$
						CurrentCapital = CurrentCapital - CurrentPayment
						
						'Interest
						CurrentInterest = CurrentCapital * (.Interest.GetValue() / 100)
						'Adjust for rounding errors
						IF CurrentInterest * 100 - INT(CurrentInterest * 100) > 0 THEN
							CurrentInterest = INT(CurrentInterest * 100) / 100
						ENDIF
						CurrentCapital = CurrentCapital + CurrentInterest
						ToAdd$ = MakeString (CurrentInterest)
						.InterestList.AddItem ToAdd$
						
						'Resulting capital
						ToAdd$ = MakeString (CurrentCapital)
						.CapitalAfterList.AddItem ToAdd$
						Period% = Period% + 1
					LOOP				
				ENDIF
				'Reset the number of periods
				.Periods.SetValue Period% - 1
			ENDIF
		ENDIF
	END WITH
END SUB

