; ==============================================================================
; Minou Popup Launcher - AutoHotkey v2
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

CoordMode "Mouse", "Screen"
SetWorkingDir A_ScriptDir

; Global state
ScriptTitle := "Minou Popup"
BaseDir := A_ScriptDir
ConfigDir := BaseDir . "\Config"
ConfigFile := ConfigDir . "\config.json"
SettingsFile := ConfigDir . "\settings.json"
UrlsFile := ConfigDir . "\urls.json"
SnippetsFile := ConfigDir . "\snippets.json"
PromptsFile := ConfigDir . "\prompts.json"
UtilitiesFile := ConfigDir . "\utilities.json"
HotstringFile := ConfigDir . "\hotstrings.json"
ConfigData := Map()
SettingsData := Map()
UrlData := Map()
SnippetData := Map()
PromptData := Array()
HotstringData := Array()
ProgramData := Array()
FolderData := Array()
UtilityData := Map()
AllSearchItems := Array()
LauncherGui := ""
SearchBox := ""
CategoryListBox := ""
ResultsListView := ""
CurrentEntries := Array()
CurrentCategory := "All"

#Include "Modules\Json.ahk"
#Include "Modules\Utilities.ahk"
#Include "Modules\MenuBuilder.ahk"
#Include "Modules\Launcher.ahk"
#Include "Modules\Hotstrings.ahk"

InitMinou()

InitMinou(*) {
    SetMenuDarkMode()
    LoadConfiguration()
    CreateLauncherGui()
    RegisterHotkeys()
    SetupTrayMenu()
}

SetMenuDarkMode(*) {
    try {
        uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
        if (!uxtheme)
            uxtheme := DllCall("LoadLibrary", "str", "uxtheme", "ptr")
        if (uxtheme) {
            SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
            if (SetPreferredAppMode)
                DllCall(SetPreferredAppMode, "int", 2)
            FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
            if (FlushMenuThemes)
                DllCall(FlushMenuThemes)
        }
    } catch {
        ; Ignore unsupported system theme changes.
    }
}

LoadConfiguration(*) {
    global ConfigData, SettingsData, UrlData, SnippetData, PromptData, ProgramData, FolderData, UtilityData
    ConfigData := LoadJsonFile(ConfigFile, Map())
    SettingsData := LoadJsonFile(SettingsFile, Map())
    UrlData := LoadJsonFile(UrlsFile, Map())
    SnippetData := LoadJsonFile(SnippetsFile, Map())
    PromptData := LoadJsonFile(PromptsFile, Array())
    HotstringData := LoadJsonFile(HotstringFile, Array())
    RegisterHotstrings()

    if (!ConfigData.Has("programs"))
        ConfigData["programs"] := []
    if (!ConfigData.Has("folders"))
        ConfigData["folders"] := []
    if (!ConfigData.Has("utilities"))
        ConfigData["utilities"] := []

    ProgramData := ConfigData["programs"]
    FolderData := ConfigData["folders"]

    if (FileExist(UtilitiesFile)) {
        UtilityData := LoadJsonFile(UtilitiesFile, Map())
    } else {
        UtilityData := ConfigData["utilities"]
    }
}

RegisterHotkeys(*) {
    global SettingsData
    hotkeyMain := "F3"
    hotkeySearch := "+F3"
    if (SettingsData.Has("hotkey") && SettingsData["hotkey"] != "")
        hotkeyMain := SettingsData["hotkey"]
    if (SettingsData.Has("searchHotkey") && SettingsData["searchHotkey"] != "")
        hotkeySearch := SettingsData["searchHotkey"]

    Hotkey(hotkeyMain, (*) => ShowLauncherGui(false))
    Hotkey(hotkeySearch, (*) => ShowLauncherGui(true))
}

SetupTrayMenu(*) {
    Tray := A_TrayMenu
    Tray.Delete()
    Tray.Add("Show Minou (F3)", (*) => ShowLauncherGui(false))
    Tray.Add("Search Mode (Shift+F3)", (*) => ShowLauncherGui(true))
    Tray.Add("Hotstring Manager", (*) => ShowHotstringManager())
    Tray.Add()
    Tray.Add("Edit config", (*) => Run("notepad.exe " . Chr(34) . ConfigFile . Chr(34)))
    Tray.Add("Reload", (*) => Reload())
    Tray.Add("Exit", (*) => ExitApp())
    A_IconTip := "Minou Popup"
}

ExpandEnvVars(path) {
    expanded := path
    if (InStr(path, "%A_ScriptDir%"))
        expanded := StrReplace(expanded, "%A_ScriptDir%", A_ScriptDir)
    if (InStr(path, "%TEMP%"))
        expanded := StrReplace(expanded, "%TEMP%", EnvGet("TEMP"))
    if (InStr(path, "%USERPROFILE%"))
        expanded := StrReplace(expanded, "%USERPROFILE%", EnvGet("USERPROFILE"))
    if (InStr(path, "%LOCALAPPDATA%"))
        expanded := StrReplace(expanded, "%LOCALAPPDATA%", EnvGet("LOCALAPPDATA"))
    if (InStr(path, "%APPDATA%"))
        expanded := StrReplace(expanded, "%APPDATA%", EnvGet("APPDATA"))
    if (InStr(path, "%ProgramFiles%"))
        expanded := StrReplace(expanded, "%ProgramFiles%", EnvGet("ProgramFiles"))
    return expanded
}

SafeRun(target, args := "") {
    target := ExpandEnvVars(target)
    if (target = "")
        return
    try {
        if (InStr(target, "http://") || InStr(target, "https://") || InStr(target, "ms-settings:") || InStr(target, "shell:")) {
            Run(target)
        } else if (FileExist(target)) {
            Run(target)
        } else if (InStr(target, "explorer.exe") || InStr(target, "cmd.exe") || InStr(target, "powershell.exe") || InStr(target, "notepad.exe")) {
            Run(target . (args != "" ? " " . args : ""))
        } else {
            Run(target . (args != "" ? " " . args : ""))
        }
    } catch {
        ToolTip("Could not launch target.")
        SetTimer((*) => ToolTip(), -1500)
    }
}

LaunchItem(entry) {
    if (entry.kind = "url") {
        SafeRun(entry.target)
    } else if (entry.kind = "program") {
        if (entry.target != "" && FileExist(entry.target))
            SafeRun(entry.target)
        else
            ToolTip("⚠ Not installed: " . entry.name)
    } else if (entry.kind = "folder") {
        SafeRun("explorer.exe", entry.target)
    } else if (entry.kind = "snippet") {
        PasteText(entry.target)
    } else if (entry.kind = "prompt") {
        A_Clipboard := entry.target
        ToolTip("Prompt copied to clipboard")
        SetTimer((*) => ToolTip(), -1500)
    } else if (entry.kind = "utility") {
        if (entry.HasOwnProp("action")) {
            if (entry.action = "internal") {
                DispatchInternalUtility(entry.target)
            } else if (entry.action = "cmd") {
                SafeRun("cmd.exe", "/c " . entry.target)
                if (entry.HasOwnProp("feedback") && entry.feedback != "")
                    ShowUtilityFeedback("✓ " . entry.feedback)
            } else if (entry.action = "powershell") {
                SafeRun("powershell.exe", "-NoProfile -Command " . entry.target)
                if (entry.HasOwnProp("feedback") && entry.feedback != "")
                    ShowUtilityFeedback("✓ " . entry.feedback)
            }
        } else if (entry.target != "") {
            SafeRun(entry.target)
        } else {
            ToolTip("Unavailable")
        }
    } else if (entry.kind = "script") {
        WinActivate("ahk_id " . entry.hwnd)
    } else if (entry.kind = "setting") {
        SafeRun(entry.target)
    }
}

PasteText(txt) {
    formattedTxt := StrReplace(txt, "{DATE}", FormatTime(, "yyyy-MM-dd"))
    formattedTxt := StrReplace(formattedTxt, "{TIME}", FormatTime(, "HH:mm:ss"))
    formattedTxt := StrReplace(formattedTxt, "{CLIPBOARD}", A_Clipboard)
    formattedTxt := StrReplace(formattedTxt, "{ENTER}", "`n")
    oldClip := A_Clipboard
    A_Clipboard := formattedTxt
    if (ClipWait(1)) {
        Send("^v")
        SetTimer((*) => (A_Clipboard := oldClip), -1000)
    }
}