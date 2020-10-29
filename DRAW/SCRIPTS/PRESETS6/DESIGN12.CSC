REM 3D Drop shadow to front    Font used: USA Black (Italic)
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 20, 80, 0, 20
	.SetFountainFillColor 48, 2, 20, 20, 0, 0
	.SetFountainFillColor 100, 2, 20, 80, 0, 20
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.StretchObject 1, 1, 0.253968, 1, FALSE, TRUE, 2
	.RecorderSelectObjectByIndex TRUE, 2
	.SkewObject 31800000, 0, 2
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject -2539, 6857
	.RecorderSelectObjectByIndex TRUE, 2
	.OrderToBack 
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyFountainFill 0, 0, 0, -900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 0, 0, 0, 50
	.SetFountainFillColor 48, 2, 20, 20, 0, 0
	.SetFountainFillColor 100, 2, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
