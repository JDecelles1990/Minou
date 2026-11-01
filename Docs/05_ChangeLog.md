# Changelog

All notable changes to Minou will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **See also:**
> - [04-Roadmap.md](04-Roadmap.md) — planned milestones and upcoming features
> - [01-Architecture.md](01-Architecture.md) — current architecture reflecting all implemented changes

---

## [Unreleased] — Modular Architecture Phase

> This section tracks all changes since the v0.1.0 monolithic prototype. A formal version number will be assigned when Milestone 1 (stub module population) is complete.

### Added

#### Section Color Differentiation & Visual Formatting (`Modules/Launcher.ahk`)
- **Distinct Section Color Palette**: Assigned vibrant, readable, high-contrast colors (contrast ratio > 5.8:1 against `#232323`) to every one of the 17 launcher sections.
- **Unified Name + Category Coloring**: In `ResultsListView`, both the **Name** and **Category / Subcategory** text are drawn in the exact parent section color using Win32 `NM_CUSTOMDRAW` (`-12`). Selected items display a subtle dark slate highlight (`0x3E3E3E`) while maintaining full text readability.
- **Owner-Drawn Category List**: `CategoryListBox` uses Win32 `WM_DRAWITEM` (`+0x0010 +0x0040`) to render each section name in its matching section color, with "All" rendered in crisp off-white.

#### Dual-Column Keyboard Navigation (`Modules/Launcher.ahk`)
- **Left / Right Arrow Column Toggling**:
  - <kbd>Left</kbd> arrow switches keyboard focus to the **Section column** (`CategoryListBox`).
  - <kbd>Right</kbd> arrow switches keyboard focus to the **Name + Category column** (`ResultsListView`).
  - Native cursor movement is preserved inside `SearchBox` whenever the user is actively typing a query.
- **Up / Down Arrow Scrolling Across Sections & Modules**:
  - In `CategoryListBox`: <kbd>Up</kbd> / <kbd>Down</kbd> scrolls through sections and immediately refreshes the displayed entries in real time.
  - In `ResultsListView`: <kbd>Up</kbd> / <kbd>Down</kbd> scrolls through modules, scrolling into `SearchBox` when moving up from row 1.
  - In `SearchBox`: <kbd>Down</kbd> drops focus directly into row 1 of `ResultsListView`.
- **Context-Sensitive Enter Key**:
  - Pressing <kbd>Enter</kbd> while on `CategoryListBox` focuses the results list on the first module of that section.
  - Pressing <kbd>Enter</kbd> while on `ResultsListView` or `SearchBox` executes `RunSelectedEntry()`.

#### Window Opacity Update to 80% (`Config/settings.json`, `Modules/Settings.ahk`)
- Updated default window opacity from 85% to **80%** across `Config/settings.json`, `Modules/Settings.ahk` (`DefaultOpacityPercent := 80`), the interactive Settings slider, and documentation.

#### Added Built-in Applications (`Config/config.json`)
- Added 10 user-requested system and desktop applications to `Programs & Folders` with full environment variable resolution and `ms-` protocol URI dispatch:
  - Microsoft Edge, PowerShell, Notepad++ (`C:\Program Files\Notepad++\notepad++.exe`), Snipping Tool, Photos (`ms-photos:`), Paint, ChatGPT, Antigravity, Word/antiword (`C:\Program Files\Git\mingw64\bin\antiword.exe`), and SSMS ServiceHub Settings.

#### Custom Title Bar & Window Controls (`Modules/Launcher.ahk`)
- **Title Bar with Window Controls**: Added a draggable header (`x0 y0 w580 h36 Background0x111111`) with custom controls:
  - ⚙ **Settings Emoji Button**: Opens the runtime Settings GUI dialog.
  - `_` **Minimize Button**: Minimizes the window to the taskbar (`LauncherGui.Minimize()`).
  - `✕` **Close Button**: Hides the launcher to the system tray (`HideLauncher()`), keeping hotkeys and tray background services active.
- **Title Bar Dragging**: Implemented `WM_LBUTTONDOWN` (`0x0201`) handling to allow dragging the borderless window anywhere along its title bar.

#### Runtime Settings & Opacity Module (`Modules/Settings.ahk`)
- **Interactive Settings GUI (`ShowSettingsGui()`)**: Allows configuring the primary launcher hotkey, search-mode hotkey, and window opacity without manually editing JSON.
- **Window Opacity (85%)**: Added `opacity` configuration (defaulting to 85%), with `ApplyOpacity()` utilizing `WinSetTransparent()` across all Minou windows and an interactive live slider in Settings.
- **Live Hotkey Rebinding**: Hotkeys can be rebound at runtime through `RegisterHotkeys()` without restarting the application; automatically rolls back if an invalid key sequence is entered.
- **Default Hotkey Update**: Changed default launch hotkey to **Alt+F3** (`"!F3"`) and search hotkey to **Alt+Shift+F3** (`"!+F3"`).

#### In-Place Section & Entry Editor (`Modules/EntryEditor.ahk`)
- **`ShowEntryEditor()`**: Added an **✏ Edit** button on the launcher footer that opens a dedicated dialog to edit the selected item's name, category, and sub-category.
- **Real-time Dual Sync**: Updates in-memory collections and persists modifications to the responsible `Config/*.json` file (`urls.json`, `snippets.json`, `utilities.json`, `config.json`, `prompts.json`).
- **Category Autocomplete**: Dropdown pre-populates existing categories and allows typing a new category name to re-categorize items.

#### Architecture & Sections Audit (`Docs/07_SectionsAudit.md`)
- **Full Sections Audit**: Created comprehensive audit documenting every category, entry name, owning JSON file, editable fields, and automated test result.
- **4-Item Section Enforcement**: Merged `Programs` (3) and `Folders` (3) into `Programs & Folders` (6); renamed `Text` to `Snippets` and expanded to 6 entries.
- **Dead Link Removal**: Cleaned up dead links (`PacketLife`, `JuriBistro`, `Microsoft Quick Assist`).
- **Resolved Pathing**: Corrected VS Code executable path using `%LOCALAPPDATA%` and expanded environment variables in `ProgramData`.

### Fixed
- **`TimeAdd` Syntax Error**: Corrected invalid v1 function call to AutoHotkey v2 `DateAdd()` in `GenerateUnixTimestamp()`.
- **Removed `A_IPAddress1` Variable**: Implemented `GetLocalIpAddress()` using WMI to eliminate blocking load-time warning dialogs.
- **`ParseNumber()` JSON Bug**: Updated `JsonParser.ParseNumber()` to use `IsDigit()` instead of invalid string comparison `ch >= "0"` which threw errors in AHK v2 on closing brackets.

#### Core Architecture
- **Modular system**: Refactored the 789-line monolithic `Minou AHK` prototype into a clean, multi-file modular system with `Minou.ahk` as a minimal orchestrator and discrete module files under `Modules/`
- **Root orchestrator** `Minou.ahk`: Declares all global variables (`ConfigData`, `SettingsData`, `UrlData`, `SnippetData`, `PromptData`, `HotstringData`, `ProgramData`, `FolderData`, `UtilityData`, `CurrentEntries`, `VisibleEntries`, etc.) and includes modules via `#Include`
- **`InitMinou()` boot sequence**: Deterministic five-step initialization — `SetMenuDarkMode()` → `LoadConfiguration()` → `CreateLauncherGui()` → `RegisterHotkeys()` → `SetupTrayMenu()`

#### `Modules/Json.ahk` — OOP JSON Engine
- **`class JsonParser`**: Pure AHK v2 recursive-descent parser with 9 methods: `__New`, `Position`, `SkipWhitespace`, `ParseValue`, `ParseObject`, `ParseArray`, `ParseString`, `ParseLiteral`, `ParseNumber`
- **Full escape sequence support** in `ParseString()`: `\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX` (Unicode code point via `Chr(Integer("0x" . hex))`)
- **`StringifyJson()`**: Recursive serializer for `Map`, `Array`, `String`, `Integer`, `Float`, and `Boolean` with configurable indentation
- **`QuoteJson()`**: JSON-safe string escaping (backslash-first ordering to prevent double-escaping)
- **`LoadJsonFile(path, defaultValue)`**: Safe file reader with `FileExist` pre-check, UTF-8 encoding, and silent error fallback
- **`SaveJsonFile(path, value)`**: UTF-8 writer using `FileOpen` + `.Write()` + `.Close()` — correct AHK v2 file API
- **Helper functions**: `ParseJson()`, `FormatInteger()`, `Join()`, `StrRepeat()`

#### `Modules/MenuBuilder.ahk` — Entry Aggregator
- **`BuildMenuEntries()`**: 8-pass aggregator producing a flat `Array` of normalized `{name, category, kind, target, hwnd?}` objects
- **URL entries**: Iterates `UrlData` Map (category → items array)
- **Program entries**: Iterates `ProgramData` with `"Programs"` category
- **Folder entries**: Iterates `FolderData` with `ExpandEnvVars()` path resolution at build time
- **Snippet entries**: Iterates `SnippetData` Map (category → items array)
- **Prompt entries**: Iterates `PromptData` Array with `"Prompts"` category
- **Utility entries**: Iterates `UtilityData` with `"Utilities"` category
- **Hardcoded Windows Settings**: 6 `ms-settings:` URIs under `"Windows Settings"` category
- **Live AHK script detection**: `WinGetList("ahk_class AutoHotkey")` + `DetectHiddenWindows(true)`, excludes `A_ScriptHwnd` (Minou itself)
- **Dual Map/Object accessor pattern**: `item is Map ? item["key"] : item.key` for compatibility

#### `Modules/Launcher.ahk` — Fluent Dark GUI
- **`CreateLauncherGui()`**: Borderless `+AlwaysOnTop +ToolWindow -Caption` window with `0x1A1A1A` background
- **Control layout**: Title label, `SearchBox` Edit, `CategoryListBox` ListBox (170×280), `ResultsListView` ListView (382×280, two columns), footer hint Text, Hotstrings Button
- **`ShowLauncherGui(searchMode)`**: Mouse-relative positioning with `+20px` offset and screen-edge clamping (`A_ScreenWidth - 620`, `A_ScreenHeight - 420`)
- **`RefreshLauncherData()`**: Rebuilds `CurrentEntries` via `BuildMenuEntries()` and repopulates `CategoryListBox` on every show
- **`RefreshLauncherResults()`**: Real-time case-insensitive filtering against `entry.name` AND `entry.category`; protected by `IsRefreshingLauncher` re-entry guard using `try/finally`
- **`RunSelectedEntry()`**: Uses `VisibleEntries[row]` — not `CurrentEntries[row]` — to correctly map filtered row index to entry
- **`IsLauncherActive()`**: `#HotIf` predicate using `WinActive("ahk_id " . LauncherGui.Hwnd)`
- **Context-sensitive hotkeys**: `Up`/`Down`/`Enter` scoped to launcher window only via `#HotIf IsLauncherActive()`
- **Double-click launch**: `ResultsListView.OnEvent("DoubleClick", ...)` → `RunSelectedEntry()`
- **Hide on close/escape**: `LauncherGui.OnEvent("Close"/"Escape", (*) => LauncherGui.Hide())` — window is never destroyed, only hidden

#### `Modules/Hotstrings.ahk` — Dynamic Hotstring Manager
- **`ShowHotstringManager()`**: Dark `+AlwaysOnTop +Resize` GUI with `Checked -Multi Grid ListView` (Trigger 140px + Replacement 340px columns)
- **CRUD buttons**: ✚ Add, ✏ Edit, 🗑 Delete, 💾 Save — all wired to handlers
- **`ShowEditDialog()`**: Shared Add/Edit modal with nested `OnOk()` closure capturing all dialog state
- **`SaveAllHotstrings()`**: Two-pass ListView scan (all rows → set `active=false`; checked rows → set `active=true`), calls `SaveJsonFile()` + `ApplyHotstrings()`
- **`ApplyHotstrings()`**: Two-phase — disable all `RegisteredHotstrings` triggers, then re-register active ones; errors shown via `MsgBox`
- **`RegisteredHotstrings` tracker**: Global `Array` tracking all currently live trigger strings for clean disable/re-register cycle
- **`RegisterHotstrings()` alias**: Thin wrapper for startup use from `LoadConfiguration()`

#### `Modules/Utilities.ahk` — Native Encoders, Formatters & Diagnostics
- **`DispatchInternalUtility(fnName)`**: Internal router for utility triggers dispatched from `LaunchItem()`
- **Encoders & Generators**: `GenerateGuid()` (UUID v4 via native COM `ole32\CoCreateGuid`), `GenerateUnixTimestamp()`, `UrlEncode()` / `UrlDecode()` (RFC-3986 buffer), `Base64Encode()` / `Base64Decode()` (`Crypt32.dll`), `GenerateSha256Clipboard()` (Windows CNG)
- **Code & Formatting**: `BeautifyClipboardJson()` (4-space indent using `Modules/Json.ahk`), `MinifyClipboardJson()` (0 indent), `EscapeClipboardString()`, `CapitalizeSqlKeywords()`
- **Explorer & Environment**: `GetActiveExplorerPath()`, `OpenTerminalAtActiveExplorer()`, `GitStatusAtActiveExplorer()`, `InspectPathEnvironment()`, `ToggleExplorerHiddenAndExt()`
- **SysAdmin & Network**: `FlushDns()`, `PingGatewayAndDns()`, `GetIpSummary()`, `ShowListeningPorts()`, `InspectDevPorts()`, `RestartExplorer()`, `PurgeTempFiles()`

#### Configuration & Launcher GUI Enhancements
- **`Config/utilities.json`**: New structured configuration supporting categorized and subcategorized utilities (`Network & SysAdmin` and `Developer Tools`)
- **Subcategory UI display**: When a specific category is selected in `CategoryListBox`, `ResultsListView` dynamically re-labels its second column to "Subcategory" and displays entry subcategories
- **Tri-field search filtering**: `RefreshLauncherResults()` matches search queries across `entry.name`, `entry.category`, and `entry.subcategory`

#### Core Functions in `Minou.ahk`
- **`SetMenuDarkMode()`**: `uxtheme.dll` ordinal 135 (`SetPreferredAppMode = 2`) + ordinal 136 (`FlushMenuThemes`) for system-wide ForceDark; `try/catch` wrapped
- **`LoadConfiguration()`**: Loads all 7 JSON files including `Config/utilities.json`, calls `RegisterHotstrings()`, guards missing keys
- **`RegisterHotkeys()`**: Reads from `SettingsData` with `"F3"` / `"+F3"` defaults; binds via `Hotkey()` lambdas
- **`SetupTrayMenu()`**: 7 tray items including Hotstring Manager shortcut
- **`ExpandEnvVars(path)`**: Expands 6 environment variable tokens; `%LOCALAPPDATA%` before `%APPDATA%` to prevent substring collision
- **`SafeRun(target, args)`**: Centralized launcher with 4-branch dispatch and `ToolTip` error feedback
- **`LaunchItem(entry)`**: 8-kind dispatch table routing to `SafeRun`, `PasteText`, `WinActivate`, `DispatchInternalUtility`, or clipboard operations
- **`PasteText(txt)`**: 4-token substitution + clipboard backup/restore via one-shot `SetTimer(-1000)`

#### Split Configuration Schema
- **`Config/settings.json`**: Hotkey + searchHotkey + theme
- **`Config/config.json`**: programs + folders + utilities arrays
- **`Config/urls.json`**: category-keyed bookmark collections
- **`Config/snippets.json`**: category-keyed snippet collections with `{DATE}`, `{TIME}`, `{CLIPBOARD}`, `{ENTER}` tokens
- **`Config/prompts.json`**: flat array of `{category, name, prompt}` objects
- **`Config/hotstrings.json`**: flat array of `{active, trigger, replacement}` objects

#### Documentation Suite
- **`Docs/01-Architecture.md`**: Full architecture with module dependency graph, global state table, GUI layout, boot sequence
- **`Docs/02-Configuration.md`**: Complete schema reference for all 6 config files with key tables, token reference, URI catalog
- **`Docs/03-Api-And-Helpers.md`**: Function-level API reference for all implemented modules and planned stub APIs
- **`Docs/04-Roadmap.md`**: 7 milestones with planned APIs, integration points, and implementation specs
- **`Docs/05_ChangeLog.md`**: This file
- **`Docs/06_DocumentationIndex.md`**: Master cross-reference index
- **`Docs/AGENTS.md`**: Documentation-specific AI agent rules (supplement to root `AGENTS.md`)
- **`AGENTS.md`** (root): Root authority — coding standards, 5-phase ACIP, modular boundary rules, doc-sync parity table

#### Stub Module Files Created (Empty — Reserved)
- `Modules/Icons.ahk`
- `Modules/Search.ahk`
- `Modules/Settings.ahk`
- `Modules/Snippets.ahk`
- `Modules/Prompts.ahk`
- `Modules/Utilities.ahk`
- `Modules/WindowManager.ahk`

### Changed

- **Refactored** monolithic prototype (`Minou AHK`, 789 lines) into modular coordinator `Minou.ahk` with discrete module boundaries
- **`Minou.ahk`** reduced to pure orchestrator: global declarations + `#Include` directives + 7 lifecycle/utility functions only
- **Config schema** split from single root `config.json` into 6 domain-specific files under `Config/`
- **`ReadMe.md`** expanded from stub to comprehensive project documentation with quick-start, project structure, all config schemas, architecture overview, and full per-file source code reference

### Fixed

- **AHK v2 string literal escaping in `Json.ahk`**: Replaced C-style backslash-quote escapes (`\"`) with correct AHK v2 single-quote and string literal syntax, resolving a parser startup crash on line 44
- **Map-safe property access in `MenuBuilder.ahk`**: Updated all item property retrieval to use the dual `item is Map ? item["key"] : item.key` guard, fixing crashes when JSON-parsed `Map` objects were mixed with inline AHK `Object` literals
- **Filtered row execution in `Launcher.ahk`**: Bound `RunSelectedEntry()` to `VisibleEntries` (filtered subset) rather than `CurrentEntries` (full dataset) to ensure filtered selections always launch the expected item
- **GUI event crash in `Launcher.ahk`**: Removed invalid `KeyDown` event listener from the search `Edit` control (unsupported in AHK v2 Edit controls), replaced with `#HotIf IsLauncherActive()` scoped hotkeys and native `Escape` GUI event binding
- **`SaveJsonFile` API**: Replaced the non-existent `FileWrite()` call with the correct `FileOpen(path, "w", "UTF-8")` + `.Write()` + `.Close()` pattern
- **Hotstring registration cleanup**: Added `RegisteredHotstrings` tracker array so previously active hotstrings are explicitly disabled (via `Hotstring("::" . trigger,, "Off")`) before re-registering, preventing duplicate or ghost trigger accumulation

---

## [0.1.0] — Monolithic Prototype

### Added

- **Initial proof-of-concept** single-file script (`Minou AHK`) using native Windows `Menu()` objects for popup display
- **`uxtheme.dll` dark menu styling** via ordinals 135/136 for experimental Windows 11 dark menu chrome
- **Baseline JSON configuration loading** from root `config.json` with embedded JSON parser
- **F3 hotkey binding** to show popup menu near mouse cursor
- **Shift+F3 search mode** with inline search box within native menu
- **Basic category structure**: Programs, Folders, URLs, Snippets, Utilities
- **`Run()` based process launch** for all entry types

### Limitations (addressed in Unreleased)

- All logic in a single 789-line script file (no modularity)
- Native `Menu()` styling is limited by OS rendering constraints
- No real-time filtering — search was a separate popup mode
- Single `config.json` made configuration unwieldy at scale
- No hotstring management
- No dedicated documentation
