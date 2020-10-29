REM Favorite : Outline,Outline Style,Outline Width,Outline Arrow Head,Outline Arrow Tail,
REM REM Converted from a DRAW PRESET binary to a DRAW RECORDING script
REM Created On Thursday, October, 17, 1996 by antoniom

WITHOBJECT "CorelDraw.Automation.7"
	.StartOfRecording 
	.SuppressPainting 
	.RecorderStorePreselectedObjects FALSE
	.SetOutlineWidth 7056
	.SetOutlineMiscProperties 2, 2, 0, 0, 100, 0, FALSE, FALSE
	.SetOutlineColor 2, 0, 100, 0, 0
	.BeginDrawArrow TRUE, 0, 5
	.AddArrowPoint -254000, 254000, FALSE, FALSE, TRUE, TRUE, 0, 0
	.AddArrowPoint 254000, 254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint 254000, -254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint -254000, -254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint -254000, 254000, FALSE, FALSE, FALSE, TRUE, 0, 1
	.EndDrawArrow 
	.SetOutlineArrow 0
	.BeginDrawArrow FALSE, 0, 5
	.AddArrowPoint -254000, 254000, FALSE, FALSE, TRUE, TRUE, 0, 0
	.AddArrowPoint 254000, 254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint 254000, -254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint -254000, -254000, FALSE, FALSE, TRUE, FALSE, 0, 1
	.AddArrowPoint -254000, 254000, FALSE, FALSE, FALSE, TRUE, 0, 1
	.EndDrawArrow 
	.SetOutlineArrow 1
	.ResumePainting 
	.EndOfRecording 
END WITHOBJECT
