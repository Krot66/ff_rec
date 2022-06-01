#SingleInstance Off
SetTitleMatchMode, 2
SetTitleMatchMode, Slow
DetectHiddenWindows, On
SetBatchLines -1
CoordMode Menu
CoordMode Mouse
CoordMode ToolTip
#Include %A_ScriptDir%\Gdip.ahk
OnExit Autodelete

/*
Использованы:
	RunCMD v0.94 by SKAN
	GDIPlus by Tic
	KillChildProcesses by Nextron
*/

EnvSet __COMPAT_LAYER, RUNASINVOKER

FileEncoding % "CP" (RegExMatch(RunCmd(A_Comspec " /c chcp"),"\d{3,}$",chcp) ? chcp : 866)
RegRead ms, HKEY_CURRENT_USER\Control Panel\Mouse, MouseSensitivity

Menu Tray, NoStandard
Menu Tray, Add, Стоп (F9), F9
Menu Tray, Add, Лог (F8), F8
Menu Tray, Add
Menu Tray, Add, Выход (Ctrl+F9), ^F9
Menu Tray, Default, Стоп (F9)
EnvGet p, Path
EnvSet Path, % A_ScriptDir ";" p
SetFormat FloatFast, 0.3
sx:=sy:=dw:=0, mult:=2, zoom:=zoom_start:=1
SysGet, M, Monitor
SysGet, MW, MonitorWorkArea
sw:=MRight, sh:=MBottom
gosub AudioDevice

If FileExist(A_ScriptDir "\ff_rec.ini") {
	IniRead out_folder, % A_ScriptDir "\ff_rec.ini", Main, out_folder, % " "
	IniRead audio_device, % A_ScriptDir "\ff_rec.ini", Main, audio_device, % " "
	If audio_list not contains % audio_device
		audio:=""
	IniRead mult, % A_ScriptDir "\ff_rec.ini", Main, mult, % " "
	IniRead font_size, % A_ScriptDir "\ff_rec.ini", Main, font_size, % " "
	IniRead font_log, % A_ScriptDir "\ff_rec.ini", Main, font_log, % " "
	IniRead msens, % A_ScriptDir "\ff_rec.ini", Main, msens, % " "
	IniRead pos, % A_ScriptDir "\ff_rec.ini", Main, pos, % " "
	IniRead subfolders, % A_ScriptDir "\ff_rec.ini", Main, subfolders, % " "
	If subfolders
		Loop Parse, subfolders, CSV
			IniRead %A_LoopField%, % A_ScriptDir "\ff_rec.ini", Main, % A_LoopField, % " "
	IniRead autodelete, % A_ScriptDir "\ff_rec.ini", Main, autodelete, % " "
}
If !mult
	mult:=2
If !font_size
	font_size:=24
If !pos
	pos:=2
		
SplitPath A_ScriptDir,,,,, out_drive
If !(A_WorkingDir=A_ScriptDir)
	out_folder:=A_WorkingDir, no_subfolders:=1
Else If !out_folder
	out_folder:=out_drive "\ff_records"
	
SetWorkingDir %A_ScriptDir%
FileCreateDir % out_folder
FileCreateDir open_in

cmd_start:=DllCall("kernel32\GetCommandLine", "Str")
If (cmd_start~="(^|\s)-info($|\s)") {
	info:=1
	goto Audio
}
If (A_Args[1]~="^.+\.bat$")
	bat_file:=A_Args[1]
If (cmd_start~="\s+-i\s+0(?=(\s+|$))")
		audio_device:=""
Else If RegExMatch(cmd_start,"\s+-i\s+""?\K[^""]+(?=""?(\s|$))", adc) {
	If (adc=0)
		audio_device:=""
	Else {
		If adc not in % dev_list
		{
			MsgBox, 16, , Неверное задание источника аудио в командной строке!, 2
			ExitApp
		}
		Else
			audio_device:=adc
	}
}
sel:=RegExMatch(cmd_start,"\s+\K-s(?=(\s+-\S|\s*$))")
sx:=RegExMatch(cmd_start,"\s+-x\s+\K\d+(?=(\s+-\S|\s*$))",sxc) ? sxc : sx
sy:=RegExMatch(cmd_start,"\s+-y\s+\K\d+(?=(\s+-\S|s\*$))",syc) ? syc : sy
sw:=RegExMatch(cmd_start,"\s+-w\s+\K\d+(?=(\s+-\S|\s*$))",swc) ? swc : sw
sh:=RegExMatch(cmd_start,"\s+-h\s+\K\d+(?=(\s+-\S|\s*$))",shc) ? shc : sh
zoom:=zoom_start:=RegExMatch(cmd_start,"\s+-z\s+\K\d+(?=(\s+-\S|\s*$))",zoomc) ? zoomc/100 : 1
mult:=RegExMatch(cmd_start,"\s+-\K\d+(?=(\s+-\S|\s*$))",multc) ? multc : mult
RegExMatch(cmd_start,"\s+-show\s+\K\d+(?=(\s+-\S|\s*$))",show)
RegExMatch(cmd_start,"\s+-t\s+\K\d+(?=(\s+-\S|\s*$))",length)

If bat_file {
	bat:=bat_file
	bat_file:=(bat_file~="\\") ? bat_file : A_ScriptDir "\bat\" bat_file
	If FileExist(bat_file)
		goto Start
	Else {
		MsgBox, 16, , % "Файл " bat_file " не существует!", 2
		ExitApp
	}
}

Menu:
	menu_out:="", audio_dev:=audio_device
	MouseMove , % MRight//2-120, % MWBottom//4
	Loop Files, bat\*.bat	
		bat_list.=RegExReplace(A_LoopFileName, ".bat$") "`n"
	Sort bat_list		
	Loop Parse, % bat_list, `n 
	{
		If !A_LoopField
			continue
		RegExMatch(A_LoopField,"^\d+",group)
		If group_old && (group!=group_old) && !(group=1)
			Menu, MainMenu, Add
		Menu, MainMenu, Add, % A_LoopField ".bat", BatFile
		If A_IsCompiled
			Menu, MainMenu, Icon, % A_LoopField ".bat", % A_ScriptName, 1
		Else If FileExist(A_WinDir "\System32\imageres.dll")
			Menu, MainMenu, Icon, % A_LoopField ".bat", % A_WinDir "\System32\imageres.dll", -68
		count++
		group_old:=group			
	}
	If !count {
		MsgBox, 48, , В папке отсутствуют bat-файлы!, 1.5
		ExitApp
	}
	Menu MainMenu, Add
	Menu MainMenu, Add, Копировать в буфер, Clip
	Menu MainMenu, Add
	audio_name:=(audio_device ? SubStr(audio_device,1,20) "..." : "Без звука")
	Menu MainMenu, Add, % audio_name, Audio
	If A_IsCompiled
		Menu, MainMenu, Icon, % audio_name, % A_ScriptName, % (audio_device ? 3 : 4)
	Menu MainMenu, Add, Выделение, Sel
	Menu MainMenu, Add, Командная строка, CMD
	Menu MainMenu, Add	
	Menu MainMenu, Add, Выход, Exit
	If A_IsCompiled
		Menu, MainMenu, Icon, Выход, % A_ScriptName, 5
	If sel { 
		Menu MainMenu, Color, C1D4EC
		Menu MainMenu, Check, Выделение
	}
	If cmd
		Menu MainMenu, Check, Командная строка
	Menu MainMenu, Show
	If !menu_out
		ExitApp
	Return
	
Exit:
	ExitApp
	
CMD:
	cmd:=!cmd, menu_out:=1
	Menu MainMenu, Delete
	goto Menu

Sel:
	sel:=!sel, menu_out:=1
	Menu MainMenu, Delete
	goto Menu
	
BatFile:
	bat:=A_ThisMenuItem
	bat_file:=A_ScriptDir "\bat\" bat, menu_out:=1
Start:
	If sel || GetKeyState("Shift")
		goto Select
Record:
	Gui 3:Destroy
	Gui 4:Destroy
	If (sx+sw<MRight-20) && (sy+sh<MWBottom-20)
		MouseMove % sx+sw+10, % sy+sh+10
	If A_IsCompiled
		Menu Tray, Icon, % A_ScriptName, 2
	Sleep 100
	WinGetTitle title, % win_id ? "ahk_id " win_id : "A"
	title:=RegExReplace(title, "[^а-яёА-ЯЁ\w\s\-_]", " ")
	title:=Trim(RegExReplace(title,"\s+","."))
	title:=SubStr(title,1,60)
	WinGet exe_file, ProcessName, % win_id ? "ahk_id " win_id : "A"
	exe_file:=StrReplace(RegExReplace(exe_file,"\.\w{2,5}$")," ", ".")
	If control
		exe_file.="(" control ")"
	ow:=sw, oh:=sh	
	If sel && !cmd && (show!="0") {
		WinSet Top,, ahk_id %win_id%	
		Loop, 4
		{
			Gui % 10+A_Index ": Destroy"
			Gui % 10+A_Index ": -Caption +ToolWindow +AlwaysOnTOp -DPIScale"
			Gui % 10+A_Index ": Color", 7CB9E8
		}
		Gui 11: Show, % "x" sx-5 " y" sy-5 " w" sw+10 " h2 NoActivate", sel
		Gui 14: Show, % "x" sx-5 " y" sy+sh+5 " w" sw+10 " h2 NoActivate", sel
		Gui 12: Show, % "x" sx-5 " y" sy-5 " w2 h" sh+10 " NoActivate", sel
		Gui 13: Show, % "x" sx+sw+5 " y" sy-5 " w2 h" sh+10 " NoActivate", sel
	}				
	ow:=mult*Round(sw*zoom/mult-0.01), oh:=mult*Round(sh*zoom/mult-0.01)
	for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where name ='ffmpeg.exe'")
		ff_old.=process.ProcessId "|"	
	SetFormat FloatFast, 0
	now:=A_YYYY "." A_MM "." A_DD "-" A_Hour "." A_Min "." A_Sec
	pr:=audio_device ? """-f dshow -i audio=""" : """-f lavfi -i """
	audio_device:=audio_device ? """" audio_device """" : "anullsrc"
	If cmd {
		FileRead bat_text, % bat_file
		If bat_text Contains % "%~5%6"
			audio_in:=" " StrReplace(pr,"""") . audio_device
		sx:=(sx=0) ? "" : " -x " sx " ", sy:=(sy=0) ? "" : " -y " sy " "
		sw:=(!sx && sw=MRight) ? "" : " -w " sw " "
		sh:=(!sy && sh=MBottom) ? "" : " -h " sh " "
		zoom:=(zoom=1) ? "" : " -z " zoom*100 " "
		mult:=(mult=2) ? "" : " -" mult " "
		cmd_line:=Clipboard:="""" A_ScriptFullPath """ """ bat_file """" audio_in . sx . sy . sw .  sh .  zoom . mult
		MsgBox, 64, , % "Командная строка в буфере обмена:`n`n" cmd_line
		ExitApp	
	}
	Sleep 100
	stdout:=out_folder "\log_" now ".txt"
	start_time:=A_TickCount
	SetTimer ReadStdOut, 20
	;MsgBox % A_ComSpec " /c """"" bat_file """ " sx " " sy " " sw "x" sh " " ow "x" oh " " pr " " audio_device " " now " " title " " exe_file " > """ stdout """ 2>&1"""
	RunWait % A_ComSpec " /c """"" bat_file """ " sx " " sy " " sw "x" sh " " ow "x" oh " " pr " " audio_device " " now " " title " " exe_file " > """ stdout """ 2>&1""", % out_folder, Hide, pid
	If (el:=ErrorLevel) {
		Run % """" stdout """"
		ExitApp		
	}		
	SetTimer ReadStdOut, Off
	Menu, Tray, NoIcon
	Loop, 4
		Gui % 10+A_Index ": Destroy"
	goto EndWindow
	
ReadStdOut:
	proc_time:=A_TickCount-start_time
	If length && (proc_time>length*1000) {
		SetTimer ReadStdOut, Off
		Goto F9
	}	
	Menu Tray, Tip, % FormatTime(proc_time) "`n" bat "`n" (audio_dev ? SubStr(audio_dev,1,20) "..." : "Без звука")
	FileRead out ,% stdout
	If !stdout || (out && (out=out_old))
		Return
	Loop Parse, % out, `n, `r
	{
		If (A_LoopField~="^\s*Output #\d+") {
			RegExMatch(A_LoopField,"'\K\S+\.\w{2,5}(?='\s*:)",file_out)			
			If !file_list && file_out && !(file_out~="\.(bmp|png|jpg|jpeg|gif|tif|tiff|wmf|emf|wav|ogg|mp3|mp2|flac|opus|ac3|m4a|aac)$") && !thumb
			{			
				thumb:=out_folder "\thumb_" now ".png"
				Run ffmpeg -f gdigrab -offset_x %sx% -offset_y %sy% -video_size %sw%x%sh% -i desktop -frames:v 1 %thumb%,, Hide, pid_thumb
			}
			file_out:=out_folder "\" file_out
			If file_out not in % file_list
				file_list.=file_out ","
		}
	}
	file_path:=file_out
	If WinExist("ahk_id" log) && (out!=out_old) {
		WinActivate
		GuiControl, 5:, MyEdit, % out	
		SendMessage 0x115, 7, 0, Edit1, % "ahk_id" log
	}
	out_old:=out
	Return
	
	
Clip:
	copy_image:=1, menu_out:=1
	If sel || GetKeyState("Shift")
		goto Select
	
Capture:
	CaptureScreen(sx "|" sy "|" sw "|" sh, 0, nQuality, 0)
	ToolTip % "`n   Скопировано!   `n ", sx+sw//2, sy+sh//2
	Sleep 1000
	ToolTip
	ExitApp

F9::
	KeyWait F9, T1
	Gui 5:Destroy
	WinActivate ahk_pid %pid%
	Sleep 50
	If (A_Language!=0409) {
		SendMessage, 0x50,, 0x4090409,, A
		Sleep 50
	}
	SendInput {Text}q 
	rec_time:=A_TickCount-start_time
	Menu, Tray, NoIcon
	Loop, 4
		Gui % 10+A_Index ": Destroy"
	Sleep 500
	If WinExist("ahk_pid" pid) {
		WinSet ExStyle, ^0x80, ahk_id %pid%
		WinMinimize ahk_pid %pid%
		WinShow ahk_id %pid%
	}	
	Return

^F9::
	delete_out:=1
	If pid
		KillChildProcesses(pid)
	Sleep 500
	If (show!="0") {
		TrayTip ff_rec, Запись остановлена`nпринудительно!
		Sleep 2000
		TrayTip
	}
Autodelete:
	DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, ms, UInt, 0)
	If autodelete {
		Loop Parse, file_list, `,
			If A_LoopField && (A_LoopField!=file_path) && FileExist(A_LoopField)
				FileDelete % A_LoopField	
		FileDelete % thumb
		If (autodelete=2 && !el)
			FileDelete % stdout
		If (autodelete=2 && delete_out)
			FileDelete % file_path
	}
	ExitApp

;============ Выделение области ================
Select:
	select_gui:=1
	Gui 3:Destroy
	Gui 3:+Lastfound +AlwaysOnTop -Caption +ToolWindow -DPIScale
	Gui 3:Color, 0000FF
	WinSet Transparent, 35
	Gui 3:Show, x0 y0 w%MRight% h%MBottom% NA, background
	ToolTip ЛKM - выделение`, Ctrl+ЛКМ - выделение окна`, Shift+ЛКМ - контрола`nAlt - скорость курсора мыши`, Tab - скрытие/показ окна выделения`nEscape - выход`, Backspace - сброс`, ПКМ или Enter - подтверждение, MRight/2-250, 0
	goto Full
	
Out:
	Hotkey LButton, Select, Off
	Tooltip
	ToolTip,,,, 2
	Loop, 4
		Gui % 10+A_Index ": Destroy"
	Gui 3:Destroy
	Gui 4:Destroy
	DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, ms, UInt, 0)
	Return	

#If WinExist("background ahk_class AutoHotkeyGUI")
LButton::
	Gui 4:Destroy
	Loop, 4
	Gui % 10+A_Index ": Destroy"
	ToolTip
	ToolTip,,,, 2
	Loop, 4
	{
		Gui % 10+A_Index ": Destroy"
		Gui % 10+A_Index ": -Caption +ToolWindow +AlwaysOnTOp -DPIScale"
		Gui % 10+A_Index ": Color", Red
	}
	control:=""
	MouseGetPos mx, my
	SetTimer Tooltip, 5
	While GetKeyState("LButton","P")
	{
		MouseGetPos mx2, my2
		Gui 11: Show, % "x" Min(mx,mx2) " y" my " w" Abs(mx2-mx) " h3 NoActivate", select
		Gui 14: Show, % "x" Min(mx,mx2) " y" my2 " w" Abs(mx2-mx)+2 " h3 NoActivate", select
		Gui 12: Show, % "x" mx " y" Min(my,my2) " w3 h" Abs(my2-my) " NoActivate", select
		Gui 13: Show, % "x" mx2 " y" Min(my,my2) " w3 h" Abs(my2`-my)+2 " NoActivate", select
		sx:=Min(mx,mx2), sy:=Min(my,my2)
		sw:=Abs(mx2-mx), sh:=Abs(my2-my)
	}
	SetTimer Tooltip, off
Zoom:
	If (sw>4) && (sh>4)		
	{
		SetFormat FloatFast, 0
		zw:=mult*Round(sw*zoom/mult-0.01), zh:=mult*Round(sh*zoom/mult-0.01)
		zshow:="    " zw "x" zh " " zoom*100 "% x" mult
		SetFormat FloatFast, 0.2
		error:=(zw/sw-zh/sh)*100
		error:=(error>0) ? "+" error : ((error=0) ? Abs(error) : error)
		If !WinExist("size_zoom ahk_class AutoHotkeyGUI")
		{
			start_pos:=(pos=2) ? MWBottom : 0
			Gui 4:+LastFound +AlwaysOnTop -Caption +ToolWindow -DPIScale
			Gui 4:Margin, 6, 1
			Gui 4:Font, s%font_size% bold, Lucida Console
			Gui 4:Font, s%font_size% bold, Consolas
			Gui 4:Color, 0A0A0A
			Gui 4:Add, Text, HwndSizeZoom cRed w%MRight%
			Gui 4:Show, x0 y%start_pos% NA, size_zoom
			WinSet, TransColor, 0A0A0A 255, size_zoom
			WinGetPos,,,, hpos
			If (pos=2)
				WinMove,,,, % MWBottom-hpos	
		}			
		GuiControl Text,% SizeZoom , % zshow "(" error "%)"
	}
	Else {
		Loop, 4
			Gui % 10+A_Index ": Destroy"
		ToolTip,,,, 2
	}
	return
	
Tooltip:
	ttip:="(" mx2 ", " my2 ")`n  " sw "x" sh
	If ttip!=ttip_old
		ToolTip % ttip ,,, 2
	ttip_old:=ttip
	Return
	
^LButton up::
	KeyWait Ctrl, T1
	gosub Out
	Sleep 50
	MouseGetPos,,, win_id
	WinGet process, ProcessName, ahk_id %win_id%
	suffix:=RegExReplace("(" RegExReplace(process,"\.\w+") ")","\s+","_")
	WinGetPos sx, sy, sw, sh, ahk_id %win_id%		
	goto Highlight
	
+LButton up::
	KeyWait Shift, T1
	gosub Out
	Sleep 50
	MouseGetPos,,, win_id, ctrl, 2
	MouseGetPos,,,, control
	control:=RegExReplace(control,"\s+","_")
	WinGet process, ProcessName, ahk_id %win_id%
	suffix:=RegExReplace("(" RegExReplace(process,"\.\w+") "-" control ")","\s+","_")
	ControlGetPos sx, sy, sw, sh,, ahk_id %ctrl%
	WinGetPos xx, yy,,, ahk_id %win_id%
	sx+=xx, sy+=yy

Highlight:	
	gosub Select
Full:
	Sleep 50
	If sx<0
		sw:=(sx+sw>MRight) ? MRight : sw+sx, sx:=0 
	else 
		sw:=(sx+sw>MRight) ? MRight-sx : sw
	If sy<0
		sh:=(sy+sh>MBottom) ? MBottom : sh+sy, sy=0
	else
		sh:=(sy+sh>MBottom) ? MRight-sy : sh

	If (sx="" || sy="" || sw<4 || sh<4)
		return
	Loop, 4
	{
		Gui % 10+A_Index ": Destroy"
		Gui % 10+A_Index ": -Caption +ToolWindow +AlwaysOnTOp -DPIScale"
		Gui % 10+A_Index ": Color", Red
	}
	Gui 11: Show, % "x" sx " y" sy " w" sw-3 " h3 NoActivate", select
	Gui 14: Show, % "x" sx " y" sy+sh-3 " w" sw-3 " h3 NoActivate", select
	Gui 12: Show, % "x" sx " y" sy " w3 h" sh-3 " NoActivate", select
	Gui 13: Show, % "x" sx+sw-3 " y" sy " w3 h" sh-3 " NoActivate", select
	If sw && sh
		goto Zoom
	return
	
Bs::
	Loop, 4
		Gui % 10+A_Index ": Destroy"
	Gui 4: Destroy
	ToolTip,,,, 2
	sx:=sy:=0, sw:=MRight, sh:=MBottom, zoom:=1, mult:=2
	Goto Select
	
Alt::
RAlt::
	shift_count:=shift_count ? 0 : 1
	If shift_count
		DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, msens, UInt, 0)
	Else
		DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, ms, UInt, 0)
	Return
	
Esc::
	gosub Out
	ExitApp

#If select_gui
Esc::ExitApp
Tab::
	If WinExist("background ahk_class AutoHotkeyGUI")	{
		Tooltip
		ToolTip,,,, 2
		Loop, 4
			Gui % 10+A_Index ": Destroy"
		Gui 3:Destroy
	}
	Else
		Goto Select
	Return

#If WinExist("select ahk_class AutoHotkeyGUI")
RButton::
	KeyWait RButton, T1
	MouseGetPos mx, my
	If !(mx>sx && mx<sx+sw && my>sy && my<sy+sh)
		ExitApp
	ow:=zw, oh:=zh
	sel:=1
Enter::
NumpadEnter::
	gosub Out
	If copy_image
		goto Capture
	goto Record

WheelDown::
Down::
	If zoom>=0.2
		zoom-=0.1
	goto Zoom

^WheelDown::
^Down::
	If zoom>=0.11
		zoom-=0.01
	goto Zoom

WheelUp::
Up::
	If zoom<=9.9
		zoom+=0.1
	goto Zoom

^WheelUp::
^Up::
	If zoom<9.99
		zoom+=0.01
	goto Zoom
	
Right::
	If mult<16
		mult:=mult*2
	goto Zoom
	
Left::
	If mult>2
		mult:=mult/2
	goto Zoom

1::
2::
3::
4::
5::
6::
7::
8::
9::
	zoom:=zoom_start*A_ThisHotkey/10
	goto Zoom	
	Return

0::
	zoom:=zoom_start
	goto Zoom	
	Return
#If
	
;============= Audio ===============
AudioDevice:
	device_list:=dev_list:="", dev_count:=0
	ad:=RunCMD("ffmpeg.exe -list_devices true -f dshow -i dummy",,"UTF-8")
	Loop Parse, % ad, `r, `n
	{
		If RegExMatch(A_LoopField, """\K.+?(?="")",dev)
			If dev not contains  Alternative,name,@device
				device_list.=dev "`n", dev_list.=dev "," , dev_count+=1		
	}
	If !device_list && !(ad~="ffmpeg\s+version") {
		MsgBox, 16, , Отсутствует ffmpeg.exe в PATH или папке программы!`nВозможно`, его версия несоответствует системе., 4
		ExitApp
	}
	Sort device_list
	return

Audio:
	If A_IsCompiled
		Menu Tray, Icon, % A_ScriptName, 1
	menu_out:=1, dev_count+=2
	Gui Destroy
	Gui Font, s11 Arial
	Gui -DPIScale +LastFound +AlwaysOnTop +HwndAD
	Gui Margin, 12, 8
	Gui Color, 4E7B99
	Gui Add, ListView, w500 gCopy -Multi Grid R%dev_count% -LV0x10 ReadOnly, N|Name
	Loop Parse, % RegExReplace(device_list,"\n$"), `n
		LV_Add((A_LoopField=audio_device) ? "Select" : "",A_Index,A_LoopField), raw:=A_Index
	LV_Add(!audio_device ? "Select" : "", raw+1, "Без звука")
	Gui Font, s10
	Gui Add, Button, x50 w120 h32 gGUIClose, Cancel
	Gui Add, Button, x+8 yp w180 hp gCopy, Копировать
	Gui Add, Button, x+8 yp w120 hp gOK, OK
	Gui Show,, Источники звука FFmpeg
	Return
	
Copy:
OK:
	row_select:=LV_GetNext()
	If !row_select {
		ToolTip Выделите строку!
		Sleep 1000
		ToolTip
		Return
	}
	LV_GetText(audio_device, row_select,2)
	If (audio_device="Без звука")
		audio_device:=""
	If (A_ThisLabel="OK")
	{
		Gui Destroy			
		IniWrite % audio_device, % A_ScriptDir "\ff_rec.ini", Main, audio_device
		If !info {
			Menu MainMenu, Delete
			If A_IsCompiled
				Menu Tray, Icon, % A_ScriptName, 2
			goto Menu
		}
		ExitApp
	}
	Clipboard:=audio_device		
	ToolTip % "Скопировано!"
	Sleep 1500
	ToolTip
	Return
	
GuiClose:
	ExitApp
	
#If WinActive("ahk_id" AD)
Esc::ExitApp
#If

;========= Окно завершения ============
EndWindow:
	If A_IsCompiled
		Menu Tray, Icon, % A_ScriptName, 1
	If pid_thumb
		Process WaitClose, % pid_thumb
	If !rec_time
		rec_time:="-", proc_time.=" мс"
	else
		proc_time:=FormatTime(proc_time), rec_time:=FormatTime(rec_time)		
	SetFormat FloatFast, 0.3	
	FileGetSize file_size, % file_path, K
	SplitPath file_path, file_name, dir, ext
	If !no_subfolders {
		Loop Parse, subfolders, CSV
		{
			sfolder:=Trim(A_LoopField)
			If %sfolder% contains % ext
			{
				FileCreateDir % (dir:=out_folder "\" sfolder)
				FileMove % file_path, % dir
				file_path:=dir "\" file_name
			}
		}
	}
	If (show="0")
		ExitApp
	Loop Files, open_in\*.*, R
	{
		If A_LoopFileExt in lnk,bat,cmd,exe,ahk
		{
			app_index.=RegExReplace(A_LoopFileName,"\.\w{2,5}$") "`n"
			path_index.=A_LoopFileLongPath "`n"			
		}		
	}
	app_index:=RegExReplace(app_index, "`n$")
	Sort app_index
	Gui 6:Destroy
	Gui 6:+LastFound -DPIScale +hWndGuiHwnd
	Gui 6:Margin, 6, 6
	Gui 6:Color, 4E7B99
	Gui 6:Font, s11
	If ext not in mp3,wav,flac,opus,m4a,aac,mp2,ac3,ogg
	{
		If (sw>=sh) 
			Gui 6:Add, Picture, gOpen y8 w360 h-1, % thumb ? thumb : file_path
		else
			Gui 6:Add, Picture, gOpen y8 w-1 h360, % thumb ? thumb : file_path
	}	
		
	Gui 6:Add, ListView, y+8 w600 Grid R6 -Hdr ReadOnly 0x2000, Type|Value
	Gui 6:Default
	LV_Add("", "Имя файла ", " " file_name)
	LV_Add("", "Папка ", " " dir "\")
	LV_Add("", "Ширина x высота ", " " ow " x " oh " px")
	LV_Add("", "Размер ", " " file_size/1000 " MB")
	LV_Add("", "Время записи ", " " rec_time)
	LV_Add("", "Время обработки ", " " proc_time)
	LV_ModifyCol(1)
	dp:=(sw>=sh) ? 120 : (600-sw*360/sh)//2
	GuiControl Move, Static1, x%dp%
	wb:=(600-18)//4
	Gui 6:Font, s10
	Gui 6:Add, Button, section w%wb% gOpen Default, Открыть
	Gui 6:Add, Button, ys x+6 wp gFolder, Папка 
	Gui 6:Add, Button, ys x+6 wp gTrash, Удалить
	Gui 6:Add, Button, ys x+6 wp gLog, Лог
	If app_index
		Gui 6:Add, Text, xs cF1F1F1, % "          Внешние инструменты"
	Loop Parse, app_index, `n
	{
		sect:=(A_Index~="^(1|5|9|13|17|21)$") ? "section xs" : "x+6 ys"
		Gui 6:Add, Button,  %sect% w%wb% gButton, % A_LoopField	
	}
	Gui 6:Show, Center, % "ff_rec [" bat "]"
	If show && (show!="0") {
		Sleep % show*1000
		Gui 6:Destroy
		ExitApp
	}
	Return
	
6GuiClose:
	Gui 6:Destroy
	ExitApp
	
Folder:
	KeyWait LButton, T1
	Run % "explorer.exe /select`," file_path
	return
	
Button:
	Loop Parse, path_index, `n
		If (A_LoopField~=A_GuiControl) 	
			Run % """" A_LoopField """ """ file_path """"
	return

F8::
	If WinExist("ahk_id" log) {
		Gui 5:Destroy
		Return
	}
	Else If FileExist(stdout) {	
		Gui 5:Destroy
		Gui 5:+LastFound +hWndlog +AlwaysOnTop -DPIScale
		Gui 5:Margin, 12, 8
		Gui 5:Color, 4E7B99, Black
		Gui 5:Font, s%font_log% c00EA00, Lucida Console
		Gui 5:Font, s%font_log% c00EA00, Consolas
		wedit:=MRight*4//5, hedit:=MWBottom*4//5
		Gui 5:Add, Edit, w%wedit% h%hedit% vMyEdit
		Gui 5:Show, Center, % "ff_rec [" bat "] - log"
	}
	Return
		
Trash:
	MsgBox, 33, , Удалить в корзину?
	IfMsgBox Cancel
		return
	IfMsgBox OK
		FileRecycle % file_path	
	ExitApp
	
Log:
	Run % """" stdout """"
	Return
	
#If WinActive("ahk_id" GuiHwnd)
Esc::
	Goto 6GuiClose

Enter::
NumpadEnter::
Open:
	Run % """" file_path """"
	return

#If
	
;=====================================
CaptureScreen(aRect, sFile, nQuality, Cursor)
{
	pToken := Gdip_Startup()
	pBitmap := Gdip_BitmapFromScreen(aRect, Cursor)
	If	sFile = 0
		Gdip_SetBitmapToClipboard(pBitmap)
	Else
		Gdip_SaveBitmapToFile(pBitmap, sFile, nQuality)
	DllCall("gdiplus\GdipDisposeImage", UInt, pBitmap)
	Gdip_Shutdown(pToken)
}


RunCMD(CmdLine, WorkingDir:="", Codepage:="CP0", Fn:="RunCMD_Output") {  ;         RunCMD v0.94        
Local         ; RunCMD v0.94 by SKAN on D34E/D37C @ autohotkey.com/boards/viewtopic.php?t=74647                                                             
Global A_Args ; Based on StdOutToVar.ahk by Sean @ autohotkey.com/board/topic/15455-stdouttovar

  Fn := IsFunc(Fn) ? Func(Fn) : 0
, DllCall("CreatePipe", "PtrP",hPipeR:=0, "PtrP",hPipeW:=0, "Ptr",0, "Int",0)
, DllCall("SetHandleInformation", "Ptr",hPipeW, "Int",1, "Int",1)
, DllCall("SetNamedPipeHandleState","Ptr",hPipeR, "UIntP",PIPE_NOWAIT:=1, "Ptr",0, "Ptr",0)

, P8 := (A_PtrSize=8)
, VarSetCapacity(SI, P8 ? 104 : 68, 0)                          ; STARTUPINFO structure      
, NumPut(P8 ? 104 : 68, SI)                                     ; size of STARTUPINFO
, NumPut(STARTF_USESTDHANDLES:=0x100, SI, P8 ? 60 : 44,"UInt")  ; dwFlags
, NumPut(hPipeW, SI, P8 ? 88 : 60)                              ; hStdOutput
, NumPut(hPipeW, SI, P8 ? 96 : 64)                              ; hStdError
, VarSetCapacity(PI, P8 ? 24 : 16)                              ; PROCESS_INFORMATION structure

  If not DllCall("CreateProcess", "Ptr",0, "Str",CmdLine, "Ptr",0, "Int",0, "Int",True
                ,"Int",0x08000000 | DllCall("GetPriorityClass", "Ptr",-1, "UInt"), "Int",0
                ,"Ptr",WorkingDir ? &WorkingDir : 0, "Ptr",&SI, "Ptr",&PI)  
     Return Format("{1:}", "", ErrorLevel := -1
                   ,DllCall("CloseHandle", "Ptr",hPipeW), DllCall("CloseHandle", "Ptr",hPipeR))

  DllCall("CloseHandle", "Ptr",hPipeW)
, A_Args.RunCMD := { "PID": NumGet(PI, P8? 16 : 8, "UInt") }      
, File := FileOpen(hPipeR, "h", Codepage)

, LineNum := 1,  sOutput := ""
  While (A_Args.RunCMD.PID + DllCall("Sleep", "Int",0))
    and DllCall("PeekNamedPipe", "Ptr",hPipeR, "Ptr",0, "Int",0, "Ptr",0, "Ptr",0, "Ptr",0)
        While A_Args.RunCMD.PID and (Line := File.ReadLine())
          sOutput .= Fn ? Fn.Call(Line, LineNum++) : Line

  A_Args.RunCMD.PID := 0
, hProcess := NumGet(PI, 0)
, hThread  := NumGet(PI, A_PtrSize)

, DllCall("GetExitCodeProcess", "Ptr",hProcess, "PtrP",ExitCode:=0)
, DllCall("CloseHandle", "Ptr",hProcess)
, DllCall("CloseHandle", "Ptr",hThread)
, DllCall("CloseHandle", "Ptr",hPipeR)

, ErrorLevel := ExitCode

Return sOutput  
}

KillChildProcesses(ParentPidOrExe){
	static Processes, i
	ParentPID:=","
	If !(Processes)
		Processes:=ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
	i++
	for Process in Processes
		If (Process.Name=ParentPidOrExe || Process.ProcessID=ParentPidOrExe)
			ParentPID.=process.ProcessID ","
	for Process in Processes
		If InStr(ParentPID,"," Process.ParentProcessId ","){
			KillChildProcesses(process.ProcessID)
			Process,Close,% process.ProcessID 
		}
	i--
	If !i
		Processes=
}

FormatTime(Time) {
	Local Rest, Hours, Min, Sec, MSec
	If Time < 0
		Return "00:00:00"
	Rest := Mod(Time, 3600000)
	Hours := Format("{:02d}", Time // 3600000)
	Min := Format("{:02d}", Rest // 60000)
	Sec := Format("{:02d}", Mod(Rest, 60000) // 1000)
	;~ MSec := Format("{:03d}", Mod(Rest, 1000))
	Return Hours ":" Min ":" Sec
}



