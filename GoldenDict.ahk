; Translate selected text for GoldenDict
GetInstallPath(ProgramName) {
    SoftwareKey := (A_Is64bitOS = 0 ? "Software" : "Software\WOW6432Node")
    RegRead, FullFileName, HKEY_LOCAL_MACHINE, %SoftwareKey%\Microsoft\Windows\CurrentVersion\Uninstall\%ProgramName%, UninstallString
    SplitPath, FullFileName,, InstallPath
    return %InstallPath%
}
GoldenDict := "C:\Program Files (x86)\GoldenDict\GoldenDict.exe"
run, %GoldenDict%

GroupAdd, DontActiveGroup, ahk_class ExploreWClass  ; Disable Explorer window. Unused on Vista and later
GroupAdd, DontActiveGroup, ahk_class CabinetWClass  ; Disable Explorer window.
GroupAdd, DontActiveGroup, ahk_class Progman        ; Disable desktop window.
GroupAdd, DontActiveGroup, ahk_class WorkerW        ; Disable desktop window.
GroupAdd, DontActiveGroup, ahk_class ConsoleWindowClass ; Disable console window.

GetArrowState() {
    arrowstate_result = 0
    GetKeyState, keystate, Left, P
    if keystate = D
        arrowstate_result += 1
    GetKeyState, keystate, Up, P
    if keystate = D
        arrowstate_result += 2
    GetKeyState, keystate, Right, P
    if keystate = D
        arrowstate_result += 4
    GetKeyState, keystate, Down, P
    if keystate = D
        arrowstate_result += 8
    return arrowstate_result
}

#IfWinNotActive ahk_group DontActiveGroup
~Rshift::
TimeButtonDown = %A_TickCount%
arrow_state = 0
; Wait for it to be released
Loop
{
    Sleep 10
    if arrow_state = 0
        arrow_state = GetArrowState()
    GetKeyState, LshiftState, Lshift, P
    if LshiftState = U  ; Button has been released.
        break
    elapsed = %A_TickCount%
    elapsed -= %TimeButtonDown%
    if elapsed > 200  ; Button was held down long enough
    {
        x0 = A_CaretX
        y0 = A_CaretY
        Loop
        {
            Sleep 10                    ; yield time to others
            if arrow_state = 0
                arrow_state = GetArrowState()
            GetKeyState, keystate, Lshift
            IfEqual keystate, U, {
                x = A_CaretX
                y = A_CaretY
                break
            }
        }
        if (arrow_state <> 0 and (x-x0 > 5 or x-x0 < -5 or y-y0 > 5 or y-y0 < -5))
        {   ; Caret has moved
            GoSub, TranslateRoutine
        }
        return
    }
}

#IfWinNotActive ahk_group DontActiveGroup
~LButton::
TimeButtonDown = %A_TickCount%
MouseGetPos x0, y0            ; save start mouse position
; Wait for it to be released
Loop
{
    Sleep 10
    GetKeyState, LButtonState, LButton, P
    if LButtonState = U  ; Button has been released.
        break
    elapsed = %A_TickCount%
    elapsed -= %TimeButtonDown%
    if elapsed > 200  ; Button was held down too long, so assume it's not a double-click.
    {
        Loop
        {
            Sleep 20                    ; yield time to others
            GetKeyState, keystate, LButton
            IfEqual keystate, U, {
                MouseGetPos x, y          ; position when button released
                break
            }
        }
        if (x-x0 > 5 or x-x0 < -5 or y-y0 > 5 or y-y0 < -5)
        {   ; mouse has moved
            GoSub, TranslateRoutine
        }
        return
    }
}
; Otherwise, button was released quickly enough.  Wait to see if it's a double-click:
TimeButtonUp = %A_TickCount%
Loop
{
    Sleep 10
    GetKeyState, LButtonState, LButton, P
    if LButtonState = D  ; Button has been pressed down again.
        break
    elapsed = %A_TickCount%
    elapsed -= %TimeButtonUp%
    if elapsed > 350  ; No click has occurred within the allowed time, so assume it's not a double-click.
    {
        ;MouseClick, Left
        return
    }
}

; Since above didn't return, it's a double-click:
Sleep, 100
;Send, ^c
GoSub, TranslateRoutine
return

TranslateRoutine:
{
    WinGetActiveTitle active_title
    OutputDebug Current active window title is %active_title%.

    old_clip := ClipBoardAll    ; save old clipboard
    ClipBoard =                 ; clear current clipboard
    send, ^c                    ; selection -> clipboard
    ClipWait, 1                 ; retrieve new clipboard
    if ErrorLevel
    {
        selected = ""
    }
    else
    {
        selected = %ClipBoard%
    }
    SetEnv, ClipBoard, %old_clip%   ; restore old clipboard

    IfEqual selected,, return
    selected := Trim(selected, " `t`r`n")
    StringLen, sel_len, selected
    if (sel_len <= 0 or sel_len > 50)
    {
        return
    }
    selected := """" . selected . """"
    run, %GoldenDict% %selected%
}
return

; CapsLock::suspend Toggle
MButton::suspend Toggle
