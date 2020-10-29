REM Purple fountain fill with 75% transparent  drop shadow.    Font used:
REM REM BANK GOTHIC Md BT
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 0, 0, 0, 0, 0, 0, 0, -1, -1, FALSE, 0, 0, FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyLensEffect 10, FALSE, FALSE, FALSE, 0, 0, 250, 2, 0, 0, 0, 50, 1239600, 1240712, 1, 1240712, 25797896
	.RecorderSelectObjectByIndex TRUE, 1
	.DuplicateObject 0, 0
	.RecorderSelectObjectByIndex TRUE, 2
	.MoveObject -5841, 6349
	.RecorderSelectObjectByIndex TRUE, 2
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 100, 0, 0
	.SetFountainFillColor 100, 2, 20, 80, 0, 20
	.RecorderSelectPreselectedObjects TRUE
	.RecorderSelectObjectsByIndex FALSE, 2, -1, -1, -1, -1
	.Group 
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
