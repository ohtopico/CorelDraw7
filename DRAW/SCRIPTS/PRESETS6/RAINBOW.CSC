REM Rainbow fill, extruded
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.OrderToBack 
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyExtrude 0, 0, 0, 5, 253, 253, FALSE, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.RecorderSelectObjectsByIndex TRUE, 3, 2, -1, -1, -1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 40, 40, 0, 20
	.SetFountainFillColor 100, 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 1, 0, -50, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 100, 20, 0, 0
	.SetFountainFillColor 14, 2, 100, 20, 0, 0
	.SetFountainFillColor 20, 2, 20, 80, 0, 20
	.SetFountainFillColor 30, 2, 40, 60, 0, 0
	.SetFountainFillColor 40, 2, 100, 100, 0, 0
	.SetFountainFillColor 50, 2, 100, 0, 100, 0
	.SetFountainFillColor 60, 2, 0, 0, 100, 0
	.SetFountainFillColor 70, 2, 0, 60, 100, 0
	.SetFountainFillColor 80, 2, 0, 100, 100, 0
	.SetFountainFillColor 85, 2, 100, 20, 0, 0
	.SetFountainFillColor 100, 2, 100, 20, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 3, 2, -1, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
