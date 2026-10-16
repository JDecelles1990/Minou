# API and Helper Functions Reference

This document provides a comprehensive technical reference for every function, class, and subroutine across Minou's core script (`Minou.ahk`) and implemented modules (`Modules/`).

> **See also:**
> - [01-Architecture.md](01-Architecture.md) — system lifecycle, module dependency graph, and data flow
> - [02-Configuration.md](02-Configuration.md) — JSON schema details for all `Config/` files
> - [04-Roadmap.md](04-Roadmap.md) — planned functions for stub modules

---

## 1. Process Execution & System Dispatch (`Minou.ahk`)

### `SafeRun(target, args := "")`

Safely launches an executable, file, directory, or protocol URI. Centralizes all external process creation to allow consistent error handling and future WDAC bypass upgrades.

```ahk
SafeRun("calc.exe")
SafeRun("powershell.exe", "-NoExit -Command Get-Process")
SafeRun("https://github.com")
SafeRun("ms-settings:display")
SafeRun("%USERPROFILE%\\Desktop")
```

**Execution branches (in order):**

| Condition | Action |
| :--- | :--- |
| Target is `http://`, `https://`, `ms-settings:`, or `shell:` | `Run(target)` — direct protocol dispatch |
| `FileExist(target)` returns truthy | `Run(target)` — confirmed file path |
| Target contains `explorer.exe`, `cmd.exe`, `powershell.exe`, or `notepad.exe` | `Run(target . " " . args)` |
| All other cases | `Run(target . " " . args)` — best-effort |
| Any `Error` thrown | `ToolTip("Could not launch target.")` auto-cleared after 1500 ms |

**Pre-processing:** Always passes `target` through `ExpandEnvVars()` first.

> **Architecture note:** The planned WDAC bypass upgrade will replace `Run()` with:
> ```ahk
> ComObject("Shell.Application").ShellExecute(target, args, "", "open", 1)
> ```
> This delegates to `explorer.exe`, bypassing AHK's `RunWithHandles` policy block. See [01-Architecture.md § 7](01-Architecture.md).

---

### `ExpandEnvVars(path)`

Expands embedded environment variables and AutoHotkey script macros within a path string. Returns the expanded string.

```ahk
expanded := ExpandEnvVars("%USERPROFILE%\\Desktop")
; → "C:\Users\Jo\Desktop"

expanded := ExpandEnvVars("%A_ScriptDir%\\Config\\config.json")
; → "C:\LAB\AHK\Minou\Config\config.json"
```

**Supported tokens and their resolutions:**

| Token | Resolution Method | Example Output |
| :--- | :--- | :--- |
| `%A_ScriptDir%` | `A_ScriptDir` (built-in) | `C:\LAB\AHK\Minou` |
| `%TEMP%` | `EnvGet("TEMP")` | `C:\Users\Jo\AppData\Local\Temp` |
| `%USERPROFILE%` | `EnvGet("USERPROFILE")` | `C:\Users\Jo` |
| `%LOCALAPPDATA%` | `EnvGet("LOCALAPPDATA")` | `C:\Users\Jo\AppData\Local` |
| `%APPDATA%` | `EnvGet("APPDATA")` | `C:\Users\Jo\AppData\Roaming` |
| `%ProgramFiles%` | `EnvGet("ProgramFiles")` | `C:\Program Files` |

> **Order sensitivity:** `%LOCALAPPDATA%` is substituted before `%APPDATA%` to prevent the substring `APPDATA` inside `LOCALAPPDATA` from being replaced first, leaving a malformed path.

---

## 2. Item Dispatch & Dynamic Injection (`Minou.ahk`)

### `LaunchItem(entry)`

Routes a normalized entry object to the appropriate system action based on `entry.kind`. Called by `RunSelectedEntry()` in `Modules/Launcher.ahk`.

```ahk
LaunchItem(entry)   ; entry = { name, category, kind, target, hwnd? }
```

**Dispatch table:**

| `entry.kind` | Action | Notes |
| :--- | :--- | :--- |
| `"url"` | `SafeRun(entry.target)` | Opens URL in default browser |
| `"program"` | `FileExist()` → `SafeRun()` | Shows `"⚠ Not installed: <name>"` tooltip if file not found |
| `"folder"` | `SafeRun("explorer.exe", entry.target)` | Opens folder in Windows Explorer |
| `"snippet"` | `PasteText(entry.target)` | Token substitution + clipboard injection |
| `"prompt"` | `A_Clipboard := entry.target` | Copies to clipboard; tooltip shown for 1500 ms |
| `"utility"` | `SafeRun(entry.target)` | Dispatches `cmd` string (exe or `send:` keystroke) |
| `"setting"` | `SafeRun(entry.target)` | Opens `ms-settings:` URI |
| `"script"` | `WinActivate("ahk_id " . entry.hwnd)` | Brings running AHK script window to foreground |

> The `"program"` branch uniquely uses `FileExist()` to validate the path before attempting launch — the only kind that performs pre-launch validation.

---

### `PasteText(txt)`

Replaces dynamic tokens in text and injects it into the currently active application without permanently overwriting the user's clipboard.

```ahk
PasteText("Created on {DATE} at {TIME}{ENTER}Clipboard was: {CLIPBOARD}")
```

**Processing pipeline:**

| Step | Code | Description |
| :--- | :--- | :--- |
| 1 | `StrReplace(txt, "{DATE}", FormatTime(, "yyyy-MM-dd"))` | Date substitution |
| 2 | `StrReplace(..., "{TIME}", FormatTime(, "HH:mm:ss"))` | Time substitution |
| 3 | `StrReplace(..., "{CLIPBOARD}", A_Clipboard)` | Captures clipboard at call time |
| 4 | `StrReplace(..., "{ENTER}", "`n")` | Newline substitution |
| 5 | `oldClip := A_Clipboard` | Back up existing clipboard |
| 6 | `A_Clipboard := formattedTxt` | Load snippet into clipboard |
| 7 | `ClipWait(1)` | Wait up to 1 s for clipboard readiness |
| 8 | `Send("^v")` | Paste into active window |
| 9 | `SetTimer((*) => (A_Clipboard := oldClip), -1000)` | Restore original clipboard after 1 s |

> **Design:** `ClipWait(1)` guards against race conditions on slow systems. The one-shot `SetTimer` (negative interval = fire once) ensures the user's clipboard is restored asynchronously after the paste completes.

For planned additional tokens, see [04-Roadmap.md § Milestone 3](04-Roadmap.md) and [02-Configuration.md § Snippet Tokens](02-Configuration.md).

---

## 3. Lifecycle Management (`Minou.ahk`)

### `InitMinou()`

Master boot function. Called once at script start. Executes in deterministic order:
1. `SetMenuDarkMode()`
2. `LoadConfiguration()`
3. `CreateLauncherGui()`
4. `RegisterHotkeys()`
5. `SetupTrayMenu()`

For the complete boot sequence diagram, see [01-Architecture.md § 3](01-Architecture.md).

---

### `SetMenuDarkMode()`

Applies system-wide ForceDark mode for Win32 menus and dialogues via undocumented `uxtheme.dll` ordinals:

```ahk
uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
if (!uxtheme)
    uxtheme := DllCall("LoadLibrary", "str", "uxtheme", "ptr")
SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
DllCall(SetPreferredAppMode, "int", 2)   ; 2 = ForceDark
FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
DllCall(FlushMenuThemes)
```

- Entire block is in `try/catch` — safe to call on any Windows build
- `LoadLibrary` fallback ensures `uxtheme.dll` is loaded even if not yet in process

---

### `LoadConfiguration()`

Reads all six JSON config files into global memory, extracts sub-arrays, and activates hotstrings:

```ahk
ConfigData    := LoadJsonFile(ConfigFile,    Map())
SettingsData  := LoadJsonFile(SettingsFile,  Map())
UrlData       := LoadJsonFile(UrlsFile,      Map())
SnippetData   := LoadJsonFile(SnippetsFile,  Map())
PromptData    := LoadJsonFile(PromptsFile,   Array())
HotstringData := LoadJsonFile(HotstringFile, Array())
RegisterHotstrings()          ; activate hotstrings immediately

ProgramData := ConfigData["programs"]
FolderData  := ConfigData["folders"]
UtilityData := ConfigData["utilities"]
```

For full config schema details, see [02-Configuration.md](02-Configuration.md).

---

### `RegisterHotkeys()`

Binds F3 and Shift+F3 (or values from `SettingsData`) to launcher show functions:

```ahk
Hotkey(hotkeyMain,   (*) => ShowLauncherGui(false))
Hotkey(hotkeySearch, (*) => ShowLauncherGui(true))
```

Falls back to `"F3"` and `"+F3"` if keys are absent or empty in `SettingsData`.

---

### `SetupTrayMenu()`

Deletes the default AHK tray menu and rebuilds with Minou-specific items. For the complete menu item list, see [01-Architecture.md § 3, Step 5](01-Architecture.md).

---

## 4. UI & Lifecycle Management (`Modules/Launcher.ahk`)

### `CreateLauncherGui()`

Builds the dark Fluent GUI window once. If called when `LauncherGui` already exists, destroys and recreates it.

**Window style:** `+AlwaysOnTop +ToolWindow -Caption` — borderless, always on top, excluded from taskbar and Alt+Tab.

**Controls added in order:**

| Control | Variable | Position | Size | Style |
| :--- | :--- | :--- | :--- | :--- |
| `Text` (title) | — | x12 y10 | w560 | `cC0C0C0` |
| `Edit` (search) | `SearchBox` | x12 y34 | w560 h28 | `Background0x232323 cWhite` |
| `ListBox` (categories) | `CategoryListBox` | x12 y72 | w170 h280 | `Background0x232323 cWhite` |
| `ListView` (results) | `ResultsListView` | x190 y72 | w382 h280 | `Background0x232323 cWhite Grid` |
| `Text` (footer) | — | x12 y360 | w560 | `c808080` |
| `Button` (hotstrings) | — | x480 y355 | w90 h24 | — |

**Event bindings:**

| Event | Control | Handler |
| :--- | :--- | :--- |
| `Change` | `SearchBox` | `RefreshLauncherResults()` |
| `Change` | `CategoryListBox` | `OnCategoryChange()` |
| `DoubleClick` | `ResultsListView` | `RunSelectedEntry()` |
| `Close` | `LauncherGui` | `LauncherGui.Hide()` |
| `Escape` | `LauncherGui` | `LauncherGui.Hide()` |
| `Click` | Hotstrings `Button` | `ShowHotstringManager()` |

---

### `ShowLauncherGui(searchMode := false)`

Called by hotkeys and tray menu. Shows the launcher next to the cursor.

```ahk
ShowLauncherGui(false)   ; Normal mode — keep existing search text
ShowLauncherGui(true)    ; Search mode — clear & focus search box
```

**Flow:**
1. Create GUI if `LauncherGui = ""`
2. `RefreshLauncherData()` — rebuild entries from current config
3. `MouseGetPos(&mouseX, &mouseY)` — screen-relative coordinates
4. Calculate position with `+20` offset, clamp to screen boundaries
5. `LauncherGui.Show("x... y... w580 h390")`
6. If `searchMode`: `SearchBox.Value := ""` + `SearchBox.Focus()`
7. `RefreshLauncherResults()` — populate immediately

For position clamping formulas, see [01-Architecture.md § 6](01-Architecture.md).

---

### `RefreshLauncherData()`

Called every time the launcher is shown. Rebuilds the full entry list and repopulates the category list:

```ahk
CurrentEntries := BuildMenuEntries()    ; fresh data from all sources
AllSearchItems := CurrentEntries        ; cached full catalogue
CurrentCategory := "All"               ; reset filter
CategoryListBox.Delete()
CategoryListBox.Add(["All"])
; extract unique categories from CurrentEntries
CategoryListBox.Choose(1)              ; select "All"
```

---

### `RefreshLauncherResults()`

Core real-time filtering function. Runs on every `SearchBox` change and every category change.

**Guard:** Uses `IsRefreshingLauncher` boolean inside `try/finally` to prevent re-entrant calls (e.g., when a category change triggers a search change event).

**Filtering logic:**
```ahk
for entry in CurrentEntries {
    matchesCategory := (CurrentCategory = "All" || entry.category = CurrentCategory)
    matchesQuery    := (query = "" || InStr(entry.name, query, false)
                                  || InStr(entry.category, query, false))
    if (matchesCategory && matchesQuery) {
        VisibleEntries.Push(entry)
        ResultsListView.Add("", entry.name, entry.category)
    }
}
```

- Search is **case-insensitive** (third param of `InStr` = `false`)
- Matches `entry.name` OR `entry.category` — typing "Prompt" shows all prompt entries
- Automatically selects first result: `ResultsListView.Modify(1, "Select")`

> **Critical:** `VisibleEntries` is rebuilt from scratch on every call. Row `N` in the ListView always maps to `VisibleEntries[N]` — never to `CurrentEntries[N]`.

---

### `OnCategoryChange(*)`

Event handler for `CategoryListBox` changes. Reads `CategoryListBox.Text` into `CurrentCategory` and calls `RefreshLauncherResults()`.

---

### `MoveSelection(offset)`

Keyboard navigation. Moves the ListView selection by `offset` rows (`+1` = Down, `-1` = Up), clamped to `[1, GetCount()]`.

```ahk
MoveSelection(-1)   ; Up arrow
MoveSelection(1)    ; Down arrow
```

---

### `RunSelectedEntry()`

Executes the currently highlighted ListView row:
1. `row := ResultsListView.GetNext(0)` — get selected row index (0 = none)
2. `entry := VisibleEntries[row]` — **must** use `VisibleEntries`, not `CurrentEntries`
3. `LauncherGui.Hide()` — dismiss popup before launching
4. `LaunchItem(entry)` — dispatch to appropriate handler

---

### `IsLauncherActive() → Boolean`

`#HotIf` context predicate. Returns `true` only when the launcher window exists and is the active foreground window.

```ahk
return LauncherGui != "" && WinActive("ahk_id " . LauncherGui.Hwnd)
```

**Context-sensitive hotkeys using this predicate:**
```ahk
#HotIf IsLauncherActive()
Up::MoveSelection(-1)
Down::MoveSelection(1)
Enter::RunSelectedEntry()
#HotIf
```

---

## 5. Menu Entry Builder (`Modules/MenuBuilder.ahk`)

### `BuildMenuEntries() → Array`

Aggregates all data sources into a single flat array of normalized entry objects. Called by `RefreshLauncherData()` each time the launcher is shown.

**Processing order — 8 passes:**

| Pass | Source Global | Category | `kind` |
| :--- | :--- | :--- | :--- |
| 1 | `UrlData` (Map) | JSON key name | `"url"` |
| 2 | `ProgramData` (Array) | `"Programs"` | `"program"` |
| 3 | `FolderData` (Array) | `"Folders"` | `"folder"` |
| 4 | `SnippetData` (Map) | JSON key name | `"snippet"` |
| 5 | `PromptData` (Array) | `"Prompts"` | `"prompt"` |
| 6 | `UtilityData` (Array) | `"Utilities"` | `"utility"` |
| 7 | Hardcoded `ms-settings:` URIs | `"Windows Settings"` | `"setting"` |
| 8 | `WinGetList("ahk_class AutoHotkey")` | `"Running Scripts"` | `"script"` |

**Hardcoded Windows Settings entries (Pass 7):**

```ahk
entries.Push({ name: "Display",        category: "Windows Settings", kind: "setting", target: "ms-settings:display" })
entries.Push({ name: "Bluetooth",      category: "Windows Settings", kind: "setting", target: "ms-settings:bluetooth" })
entries.Push({ name: "Windows Update", category: "Windows Settings", kind: "setting", target: "ms-settings:windowsupdate" })
entries.Push({ name: "Storage",        category: "Windows Settings", kind: "setting", target: "ms-settings:storage" })
entries.Push({ name: "Clipboard",      category: "Windows Settings", kind: "setting", target: "ms-settings:clipboard" })
entries.Push({ name: "Developer Mode", category: "Windows Settings", kind: "setting", target: "ms-settings:developers" })
```

**Running scripts detection (Pass 8):**

```ahk
DetectHiddenWindows(true)
for hwnd in WinGetList("ahk_class AutoHotkey") {
    if (hwnd != A_ScriptHwnd) {
        title := WinGetTitle("ahk_id " . hwnd)
        if (title != "")
            entries.Push({ name: title, category: "Running Scripts", kind: "script", hwnd: hwnd })
    }
}
```

**Dual Map/Object access pattern:**

Each item property is read with a compatibility guard to handle both `Map` objects (from JSON) and AHK `Object` instances (from inline object literals):

```ahk
name := item is Map ? item["name"] : item.name
path := item is Map ? item["path"] : item.path
```

**Folder path expansion:**

`FolderData` entries run through `ExpandEnvVars()` at build time:
```ahk
entries.Push({ name: name, category: "Folders", kind: "folder", target: ExpandEnvVars(path) })
```

---

## 6. JSON Serialization Engine (`Modules/Json.ahk`)

### `ParseJson(text) → Any`

Top-level entry point. Creates a `JsonParser` instance, calls `ParseValue()`, verifies no trailing data, and returns the parsed AHK value.

```ahk
data := ParseJson('{"name": "Minou", "version": 2}')
; → Map: data["name"] = "Minou", data["version"] = 2

items := ParseJson('[1, "two", true, null]')
; → Array: items[1] = 1, items[2] = "two", items[3] = true, items[4] = ""
```

**Throws** `Error("Unexpected trailing JSON data")` if the input contains extra content after the parsed value.

---

### `class JsonParser`

Pure AHK v2 recursive-descent JSON parser. Uses a position cursor (`PositionValue`, 1-indexed).

#### `__New(text)`

Constructor. Stores the source string and initializes `PositionValue := 1`.

#### `SkipWhitespace()`

Advances the cursor past ` `, `\n`, `\r`, `\t` characters in a `while` loop.

#### `ParseValue() → Any`

Main dispatch method. Reads the character at the current position (after skipping whitespace) and delegates:

| Char | Method | Return Type |
| :--- | :--- | :--- |
| `{` | `ParseObject()` | `Map` |
| `[` | `ParseArray()` | `Array` |
| `"` | `ParseString()` | `String` |
| `t` | `ParseLiteral("true", true)` | `true` (integer 1) |
| `f` | `ParseLiteral("false", false)` | `false` (integer 0) |
| `n` | `ParseLiteral("null", "")` | `""` (empty string) |
| `0-9`, `-` | `ParseNumber()` | `Integer` or `Float` |

#### `ParseObject() → Map`

Parses `{ "key": value, ... }`. Creates an AHK `Map()`. For each key-value pair:
- Calls `ParseString()` for the key
- Expects and consumes `:`
- Calls `ParseValue()` for the value
- Expects `,` (continue) or `}` (end)

Throws descriptive errors on: missing `:`, missing `}`, unexpected end of input.

#### `ParseArray() → Array`

Parses `[ value, ... ]`. Creates an AHK `Array()`. For each element:
- Calls `ParseValue()`
- Expects `,` (continue) or `]` (end)

#### `ParseString() → String`

Parses a `"..."` string with full escape sequence support:

| JSON Escape | AHK Char | Notes |
| :--- | :--- | :--- |
| `\"` | `"` | Double quote |
| `\\` | `\` | Backslash |
| `\/` | `/` | Forward slash |
| `\b` | `` `b `` | Backspace |
| `\f` | `` `f `` | Form feed |
| `\n` | `` `n `` | Newline (LF) |
| `\r` | `` `r `` | Carriage return |
| `\t` | `` `t `` | Tab |
| `\uXXXX` | `Chr(Integer("0x" . hex))` | Full Unicode code point |

Throws on: unterminated string, invalid escape sequence, invalid `\u` sequence.

#### `ParseNumber() → Integer | Float`

Reads characters `[0-9.\-+eE]` until a non-numeric character, then calls `Number(textValue)` to convert. Throws `Error("Invalid number")` if the extracted substring is empty.

#### `ParseLiteral(literal, value) → Any`

Verifies the next `StrLen(literal)` characters match `literal`, advances the cursor, and returns `value`. Used for `true`, `false`, and `null`.

---

### `StringifyJson(value, indent := "    ", level := 0) → String`

Recursive serializer. Converts AHK `Map`, `Array`, `String`, `Integer`, `Float`, and `Boolean` values back into formatted JSON:

```ahk
json := StringifyJson(Map("name", "test", "count", 3))
; → '{\n    "name": "test",\n    "count": 3\n}'

json := StringifyJson(["a", "b", "c"])
; → '[\n    "a",\n    "b",\n    "c"\n]'
```

**Type dispatch:**

| AHK Type | JSON Output |
| :--- | :--- |
| `Map` (empty) | `{}` |
| `Map` (non-empty) | `{ "key": value, ... }` indented |
| `Array` (empty) | `[]` |
| `Array` (non-empty) | `[ value, ... ]` indented |
| `String` | `QuoteJson(value)` — escaped and quoted |
| `true` | `true` |
| `false` | `false` |
| `""` (empty string) | `""` |
| Number | Raw number string |

---

### `QuoteJson(value) → String`

Applies JSON-safe string escaping in this mandatory order:

```ahk
escaped := StrReplace(value,   "\",   "\\")   ; 1. backslash — must be first
escaped := StrReplace(escaped, '"',   '\"')   ; 2. double-quote
escaped := StrReplace(escaped, "`n",  "\n")   ; 3. LF
escaped := StrReplace(escaped, "`r",  "\r")   ; 4. CR
escaped := StrReplace(escaped, "`t",  "\t")   ; 5. tab
return '"' . escaped . '"'
```

> **Order note:** Backslash must be escaped first; otherwise, subsequently added `\n`, `\r`, `\t` sequences would get their `\` double-escaped.

---

### `LoadJsonFile(path, defaultValue := "") → Any`

Safe file loader for config files:

```ahk
data := LoadJsonFile("Config/settings.json", Map())
; Returns Map() if file missing or JSON invalid
```

**Flow:**
1. `FileExist(path)` — returns `defaultValue` immediately if file missing
2. `FileRead(path, "UTF-8")` — reads with explicit encoding
3. `ParseJson(content)` — parses
4. On any `Error` — returns `defaultValue` silently

---

### `SaveJsonFile(path, value)`

Serializes and writes to disk:

```ahk
SaveJsonFile("Config/hotstrings.json", HotstringData)
```

```ahk
fileObj := FileOpen(path, "w", "UTF-8")
fileObj.Write(StringifyJson(value))
fileObj.Close()
```

> Always uses `FileOpen` + `.Write()` + `.Close()` — not the non-existent `FileWrite()` function.

---

### Helper Functions

#### `FormatInteger(hex) → Integer`

Converts a 4-char hex string to an integer for Unicode escape processing:
```ahk
FormatInteger("0041") → 65   ; → Chr(65) = "A"
```

#### `Join(items, separator) → String`

Joins an `Array` of strings with a separator (used by `StringifyJson`):
```ahk
Join(["a", "b", "c"], ", ") → "a, b, c"
```

#### `StrRepeat(text, count) → String`

Repeats a string `count` times (used for JSON indentation):
```ahk
StrRepeat("    ", 2) → "        "   ; 8 spaces
```

---

## 7. Hotstring Manager (`Modules/Hotstrings.ahk`)

### `ShowHotstringManager(*)`

Opens (or reopens) the Hotstring Manager GUI window:

- Window: `+AlwaysOnTop +Resize`, `0x1A1A1A` background, Segoe UI
- `ListView` with `Checked -Multi Grid` options: *Trigger* (140 px) + *Replacement* (340 px)
  - `Checked` = checkbox per row for enable/disable
  - `-Multi` = single-row selection only
- Buttons: ✚ Add, ✏ Edit, 🗑 Delete, 💾 Save
- Calls `PopulateHotstringListView()` to fill from `HotstringData`

---

### `PopulateHotstringListView()`

Clears and rebuilds the ListView from current `HotstringData`:

```ahk
for index, hs in HotstringData {
    opts := hs["active"] ? "Check" : ""
    HotstringListView.Add(opts, hs["trigger"], hs["replacement"])
}
```

---

### `ShowEditDialog(triggerVal, replacementVal, isEditing, targetRow)`

Shared Add/Edit modal dialog (`+AlwaysOnTop +ToolWindow`):
- Edit controls for trigger and replacement (pre-filled when editing)
- OK button with nested `OnOk()` closure that captures all dialog state
- Validation: trigger and replacement must both be non-empty strings
- If `isEditing`: `HotstringListView.Modify(targetRow, "", newTrigger, newReplacement)`
- If adding: `HotstringListView.Add("Check", newTrigger, newReplacement)` — new entries default to active

---

### `DeleteSelectedHotstring()`

Gets the selected row, asks for Yes/No confirmation via `MsgBox(..., 4 + 48)`, deletes the row on `"Yes"`.

---

### `SaveAllHotstrings()`

The complete save pipeline:

```ahk
; Step 1: Read all rows from ListView
loop totalRows {
    trigger     := HotstringListView.GetText(A_Index, 1)
    replacement := HotstringListView.GetText(A_Index, 2)
    newData.Push(Map("active", false, "trigger", trigger, "replacement", replacement))
}

; Step 2: Set active=true for checked rows
loop {
    checkedRow := HotstringListView.GetNext(checkedRow, "Checked")
    if (!checkedRow) break
    newData[checkedRow]["active"] := true
}

; Step 3: Update memory and persist
HotstringData := newData
SaveJsonFile(HotstringFile, HotstringData)

; Step 4: Re-register with AHK engine
ApplyHotstrings()
```

---

### `ApplyHotstrings()`

Two-phase hotstring registration:

**Phase 1 — Disable previously registered triggers:**
```ahk
for index, oldTrigger in RegisteredHotstrings {
    try Hotstring("::" . oldTrigger,, "Off")   ; omit replacement to disable
}
RegisteredHotstrings := Array()
```

**Phase 2 — Register active triggers:**
```ahk
for index, hs in HotstringData {
    if (hs["active"]) {
        Hotstring("::" . hs["trigger"], hs["replacement"])
        RegisteredHotstrings.Push(hs["trigger"])
    }
}
```

Errors during registration are shown as `MsgBox` (non-silent) since a misconfigured trigger needs correction.

---

### `RegisterHotstrings()`

Thin startup alias — calls `ApplyHotstrings()`. Called from `LoadConfiguration()` so hotstrings are active immediately at boot without duplicating logic.

---

### `CloseHotstringManager()`

Safely destroys the Hotstring Manager window and clears `HotstringGui := ""`. Handles `Close` and `Escape` events from the GUI.

---

### `AddHotstringDialog()`

Thin wrapper that calls `ShowEditDialog("", "", false, 0)` — empty values, `isEditing = false`.

---

### `EditSelectedHotstring()`

Gets the selected row from `HotstringListView`, reads its text values, and calls `ShowEditDialog(trigger, replacement, true, row)`.

---

## 8. Stub Modules (Planned API Surfaces)

These modules are empty files reserved for future implementation. Their planned public API is documented here to guide development. See [04-Roadmap.md](04-Roadmap.md) for milestones.

### `Modules/Search.ahk` (Planned)

```ahk
; FuzzySearch(query, items) → Array of scored entries
; ScoreEntry(query, entry) → Integer (higher = better match)
```

### `Modules/Icons.ahk` (Planned)

```ahk
; GetIcon(entry) → HICON handle or image path string
; ExtractExeIcon(path) → HICON
; FetchFavicon(url) → file path in Cache/
```

### `Modules/Settings.ahk` (Planned)

```ahk
; ShowSettingsGui() → void
; SaveSettings(newSettings) → void   ; calls SaveJsonFile + RegisterHotkeys()
```

### `Modules/WindowManager.ahk` (Planned)

```ahk
; GetMonitorForPoint(x, y) → Integer     ; monitor index containing the point
; ClampToMonitorWorkArea(x, y, w, h) → {x, y}
```

### `Modules/Snippets.ahk` (Planned)

```ahk
; ExpandTokens(txt) → String   ; extended PasteText with {Selection}, {ComputerName}, etc.
```

### `Modules/Prompts.ahk` (Planned)

```ahk
; LoadPromptsFromDir(dir) → Array    ; reads *.md files from Prompts/ directory
; GetPromptPreview(entry) → String   ; returns first 300 chars of prompt
```

---

## 9. AHK Script IPC (Planned)

Minou can detect and remotely control other running AutoHotkey scripts using Windows `WM_COMMAND` messages. This is planned for the Running Scripts category actions.

```ahk
ControlSingleScript(hwnd, action)
ControlAllAHKScripts(action)
```

| Action | WM_COMMAND ID | Code |
| :--- | :--- | :--- |
| Reload | 65303 | `PostMessage(0x0111, 65303, 0,, "ahk_id " . hwnd)` |
| Suspend | 65305 | `PostMessage(0x0111, 65305, 0,, "ahk_id " . hwnd)` |
| Kill | N/A | `WinKill("ahk_id " . hwnd)` |

---

## 10. Utilities Engine (`Modules/Utilities.ahk`) ✅

`Modules/Utilities.ahk` provides a native suite of encoders, formatters, diagnostic helpers, and environment tools callable via `LaunchItem()` or direct function invocation.

### Dispatcher

#### `DispatchInternalUtility(fnName)`
Routes utility string triggers (from `Config/utilities.json` entries with `"action": "internal"`) to their respective functions.

---

### Encoders & Generators

#### `GenerateGuid() → String`
Generates a compliant UUID v4 string via native COM `ole32\CoCreateGuid`, copies to `A_Clipboard`, and shows non-intrusive feedback.

#### `GenerateUnixTimestamp() → Integer`
Calculates seconds since Unix epoch (`1970-01-01 00:00:00 UTC`) via `DateDiff()`, copies to `A_Clipboard`, and returns value.

#### `UrlEncode(str) → String` / `UrlDecode(str) → String`
Converts arbitrary strings into RFC-3986 percent-encoded URL strings via UTF-8 memory buffer, and reverses percent sequences. `UrlEncodeClipboard()` and `UrlDecodeClipboard()` apply directly to `A_Clipboard`.

#### `Base64Encode(str) → String` / `Base64Decode(str) → String`
Encodes/decodes UTF-8 strings into Base64 using Windows Crypto API (`Crypt32.dll\CryptBinaryToStringW` and `CryptStringToBinaryW`). `Base64EncodeClipboard()` and `Base64DecodeClipboard()` operate on `A_Clipboard`.

#### `GenerateSha256Clipboard()`
Calculates SHA-256 hash of clipboard contents via Windows CNG / PowerShell cryptography provider and places lowercase hexadecimal hash on `A_Clipboard`.

---

### Code & Data Formatting

#### `BeautifyClipboardJson()`
Parses JSON from `A_Clipboard` using `Modules/Json.ahk` and rewrites it with clean 4-space indentation.

#### `MinifyClipboardJson()`
Parses JSON from `A_Clipboard` and serializes it without whitespace (`indent := 0`) for compact transmission.

#### `EscapeClipboardString()`
Escapes backslashes, quotation marks, and line breaks so multiline strings can be safely pasted into code literals.

#### `CapitalizeSqlKeywords()`
Case-insensitively finds SQL keywords (`SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, etc.) and formats them in uppercase.

---

### Git & Explorer Integration

#### `GetActiveExplorerPath() → String`
Queries the active Windows Explorer window via `Shell.Application` COM and retrieves the current filesystem folder path.

#### `OpenTerminalAtActiveExplorer()`
Launches Windows Terminal (`wt.exe -d "<path>"`) targeting the active Explorer directory.

#### `GitStatusAtActiveExplorer()`
Runs `git.exe status -sb` in the active Explorer folder and displays a summary.

#### `InspectPathEnvironment()`
Splits system and user `%PATH%` by `;`, checks existence with `DirExist()`, copies the report to clipboard, and displays an inspector dialog.

#### `ToggleExplorerHiddenAndExt()`
Toggles `Hidden` files and `HideFileExt` in `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` and broadcasts shell refresh messages.

---

### Network & SysAdmin Diagnostics

#### `FlushDns()`
Runs `ipconfig /flushdns` in a hidden process and confirms via tooltip.

#### `PingGatewayAndDns()`
Runs parallel ICMP test to `1.1.1.1` and `8.8.8.8` via PowerShell and copies latency measurements to clipboard.

#### `GetIpSummary()`
Retrieves local adapter IPv4 via `A_IPAddress1` and queries public IP via `api.ipify.org` using `WinHttp.WinHttpRequest.5.1`.

#### `ShowListeningPorts()`
Runs `netstat -ano -p tcp` filtered to `LISTENING`, copies the full output to clipboard, and displays a formatted preview.

#### `InspectDevPorts()`
Checks common local web development ports (`:3000`, `:5000`, `:8000`, `:8080`, `:5173`) to identify active listeners and PIDs.

#### `RestartExplorer()`
Silently terminates and relaunches `explorer.exe` to recover frozen shell and taskbar instances.

#### `PurgeTempFiles()`
Safely purges unpinned files and directories from `%TEMP%` without throwing on locked process handles.

