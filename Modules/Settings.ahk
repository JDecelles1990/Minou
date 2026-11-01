; ==============================================================================
; Settings.ahk - Runtime Settings Module for Minou
; Owns hotkey bindings, window opacity and the Settings GUI.
; Every change updates SettingsData (memory) AND Config/settings.json (disk).
; ==============================================================================

global SettingsGui := ""
global ActiveHotkeys := Array()
global DefaultHotkey := "!F3"
global DefaultSearchHotkey := "!+F3"
global DefaultOpacityPercent := 80

; -- Generic accessors --------------------------------------------------------
GetSetting(key, defaultValue := "") {
    global SettingsData
    if (SettingsData.Has(key) && SettingsData[key] != "")
        return SettingsData[key]
    return defaultValue
}

SetSetting(key, value) {
    global SettingsData, SettingsFile
    SettingsData[key] := value
    try {
        SaveJsonFile(SettingsFile, SettingsData)
    } catch Error as err {
        MsgBox("Could not save settings:`n" . err.Message, "Minou", "Icon!")
    }
}

; -- Hotkeys ------------------------------------------------------------------
; Converts an AHK hotkey string ("!+F3", "$!F3") to a readable label ("Alt+Shift+F3").
HotkeyToText(hk) {
    text := ""
    index := 1
    hkClean := LTrim(hk, "$~*")
    while (index <= StrLen(hkClean)) {
        ch := SubStr(hkClean, index, 1)
        if (ch = "^") {
            text .= "Ctrl+"
        } else if (ch = "!") {
            text .= "Alt+"
        } else if (ch = "+") {
            text .= "Shift+"
        } else if (ch = "#") {
            text .= "Win+"
        } else {
            break
        }
        index += 1
    }
    return text . SubStr(hkClean, index)
}

; (Re)binds the launcher and search hotkeys from SettingsData. Safe to call repeatedly.
; Returns true on success, false if a hotkey string was rejected by AutoHotkey.
RegisterHotkeys(*) {
    global ActiveHotkeys, DefaultHotkey, DefaultSearchHotkey

    for activeKey in ActiveHotkeys {
        try {
            Hotkey(activeKey, "Off")
        } catch Error as err {
            ; Hotkey was never created or already removed; nothing to do.
        }
    }
    ActiveHotkeys := Array()

    hotkeyMain := GetSetting("hotkey", DefaultHotkey)
    hotkeySearch := GetSetting("searchHotkey", DefaultSearchHotkey)

    ; Helper to register both low-level hook and AltGr (<^>!) variant for international keyboards
    BindKey(hk, callback) {
        hookKey := SubStr(hk, 1, 1) = "$" ? hk : "$" . hk
        try {
            Hotkey(hookKey, callback, "On")
            ActiveHotkeys.Push(hookKey)
        } catch Error as err {
            ; Fall back to bare hotkey if $ prefix is rejected
            Hotkey(hk, callback, "On")
            ActiveHotkeys.Push(hk)
        }
        ; If hotkey uses Alt (!), also register AltGr (<^>!) for French / multilingual layouts
        if (InStr(hk, "!") && !InStr(hk, "^")) {
            altGrKey := "$" . StrReplace(hk, "!", "<^>!")
            try {
                Hotkey(altGrKey, callback, "On")
                ActiveHotkeys.Push(altGrKey)
            } catch {
                ; Ignore if AltGr variant is unsupported
            }
        }
    }

    try {
        BindKey(hotkeyMain, (*) => ShowLauncherGui(false))
    } catch Error as err {
        MsgBox("Invalid launcher hotkey '" . hotkeyMain . "':`n" . err.Message, "Minou", "Icon!")
        return false
    }

    try {
        BindKey(hotkeySearch, (*) => ShowLauncherGui(true))
    } catch Error as err {
        MsgBox("Invalid search hotkey '" . hotkeySearch . "':`n" . err.Message, "Minou", "Icon!")
        return false
    }
    return true
}

; -- Opacity ------------------------------------------------------------------
GetOpacityPercent() {
    global DefaultOpacityPercent
    value := GetSetting("opacity", DefaultOpacityPercent)
    if (!IsNumber(value))
        return DefaultOpacityPercent
    return Max(20, Min(100, Round(value)))
}

; Applies the configured (or supplied) opacity to any Minou Gui object.
ApplyOpacity(guiObj, percent := "") {
    if (guiObj = "")
        return
    if (percent = "")
        percent := GetOpacityPercent()
    try {
        WinSetTransparent(Round(255 * percent / 100), "ahk_id " . guiObj.Hwnd)
    } catch Error as err {
        ; Window may be destroyed or not yet created; ignore.
    }
}

; -- Settings GUI -------------------------------------------------------------
ShowSettingsGui(*) {
    global SettingsGui, DefaultHotkey, DefaultSearchHotkey, DefaultOpacityPercent

    if (SettingsGui != "") {
        try SettingsGui.Destroy()
        SettingsGui := ""
    }

    SettingsGui := Gui("+AlwaysOnTop", "Minou - Settings")
    SettingsGui.BackColor := "0x1A1A1A"
    SettingsGui.SetFont("s10 cD0D0D0", "Segoe UI")
    SettingsGui.OnEvent("Close", (*) => CloseSettingsGui())
    SettingsGui.OnEvent("Escape", (*) => CloseSettingsGui())

    SettingsGui.SetFont("s12 cWhite Bold", "Segoe UI")
    SettingsGui.Add("Text", "x16 y12 w360", "Settings")
    SettingsGui.SetFont("s10 cD0D0D0 Norm", "Segoe UI")

    SettingsGui.Add("Text", "x16 y50 w360", "Launcher hotkey")
    hkMain := SettingsGui.Add("Hotkey", "x16 y72 w360", GetSetting("hotkey", DefaultHotkey))

    SettingsGui.Add("Text", "x16 y110 w360", "Search-mode hotkey")
    hkSearch := SettingsGui.Add("Hotkey", "x16 y132 w360", GetSetting("searchHotkey", DefaultSearchHotkey))

    opacityNow := GetOpacityPercent()
    lblOpacity := SettingsGui.Add("Text", "x16 y170 w360", "Opacity: " . opacityNow . "%")
    sldOpacity := SettingsGui.Add("Slider", "x16 y192 w360 h30 Range20-100 TickInterval10 ToolTip", opacityNow)
    sldOpacity.OnEvent("Change", OnOpacityChange)

    btnSave := SettingsGui.Add("Button", "x16 y240 w110 h30 Default", "Save")
    btnReset := SettingsGui.Add("Button", "x+8 w130 h30", "Reset defaults")
    btnCancel := SettingsGui.Add("Button", "x+8 w100 h30", "Cancel")

    btnSave.OnEvent("Click", OnSave)
    btnReset.OnEvent("Click", OnReset)
    btnCancel.OnEvent("Click", (*) => CloseSettingsGui())

    OnOpacityChange(*) {
        lblOpacity.Text := "Opacity: " . sldOpacity.Value . "%"
        ApplyOpacity(SettingsGui, sldOpacity.Value)
        ApplyOpacity(LauncherGui, sldOpacity.Value)
    }

    OnReset(*) {
        hkMain.Value := DefaultHotkey
        hkSearch.Value := DefaultSearchHotkey
        sldOpacity.Value := DefaultOpacityPercent
        OnOpacityChange()
    }

    OnSave(*) {
        newMain := hkMain.Value
        newSearch := hkSearch.Value
        if (newMain = "" || newSearch = "") {
            MsgBox("Both hotkeys must be set.", "Minou", "Icon!")
            return
        }
        if (newMain = newSearch) {
            MsgBox("The two hotkeys must be different.", "Minou", "Icon!")
            return
        }

        oldMain := GetSetting("hotkey", DefaultHotkey)
        oldSearch := GetSetting("searchHotkey", DefaultSearchHotkey)

        SetSetting("hotkey", newMain)
        SetSetting("searchHotkey", newSearch)
        SetSetting("opacity", sldOpacity.Value)

        if (!RegisterHotkeys()) {
            ; Roll back to the previous working bindings.
            SetSetting("hotkey", oldMain)
            SetSetting("searchHotkey", oldSearch)
            RegisterHotkeys()
            return
        }

        ApplyOpacity(LauncherGui)
        UpdateLauncherHint()
        SetupTrayMenu()
        CloseSettingsGui()
        ToolTip("✓ Settings saved")
        SetTimer((*) => ToolTip(), -1500)
    }

    SettingsGui.Show("w392 h288")
    ApplyOpacity(SettingsGui)
}

CloseSettingsGui() {
    global SettingsGui, LauncherGui
    if (SettingsGui != "") {
        try SettingsGui.Destroy()
        SettingsGui := ""
    }
    ; Restore the persisted opacity in case the slider preview was cancelled.
    ApplyOpacity(LauncherGui)
}
