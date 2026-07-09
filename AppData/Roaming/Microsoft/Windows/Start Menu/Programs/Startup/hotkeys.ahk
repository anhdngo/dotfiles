#Requires AutoHotkey v2.0

; Open Edge profile 1 with Ctrl + Alt + B
^!b:: {
    Run('firefox.exe')
}

; Open Edge profile 2 with Ctrl + Alt + Shift + B
^+!b::
{
    Run('firefox.exe --private-window')
}

; Open Command Prompt with Ctrl + Alt + T
^!t:: {
	Run("cmd.exe", EnvGet("USERPROFILE"))
}
^!+t::{
	try {
        Run('*RunAs cmd.exe')
    } catch Error {
        MsgBox("Failed to run as admin.`nError: " Error.Message)
    }
}


; Open powershell with Ctrl + Alt + Y
^!y:: {
	Run("powershell.exe", EnvGet("USERPROFILE"))
}
^!+y::{
	try {
        Run('*RunAs powershell.exe')
    } catch Error {
        MsgBox("Failed to run as admin.`nError: " Error.Message)
    }
}

; Open wsl with Ctrl + Alt + Enter
^!Enter::
{
	Run("cmd /k wsl", EnvGet("USERPROFILE")) ; /k keeps the terminal open after executing the command
    return
}

; Launch a new File Explorer window
^!e::
{
    Run("explorer.exe")
    return
}

; Disable normal Caps Lock behavior and open Task Switcher with Caps Lock
CapsLock:: {
    Send "{LWin Down}{Tab}"
    Sleep 100
    Send "{LWin Up}"
}

^!Backspace::
{
    ; Get the handle of the currently active window
    activeWindow := WinGetID("A")

    ; Check if a window is active
    if (activeWindow)
    {
        ; Close the active window
        WinClose(activeWindow)
    }
    return
}

; Map mouse side buttons to switching desktops
XButton1::
{
    Send("^#{Left}")
}

XButton2::
{
    Send("^#{Right}")
}
