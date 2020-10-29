REM Displays the systems free resources
REM GDI.CSC          Septembre 23, 1996
REM You need to have the Windows DLL RSRC32.dll installed 
REM for this script to work.
REM Copyright 1996 Corel Corporation. All rights reserved.

'  Declare DLL function
DECLARE FUNCTION GetRes LIB "RSRC32.dll" (BYVAL a AS INTEGER) AS LONG ALIAS "_MyGetFreeSystemResources32@4"
' GetRes function constants
GLOBAL CONST GFSR_SYSTEMRESOURCES%=0
GLOBAL CONST GFSR_GDIRESOURCES%=1
GLOBAL CONST GFSR_USERRESOURCES%=2

	' Resource meter dialog
BEGIN DIALOG OBJECT RES 207, 56, "Resource Indicator", SUB RESHandler
	TEXT  6, 6, 62, 12, .SysResText, "System resources:"
	TEXT  68, 6, 15, 12, .SysRes, ""
	PROGRESS 92, 6, 106, 12, .SysProg
	TEXT  7, 36, 57, 12, .GDIResText, "GDI Resources:"
	TEXT  68, 21, 15, 12, .GDIRes, ""
	PROGRESS 92, 21, 106, 12, .GDIProg
	TEXT  7, 21, 54, 12, .UserResText, "User Resources:"
	TEXT  68, 36, 15, 12, .UserRes, ""
	PROGRESS 92, 36, 106, 12, .UserProg
END DIALOG

' Dialog handler
SUB RESHandler(BYVAL ControlID%, BYVAL Event%)
	DIM Sys AS LONG
	DIM User AS LONG
	DIM GDI AS LONG
	IF Event%=0 OR Event%=5 THEN
	  ' Timer
		' Collect res info
		Sys&=GetRes(GFSR_SYSTEMRESOURCES)
		User&=GetRes(GFSR_USERRESOURCES)
		GDI&=GetRes(GFSR_GDIRESOURCES)
		' Set up text
		RES.SysRes.SetText(" " + CSTR(Sys&) + "%")
		RES.UserRes.SetText(" " + CSTR(User&) + "%")
		RES.GDIRes.SetText(" " + CSTR(GDI&) + "%")
		' Set up progress controls
		RES.SysProg.SetValue Sys&
		RES.UserProg.SetValue User&
		RES.GDIProg.SetValue GDI&
	END IF
END SUB

' Main code
RES.SetTimer 10000 ' Update every 10 seconds
RES.SetStyle 32   ' Enable minimize/maximize
' Set progress controls
RES.SysProg.SetMinRange 0
RES.GDIProg.SetMinRange 0
RES.UserProg.SetMinRange 0
RES.SysProg.SetMaxRange 100
RES.GDIProg.SetMaxRange 100
RES.UserProg.SetMaxRange 100
' Call up dialog
DIALOG RES



