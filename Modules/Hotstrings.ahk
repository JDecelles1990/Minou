; ==============================================================================
; Hotstrings.ahk — Dynamic Hotstring Manager Module for Minou
; Provides a GUI editor to create, edit, delete, enable/disable hotstrings
; that are persisted to Config/hotstrings.json and registered at runtime.
; ==============================================================================

global HotstringGui := ""
global HotstringListView := ""
global RegisteredHotstrings := Array()

; ── Public: Show the Hotstring Manager GUI ────────────────────────────────────
ShowHotstringManager(*) {
    global HotstringGui, HotstringListView, HotstringData

    ; Destroy any existing instance to rebuild cleanly
    if (HotstringGui != "") {
        try HotstringGui.Destroy()
        HotstringGui := ""
    }

    HotstringGui := Gui("+AlwaysOnTop +Resize", "Minou — Hotstring Manager")
    HotstringGui.BackColor := "0x1A1A1A"
    HotstringGui.SetFont("s10 cD0D0D0", "Segoe UI")
    HotstringGui.OnEvent("Close", (*) => CloseHotstringManager())
    HotstringGui.OnEvent("Escape", (*) => CloseHotstringManager())

    HotstringGui.SetFont("s11 cWhite Bold", "Segoe UI")
    HotstringGui.Add("Text", "x12 y10 w500", "Hotstring Manager")
    HotstringGui.SetFont("s9 cA0A0A0 Norm", "Segoe UI")
    HotstringGui.Add("Text", "x12 y32 w500", "Type the trigger abbreviation, then it auto-expands to the replacement text.")

    HotstringGui.SetFont("s10 cD0D0D0 Norm", "Segoe UI")

    ; ListView with Checked option for enable/disable
    HotstringListView := HotstringGui.Add("ListView"
        , "x12 y58 w500 h240 Background0x232323 cWhite Grid Checked -Multi"
        , ["Trigger", "Replacement"])
    HotstringListView.ModifyCol(1, 140)
    HotstringListView.ModifyCol(2, 340)

    ; Populate from in-memory HotstringData
    PopulateHotstringListView()

    ; ── Button Row ────────────────────────────────────────────────────────────
    btnY := "y+12"
    BtnAdd := HotstringGui.Add("Button", "x12 " . btnY . " w90 h30", "✚ Add")
    BtnAdd.OnEvent("Click", (*) => AddHotstringDialog())

    BtnEdit := HotstringGui.Add("Button", "x+8 w90 h30", "✏ Edit")
    BtnEdit.OnEvent("Click", (*) => EditSelectedHotstring())

    BtnDel := HotstringGui.Add("Button", "x+8 w100 h30", "🗑 Delete")
    BtnDel.OnEvent("Click", (*) => DeleteSelectedHotstring())

    BtnSave := HotstringGui.Add("Button", "x+8 w100 h30", "💾 Save")
    BtnSave.OnEvent("Click", (*) => SaveAllHotstrings())

    HotstringGui.Show("w524")
}

; ── Populate ListView from HotstringData ──────────────────────────────────────
PopulateHotstringListView() {
    global HotstringListView, HotstringData
    HotstringListView.Delete()
    for index, hs in HotstringData {
        isActive := false
        if (hs.Has("active"))
            isActive := hs["active"]
        trigger := hs.Has("trigger") ? hs["trigger"] : ""
        replacement := hs.Has("replacement") ? hs["replacement"] : ""
        opts := isActive ? "Check" : ""
        HotstringListView.Add(opts, trigger, replacement)
    }
}

; ── Close the manager GUI cleanly ─────────────────────────────────────────────
CloseHotstringManager() {
    global HotstringGui
    if (HotstringGui != "") {
        try HotstringGui.Destroy()
        HotstringGui := ""
    }
}

; ── Add New Hotstring Dialog ──────────────────────────────────────────────────
AddHotstringDialog() {
    global HotstringGui, HotstringListView
    ShowEditDialog("", "", false, 0)
}

; ── Edit the currently selected hotstring ─────────────────────────────────────
EditSelectedHotstring() {
    global HotstringListView
    row := HotstringListView.GetNext(0)
    if (row = 0) {
        MsgBox("Select a hotstring to edit first.", "Minou", 48)
        return
    }
    trigger := HotstringListView.GetText(row, 1)
    replacement := HotstringListView.GetText(row, 2)
    ShowEditDialog(trigger, replacement, true, row)
}

; ── Shared Add/Edit dialog ────────────────────────────────────────────────────
ShowEditDialog(triggerVal, replacementVal, isEditing, targetRow) {
    global HotstringGui, HotstringListView

    dlg := Gui("+AlwaysOnTop +ToolWindow", isEditing ? "Edit Hotstring" : "Add Hotstring")
    dlg.BackColor := "0x1A1A1A"
    dlg.SetFont("s10 cD0D0D0", "Segoe UI")

    dlg.Add("Text", "x12 y12 w320", "Trigger abbreviation (e.g. btw):")
    edTrigger := dlg.Add("Edit", "x12 y34 w320 h26 Background0x232323 cWhite", triggerVal)

    dlg.Add("Text", "x12 y70 w320", "Replacement text:")
    edReplacement := dlg.Add("Edit", "x12 y92 w320 h26 Background0x232323 cWhite", replacementVal)

    btnOk := dlg.Add("Button", "x12 y130 w100 h30 Default", "OK")
    btnCancel := dlg.Add("Button", "x+10 w100 h30", "Cancel")

    ; OK handler — closure captures all context
    btnOk.OnEvent("Click", OnOk)
    btnCancel.OnEvent("Click", (*) => dlg.Destroy())
    dlg.OnEvent("Escape", (*) => dlg.Destroy())

    OnOk(*) {
        newTrigger := Trim(edTrigger.Value)
        newReplacement := Trim(edReplacement.Value)
        if (newTrigger = "") {
            MsgBox("Trigger cannot be empty.", "Error", 48)
            return
        }
        if (newReplacement = "") {
            MsgBox("Replacement cannot be empty.", "Error", 48)
            return
        }
        if (isEditing && targetRow > 0) {
            HotstringListView.Modify(targetRow, "", newTrigger, newReplacement)
        } else {
            HotstringListView.Add("Check", newTrigger, newReplacement)
        }
        dlg.Destroy()
    }

    dlg.Show("w344")
}

; ── Delete the selected row ───────────────────────────────────────────────────
DeleteSelectedHotstring() {
    global HotstringListView
    row := HotstringListView.GetNext(0)
    if (row = 0) {
        MsgBox("Select a hotstring to delete first.", "Minou", 48)
        return
    }
    trigger := HotstringListView.GetText(row, 1)
    result := MsgBox("Delete hotstring '" . trigger . "'?", "Confirm", 4 + 48)
    if (result = "Yes") {
        HotstringListView.Delete(row)
    }
}

; ── Save All: rebuild in-memory data, write to disk, re-register ──────────────
SaveAllHotstrings() {
    global HotstringListView, HotstringData, HotstringFile

    ; Build a fresh array from the ListView state
    newData := Array()
    totalRows := HotstringListView.GetCount()

    loop totalRows {
        trigger := HotstringListView.GetText(A_Index, 1)
        replacement := HotstringListView.GetText(A_Index, 2)
        newData.Push(Map("active", false, "trigger", trigger, "replacement", replacement))
    }

    ; Walk the checked rows to set active = true
    checkedRow := 0
    loop {
        checkedRow := HotstringListView.GetNext(checkedRow, "Checked")
        if (!checkedRow)
            break
        newData[checkedRow]["active"] := true
    }

    ; Update global state and persist
    HotstringData := newData
    SaveJsonFile(HotstringFile, HotstringData)

    ; Re-register all hotstrings with AHK engine
    ApplyHotstrings()

    ToolTip("✓ Hotstrings saved and applied")
    SetTimer((*) => ToolTip(), -2000)
}

; ── Register/unregister hotstrings with the AHK v2 Hotstring() function ───────
; Per official docs: https://www.autohotkey.com/docs/v2/lib/Hotstring.htm
;   Hotstring("::trigger", "replacement")   → create or update
;   Hotstring("::trigger",, "Off")          → disable (omit replacement param)
;   Hotstring("::trigger",, "On")           → re-enable existing
ApplyHotstrings() {
    global HotstringData, RegisteredHotstrings

    ; First, disable all previously registered hotstrings
    for index, oldTrigger in RegisteredHotstrings {
        try {
            Hotstring("::" . oldTrigger,, "Off")
        } catch {
            ; Hotstring may have already been removed; ignore.
        }
    }
    RegisteredHotstrings := Array()

    ; Register active hotstrings
    for index, hs in HotstringData {
        if (hs["active"]) {
            try {
                Hotstring("::" . hs["trigger"], hs["replacement"])
                RegisteredHotstrings.Push(hs["trigger"])
            } catch Error as err {
                MsgBox("Failed to register hotstring '" . hs["trigger"] . "':`n" . err.Message, "Minou — Error", 16)
            }
        }
    }
}

; ── Alias for startup use from LoadConfiguration ──────────────────────────────
RegisterHotstrings() {
    ApplyHotstrings()
}
