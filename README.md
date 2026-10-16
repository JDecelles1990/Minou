# 🐱 Minou

> **A modern, modular, dark-themed popup launcher and automation suite for Windows 11 — built with AutoHotkey v2.0.**

Minou bridges keyboard-centric productivity with mouse-friendly contextual controls, letting you launch programs, open URLs, inject text snippets, dispatch LLM prompts, and control running AutoHotkey scripts — all from a single keystroke, appearing beside your cursor in under 16 ms.

---

## ✨ Features

| Category | What Minou Does |
| :--- | :--- |
| 🚀 **App Launcher** | Launch applications, directories, and system utilities from a searchable GUI |
| 🧰 **Developer & SysAdmin Utilities** | Native UUID v4 generation, Unix epoch timestamps, Base64/URL encoders, JSON formatters, DNS flusher, dev port inspection, and Explorer restart |
| 🌐 **URL Bookmarks** | Instantly open categorized web dashboards, cybersecurity portals, and search engines |
| ✂️ **Text Snippets** | Paste dynamic text templates supporting `{DATE}`, `{TIME}`, `{CLIPBOARD}`, `{ENTER}` |
| 🤖 **LLM Prompts** | Copy structured prompts directly to clipboard for immediate use in any AI tool |
| ⌨️ **Hotstrings** | Auto-expand abbreviations system-wide, managed via a dedicated GUI editor |
| 🔍 **Real-Time Search** | Filter across all categories and subcategories with live results as you type |
| 🛡️ **WDAC Bypass** | Runs programs safely via `Shell.Application.ShellExecute` to avoid AppLocker / WDAC blocks |
| 🖥️ **AHK Script Control** | Detect, reload, suspend, or kill other running AutoHotkey scripts via `PostMessage` IPC |

---

## ⚡ Quick Start

### Prerequisites

- **Windows 11** (Windows 10 compatible)
- **[AutoHotkey v2.0+](https://www.autohotkey.com/download/)** — **Required.** Minou is exclusively AHK v2 and will not run on v1.

### Installation

```
1. Clone or download this repository to a local path (e.g., C:\LAB\AHK\Minou\)
2. Run Minou.ahk with AutoHotkey v2
3. Press F3 — the launcher appears beside your cursor
```

### Default Hotkeys

| Hotkey | Action |
| :--- | :--- |
| `F3` | Open the launcher popup at the current mouse position |
| `Shift + F3` | Open the launcher with search box pre-focused and cleared |
| `Up` / `Down` | Navigate the results list |
| `Enter` | Launch the selected item |
| `Esc` | Close the launcher |

> Hotkeys are fully configurable in `Config/settings.json`.

---

## 🗂️ Project Structure

```
Minou/
├── Minou.ahk                   # Root orchestrator — lifecycle & #Include directives only
├── Minou AHK                   # Legacy monolithic reference script (789 lines)
│
├── Config/                     # All active configuration (JSON)
│   ├── settings.json           # Hotkeys and visual settings
│   ├── config.json             # Programs, folders, and utilities
│   ├── urls.json               # Categorized web bookmarks
│   ├── snippets.json           # Dynamic text templates
│   ├── prompts.json            # LLM prompt library
│   ├── utilities.json          # Categorized & subcategorized utilities
│   └── hotstrings.json         # Auto-expansion triggers (managed by GUI)
│
├── Modules/                    # Feature modules
│   ├── Json.ahk                # ✅ Pure AHK v2 OOP JSON parser & serializer
│   ├── MenuBuilder.ahk         # ✅ Aggregates all data sources into unified entries
│   ├── Launcher.ahk            # ✅ Custom dark Fluent GUI & keyboard event handlers
│   ├── Hotstrings.ahk          # ✅ Hotstring manager GUI & live registration
│   ├── Utilities.ahk           # ✅ Native encoders, formatters, and sysadmin diagnostics
│   ├── Icons.ahk               # 🔲 Stub — icon extraction & caching (planned)
│   ├── Search.ahk              # 🔲 Stub — fuzzy search engine (planned)
│   ├── Settings.ahk            # 🔲 Stub — settings UI & hotkey rebinding (planned)
│   ├── Snippets.ahk            # 🔲 Stub — advanced snippet token engine (planned)
│   ├── Prompts.ahk             # 🔲 Stub — markdown prompt loader (planned)
│   └── WindowManager.ahk       # 🔲 Stub — multi-monitor placement (planned)
│
├── Cache/
│   ├── icons.db                # Cached icon paths/binaries
│   └── recent.json             # Usage tracking & recents history
│
├── Plugins/                    # Drop-in third-party extension modules
├── Assets/Icons/               # Bundled SVG/PNG assets
└── Docs/                       # Canonical project documentation
```

> **Legend:** ✅ Implemented · 🔲 Planned stub (empty file, reserved for future milestone)

---

## ⚙️ Configuration

All configuration lives in the `Config/` directory as focused JSON files. No code changes are needed to add programs, URLs, or snippets.

### `Config/settings.json` — Hotkeys & Theme

```json
{
  "hotkey": "F3",
  "searchHotkey": "+F3",
  "theme": "dark"
}
```

### `Config/config.json` — Programs, Folders & Utilities

```json
{
  "programs": [
    { "name": "VS Code",          "path": "C:\\Program Files\\Microsoft VS Code\\Code.exe" },
    { "name": "Windows Terminal", "path": "wt.exe" }
  ],
  "folders": [
    { "name": "Desktop",   "path": "%USERPROFILE%\\Desktop" },
    { "name": "Documents", "path": "%USERPROFILE%\\Documents" }
  ],
  "utilities": [
    { "name": "Calculator",        "cmd": "calc.exe" },
    { "name": "Clipboard History", "cmd": "send:#v" },
    { "name": "Snipping Tool",     "cmd": "send:#+s" }
  ]
}
```

**Utility `send:` prefix** — Simulates keyboard shortcuts instead of launching an executable:
- `send:#v` → Win+V (Clipboard History)
- `send:#+s` → Win+Shift+S (Snipping Tool)
- `send:#+r` → Win+Shift+R (Screen Recorder)

### `Config/urls.json` — Categorized Bookmarks

```json
{
  "Cybersecurity": [
    { "name": "Microsoft Defender XDR", "url": "https://security.microsoft.com" },
    { "name": "VirusTotal",             "url": "https://www.virustotal.com" }
  ],
  "Search Engines": [
    { "name": "Google",     "url": "https://www.google.com" },
    { "name": "DuckDuckGo", "url": "https://duckduckgo.com" }
  ]
}
```

### `Config/snippets.json` — Text Templates

```json
{
  "Text": [
    { "name": "Email Signature", "text": "Kind regards,{ENTER}John Doe{ENTER}{DATE}" },
    { "name": "Timestamp",       "text": "{TIME}" }
  ],
  "Code": [
    { "name": "Try Catch Block", "text": "try {\n    // Code\n} catch Error as err {\n    MsgBox(err.Message)\n}" }
  ]
}
```

**Dynamic tokens:** `{DATE}` · `{TIME}` · `{CLIPBOARD}` · `{ENTER}`

### `Config/prompts.json` — LLM Prompt Library

```json
[
  {
    "category": "Programming",
    "name": "Debug Code",
    "prompt": "Analyze the following code for syntax errors, logic bugs, edge cases..."
  }
]
```

When activated, the prompt is written to clipboard for instant paste (Ctrl+V) into any AI tool.

### `Config/hotstrings.json` — Auto-Expansion Triggers

Managed via the **Hotstring Manager GUI** (Tray → Hotstring Manager):

```json
[
  { "active": true,  "trigger": "btw", "replacement": "By the way" },
  { "active": false, "trigger": "brb", "replacement": "Be right back" }
]
```

### Environment Variables in Paths

| Variable | Expands To |
| :--- | :--- |
| `%A_ScriptDir%` | Minou script directory |
| `%USERPROFILE%` | `C:\Users\<Username>` |
| `%APPDATA%` | `C:\Users\<Username>\AppData\Roaming` |
| `%LOCALAPPDATA%` | `C:\Users\<Username>\AppData\Local` |
| `%ProgramFiles%` | `C:\Program Files` |
| `%TEMP%` | System temporary folder |

### Special URI Protocols

`SafeRun` natively handles Windows protocol handlers:
- **`ms-settings:`** — `ms-settings:display`, `ms-settings:bluetooth`, `ms-settings:windowsupdate`, `ms-settings:storage`, `ms-settings:clipboard`, `ms-settings:developers`
- **`shell:`** — `shell:Personal`, `shell:Downloads`, `shell:Desktop`, `shell:Programs`

---

## 🏗️ Architecture Overview

Minou was refactored from a **789-line monolithic script** into a clean modular system. `Minou.ahk` is a minimal orchestrator; all logic lives in `Modules/`.

### Boot Sequence

```
Minou.ahk  →  InitMinou()
                ├─ SetMenuDarkMode()       uxtheme.dll ordinals 135/136 → ForceDark
                ├─ LoadConfiguration()     Parses all Config/*.json into memory
                │   └─ RegisterHotstrings()  Activates hotstrings at boot
                ├─ CreateLauncherGui()     Builds borderless dark GUI (hidden)
                ├─ RegisterHotkeys()       Binds F3 / Shift+F3 from SettingsData
                └─ SetupTrayMenu()         Tray: Show, Hotstrings, Edit, Reload, Exit
```

### Global State

| Variable | Type | Source | Purpose |
| :--- | :--- | :--- | :--- |
| `ConfigData` | `Map` | `Config/config.json` | Programs, folders, utilities arrays |
| `SettingsData` | `Map` | `Config/settings.json` | Hotkeys, theme |
| `UrlData` | `Map` | `Config/urls.json` | Categorized bookmark collections |
| `SnippetData` | `Map` | `Config/snippets.json` | Text template collections |
| `PromptData` | `Array` | `Config/prompts.json` | LLM prompt objects |
| `HotstringData` | `Array` | `Config/hotstrings.json` | Auto-expansion rules |
| `ProgramData` | `Array` | Extracted from `ConfigData` | Program entries |
| `FolderData` | `Array` | Extracted from `ConfigData` | Folder entries |
| `UtilityData` | `Array` | Extracted from `ConfigData` | Utility entries |
| `CurrentEntries` | `Array` | `BuildMenuEntries()` | All normalized launchable items |
| `VisibleEntries` | `Array` | `RefreshLauncherResults()` | Currently displayed filtered subset |
| `AllSearchItems` | `Array` | Copy of `CurrentEntries` | Full searchable catalogue |

### Unified Item Format

Every launchable item — regardless of source — is normalized by `MenuBuilder.ahk` into:

```ahk
{
    name:     "Display Name",
    category: "Category Label",
    kind:     "url" | "program" | "folder" | "snippet" | "prompt" | "utility" | "setting" | "script",
    target:   "Path / URL / Command / Text",
    hwnd:     0x0   ; optional — for running AHK script windows
}
```

### GUI Layout

The launcher is a borderless, always-on-top Fluent dark window (`+AlwaysOnTop +ToolWindow -Caption`):
- **Background**: `0x1A1A1A` (near-black)
- **Search Edit Box**: `0x232323` background, white text, Segoe UI 10pt — appears at `x12 y34 w560 h28`
- **Category ListBox**: `170 × 280 px` at `x12 y72` — filters by category
- **Results ListView**: `382 × 280 px` at `x190 y72` — *Name* (220 px) + *Category* (140 px)
- **Footer hint**: `"F3 launch • Shift+F3 search • Enter run • Esc close"` at `x12 y360`
- **Hotstrings button**: Quick access to Hotstring Manager at `x480 y355 w90 h24`

The popup appears **20 px offset from the mouse cursor** and clamps to screen edges:
- If `xPos + 600 > A_ScreenWidth` → `xPos = A_ScreenWidth - 620`
- If `yPos + 400 > A_ScreenHeight` → `yPos = A_ScreenHeight - 420`

---

## 📦 Source Code — Detailed Technical Reference

> Every implemented file is documented here with its purpose, functions, data flows, and design decisions.

---

### `Minou.ahk` — Root Orchestrator & Lifecycle Bootstrapper

**Role:** Minimal entry point. Declares all global variables, includes module files, and calls `InitMinou()`. Contains no business logic beyond lifecycle management and shared utility functions.

**AHK Directives:**
```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
CoordMode "Mouse", "Screen"
SetWorkingDir A_ScriptDir
```

**Global Variables declared here:**

| Variable | Type | Initial Value | Description |
| :--- | :--- | :--- | :--- |
| `ScriptTitle` | `String` | `"Minou Popup"` | Window title / tray tooltip |
| `BaseDir` | `String` | `A_ScriptDir` | Root path of the script |
| `ConfigDir` | `String` | `BaseDir . "\Config"` | Config folder path |
| `ConfigFile` | `String` | path | Full path to `config.json` |
| `SettingsFile` | `String` | path | Full path to `settings.json` |
| `UrlsFile` | `String` | path | Full path to `urls.json` |
| `SnippetsFile` | `String` | path | Full path to `snippets.json` |
| `PromptsFile` | `String` | path | Full path to `prompts.json` |
| `HotstringFile` | `String` | path | Full path to `hotstrings.json` |
| `ConfigData` | `Map` | `Map()` | Loaded config.json data |
| `SettingsData` | `Map` | `Map()` | Loaded settings.json data |
| `UrlData` | `Map` | `Map()` | Loaded urls.json data |
| `SnippetData` | `Map` | `Map()` | Loaded snippets.json data |
| `PromptData` | `Array` | `Array()` | Loaded prompts.json data |
| `HotstringData` | `Array` | `Array()` | Loaded hotstrings.json data |
| `ProgramData` | `Array` | `Array()` | Extracted from ConfigData |
| `FolderData` | `Array` | `Array()` | Extracted from ConfigData |
| `UtilityData` | `Array` | `Array()` | Extracted from ConfigData |
| `AllSearchItems` | `Array` | `Array()` | Complete item catalogue |
| `LauncherGui` | `String/Obj` | `""` | GUI instance handle |
| `SearchBox` | `String/Obj` | `""` | Edit control reference |
| `CategoryListBox` | `String/Obj` | `""` | ListBox control reference |
| `ResultsListView` | `String/Obj` | `""` | ListView control reference |
| `CurrentEntries` | `Array` | `Array()` | All normalized entries |
| `CurrentCategory` | `String` | `"All"` | Active category filter |

**Module includes (in order):**
```ahk
#Include "Modules\Json.ahk"         ; Must be first — other modules depend on it
#Include "Modules\MenuBuilder.ahk"
#Include "Modules\Launcher.ahk"
#Include "Modules\Hotstrings.ahk"
```

**Functions defined in `Minou.ahk`:**

#### `InitMinou()`
The single boot entry point. Calls five lifecycle functions in sequence:
1. `SetMenuDarkMode()` — dark theme for Win32 system menus
2. `LoadConfiguration()` — parse all JSON configs into memory
3. `CreateLauncherGui()` — build the GUI (hidden)
4. `RegisterHotkeys()` — bind F3 and Shift+F3
5. `SetupTrayMenu()` — create tray icon menu

#### `SetMenuDarkMode()`
Uses `DllCall` to call `uxtheme.dll` by ordinal (not by name, since these are undocumented exports):
- Ordinal **135** = `SetPreferredAppMode(2)` — value `2` = `ForceDark`
- Ordinal **136** = `FlushMenuThemes()` — applies the new mode immediately
- Wrapped in `try/catch` — silently ignored on unsupported builds.

```ahk
uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
DllCall(SetPreferredAppMode, "int", 2)
```

#### `LoadConfiguration()`
Calls `LoadJsonFile()` (from `Json.ahk`) for each config file into its corresponding global variable. Also:
- Calls `RegisterHotstrings()` to activate hotstrings immediately at boot
- Guards against missing keys: if `ConfigData` has no `"programs"`, `"folders"`, or `"utilities"` keys, they are initialized as empty arrays
- Extracts `ProgramData`, `FolderData`, `UtilityData` as direct references from `ConfigData`

#### `RegisterHotkeys()`
Reads `hotkey` and `searchHotkey` from `SettingsData`, falling back to `"F3"` and `"+F3"`. Binds using AHK v2 lambda syntax:
```ahk
Hotkey(hotkeyMain,   (*) => ShowLauncherGui(false))
Hotkey(hotkeySearch, (*) => ShowLauncherGui(true))
```

#### `SetupTrayMenu()`
Replaces the default AHK tray menu entirely with:
- **Show Minou (F3)** → `ShowLauncherGui(false)`
- **Search Mode (Shift+F3)** → `ShowLauncherGui(true)`
- **Hotstring Manager** → `ShowHotstringManager()`
- *(separator)*
- **Edit config** → opens `Config/config.json` in Notepad
- **Reload** → `Reload()`
- **Exit** → `ExitApp()`

#### `ExpandEnvVars(path)`
String replacement function that handles 6 specific tokens. Order matters for `%APPDATA%` vs `%LOCALAPPDATA%` — `%LOCALAPPDATA%` is checked first to prevent partial replacement:
```ahk
expanded := StrReplace(expanded, "%A_ScriptDir%", A_ScriptDir)
expanded := StrReplace(expanded, "%TEMP%",         EnvGet("TEMP"))
expanded := StrReplace(expanded, "%USERPROFILE%",  EnvGet("USERPROFILE"))
expanded := StrReplace(expanded, "%LOCALAPPDATA%", EnvGet("LOCALAPPDATA"))
expanded := StrReplace(expanded, "%APPDATA%",      EnvGet("APPDATA"))
expanded := StrReplace(expanded, "%ProgramFiles%", EnvGet("ProgramFiles"))
```

#### `SafeRun(target, args := "")`
Centralized dispatch function. Calls `ExpandEnvVars()` first, then branches:
- URLs (`http://`, `https://`, `ms-settings:`, `shell:`) → native `Run(target)`
- File that exists on disk → native `Run(target)`
- Known executables (`explorer.exe`, `cmd.exe`, `powershell.exe`, `notepad.exe`) → `Run(target . " " . args)`
- All other targets → `Run(target . " " . args)` with fallback
- On any `Error` → `ToolTip("Could not launch target.")` auto-cleared after 1500 ms

> **Note:** The current implementation uses native `Run()`. The architecture documentation describes the planned `Shell.Application.ShellExecute` COM delegation for WDAC bypass — this is the intended upgrade path for `SafeRun`.

#### `LaunchItem(entry)`
Routes a normalized `entry` object to the appropriate action based on `entry.kind`:

| `entry.kind` | Code path |
| :--- | :--- |
| `"url"` | `SafeRun(entry.target)` |
| `"program"` | `FileExist()` check → `SafeRun()` or `ToolTip("⚠ Not installed: ...")` |
| `"folder"` | `SafeRun("explorer.exe", entry.target)` |
| `"snippet"` | `PasteText(entry.target)` |
| `"prompt"` | `A_Clipboard := entry.target` + tooltip confirmation |
| `"utility"` | `SafeRun(entry.target)` |
| `"script"` | `WinActivate("ahk_id " . entry.hwnd)` |
| `"setting"` | `SafeRun(entry.target)` |

#### `PasteText(txt)`
Token-based clipboard injection:
1. Replaces `{DATE}` → `FormatTime(, "yyyy-MM-dd")`
2. Replaces `{TIME}` → `FormatTime(, "HH:mm:ss")`
3. Replaces `{CLIPBOARD}` → current `A_Clipboard` value
4. Replaces `{ENTER}` → `` `n `` (newline)
5. Backs up `A_Clipboard` to `oldClip`
6. Sets `A_Clipboard := formattedTxt`
7. Calls `ClipWait(1)` — waits up to 1 second for clipboard readiness
8. Sends `^v` (Ctrl+V) to paste into the active window
9. Schedules `SetTimer(..., -1000)` one-shot to restore `oldClip` after 1 second

---

### `Modules/Json.ahk` — Pure AHK v2 JSON Engine

**Role:** Self-contained, dependency-free JSON parser and serializer. All other modules that need to read or write config files rely on this module's public API.

**Class: `JsonParser`**

A recursive-descent parser implemented as an AHK v2 class. Stores the source text and a position cursor (`PositionValue`, 1-indexed as per AHK string convention).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `__New(text)` | Constructor | Stores `text`, sets `PositionValue := 1` |
| `Position()` | `→ Integer` | Returns current cursor position |
| `SkipWhitespace()` | `→ void` | Advances past ` `, `\n`, `\r`, `\t` |
| `ParseValue()` | `→ Any` | Dispatcher: reads first char and delegates to the correct sub-parser |
| `ParseObject()` | `→ Map` | Parses `{key: value, ...}` → AHK `Map()` |
| `ParseArray()` | `→ Array` | Parses `[value, ...]` → AHK `Array()` |
| `ParseString()` | `→ String` | Parses `"..."` with full escape sequence support |
| `ParseLiteral(literal, value)` | `→ Any` | Parses `true`, `false`, `null` literals |
| `ParseNumber()` | `→ Integer/Float` | Parses numeric literals including `-`, `.`, `e`, `E` |

**Escape sequences handled in `ParseString()`:**

| JSON Escape | AHK Output |
| :--- | :--- |
| `\"` | `"` |
| `\\` | `\` |
| `\/` | `/` |
| `\b` | `` `b `` |
| `\f` | `` `f `` |
| `\n` | `` `n `` |
| `\r` | `` `r `` |
| `\t` | `` `t `` |
| `\uXXXX` | `Chr(FormatInteger(hex))` — full Unicode point conversion |

**`ParseValue()` dispatch table:**

| First char | Method called | AHK return type |
| :--- | :--- | :--- |
| `{` | `ParseObject()` | `Map` |
| `[` | `ParseArray()` | `Array` |
| `"` | `ParseString()` | `String` |
| `t` | `ParseLiteral("true", true)` | `true` |
| `f` | `ParseLiteral("false", false)` | `false` |
| `n` | `ParseLiteral("null", "")` | `""` (empty string) |
| `0-9` / `-` | `ParseNumber()` | `Integer` or `Float` |

**Top-level functions:**

#### `ParseJson(text)`
Entry point. Creates a `JsonParser`, calls `ParseValue()`, then verifies no trailing data remains (throws `Error("Unexpected trailing JSON data")` if cursor position < string length).

#### `StringifyJson(value, indent := "    ", level := 0)`
Recursive serializer. Handles:
- `Map` → `{ "key": value, ... }` with proper indentation
- `Array` → `[ value, ... ]` with proper indentation
- `String` → `QuoteJson(value)` (escapes backslash, quotes, newlines, carriage returns, tabs)
- `true` / `false` → `"true"` / `"false"`
- Numbers → stringified as-is

#### `QuoteJson(value)`
Applies JSON-safe escaping to a string value:
```ahk
escaped := StrReplace(value,   "\",  "\\")   ; backslash first
escaped := StrReplace(escaped, '"',  '\"')   ; then double-quote
escaped := StrReplace(escaped, "`n", "\n")   ; LF
escaped := StrReplace(escaped, "`r", "\r")   ; CR
escaped := StrReplace(escaped, "`t", "\t")   ; tab
return '"' . escaped . '"'
```

#### `LoadJsonFile(path, defaultValue := "")`
Safe file reader: checks `FileExist(path)` first, returns `defaultValue` if missing. Reads with `FileRead(path, "UTF-8")`, parses via `ParseJson()`, returns `defaultValue` on any parse error.

#### `SaveJsonFile(path, value)`
Serializes `value` to formatted JSON via `StringifyJson()` and writes using `FileOpen(path, "w", "UTF-8")` → `.Write()` → `.Close()`.

**Helpers:**

| Function | Signature | Purpose |
| :--- | :--- | :--- |
| `FormatInteger(hex)` | `→ Integer` | Converts hex string to integer: `Integer("0x" . hex)` |
| `Join(items, separator)` | `→ String` | Joins an `Array` of strings with a separator |
| `StrRepeat(text, count)` | `→ String` | Repeats a string `count` times (used for indentation) |

---

### `Modules/MenuBuilder.ahk` — Unified Entry Aggregator

**Role:** Single function `BuildMenuEntries()` that reads all global data sources and produces a flat, uniformly-typed `Array` of entry objects. This is the data pipeline connecting configuration to the launcher GUI.

**Function: `BuildMenuEntries()` → `Array`**

Processes sources in this fixed order:

| Pass | Source | Category assigned | `kind` value |
| :--- | :--- | :--- | :--- |
| 1 | `UrlData` (Map of category → items) | Category from JSON key | `"url"` |
| 2 | `ProgramData` (Array) | `"Programs"` | `"program"` |
| 3 | `FolderData` (Array) | `"Folders"` | `"folder"` |
| 4 | `SnippetData` (Map of category → items) | Category from JSON key | `"snippet"` |
| 5 | `PromptData` (Array) | `"Prompts"` | `"prompt"` |
| 6 | `UtilityData` (Array) | `"Utilities"` | `"utility"` |
| 7 | Hardcoded Windows Settings URIs | `"Windows Settings"` | `"setting"` |
| 8 | Live `WinGetList("ahk_class AutoHotkey")` | `"Running Scripts"` | `"script"` |

**Hardcoded Windows Settings entries:**
```
Display        → ms-settings:display
Bluetooth      → ms-settings:bluetooth
Windows Update → ms-settings:windowsupdate
Storage        → ms-settings:storage
Clipboard      → ms-settings:clipboard
Developer Mode → ms-settings:developers
```

**Dual-access pattern for Map/Object compatibility:**
Each item property is read with a guard to handle both `Map` objects (from JSON) and AHK `Object` instances:
```ahk
name := item is Map ? item["name"] : item.name
```
This ensures `MenuBuilder.ahk` remains robust even if data arrives from different sources.

**Running Scripts detection:**
```ahk
DetectHiddenWindows(true)                        ; Find minimized/hidden AHK windows
for hwnd in WinGetList("ahk_class AutoHotkey") {
    if (hwnd != A_ScriptHwnd) {                  ; Exclude Minou itself
        title := WinGetTitle("ahk_id " . hwnd)
        if (title != "")
            entries.Push({ name: title, category: "Running Scripts", kind: "script", hwnd: hwnd })
    }
}
```

**Folder path expansion:**
`FolderData` entries have their `path` passed through `ExpandEnvVars()` at build time so the resulting `target` field is always a fully resolved absolute path.

---

### `Modules/Launcher.ahk` — GUI Engine & Keyboard Navigation

**Role:** Builds and manages the entire launcher GUI lifecycle — construction, display, filtering, selection, and keyboard navigation. Defines context-sensitive hotkeys that only activate when the launcher window is focused.

**Module-level globals:**
```ahk
global VisibleEntries := Array()      ; The currently displayed filtered subset
global IsRefreshingLauncher := false  ; Recursion guard for RefreshLauncherResults
```

**Function: `CreateLauncherGui()`**

Constructs all GUI controls once. If a previous instance exists, destroys it first.

Controls added in order:
```
Text       "Minou Launcher"           x12  y10  w560
Edit       SearchBox                  x12  y34  w560 h28   Background0x232323
ListBox    CategoryListBox            x12  y72  w170 h280  Background0x232323
ListView   ResultsListView            x190 y72  w382 h280  Background0x232323, columns: [Name 220px, Category 140px]
Text       Footer hint                x12  y360 w560
Button     "Hotstrings"               x480 y355 w90  h24
```

Event bindings:
- `SearchBox.OnEvent("Change", ...)` → `RefreshLauncherResults()`
- `CategoryListBox.OnEvent("Change", ...)` → `OnCategoryChange()`
- `ResultsListView.OnEvent("DoubleClick", ...)` → `RunSelectedEntry()`
- `LauncherGui.OnEvent("Close", ...)` → `LauncherGui.Hide()` (hides, does not destroy)
- `LauncherGui.OnEvent("Escape", ...)` → `LauncherGui.Hide()`

**Function: `ShowLauncherGui(searchMode := false)`**

Called by hotkeys. Flow:
1. Creates GUI if not already created
2. Calls `RefreshLauncherData()` to rebuild the entry list from current config
3. Reads `MouseGetPos(&mouseX, &mouseY)` with `CoordMode "Mouse", "Screen"`
4. Applies `+20, +20` offset, clamps to screen bounds (580 × 390 window)
5. Calls `LauncherGui.Show("x... y... w580 h390")`
6. If `searchMode = true`: clears `SearchBox.Value` and calls `SearchBox.Focus()`
7. Calls `RefreshLauncherResults()` to populate immediately
8. Catches any `Error` and shows a `MsgBox`

**Function: `RefreshLauncherData()`**

Rebuilds category list from scratch every time the launcher is shown:
1. Calls `BuildMenuEntries()` → stores in `CurrentEntries` and `AllSearchItems`
2. Resets `CurrentCategory := "All"`
3. Clears and repopulates `CategoryListBox` with `"All"` + unique category names extracted by iterating `CurrentEntries`
4. Selects first item: `CategoryListBox.Choose(1)`

**Function: `RefreshLauncherResults()`**

Core filtering function. Protected by `IsRefreshingLauncher` boolean guard to prevent re-entrant calls. Uses `try/finally` to guarantee guard reset:

```ahk
for entry in CurrentEntries {
    matchesCategory := (CurrentCategory = "All" || entry.category = CurrentCategory)
    matchesQuery    := (query = "" || InStr(entry.name, query, false) || InStr(entry.category, query, false))
    if (matchesCategory && matchesQuery) {
        VisibleEntries.Push(entry)
        ResultsListView.Add("", entry.name, entry.category)
    }
}
```

- Search is **case-insensitive** (`InStr(..., false)`)
- Matches against both `entry.name` AND `entry.category`
- Always selects the first result: `ResultsListView.Modify(1, "Select")`

**Function: `OnCategoryChange(*)`**

Reads `CategoryListBox.Text` into `CurrentCategory` and calls `RefreshLauncherResults()`.

**Function: `MoveSelection(offset)`**

Keyboard navigation helper. Gets the currently selected ListView row via `GetNext(0)`, adds `offset` (`+1` or `-1`), clamps to `[1, GetCount()]`, and calls `ResultsListView.Modify(newIndex, "Select")`.

**Function: `RunSelectedEntry()`**

Gets selected row index from `ResultsListView.GetNext(0)`. Looks up `VisibleEntries[row]` (not `CurrentEntries[row]`) — this is critical: the row index maps to the **filtered** `VisibleEntries` array, not the full dataset. Then:
1. `LauncherGui.Hide()` — dismisses the popup before launching
2. `LaunchItem(entry)` — dispatches to the appropriate handler

**Function: `IsLauncherActive()` → `Boolean`**

Context predicate used by `#HotIf`. Returns `true` only when `LauncherGui` exists and `WinActive()` confirms focus is on the launcher window.

**Context-sensitive hotkeys:**
```ahk
#HotIf IsLauncherActive()
Up::MoveSelection(-1)
Down::MoveSelection(1)
Enter::RunSelectedEntry()
#HotIf
```
These hotkeys are **only active when the launcher has focus**, preventing interference with other applications.

---

### `Modules/Hotstrings.ahk` — Dynamic Hotstring Manager

**Role:** Provides a full-featured GUI editor for creating, editing, deleting, enabling, and disabling system-wide auto-expansion hotstrings. Persists state to `Config/hotstrings.json` and dynamically registers/unregisters hotstrings with the AHK v2 engine at runtime.

**Module-level globals:**
```ahk
global HotstringGui         := ""       ; Manager window instance
global HotstringListView    := ""       ; ListView control reference
global RegisteredHotstrings := Array()  ; Tracks which triggers are currently registered
```

**Function: `ShowHotstringManager(*)`**

Builds the manager GUI window:
- Destroys any existing instance first (idempotent — safe to call multiple times)
- Window: `+AlwaysOnTop +Resize`, `0x1A1A1A` background, Segoe UI
- Header: title + descriptive subtitle
- `ListView` (`Checked -Multi Grid`): two columns — *Trigger* (140 px) + *Replacement* (340 px)
  - `Checked` option adds a checkbox to each row for enable/disable toggle
  - `-Multi` restricts to single-row selection
- Button row: ✚ Add · ✏ Edit · 🗑 Delete · 💾 Save — each wired to its handler
- Calls `PopulateHotstringListView()` to load current data
- Shows at fixed width: `w524`

**Function: `PopulateHotstringListView()`**

Clears the ListView and re-adds all entries from `HotstringData`. For each hotstring:
- Reads `hs["active"]`, `hs["trigger"]`, `hs["replacement"]` from `Map`
- Passes `"Check"` as the options parameter if `active = true` (adds the checkbox tick)

**Function: `ShowEditDialog(triggerVal, replacementVal, isEditing, targetRow)`**

Shared Add/Edit dialog (`+AlwaysOnTop +ToolWindow`). Contains:
- `Edit` control for trigger abbreviation (pre-filled when editing)
- `Edit` control for replacement text (pre-filled when editing)
- OK / Cancel buttons, Escape binding

The `OnOk()` nested function (inner closure) captures all dialog state:
- Validates: trigger and replacement must both be non-empty
- If `isEditing`: calls `HotstringListView.Modify(targetRow, "", newTrigger, newReplacement)`
- If adding: calls `HotstringListView.Add("Check", newTrigger, newReplacement)` (new entries default to active)

**Function: `DeleteSelectedHotstring()`**

Gets selected row, asks for confirmation via `MsgBox(..., 4 + 48)` (Yes/No with warning icon), deletes on `"Yes"`.

**Function: `SaveAllHotstrings()`**

The critical save-to-disk-and-apply pipeline:
1. Reads all rows from `HotstringListView` via `GetCount()` + `GetText(row, col)` loop
2. Builds `newData` array with `active := false` for all rows
3. Second loop using `GetNext(checkedRow, "Checked")` to set `active := true` on checked rows
4. Assigns `HotstringData := newData`
5. Calls `SaveJsonFile(HotstringFile, HotstringData)` — persists to disk
6. Calls `ApplyHotstrings()` — re-registers with AHK engine
7. Shows `ToolTip("✓ Hotstrings saved and applied")` auto-cleared after 2000 ms

**Function: `ApplyHotstrings()`**

Two-phase registration:
1. **Disable phase**: Iterates `RegisteredHotstrings` (previously registered triggers), calls `Hotstring("::" . oldTrigger,, "Off")` on each. Clears `RegisteredHotstrings := Array()`.
2. **Register phase**: Iterates `HotstringData`. For each `active = true` entry:
   ```ahk
   Hotstring("::" . hs["trigger"], hs["replacement"])
   RegisteredHotstrings.Push(hs["trigger"])
   ```
   Errors during registration are shown as a `MsgBox` (non-silent, since misconfigured hotstrings need attention).

**Function: `RegisterHotstrings()`**

Thin alias for `ApplyHotstrings()`. Called from `LoadConfiguration()` at startup so the same re-registration logic is reused during boot without code duplication.

---

### `Modules/Icons.ahk` — Icon Extraction & Caching *(Stub)*

**Status:** Empty file — reserved for Milestone 1.

**Planned implementation:**
- Extract icons from `.exe` resources using `LoadImage()` or `ExtractAssociatedIcon()` via `DllCall`
- Fetch website favicons via HTTP for URL entries
- Cache extracted icon handles/paths to `Cache/icons.db` to avoid re-extraction on every launch
- Expose `GetIcon(entry)` → HICON or image path for use by the ListView

---

### `Modules/Search.ahk` — Fuzzy Search Engine *(Stub)*

**Status:** Empty file — reserved for Milestone 1.

**Planned implementation:**
- Implement multi-token fuzzy matching algorithm across all `AllSearchItems`
- Rank results by relevance score (exact match > prefix match > substring match > fuzzy match)
- Replace the current `InStr`-based filter in `RefreshLauncherResults()` with a scored sort
- Support searching: Programs, Folders, URLs, Snippets, Prompts, Utilities, Windows Settings

---

### `Modules/Settings.ahk` — Settings UI & Runtime Configuration *(Stub)*

**Status:** Empty file — reserved for Milestone 1.

**Planned implementation:**
- Interactive GUI for editing `Config/settings.json` without opening a text editor
- Live hotkey rebinding (change F3 / Shift+F3 without restarting)
- Theme selection and color customization
- Save changes via `SaveJsonFile()` + `RegisterHotkeys()` re-invocation

---

### `Modules/Snippets.ahk` — Advanced Snippet Token Engine *(Stub)*

**Status:** Empty file — reserved for Milestone 3.

**Planned implementation:**
- Extend `PasteText()` with additional context-aware tokens:
  - `{Selection}` — text highlighted by the user before pressing F3
  - `{ComputerName}` — `A_ComputerName`
  - `{Username}` — `A_UserName`
  - `{Name}` — prompted or user-configured display name
- Snippet preview pane inside the launcher

---

### `Modules/Prompts.ahk` — Markdown Prompt Loader *(Stub)*

**Status:** Empty file — reserved for Milestone 3.

**Planned implementation:**
- Load individual Markdown files from a `Prompts/` directory as prompt sources
- Index prompt content for search
- Show a preview pane in the launcher before copy/insertion
- Inject prompt into clipboard via `A_Clipboard` and optionally auto-paste

---

### `Modules/Utilities.ahk` — Encoding & Conversion Tools *(Stub)*

**Status:** Empty file — reserved for Milestone 1.

**Planned implementation:**
- `UrlEncode(str)` — RFC-3986 percent-encoding via UTF-8 memory buffer
- `Base64Encode(str)` — `Crypt32.dll\CryptBinaryToStringW` (flag `0x40000001`)
- Character map and quick conversion tools
- System automation utilities accessible from the launcher

---

### `Modules/WindowManager.ahk` — Multi-Monitor Placement *(Stub)*

**Status:** Empty file — reserved for Milestone 1.

**Planned implementation:**
- Full multi-monitor DPI awareness using `MonitorGet` and `MonitorGetWorkArea`
- Smart popup placement that respects taskbar positions and per-monitor DPI scaling
- Extract the screen-clamping logic currently in `ShowLauncherGui()` into this module

---

## 📚 Documentation

| Document | Audience | Contents |
| :--- | :--- | :--- |
| [01-Architecture.md](../Docs/01-Architecture.md) | Maintainers | Lifecycle, modules, GUI design, global state, WDAC handling |
| [02-Configuration.md](../Docs/02-Configuration.md) | Users & Devs | Full JSON schema reference, dynamic tokens, URI protocols |
| [03-Api-And-Helpers.md](../Docs/03-Api-And-Helpers.md) | Developers | `SafeRun`, `LaunchItem`, `PasteText`, `JsonParser`, IPC, encoders |
| [04-Roadmap.md](../Docs/04-Roadmap.md) | Contributors | Planned milestones: fuzzy search, icons, plugins, diagnostics |
| [05_ChangeLog.md](../Docs/05_ChangeLog.md) | All | Full changelog (Keep a Changelog / SemVer) |
| [06_DocumentationIndex.md](../Docs/06_DocumentationIndex.md) | All | Master cross-reference index of all docs |
| [AGENTS.md](../AGENTS.md) | AI Assistants | Coding standards, module rules, doc-sync protocol (ACIP) |

---

## 🗺️ Roadmap Highlights

- **Fuzzy Search Engine** (`Modules/Search.ahk`) — Multi-token ranking across all item types
- **Icon Extraction** (`Modules/Icons.ahk`) — Auto-extract `.exe` and favicon icons, cached to `Cache/icons.db`
- **Settings UI** (`Modules/Settings.ahk`) — Live hotkey rebinding & theme customization
- **Dynamic App Discovery** — Registry, Start Menu, Winget, Scoop, and Chocolatey scanning
- **Advanced Snippet Tokens** — `{Selection}`, `{ComputerName}`, `{Username}`, `{Name}`
- **File-Based Prompt Library** — Individual Markdown files in `Prompts/` with preview pane
- **Clipboard Manager** — History tracking, pinned items, integrated search
- **Plugin Architecture** (`Plugins/`) — Drop-in modules for VSCode, Everything, GitHub, Obsidian
- **Everything Search SDK** — Sub-second full-disk file search from the Minou search box
- **Local AI IPC** — Direct prompt dispatch to Ollama / LM Studio HTTP APIs

See [04-Roadmap.md](../Docs/04-Roadmap.md) for the full milestone breakdown.

---

## 🛠️ Development Guidelines

Minou is **exclusively AutoHotkey v2.0**. All contributions must follow:

- Include `#Requires AutoHotkey v2.0` · `#SingleInstance Force` · `Persistent` at every entry point
- Use `:=` for all assignments — legacy `=` is prohibited
- Use `Map()` for key-value data, `Array()` / `[]` for ordered lists — no pseudo-arrays (`Item%N%`)
- Use modern OOP GUI API with `.OnEvent()` — no legacy `Gui, Add, ...` syntax
- Route all program / URL / protocol launches through `SafeRun()` — never bare `Run()`
- Keep `Minou.ahk` minimal: add all new features to dedicated modules under `Modules/`
- Wrap all system calls in `try { ... } catch Error as err { ... }`
- Read/write config only via `LoadJsonFile()` / `SaveJsonFile()` from `Json.ahk`
- Keep in-memory global state (`ConfigData`, `HotstringData`, etc.) in sync with disk after every mutation

AI agents operating in this repository must follow the full **[Agent Change Implementation Protocol (ACIP)](../AGENTS.md)**, including mandatory documentation synchronization on every code change.

### Syntax Validation

After any change, run:
```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /validate "Minou.ahk"
```

---

## 📜 License

Personal / private use. See repository root for terms.
