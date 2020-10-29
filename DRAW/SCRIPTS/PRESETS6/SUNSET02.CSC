REM Off center radial fill with extrude and  perspective.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.RecorderApplyPerspective 1, 0, -237743, -67817, -109727, 67817, 109727, 67817, 237743, -67817, 0, 0, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 1, 0, -50, 900, 256, 0, 3, 50
	.SetFountainFillColor 0, 2, 0, 60, 60, 40
	.SetFountainFillColor 80, 2, 0, 0, 100, 0
	.SetFountainFillColor 100, 2, 0, 0, 100, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 4, 0, 0, 20, 1523, -43687, TRUE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
