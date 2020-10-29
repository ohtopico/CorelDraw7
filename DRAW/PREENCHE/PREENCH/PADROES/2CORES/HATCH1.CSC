REM Favorite : Fill,
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script
REM Created On Tuesday, October, 15, 1996 by antoniom

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects FALSE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyTwoColorFill "hatch1f.bmp", 2, 0, 0, 0, 100, 2, 0, 0, 0, 0, 127000, 127000, 0, 0, TRUE, 0, TRUE, FALSE
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
