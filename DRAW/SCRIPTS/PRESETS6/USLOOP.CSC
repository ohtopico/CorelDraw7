REM 2 objects filled 3 color fade, blended together w/ 360  rotation &
REM REM loop.  Font: Times New Roman.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 0, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 100, 100, 0, 0
	.SetFountainFillColor 50, 2, 0, 0, 0, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject 550163, -855471
	.RecorderSelectObjectByIndex TRUE, 2
	.StretchObject 1.94289, 1, 1.94289, 1, FALSE, FALSE, 9
	.RecorderSelectObjectByIndex TRUE, 2
	.StretchObject 1.13199, 1, 1.13199, 1, FALSE, FALSE, 9
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 3556, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyFountainFill 0, 0, 0, -1800, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 100, 100, 0, 0
	.SetFountainFillColor 50, 2, 0, 0, 0, 0
	.SetFountainFillColor 100, 2, 0, 100, 100, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.ApplyBlend TRUE, 20, 360000000, TRUE, 0, FALSE, FALSE, 0, 0, 0, TRUE, TRUE, FALSE, FALSE, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
