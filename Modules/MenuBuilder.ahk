BuildMenuEntries() {
    global SettingsData, UrlData, SnippetData, PromptData, ProgramData, FolderData, UtilityData
    entries := Array()

    for categoryName, items in UrlData {
        for item in items {
            name := item is Map ? item["name"] : item.name
            url := item is Map ? item["url"] : item.url
            entries.Push({ name: name, category: categoryName, kind: "url", target: url })
        }
    }

    for item in ProgramData {
        name := item is Map ? item["name"] : item.name
        path := item is Map ? item["path"] : item.path
        entries.Push({ name: name, category: "Programs", kind: "program", target: path })
    }

    for item in FolderData {
        name := item is Map ? item["name"] : item.name
        path := item is Map ? item["path"] : item.path
        entries.Push({ name: name, category: "Folders", kind: "folder", target: ExpandEnvVars(path) })
    }

    if (SnippetData is Map) {
        for categoryName, items in SnippetData {
            for item in items {
                name := item is Map ? item["name"] : item.name
                text := item is Map ? item["text"] : item.text
                entries.Push({ name: name, category: categoryName, kind: "snippet", target: text })
            }
        }
    }

    if (PromptData is Array) {
        for item in PromptData {
            name := item is Map ? item["name"] : item.name
            prompt := item is Map ? item["prompt"] : item.prompt
            entries.Push({ name: name, category: "Prompts", kind: "prompt", target: prompt })
        }
    }

    for item in UtilityData {
        name := item is Map ? item["name"] : item.name
        cmd := item is Map ? item["cmd"] : item.cmd
        entries.Push({ name: name, category: "Utilities", kind: "utility", target: cmd })
    }

    entries.Push({ name: "Display", category: "Windows Settings", kind: "setting", target: "ms-settings:display" })
    entries.Push({ name: "Bluetooth", category: "Windows Settings", kind: "setting", target: "ms-settings:bluetooth" })
    entries.Push({ name: "Windows Update", category: "Windows Settings", kind: "setting", target: "ms-settings:windowsupdate" })
    entries.Push({ name: "Storage", category: "Windows Settings", kind: "setting", target: "ms-settings:storage" })
    entries.Push({ name: "Clipboard", category: "Windows Settings", kind: "setting", target: "ms-settings:clipboard" })
    entries.Push({ name: "Developer Mode", category: "Windows Settings", kind: "setting", target: "ms-settings:developers" })

    DetectHiddenWindows(true)
    for hwnd in WinGetList("ahk_class AutoHotkey") {
        if (hwnd != A_ScriptHwnd) {
            title := WinGetTitle("ahk_id " . hwnd)
            if (title != "") {
                entries.Push({ name: title, category: "Running Scripts", kind: "script", hwnd: hwnd })
            }
        }
    }

    return entries
}
