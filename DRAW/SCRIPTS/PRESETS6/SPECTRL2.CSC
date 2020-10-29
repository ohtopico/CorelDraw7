REM Off center spectral fill with reverse spectral fill on contour.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 2, 0, -50, 0, 256, 0, 1, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 65, 2, 100, 0, 0, 0
	.SetFountainFillColor 75, 2, 0, 100, 100, 0
	.SetFountainFillColor 85, 2, 0, 0, 100, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyContour 2, 1523, 5, 0, 2, 0, 0, 0, 0, 2, 100, 100, 0, 0, 2, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
