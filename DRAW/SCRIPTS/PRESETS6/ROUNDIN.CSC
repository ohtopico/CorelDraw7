REM Grey contour to center.
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects TRUE
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyOutline 762, 0, 0, 0, 100, 0, 0, -1, -1, FALSE, 1, 0, FALSE
	.SetOutlineColor 2, 0, 0, 0, 50
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyUniformFillColor 2, 0, 0, 0, 50
	.RecorderSelectObjectByIndex TRUE, 1
	.ApplyContour 0, 1269, 13, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
