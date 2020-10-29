REM Plaque with spectral fill to back of embossed element.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.MoveObject -3301, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.MoveObject 0, 3301
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyUniformFillColor 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject 3301, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject 0, -3301
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject 3301, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject 0, -3301
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyUniformFillColor 2, 0, 0, 0, 50
	.RecorderSelectObjectByIndex TRUE, 2
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject -3301, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject 0, 3301
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyFountainFill 2, 0, 0, 900, 256, 0, 1, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderObjectScaleInfo 51942992, 17297388, 330197, -330197
	.CreateRectangle 0, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 4
	.ApplyOutline 762, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 100, 100, 0, 0
	.RecorderSelectObjectByIndex TRUE, 4
	.ApplyOutline 7620, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 100, 100, 0, 0
	.RecorderSelectObjectByIndex TRUE, 4
	.ApplyFountainFill 2, 0, 0, 900, 256, 0, 1, 50
	.SetFountainFillColor 0, 2, 0, 100, 100, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 4
	.OrderToBack 
	.RecorderSelectObjectByIndex TRUE, 4
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 5
	.ApplyNoFill 
	.RecorderSelectObjectByIndex TRUE, 5
	.ApplyOutline 2540, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 5, 4, 3, 2, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
