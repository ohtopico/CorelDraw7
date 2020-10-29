REM Flame fractal fill with red to yellow blend  outline.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyTextureFill "", "Flames", "Flames"
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 3556, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyNoFill 
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 12700, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyOutline 12700, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 0, 100, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyOutline 2540, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 0, 100, 0
	.RecorderSelectObjectsByIndex TRUE, 2, 3, -1, -1, -1
	.ApplyBlend TRUE, 10, 0, FALSE, 0, FALSE, FALSE, 0, 0, 0, TRUE, TRUE, FALSE, FALSE, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 4, 3, 2, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
