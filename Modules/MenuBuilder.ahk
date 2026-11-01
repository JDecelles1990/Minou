; ==============================================================================
; MenuBuilder.ahk - Data unification & menu entry formatting
; Every entry is a plain object: { name, category, [subcategory], kind, target, ... }
; Editable entries also carry:
;   src : which config collection owns the item ("urls", "snippets", "utilities",
;         "programs", "folders", "prompts")
;   ref : the live Map from that collection (mutated in place by EntryEditor.ahk)
; ==============================================================================

; Section title shared by Programs and Folders (merged by design, see Docs/07).
global ProgramsFoldersCategory := "Programs & Folders"

ItemField(item, key, defaultValue := "") {
    if (item is Map)
        return item.Has(key) ? item[key] : defaultValue
    return item.HasOwnProp(key) ? item.%key% : defaultValue
}

BuildMenuEntries() {
    global SettingsData, UrlData, SnippetData, PromptData, ProgramData, FolderData, UtilityData, ProgramsFoldersCategory
    entries := Array()

    for categoryName, items in UrlData {
        for item in items {
            entries.Push({ name: ItemField(item, "name"), category: categoryName, kind: "url", target: ItemField(item, "url"), src: "urls", ref: item })
        }
    }

    for item in ProgramData {
        category := ItemField(item, "category", ProgramsFoldersCategory)
        subcategory := ItemField(item, "subcategory", "Programs")
        entries.Push({ name: ItemField(item, "name"), category: category, subcategory: subcategory, kind: "program", target: ExpandEnvVars(ItemField(item, "path")), src: "programs", ref: item })
    }

    for item in FolderData {
        category := ItemField(item, "category", ProgramsFoldersCategory)
        subcategory := ItemField(item, "subcategory", "Folders")
        entries.Push({ name: ItemField(item, "name"), category: category, subcategory: subcategory, kind: "folder", target: ExpandEnvVars(ItemField(item, "path")), src: "folders", ref: item })
    }

    if (SnippetData is Map) {
        for categoryName, items in SnippetData {
            for item in items {
                entries.Push({ name: ItemField(item, "name"), category: categoryName, kind: "snippet", target: ItemField(item, "text"), src: "snippets", ref: item })
            }
        }
    }

    if (PromptData is Array) {
        for item in PromptData {
            entries.Push({ name: ItemField(item, "name"), category: "Prompts", subcategory: ItemField(item, "category", "General"), kind: "prompt", target: ItemField(item, "prompt"), src: "prompts", ref: item })
        }
    }

    if (UtilityData is Map) {
        for categoryName, subcategories in UtilityData {
            if (subcategories is Map) {
                for subcategoryName, items in subcategories {
                    if (items is Array) {
                        for item in items {
                            entries.Push({ name: ItemField(item, "name"), category: categoryName, subcategory: subcategoryName, kind: "utility", action: ItemField(item, "action", "cmd"), target: ItemField(item, "target"), feedback: ItemField(item, "feedback"), src: "utilities", ref: item })
                        }
                    }
                }
            } else if (subcategories is Array) {
                for item in subcategories {
                    entries.Push({ name: ItemField(item, "name"), category: categoryName, subcategory: "General", kind: "utility", action: ItemField(item, "action", "cmd"), target: ItemField(item, "target"), feedback: ItemField(item, "feedback"), src: "utilities", ref: item })
                }
            }
        }
    } else if (UtilityData is Array) {
        ; Legacy flat utilities from Config/config.json (read-only in the editor).
        for item in UtilityData {
            entries.Push({ name: ItemField(item, "name"), category: "Utilities", subcategory: "General", kind: "utility", action: "cmd", target: ItemField(item, "cmd"), feedback: "" })
        }
    }

    ; Built-in Windows Settings shortcuts (not user-editable).
    entries.Push({ name: "Display", category: "Windows Settings", kind: "setting", target: "ms-settings:display" })
    entries.Push({ name: "Bluetooth", category: "Windows Settings", kind: "setting", target: "ms-settings:bluetooth" })
    entries.Push({ name: "Windows Update", category: "Windows Settings", kind: "setting", target: "ms-settings:windowsupdate" })
    entries.Push({ name: "Storage", category: "Windows Settings", kind: "setting", target: "ms-settings:storage" })
    entries.Push({ name: "Clipboard", category: "Windows Settings", kind: "setting", target: "ms-settings:clipboard" })
    entries.Push({ name: "Developer Mode", category: "Windows Settings", kind: "setting", target: "ms-settings:developers" })

    ; Live AutoHotkey scripts (dynamic, not editable).
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
