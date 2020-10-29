REM Black / white fountain fill face, VP locked to object, 2 light sources
REM REM    Font used: Bedrock
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyFountainFill 0, 0, 0, 900, 256, 0, 0, 50
	.SetFountainFillColor 0, 2, 0, 0, 0, 100
	.SetFountainFillColor 100, 2, 0, 0, 0, 0
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 3556, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 2, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 100
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyExtrude 4, 0, 0, 20, 0, -31495, FALSE, 12, 100, 5, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
