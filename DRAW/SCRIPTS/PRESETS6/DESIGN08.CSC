REM Blue fountain fill with feathered drop  shadow    Font used: AvantGarde
REM REM Bk BT
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyUniformFillColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 3556, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyUniformFillColor 5, 153, 153, 153, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 254, 1, 1, 1, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 0, 0, 0, 50
	.RecorderSelectObjectByIndex TRUE, 2
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 3
	.MoveObject -7619, 6095
	.RecorderSelectObjectByIndex TRUE, 3
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 100, 20, 0, 0
	.SetFountainFillColor 100, 2, 100, 100, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.ApplyBlend TRUE, 10, 0, FALSE, 0, FALSE, FALSE, 0, 0, 0, TRUE, TRUE, FALSE, FALSE, 0, 0, 0, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 4, 3, 2, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
