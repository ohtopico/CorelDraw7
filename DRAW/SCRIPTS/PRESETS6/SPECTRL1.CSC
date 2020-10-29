REM Spectral conical fill.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 1, 0, 0, 900, 256, 0, 1, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 2, 0, 0, 900, 256, 0, 1, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
