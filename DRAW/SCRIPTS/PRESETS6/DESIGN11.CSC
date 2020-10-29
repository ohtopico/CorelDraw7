REM 3D Drop shadow to back      Font used: USA Black (Italic)
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 0, 100, 0
	.SetFountainFillColor 100, 2, 0, 60, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 1270, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.StretchObject 1, 1, 0.527778, 1, FALSE, FALSE, 2
	.RecorderSelectObjectByIndex TRUE, 2
	.SkewObject -22600000, 0, 6
	.RecorderSelectObjectByIndex TRUE, 2
	.OrderToBack 
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 0, 0, 80
	.SetFountainFillColor 100, 2, 0, 0, 0, 20
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
