global VisibleEntries := Array()
global IsRefreshingLauncher := false

CreateLauncherGui() {
    global LauncherGui, SearchBox, CategoryListBox, ResultsListView

    if (LauncherGui != "") {
        LauncherGui.Destroy()
    }

    LauncherGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
    LauncherGui.BackColor := "0x1A1A1A"
    LauncherGui.SetFont("s10 cD0D0D0", "Segoe UI")

    LauncherGui.Add("Text", "x12 y10 w560 cC0C0C0", "Minou Launcher")
    SearchBox := LauncherGui.Add("Edit", "x12 y34 w560 h28 Background0x232323 cWhite")
    SearchBox.OnEvent("Change", (*) => RefreshLauncherResults())

    CategoryListBox := LauncherGui.Add("ListBox", "x12 y72 w170 h280 Background0x232323 cWhite")
    CategoryListBox.OnEvent("Change", OnCategoryChange)

    ResultsListView := LauncherGui.Add("ListView", "x190 y72 w382 h280 Background0x232323 cWhite Grid", ["Name", "Category"])
    ResultsListView.ModifyCol(1, 220)
    ResultsListView.ModifyCol(2, 140)
    ResultsListView.OnEvent("DoubleClick", (*) => RunSelectedEntry())

    LauncherGui.Add("Text", "x12 y360 w560 c808080", "F3 launch • Shift+F3 search • Enter run • Esc close")

    BtnHotstrings := LauncherGui.Add("Button", "x480 y355 w90 h24", "Hotstrings")
    BtnHotstrings.OnEvent("Click", (*) => ShowHotstringManager())

    LauncherGui.OnEvent("Close", (*) => LauncherGui.Hide())
    LauncherGui.OnEvent("Escape", (*) => LauncherGui.Hide())
}

ShowLauncherGui(searchMode := false) {
    global LauncherGui, SearchBox, CurrentCategory
    try {
        if (LauncherGui = "")
            CreateLauncherGui()

        RefreshLauncherData()

        MouseGetPos(&mouseX, &mouseY)
        xPos := mouseX + 20
        yPos := mouseY + 20
        if (xPos + 600 > A_ScreenWidth)
            xPos := A_ScreenWidth - 620
        if (yPos + 400 > A_ScreenHeight)
            yPos := A_ScreenHeight - 420

        LauncherGui.Show("x" . xPos . " y" . yPos . " w580 h390")
        if (searchMode) {
            SearchBox.Value := ""
            SearchBox.Focus()
        }
        RefreshLauncherResults()
    } catch Error as err {
        MsgBox("Minou launcher error:`n" . err.Message, "Minou", "Icon!")
    }
}

RefreshLauncherData() {
    global CurrentEntries, CurrentCategory, AllSearchItems, CategoryListBox
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
        for categoryName in categories {
            CategoryListBox.Add([categoryName])
        }
        CategoryListBox.Choose(1)
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
            ResultsListView.Modify(1, "Select")
        }
    } finally {
        IsRefreshingLauncher := false
    }
}

MoveSelection(offset) {
    global ResultsListView
    current := ResultsListView.GetNext(0)
    if (current = 0)
        current := 1
    newIndex := current + offset
    if (newIndex < 1)
        newIndex := 1
    if (newIndex > ResultsListView.GetCount())
        newIndex := ResultsListView.GetCount()
    ResultsListView.Modify(newIndex, "Select")
}

RunSelectedEntry() {
    global ResultsListView, VisibleEntries
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

#HotIf IsLauncherActive()
Up::MoveSelection(-1)
Down::MoveSelection(1)
Enter::RunSelectedEntry()
#HotIf
