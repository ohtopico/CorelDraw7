REM FRACTAL SHADOW - a fractal texture with a feathered shadow.    Font
REM REM used: Arial
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 127000, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyUniformFillColor 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyUniformFillColor 2, 0, 0, 0, 20
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 127000, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 20
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 2
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject 0, 3301
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject 0, 3301
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject 0, 3301
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyTextureFill "", "Mineral.Cloudy 5 Colors", "Mineral.Cloudy 5 Colors"
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyOutline 762, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.ApplyBlend TRUE, 20, 0, FALSE, 0, FALSE, FALSE, 0, 0, 0, TRUE, TRUE, FALSE, FALSE, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 4, 3, 2, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
