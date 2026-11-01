global VisibleEntries := Array()
global IsRefreshingLauncher := false
global LauncherHint := ""

; Section color palette (Win32 BGR format 0x00BBGGRR for high contrast dark UI)
global SectionColors := Map(
    "Cloud Platforms", 0xF7C34F,
    "Cybersecurity", 0x5252FF,
    "Developer Tools", 0x26A7FF,
    "Documentation", 0xD893CE,
    "Finance", 0xAEF069,
    "Housing", 0x4FD5FF,
    "Learning", 0xFFE500,
    "Network & SysAdmin", 0xFF88B3,
    "Networking", 0xFFC440,
    "Programs & Folders", 0xDAFF64,
    "Prompts", 0x8140FF,
    "Québec & Canada Government", 0x406EFF,
    "Remote Support", 0xB6E91D,
    "Running Scripts", 0x00EAAE,
    "Shopping", 0x91ABFF,
    "Snippets", 0x00FFC6,
    "Windows Settings", 0xC5BEB0
)

GetSectionColor(categoryName) {
    global SectionColors
    if (SectionColors.Has(categoryName))
        return SectionColors[categoryName]
    return 0xE0E0E0 ; Default silver-white
}

; Launcher window geometry (client area, pixels).
global LauncherWidth := 580
global LauncherHeight := 392
global LauncherTitleHeight := 36

CreateLauncherGui() {
    global LauncherGui, SearchBox, CategoryListBox, ResultsListView, LauncherHint
    global LauncherWidth, LauncherHeight, LauncherTitleHeight

    if (LauncherGui != "") {
        LauncherGui.Destroy()
    }

    LauncherGui := Gui("+AlwaysOnTop -Caption +MinimizeBox +Border", "Minou")
    LauncherGui.BackColor := "0x1A1A1A"

    ; -- Custom title bar (draggable): title, settings, minimize, close ----------
    LauncherGui.Add("Text", "x0 y0 w" . LauncherWidth . " h" . LauncherTitleHeight . " Background0x111111")
    LauncherGui.SetFont("s10 cC0C0C0 Bold", "Segoe UI")
    LauncherGui.Add("Text", "x12 y8 w300 h22 BackgroundTrans", "Minou Launcher")

    LauncherGui.SetFont("s12 cD0D0D0 Norm", "Segoe UI Emoji")
    BtnSettings := LauncherGui.Add("Text", "x" . (LauncherWidth - 100) . " y3 w32 h30 +0x200 +0x100 Center BackgroundTrans", "⚙")
    BtnSettings.OnEvent("Click", (*) => ShowSettingsGui())

    LauncherGui.SetFont("s12 cD0D0D0 Bold", "Segoe UI")
    BtnMinimize := LauncherGui.Add("Text", "x" . (LauncherWidth - 66) . " y3 w32 h30 +0x200 +0x100 Center BackgroundTrans", "_")
    BtnMinimize.OnEvent("Click", (*) => MinimizeLauncher())
    BtnClose := LauncherGui.Add("Text", "x" . (LauncherWidth - 34) . " y3 w32 h30 +0x200 +0x100 Center BackgroundTrans", "✕")
    BtnClose.OnEvent("Click", (*) => HideLauncher())

    ; -- Search + results ---------------------------------------------------------
    LauncherGui.SetFont("s10 cD0D0D0 Norm", "Segoe UI")
    SearchBox := LauncherGui.Add("Edit", "x12 y46 w560 h28 Background0x232323 cWhite")
    SearchBox.OnEvent("Change", (*) => RefreshLauncherResults())

    CategoryListBox := LauncherGui.Add("ListBox", "x12 y84 w170 h270 Background0x232323 cWhite +0x0010 +0x0040")
    CategoryListBox.OnEvent("Change", OnCategoryChange)

    ResultsListView := LauncherGui.Add("ListView", "x190 y84 w382 h270 Background0x232323 cWhite Grid", ["Name", "Category"])
    ResultsListView.ModifyCol(1, 220)
    ResultsListView.ModifyCol(2, 140)
    ResultsListView.OnEvent("DoubleClick", (*) => RunSelectedEntry())
    ResultsListView.OnNotify(-12, OnResultsListViewCustomDraw)

    ; -- Footer: hint + action buttons ---------------------------------------------
    LauncherGui.SetFont("s8 c808080", "Segoe UI")
    LauncherHint := LauncherGui.Add("Text", "x12 y364 w360 h20", "")

    LauncherGui.SetFont("s10 cD0D0D0", "Segoe UI")
    BtnEdit := LauncherGui.Add("Button", "x378 y360 w90 h26", "✏ Edit")
    BtnEdit.OnEvent("Click", (*) => ShowEntryEditor())

    BtnHotstrings := LauncherGui.Add("Button", "x474 y360 w98 h26", "Hotstrings")
    BtnHotstrings.OnEvent("Click", (*) => ShowHotstringManager())

    UpdateLauncherHint()

    LauncherGui.OnEvent("Close", (*) => HideLauncher())
    LauncherGui.OnEvent("Escape", (*) => HideLauncher())

    ; Drag the borderless window by its title bar.
    OnMessage(0x0201, OnLauncherLButtonDown)
    ; Owner-draw CategoryListBox to render each section in its distinctive color.
    OnMessage(0x002B, OnLauncherDrawItem)
}

; Rebuilds the footer hint from the configured hotkeys.
UpdateLauncherHint() {
    global LauncherHint, DefaultHotkey, DefaultSearchHotkey
    if (LauncherHint = "")
        return
    LauncherHint.Text := HotkeyToText(GetSetting("hotkey", DefaultHotkey)) . " launch • ←/→ columns • ↑/↓ navigate • Enter run • Esc close"
}

OnLauncherLButtonDown(wParam, lParam, msg, hwnd) {
    global LauncherGui, LauncherTitleHeight
    if (LauncherGui = "" || hwnd != LauncherGui.Hwnd)
        return
    clickY := (lParam >> 16) & 0xFFFF
    if (clickY <= LauncherTitleHeight)
        PostMessage(0xA1, 2, 0, , "ahk_id " . hwnd)   ; WM_NCLBUTTONDOWN + HTCAPTION
}

HideLauncher() {
    global LauncherGui
    if (LauncherGui != "")
        LauncherGui.Hide()
}

MinimizeLauncher() {
    global LauncherGui
    if (LauncherGui != "")
        LauncherGui.Minimize()
}

ShowLauncherGui(searchMode := false) {
    global LauncherGui, SearchBox, CurrentCategory, LauncherWidth, LauncherHeight
    try {
        if (LauncherGui = "")
            CreateLauncherGui()

        RefreshLauncherData()

        MouseGetPos(&mouseX, &mouseY)
        xPos := mouseX + 20
        yPos := mouseY + 20
        if (xPos + LauncherWidth + 20 > A_ScreenWidth)
            xPos := A_ScreenWidth - LauncherWidth - 20
        if (yPos + LauncherHeight + 20 > A_ScreenHeight)
            yPos := A_ScreenHeight - LauncherHeight - 20

        try {
            if (WinGetMinMax("ahk_id " . LauncherGui.Hwnd) = -1)
                LauncherGui.Restore()
        }

        LauncherGui.Show("x" . xPos . " y" . yPos . " w" . LauncherWidth . " h" . LauncherHeight)
        WinActivate("ahk_id " . LauncherGui.Hwnd)
        ApplyOpacity(LauncherGui)
        RefreshLauncherResults()
        if (searchMode) {
            SearchBox.Value := ""
            SearchBox.Focus()
        } else {
            FocusResultsColumn()
        }
    } catch Error as err {
        MsgBox("Minou launcher error:`n" . err.Message, "Minou", "Icon!")
    }
}

; Reloads every entry and rebuilds the category list.
; keepCategory = true restores the previously selected category (used after edits).
RefreshLauncherData(keepCategory := false) {
    global CurrentEntries, CurrentCategory, AllSearchItems, CategoryListBox
    previousCategory := CurrentCategory
    CurrentEntries := BuildMenuEntries()
    AllSearchItems := CurrentEntries
    CurrentCategory := "All"

    if (CategoryListBox != "") {
        CategoryListBox.Delete()
        CategoryListBox.Add(["All"])
        categories := Map()
        for entry in CurrentEntries {
            categories[entry.category] := true
        }
        chosenIndex := 1
        position := 1
        for categoryName in categories {
            CategoryListBox.Add([categoryName])
            position += 1
            if (keepCategory && categoryName == previousCategory) {
                chosenIndex := position
                CurrentCategory := categoryName
            }
        }
        CategoryListBox.Choose(chosenIndex)
    }
}

OnCategoryChange(*) {
    global CategoryListBox, CurrentCategory
    if (CategoryListBox.Value > 0) {
        CurrentCategory := CategoryListBox.Text
        RefreshLauncherResults()
    }
}

RefreshLauncherResults() {
    global SearchBox, CategoryListBox, ResultsListView, CurrentEntries, CurrentCategory, VisibleEntries, IsRefreshingLauncher
    if (IsRefreshingLauncher)
        return

    IsRefreshingLauncher := true
    try {
        query := Trim(SearchBox.Value)
        ResultsListView.Delete()
        VisibleEntries := Array()

        if (CurrentCategory != "All") {
            ResultsListView.ModifyCol(2, 140, "Subcategory")
        } else {
            ResultsListView.ModifyCol(2, 140, "Category")
        }

        for entry in CurrentEntries {
            matchesCategory := (CurrentCategory = "All" || entry.category = CurrentCategory)
            matchesQuery := (query = "" 
                || InStr(entry.name, query, false) 
                || InStr(entry.category, query, false)
                || (entry.HasOwnProp("subcategory") && InStr(entry.subcategory, query, false)))
            if (matchesCategory && matchesQuery) {
                VisibleEntries.Push(entry)
                secondCol := (CurrentCategory != "All" && entry.HasOwnProp("subcategory") && entry.subcategory != "") ? entry.subcategory : entry.category
                ResultsListView.Add("", entry.name, secondCol)
            }
        }

        if (VisibleEntries.Length > 0) {
            ResultsListView.Modify(0, "-Select -Focus")
            ResultsListView.Modify(1, "Select Focus Vis")
        }
    } finally {
        IsRefreshingLauncher := false
    }
}

; Owner-draw CategoryListBox to render each section item in its distinct color.
OnLauncherDrawItem(wParam, lParam, msg, hwnd) {
    global LauncherGui, CategoryListBox
    if (LauncherGui = "" || hwnd != LauncherGui.Hwnd)
        return
    if (NumGet(lParam, 0, "UInt") != 2) ; ODT_LISTBOX = 2
        return
    hwndItem := NumGet(lParam, 24, "UPtr")
    if (CategoryListBox = "" || hwndItem != CategoryListBox.Hwnd)
        return

    itemID := NumGet(lParam, 8, "Int")
    if (itemID < 0)
        return

    itemState := NumGet(lParam, 16, "UInt")
    hdc := NumGet(lParam, 32, "UPtr")
    rcLeft := NumGet(lParam, 40, "Int")
    rcTop := NumGet(lParam, 44, "Int")
    rcRight := NumGet(lParam, 48, "Int")
    rcBottom := NumGet(lParam, 52, "Int")

    textLen := SendMessage(0x018A, itemID, 0, hwndItem) ; LB_GETTEXTLEN
    text := ""
    if (textLen > 0) {
        buf := Buffer((textLen + 1) * 2, 0)
        SendMessage(0x0189, itemID, buf.Ptr, hwndItem) ; LB_GETTEXT
        text := StrGet(buf)
    }

    isSelected := (itemState & 1) != 0
    bgCol := isSelected ? 0x3E3E3E : 0x232323
    hBrush := DllCall("CreateSolidBrush", "UInt", bgCol, "Ptr")
    DllCall("FillRect", "Ptr", hdc, "Ptr", lParam + 40, "Ptr", hBrush)
    DllCall("DeleteObject", "Ptr", hBrush)

    txtCol := (text = "All") ? 0xE0E0E0 : GetSectionColor(text)
    DllCall("SetTextColor", "Ptr", hdc, "UInt", txtCol)
    DllCall("SetBkMode", "Ptr", hdc, "Int", 1) ; TRANSPARENT

    hFont := SendMessage(0x0031, 0, 0, hwndItem) ; WM_GETFONT
    oldFont := (hFont != 0) ? DllCall("SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr") : 0

    rcDraw := Buffer(16, 0)
    NumPut("Int", rcLeft + 8, rcDraw, 0)
    NumPut("Int", rcTop, rcDraw, 4)
    NumPut("Int", rcRight - 4, rcDraw, 8)
    NumPut("Int", rcBottom, rcDraw, 12)
    DllCall("DrawText", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", rcDraw.Ptr, "UInt", 0x0024)

    if (oldFont != 0)
        DllCall("SelectObject", "Ptr", hdc, "Ptr", oldFont)

    return 1
}

; Custom draw ResultsListView so Name and Category share the parent section's color.
OnResultsListViewCustomDraw(guiCtrl, lParam) {
    global VisibleEntries
    stage := NumGet(lParam, 24, "UInt")
    if (stage == 1) ; CDDS_PREPAINT
        return 0x20 ; CDRF_NOTIFYITEMDRAW
    if (stage == 0x10001) { ; CDDS_ITEMPREPAINT
        itemIdx := NumGet(lParam, 56, "UPtr") ; 0-based
        uItemState := NumGet(lParam, 64, "UInt")
        isSelected := (uItemState & 0x0001) != 0

        colorBGR := 0xE0E0E0
        if (itemIdx + 1 <= VisibleEntries.Length) {
            entry := VisibleEntries[itemIdx + 1]
            if (entry.HasOwnProp("category"))
                colorBGR := GetSectionColor(entry.category)
        }

        NumPut("UInt", colorBGR, lParam, 80) ; clrText
        NumPut("UInt", isSelected ? 0x3E3E3E : 0x232323, lParam, 84) ; clrTextBk
        return 0x20 ; CDRF_NOTIFYSUBITEMDRAW
    }
    if (stage == 0x30001) { ; CDDS_SUBITEMPREPAINT
        itemIdx := NumGet(lParam, 56, "UPtr") ; 0-based
        uItemState := NumGet(lParam, 64, "UInt")
        isSelected := (uItemState & 0x0001) != 0

        colorBGR := 0xE0E0E0
        if (itemIdx + 1 <= VisibleEntries.Length) {
            entry := VisibleEntries[itemIdx + 1]
            if (entry.HasOwnProp("category"))
                colorBGR := GetSectionColor(entry.category)
        }

        NumPut("UInt", colorBGR, lParam, 80) ; clrText
        NumPut("UInt", isSelected ? 0x3E3E3E : 0x232323, lParam, 84) ; clrTextBk
        return 0x02 ; CDRF_NEWFONT
    }
    return 0
}

FocusSectionColumn() {
    global CategoryListBox
    if (CategoryListBox != "") {
        CategoryListBox.Focus()
        if (CategoryListBox.Value = 0)
            CategoryListBox.Choose(1)
    }
}

FocusResultsColumn() {
    global ResultsListView
    if (ResultsListView != "") {
        ResultsListView.Focus()
        row := ResultsListView.GetNext(0)
        if (row = 0 && ResultsListView.GetCount() > 0) {
            ResultsListView.Modify(1, "Select Focus Vis")
        } else if (row > 0) {
            ResultsListView.Modify(row, "Select Focus Vis")
        }
    }
}

MoveCategorySelection(offset) {
    global CategoryListBox
    if (CategoryListBox = "")
        return
    curr := CategoryListBox.Value
    if (curr = 0)
        curr := 1
    newIdx := curr + offset
    cnt := SendMessage(0x018B, 0, 0, CategoryListBox.Hwnd) ; LB_GETCOUNT
    if (newIdx < 1)
        newIdx := 1
    if (newIdx > cnt)
        newIdx := cnt
    if (newIdx != curr) {
        CategoryListBox.Choose(newIdx)
        OnCategoryChange()
    }
}

MoveResultsSelection(offset) {
    global ResultsListView, SearchBox
    if (ResultsListView = "")
        return
    curr := ResultsListView.GetNext(0)
    if (curr = 0)
        curr := 1
    newIdx := curr + offset
    cnt := ResultsListView.GetCount()
    if (newIdx < 1) {
        if (SearchBox != "")
            SearchBox.Focus()
        return
    }
    if (newIdx > cnt)
        newIdx := cnt
    ResultsListView.Modify(0, "-Select -Focus")
    ResultsListView.Modify(newIdx, "Select Focus Vis")
}

MoveSelection(offset) => MoveResultsSelection(offset)

HandleLauncherUp() {
    global LauncherGui, CategoryListBox, ResultsListView, SearchBox
    if (LauncherGui = "")
        return
    focused := LauncherGui.FocusedCtrl
    if (focused == CategoryListBox) {
        MoveCategorySelection(-1)
    } else if (focused == ResultsListView) {
        MoveResultsSelection(-1)
    } else if (focused == SearchBox) {
        ; At top in search box
    } else {
        MoveResultsSelection(-1)
    }
}

HandleLauncherDown() {
    global LauncherGui, CategoryListBox, ResultsListView, SearchBox
    if (LauncherGui = "")
        return
    focused := LauncherGui.FocusedCtrl
    if (focused == CategoryListBox) {
        MoveCategorySelection(1)
    } else if (focused == SearchBox) {
        FocusResultsColumn()
    } else if (focused == ResultsListView) {
        MoveResultsSelection(1)
    } else {
        MoveResultsSelection(1)
    }
}

HandleLauncherEnter() {
    global LauncherGui, CategoryListBox
    if (LauncherGui != "" && LauncherGui.FocusedCtrl == CategoryListBox) {
        FocusResultsColumn()
    } else {
        RunSelectedEntry()
    }
}

RunSelectedEntry() {
    global ResultsListView, VisibleEntries, LauncherGui
    row := ResultsListView.GetNext(0)
    if (row = 0)
        return
    if (row <= VisibleEntries.Length) {
        entry := VisibleEntries[row]
        LauncherGui.Hide()
        LaunchItem(entry)
    }
}

IsLauncherActive() {
    global LauncherGui
    return LauncherGui != "" && WinActive("ahk_id " . LauncherGui.Hwnd)
}

ShouldHandleLauncherLeft() {
    global LauncherGui, SearchBox
    if (!IsLauncherActive())
        return false
    if (LauncherGui != "" && LauncherGui.FocusedCtrl == SearchBox && SearchBox.Value != "")
        return false
    return true
}

ShouldHandleLauncherRight() {
    global LauncherGui, SearchBox
    if (!IsLauncherActive())
        return false
    if (LauncherGui != "" && LauncherGui.FocusedCtrl == SearchBox && SearchBox.Value != "")
        return false
    return true
}

#HotIf IsLauncherActive()
Up::HandleLauncherUp()
Down::HandleLauncherDown()
Enter::HandleLauncherEnter()
#HotIf

#HotIf ShouldHandleLauncherLeft()
Left::FocusSectionColumn()
#HotIf

#HotIf ShouldHandleLauncherRight()
Right::FocusResultsColumn()
#HotIf
