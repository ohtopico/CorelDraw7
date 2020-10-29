REM Yellow to red off center fill, extruded.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 1, 0, -50, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 80, 2, 0, 0, 100, 0
	.SetFountainFillColor 100, 2, 0, 0, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 4, 0, 0, 20, -29463, -47243, TRUE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
