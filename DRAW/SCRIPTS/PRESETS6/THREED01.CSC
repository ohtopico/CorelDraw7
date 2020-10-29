REM Blue fountain fill face, VP locked to object, 3 light sources    Font
REM REM used: AvantGarde Bk BT
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 100, 100, 0, 0
	.SetFountainFillColor 100, 2, 100, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 3556, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 0, 0, 0, 20, -49275, -39369, TRUE, 3, 100, 10, 32, 7, 35, 2, 2, 100, 100, 0, 0, 2, 100, 100, 0, 0, 2, 0, 0, 0, 100
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
