REM Conical fill with extrude.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
rem	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 2, 0, -50, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 0, 100, 0
	.SetFountainFillColor 10, 2, 0, 60, 60, 40
	.SetFountainFillColor 20, 2, 0, 0, 100, 0
	.SetFountainFillColor 30, 2, 0, 60, 60, 40
	.SetFountainFillColor 40, 2, 0, 0, 100, 0
	.SetFountainFillColor 50, 2, 0, 60, 60, 40
	.SetFountainFillColor 60, 2, 0, 0, 100, 0
	.SetFountainFillColor 70, 2, 0, 60, 60, 40
	.SetFountainFillColor 80, 2, 0, 0, 100, 0
	.SetFountainFillColor 90, 2, 0, 60, 60, 40
	.SetFountainFillColor 100, 2, 0, 0, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 4, 0, 0, 20, -32765, -33527, TRUE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
