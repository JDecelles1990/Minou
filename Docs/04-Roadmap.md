# Development Roadmap & Feature Specifications

This document outlines the planned architectural milestones and future feature roadmap for Minou.

> **See also:**
> - [05_ChangeLog.md](05_ChangeLog.md) — completed work and version history
> - [01-Architecture.md](01-Architecture.md) — current architecture and module dependency graph
> - [03-Api-And-Helpers.md § Stub Modules](03-Api-And-Helpers.md) — planned API surfaces for stub modules

---

## Current Implementation Status

Before reviewing the roadmap, the following modules are **fully implemented** as of the current release:

| Module | File | Status | Description |
| :--- | :--- | :--- | :--- |
| JSON Engine | `Modules/Json.ahk` | ✅ Complete | Recursive-descent parser + serializer |
| Menu Builder | `Modules/MenuBuilder.ahk` | ✅ Complete | 8-pass unified entry aggregator |
| Launcher GUI | `Modules/Launcher.ahk` | ✅ Complete | Fluent dark GUI, search, keyboard nav |
| Hotstrings | `Modules/Hotstrings.ahk` | ✅ Complete | GUI editor, JSON persistence, live registration |
| Utilities Engine | `Modules/Utilities.ahk` | ✅ Complete | Native encoders, JSON formatters, sysadmin diagnostics |
| Root Orchestrator | `Minou.ahk` | ✅ Complete | Lifecycle, `SafeRun`, `PasteText`, `LaunchItem` |

The following are **empty stub files** awaiting milestone implementation:

`Icons.ahk` · `Search.ahk` · `Settings.ahk` · `Snippets.ahk` · `Prompts.ahk` · `WindowManager.ahk`

---

## Milestone 1: Complete Module Stubs

**Goal:** Populate all 7 empty module files with their planned implementations. No new architectural changes — only filling in the reserved module boundaries.

### `Modules/Search.ahk` — Fuzzy Search Engine

Replace the current `InStr`-based case-insensitive substring matching in `RefreshLauncherResults()` with a scored fuzzy ranking algorithm:

**Planned scoring model:**

| Match Type | Score |
| :--- | :--- |
| Exact full-name match | 100 |
| Name starts with query | 80 |
| Name contains query (substring) | 60 |
| Category starts with query | 40 |
| Category contains query | 20 |
| Individual token matches (space-split query) | ÷ by token count |

**Public API:**
```ahk
FuzzySearch(query, items)      ; → Array of {entry, score} sorted descending
ScoreEntry(query, entry)       ; → Integer score
```

**Integration point:** `RefreshLauncherResults()` in `Launcher.ahk` currently calls `InStr()` directly — this will be replaced with a call to `FuzzySearch()`.

---

### `Modules/Icons.ahk` — Icon Extraction & Caching

Add icon display to the `ResultsListView` for program and URL entries.

**Extraction sources:**

| Entry Kind | Extraction Method |
| :--- | :--- |
| `"program"` | `ExtractAssociatedIcon()` / `LoadImage()` via `DllCall` from `.exe` |
| `"url"` | HTTP fetch of `https://domain/favicon.ico` |
| `"folder"` | `SHGetFileInfo()` shell icon |
| `"setting"` | System Settings icon |

**Cache design:**
- Cache file: `Cache/icons.db` (JSON or binary)
- Key: full executable path or domain name
- Value: extracted HICON handle or saved `.png` path
- Cache miss → extract → store → return

**Public API:**
```ahk
GetIcon(entry)             ; → HICON or image path
ExtractExeIcon(path)       ; → HICON
FetchFavicon(url)          ; → file path in Cache/
InvalidateIconCache()      ; → void (clear and rebuild)
```

---

### `Modules/Settings.ahk` — Interactive Settings UI

Allow users to change hotkeys, UI colors, and preferences without editing JSON directly.

**Planned GUI elements:**
- Hotkey Edit controls with live validation (prevent conflicts with existing system hotkeys)
- Theme color pickers or preset selector
- Toggle checkboxes for future options (e.g., show icons, show score, remember last search)
- **Save** button: calls `SaveJsonFile(SettingsFile, SettingsData)` + `RegisterHotkeys()` to apply without restart

**Public API:**
```ahk
ShowSettingsGui()               ; → void
SaveSettings(newSettingsMap)    ; → void (persist + apply)
ValidateHotkey(hk)              ; → Boolean (checks for conflicts)
```

---

### `Modules/Utilities.ahk` — Encoders, Formatters & Diagnostics ✅

**Status: Complete** (Implemented with `Config/utilities.json` categorized & subcategorized support).

Features implemented:
- **Encoders & Generators:** `GenerateGuid()`, `GenerateUnixTimestamp()`, `UrlEncode()`, `UrlDecode()`, `Base64Encode()`, `Base64Decode()`, `GenerateSha256Clipboard()`
- **Code & Formatting:** `BeautifyClipboardJson()`, `MinifyClipboardJson()`, `EscapeClipboardString()`, `CapitalizeSqlKeywords()`
- **Explorer & Environment:** `OpenTerminalAtActiveExplorer()`, `GitStatusAtActiveExplorer()`, `InspectPathEnvironment()`, `ToggleExplorerHiddenAndExt()`
- **SysAdmin & Network:** `FlushDns()`, `PingGatewayAndDns()`, `GetIpSummary()`, `ShowListeningPorts()`, `InspectDevPorts()`, `RestartExplorer()`, `PurgeTempFiles()`

---

### `Modules/WindowManager.ahk` — Multi-Monitor DPI Placement

Extract and replace the current screen-clamping logic in `ShowLauncherGui()`:

**Current code (to be moved):**
```ahk
xPos := mouseX + 20
yPos := mouseY + 20
if (xPos + 600 > A_ScreenWidth)  xPos := A_ScreenWidth - 620
if (yPos + 400 > A_ScreenHeight) yPos := A_ScreenHeight - 420
```

**Planned improvements:**
- Per-monitor DPI awareness using `MonitorGet` and `MonitorGetWorkArea`
- Respect taskbar position and auto-hide state
- Handle popup appearing on a second monitor when cursor is near primary/secondary boundary

**Public API:**
```ahk
GetMonitorForPoint(x, y)              ; → Integer (monitor index)
ClampToMonitorWorkArea(x, y, w, h)   ; → {x: Int, y: Int}
GetPopupPosition(mouseX, mouseY, popupW, popupH) ; → {x, y}
```

---

### `Modules/Snippets.ahk` — Advanced Token Engine

Extend `PasteText()` with additional context-aware variables:

**Planned additional tokens:**

| Token | Value Source | Notes |
| :--- | :--- | :--- |
| `{Selection}` | Text highlighted before F3 press | Requires pre-capture via `A_Clipboard` before GUI opens |
| `{ComputerName}` | `A_ComputerName` | Machine hostname |
| `{Username}` | `A_UserName` | Windows login name |
| `{Name}` | User-configured in `settings.json` | Display name |
| `{GUID}` | `COM {8502C…}` GUID generator | Generates UUID v4 |

**Public API:**
```ahk
ExpandTokens(txt)          ; → String (extended replacement)
CaptureSelection()         ; → String (clipboard-based selection capture)
```

**Snippet preview pane:** Add a read-only `Edit` control to the right panel of the launcher when a snippet is selected, showing the resolved preview with current token values.

---

### `Modules/Prompts.ahk` — Markdown Prompt Loader

Transition the prompt library from `Config/prompts.json` to individual Markdown files.

**Directory layout:**
```
Prompts/
├── Programming/
│   ├── Debug.md
│   ├── Refactor.md
│   └── Review.md
├── PowerShell/
│   ├── Script.md
│   └── Azure.md
├── General/
│   ├── Summarize.md
│   └── Rewrite.md
└── Networking/
    └── Troubleshoot.md
```

**Public API:**
```ahk
LoadPromptsFromDir(dir)        ; → Array of {name, category, prompt}
GetPromptPreview(entry)        ; → String (first 300 chars)
```

**Integration:** `BuildMenuEntries()` will call `LoadPromptsFromDir()` instead of reading from `PromptData` array. A preview pane will render in the launcher when a prompt is selected.

---

## Milestone 2: Dynamic App Detection

**Goal:** Eliminate hardcoded executable paths in `Config/config.json` by discovering installed software automatically at runtime.

### Multi-Source Discovery Engine

**Pass 1 — Registry App Paths:**
```
HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths
HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths
```

**Pass 2 — Uninstall Keys:**
```
HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
```

**Pass 3 — Start Menu Shortcuts:**
```ahk
shell:Programs          ; Per-user shortcuts
shell:Common Programs   ; System-wide shortcuts
```

**Pass 4 — Package Manager Paths:**
- **Winget:** `winget list --output json` (subprocess)
- **Scoop:** `%USERPROFILE%\scoop\shims\*.exe`
- **Chocolatey:** `%ProgramData%\chocolatey\bin\*.exe`

### Validation & Graceful Fallback

For hybrid AI tools (e.g., Ollama, OpenWebUI, Continue, GPT4All, AnythingLLM) that can run as a local desktop executable, a web URL, or both:

- If the executable exists locally → show with `"program"` kind
- If only a localhost URL is reachable → show with `"url"` kind: `http://localhost:11434`
- If neither → show the entry with a `"⚠ Not Installed"` suffix and disable the launcher row

---

## Milestone 3: Advanced Snippet & Prompt Engines

Full implementation of `Modules/Snippets.ahk` and `Modules/Prompts.ahk`.

### Expanded Snippet Tokens

See [02-Configuration.md § Planned Additional Tokens](02-Configuration.md) for the full token table.

### File-Based Markdown Prompt Library

See [Milestone 1 — Modules/Prompts.ahk](#modulespromptahk--markdown-prompt-loader) above.

**Preview pane design:**
- Rendered below (or to the right of) the ListView when a `"prompt"` entry is selected
- Shows the first ~500 characters of the prompt text in a read-only `Edit` control
- Paste button: copies full prompt to clipboard without launching

---

## Milestone 4: Clipboard Manager

Implement an IT-centric clipboard history module:

**History tracking:**
- Monitor `OnClipboardChange` to capture all clipboard changes
- Store metadata: timestamp, type (text/image), first 200 chars preview
- Persist to `Cache/recent.json`

**Pinned items:**
- Pin frequent scripts, SQL queries, or email responses
- Prevent pinned items from being evicted by history limit (configurable, default 50)

**Integration with launcher:**
- Clipboard history appears as a `"Clipboard History"` category in `CategoryListBox`
- Shift+F3 search includes clipboard history items by default

**Public API (planned):**
```ahk
ClipboardHistoryAdd(text)          ; called from OnClipboardChange handler
ClipboardHistoryGet()              ; → Array of {text, timestamp, pinned}
ClipboardHistoryPin(index)         ; toggle pinned state + save
```

---

## Milestone 5: Drop-In Plugin Architecture

Allow extending Minou without modifying core script code.

**Plugin directory layout:**
```
Plugins/
├── VSCode/
│   ├── plugin.json        ; metadata: name, version, author, categories
│   └── actions.ahk        ; implements GetEntries() → Array
├── Everything/
│   ├── plugin.json
│   └── actions.ahk
├── GitHub/
│   ├── plugin.json
│   └── actions.ahk
└── Obsidian/
    ├── plugin.json
    └── actions.ahk
```

**`plugin.json` schema:**
```json
{
  "name": "VSCode Plugin",
  "version": "1.0.0",
  "author": "Author Name",
  "categories": ["Development"],
  "entryScript": "actions.ahk"
}
```

**Plugin contract:** Each `actions.ahk` must expose a `GetEntries()` function returning an `Array` of unified entry objects (same format as `BuildMenuEntries()` output).

**`BuildMenuEntries()` integration:**
```ahk
; After all built-in passes:
for pluginDir in GetPluginDirectories() {
    pluginEntries := LoadPlugin(pluginDir)
    for entry in pluginEntries
        entries.Push(entry)
}
```

---

## Milestone 6: Built-In System Diagnostics

Add a self-testing diagnostic tool accessible from the tray menu:

| Diagnostic Check | Method |
| :--- | :--- |
| Scan for missing executable paths | `FileExist()` on all `ProgramData` entries |
| Validate HTTP status for web bookmarks | `WinHTTP.WinHttpRequest` COM object |
| Lint all JSON config files | `ParseJson()` on each file, report errors |
| Flag duplicate hotkeys or shortcuts | Compare `HotstringData` triggers for duplicates |
| Report launcher startup time | `A_TickCount` delta from script start to `InitMinou()` completion |
| Report RAM footprint | `Process.GetCurrentProcess().WorkingSet64` via DllCall |

**Output:** A formatted report GUI showing all checks with pass/fail status.

---

## Milestone 7: External Ecosystem Integrations

### Everything Search SDK

Sub-second full-disk file search directly from the Minou search box:
- Use Everything SDK DLL (`Everything64.dll`) via `DllCall`
- Integrate results as a `"Files"` category in the launcher
- Configurable file type filters

### PowerToys Command Palette Interop

Seamless invocation between Minou and PowerToys Run:
- Detect PowerToys via registry / process list
- Allow users to bind a Minou hotkey that invokes PowerToys Run with current search text

### Local AI Provider IPC

Direct prompt dispatch to local AI endpoints without opening a browser:
- **Ollama:** HTTP POST to `http://localhost:11434/api/generate`
- **LM Studio:** HTTP POST to `http://localhost:1234/v1/chat/completions`
- **AnythingLLM:** `http://localhost:3001` API

**Planned flow:**
1. User selects a `"prompt"` entry in launcher
2. Secondary action (e.g., Ctrl+Enter) sends to local AI instead of copying to clipboard
3. Response shown in a dedicated output GUI panel
