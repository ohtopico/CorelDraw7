REM Sunset with simple drop shadow      Font used: Bahamas Heavy
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject -8889, 6095
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyOutline 508, 1, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, TRUE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 0, 0, 100, 0
	.SetFountainFillColor 100, 2, 0, 60, 100, 0
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
