; ==============================================================================
; EntryEditor.ahk - Edit names, categories and sub-categories of launcher entries
; Works on the live in-memory collections (UrlData, SnippetData, UtilityData,
; ConfigData, PromptData) and immediately serializes the owning Config/*.json.
; Built-in entries (Windows Settings, Running Scripts, legacy utilities) are read-only.
; ==============================================================================

global EntryEditorGui := ""

ShowEntryFeedback(msg) {
    ToolTip(msg)
    SetTimer((*) => ToolTip(), -1800)
}

; Which fields can be edited for a given entry source.
EntryHasSubcategory(entry) {
    return (entry.src = "utilities" || entry.src = "prompts" || entry.src = "programs" || entry.src = "folders")
}

EntryCategoryLocked(entry) {
    ; Prompts always live in the single "Prompts" section; only their sub-category is editable.
    return (entry.src = "prompts")
}

; Opens the editor for the entry currently selected in the launcher list.
ShowEntryEditor(*) {
    global ResultsListView, VisibleEntries, EntryEditorGui, CurrentEntries

    row := ResultsListView.GetNext(0)
    if (row = 0 || row > VisibleEntries.Length) {
        ShowEntryFeedback("Select an entry to edit first")
        return
    }

    entry := VisibleEntries[row]
    if (!entry.HasOwnProp("src") || !entry.HasOwnProp("ref")) {
        ShowEntryFeedback("Built-in entries cannot be edited")
        return
    }

    if (EntryEditorGui != "") {
        try EntryEditorGui.Destroy()
        EntryEditorGui := ""
    }

    ; Suggest every category that already exists among editable entries.
    categoryMap := Map()
    for other in CurrentEntries {
        if (other.HasOwnProp("src"))
            categoryMap[other.category] := true
    }
    categoryList := Array()
    for categoryName in categoryMap {
        categoryList.Push(categoryName)
    }

    hasSub := EntryHasSubcategory(entry)
    catLocked := EntryCategoryLocked(entry)

    dlg := Gui("+AlwaysOnTop +ToolWindow", "Edit entry")
    EntryEditorGui := dlg
    dlg.BackColor := "0x1A1A1A"
    dlg.SetFont("s10 cD0D0D0", "Segoe UI")

    dlg.Add("Text", "x12 y12 w340", "Name")
    edName := dlg.Add("Edit", "x12 y34 w340 h26 Background0x232323 cWhite", entry.name)

    dlg.Add("Text", "x12 y70 w340", "Category (type a new one to create it)")
    cbCategory := dlg.Add("ComboBox", "x12 y92 w340 Background0x232323 cWhite", categoryList)
    cbCategory.Text := entry.category
    if (catLocked)
        cbCategory.Enabled := false

    nextY := 130
    edSub := ""
    if (hasSub) {
        dlg.Add("Text", "x12 y" . nextY . " w340", "Sub-category")
        edSub := dlg.Add("Edit", "x12 y" . (nextY + 22) . " w340 h26 Background0x232323 cWhite", entry.HasOwnProp("subcategory") ? entry.subcategory : "")
        nextY += 60
    }

    btnSave := dlg.Add("Button", "x12 y" . nextY . " w100 h30 Default", "Save")
    btnCancel := dlg.Add("Button", "x+10 w100 h30", "Cancel")
    btnSave.OnEvent("Click", OnSave)
    btnCancel.OnEvent("Click", (*) => CloseEntryEditor())
    dlg.OnEvent("Close", (*) => CloseEntryEditor())
    dlg.OnEvent("Escape", (*) => CloseEntryEditor())

    OnSave(*) {
        newName := Trim(edName.Value)
        newCategory := catLocked ? entry.category : Trim(cbCategory.Text)
        newSub := hasSub ? Trim(edSub.Value) : ""

        if (newName = "") {
            MsgBox("Name cannot be empty.", "Minou", "Icon!")
            return
        }
        if (newCategory = "") {
            MsgBox("Category cannot be empty.", "Minou", "Icon!")
            return
        }

        if (ApplyEntryEdit(entry, newName, newCategory, newSub)) {
            CloseEntryEditor()
            RefreshLauncherData(true)
            RefreshLauncherResults()
            ShowEntryFeedback("✓ Entry updated")
        }
    }

    dlg.Show("w364 h" . (nextY + 46))
    ApplyOpacity(dlg)
}

CloseEntryEditor() {
    global EntryEditorGui
    if (EntryEditorGui != "") {
        try EntryEditorGui.Destroy()
        EntryEditorGui := ""
    }
}

; Applies the edit to memory and disk. Returns true on success.
ApplyEntryEdit(entry, newName, newCategory, newSub) {
    global UrlData, SnippetData, UtilityData, ConfigData, PromptData
    global UrlsFile, SnippetsFile, UtilitiesFile, ConfigFile, PromptsFile, ProgramsFoldersCategory

    item := entry.ref
    try {
        switch entry.src {
            case "urls":
                MoveItemBetweenCategories(UrlData, entry.category, newCategory, item)
                item["name"] := newName
                SaveJsonFile(UrlsFile, UrlData)
            case "snippets":
                MoveItemBetweenCategories(SnippetData, entry.category, newCategory, item)
                item["name"] := newName
                SaveJsonFile(SnippetsFile, SnippetData)
            case "utilities":
                MoveUtilityItem(UtilityData, entry, newCategory, newSub == "" ? "General" : newSub)
                item["name"] := newName
                SaveJsonFile(UtilitiesFile, UtilityData)
            case "programs":
                item["name"] := newName
                SetOrClearField(item, "category", newCategory, ProgramsFoldersCategory)
                SetOrClearField(item, "subcategory", newSub, "Programs")
                SaveJsonFile(ConfigFile, ConfigData)
            case "folders":
                item["name"] := newName
                SetOrClearField(item, "category", newCategory, ProgramsFoldersCategory)
                SetOrClearField(item, "subcategory", newSub, "Folders")
                SaveJsonFile(ConfigFile, ConfigData)
            case "prompts":
                item["name"] := newName
                item["category"] := (newSub == "" ? "General" : newSub)
                SaveJsonFile(PromptsFile, PromptData)
            default:
                return false
        }
    } catch Error as err {
        MsgBox("Could not save the change:`n" . err.Message, "Minou", "Icon!")
        return false
    }
    return true
}

; Stores value on the item, or removes the key when it equals the built-in default.
SetOrClearField(item, key, value, defaultValue) {
    if (value == "" || value == defaultValue) {
        if (item.Has(key))
            item.Delete(key)
    } else {
        item[key] := value
    }
}

RemoveItemFromArray(arr, item) {
    for index, candidate in arr {
        if (candidate == item) {
            arr.RemoveAt(index)
            return true
        }
    }
    return false
}

; catMap shape: Map(categoryName -> Array(items)). Empty categories are removed.
MoveItemBetweenCategories(catMap, oldCategory, newCategory, item) {
    if (oldCategory == newCategory)
        return
    if (catMap.Has(oldCategory)) {
        RemoveItemFromArray(catMap[oldCategory], item)
        if (catMap[oldCategory].Length = 0)
            catMap.Delete(oldCategory)
    }
    if (!catMap.Has(newCategory))
        catMap[newCategory] := Array()
    catMap[newCategory].Push(item)
}

; Utilities shape: Map(category -> Map(subcategory -> Array(items))) (or category -> Array).
MoveUtilityItem(utilData, entry, newCategory, newSub) {
    item := entry.ref
    oldCategory := entry.category
    oldSub := entry.HasOwnProp("subcategory") ? entry.subcategory : "General"
    if (oldCategory == newCategory && oldSub == newSub)
        return

    if (utilData.Has(oldCategory)) {
        container := utilData[oldCategory]
        if (container is Map) {
            if (container.Has(oldSub)) {
                RemoveItemFromArray(container[oldSub], item)
                if (container[oldSub].Length = 0)
                    container.Delete(oldSub)
            }
            if (container.Count = 0)
                utilData.Delete(oldCategory)
        } else if (container is Array) {
            RemoveItemFromArray(container, item)
            if (container.Length = 0)
                utilData.Delete(oldCategory)
        }
    }

    if (!utilData.Has(newCategory) || !(utilData[newCategory] is Map)) {
        ; Convert a legacy flat category into the sub-category layout.
        legacyItems := utilData.Has(newCategory) ? utilData[newCategory] : Array()
        utilData[newCategory] := Map()
        if (legacyItems.Length > 0)
            utilData[newCategory]["General"] := legacyItems
    }
    if (!utilData[newCategory].Has(newSub))
        utilData[newCategory][newSub] := Array()
    utilData[newCategory][newSub].Push(item)
}

