REM Purple / blue fountain fill face, VP locked to object, 2 light sources
REM REM    Font used: BankGothic Md BT
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 100, 100, 0, 0
	.SetFountainFillColor 46, 2, 0, 100, 0, 0
	.SetFountainFillColor 100, 2, 100, 100, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 3556, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 4, 0, 0, 10, 24637, -22605, TRUE, 12, 79, 5, 56, 0, 0, 2, 2, 100, 100, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 100
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
