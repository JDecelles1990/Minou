# API and Helper Functions Reference

This document provides a comprehensive technical reference for the functions, classes, and subroutines across Minou's core script (`Minou.ahk`), modules (`Modules/`), and reference codebase.

---

## 1. Process Execution & System Dispatch

### `SafeRun(target, args := "")`
Safely launches an executable, file, directory, or protocol URI with WDAC (Windows Defender Application Control) bypass mechanisms.

```ahk
SafeRun("calc.exe")
SafeRun("powershell.exe", "-NoExit -Command Get-Process")
SafeRun("https://github.com")
SafeRun("ms-settings:display")
```

- **Path Expansion**: Pre-processes `target` via `ExpandEnvVars()`.
- **COM Shell Delegation**: Calls `ComObject("Shell.Application").ShellExecute(expandedTarget, strArgs, "", "open", 1)` to execute directly via Windows Shell, avoiding security policy errors associated with AHK's `RunWithHandles`.
- **Fallback Execution**: If COM instantiation fails, attempts native AHK `Run()`.
- **Error Protection**: Catches `Error` exceptions and shows a non-blocking tooltip: `"Could not launch target."` without interrupting script execution.

---

### `ExpandEnvVars(path)`
Expands embedded environment variables and AutoHotkey script macros within a path string.

```ahk
expanded := ExpandEnvVars("%USERPROFILE%\Desktop")
; -> "C:\Users\Jo\Desktop"
```

**Supported Tokens:**
- `%A_ScriptDir%` $\rightarrow$ Replaced with `A_ScriptDir`
- `%USERPROFILE%` $\rightarrow$ `EnvGet("USERPROFILE")`
- `%TEMP%` $\rightarrow$ `EnvGet("TEMP")`
- `%LOCALAPPDATA%` $\rightarrow$ `EnvGet("LOCALAPPDATA")`
- `%APPDATA%` $\rightarrow$ `EnvGet("APPDATA")`
- `%ProgramFiles%` $\rightarrow$ `EnvGet("ProgramFiles")`

---

## 2. Item Dispatch & Dynamic Injection

### `LaunchItem(entry)`
Routes an arbitrary launch request based on the item's `kind` property:

```ahk
LaunchItem(entry)
```

| `entry.kind` | Action Taken |
| :--- | :--- |
| `"url"` | Dispatches URL via `SafeRun(entry.target)` |
| `"program"` | Validates `FileExist()` or system PATH, then runs via `SafeRun()` |
| `"folder"` | Launches via `SafeRun("explorer.exe", entry.target)` |
| `"snippet"` | Injects text into active window via `PasteText(entry.target)` |
| `"prompt"` | Copies prompt text to `A_Clipboard` and shows confirmation tooltip |
| `"utility"` | Dispatches command via `SafeRun(entry.target)` or executes `send:` key combo |
| `"setting"` | Opens Windows 11 Settings via `SafeRun(entry.target)` |
| `"script"` | Activates running AHK instance window via `WinActivate("ahk_id " . entry.hwnd)` |

---

### `PasteText(txt)`
Replaces dynamic tokens in text and injects it into the currently active application without clobbering the user's clipboard long-term.

```ahk
PasteText("Created on {DATE} at {TIME} with clip: {CLIPBOARD}")
```

1. **Token Replacement**:
   - `{DATE}` $\rightarrow$ Replaced with current date formatted as `yyyy-MM-dd`.
   - `{TIME}` $\rightarrow$ Replaced with current time formatted as `HH:mm:ss`.
   - `{CLIPBOARD}` $\rightarrow$ Replaced with existing clipboard string.
   - `{ENTER}` $\rightarrow$ Formatted as newline.
2. **Clipboard Backup**: Backs up `A_Clipboard` to `oldClip`.
3. **Clipboard Injection**: Assigns `A_Clipboard := formattedTxt` and awaits readiness with `ClipWait(1)`.
4. **Paste Keystroke**: Sends <kbd>Ctrl</kbd> + <kbd>V</kbd> (`Send("^v")`).
5. **Auto-Restoration**: Sets a one-shot asynchronous timer (`SetTimer(..., -1000)`) to restore `oldClip` after 1 second.

---

## 3. UI & Lifecycle Management (`Modules/Launcher.ahk`)

### `CreateLauncherGui()`
Instantiates the custom dark Fluent GUI window:
- Styles: `+AlwaysOnTop +ToolWindow -Caption`.
- Background color: `0x1A1A1A`.
- Controls:
  - Header title label (`Segoe UI`, `10pt`).
  - Search Edit Box (`0x232323` background, white text).
  - Category ListBox (Width: `170px`, Height: `280px`).
  - Results ListView (Two columns: `"Name"` [220px], `"Category"` [140px]).
  - Footer status hint (`"F3 launch • Shift+F3 search • Enter run • Esc close"`).

### `ShowLauncherGui(searchMode := false)`
Calculates display coordinates beside the current mouse position, enforces screen boundary clamping, and shows the launcher.
- When `searchMode = true`, focuses and clears `SearchBox`.

### `RefreshLauncherResults()`
Filters items in `CurrentEntries` against the currently selected category in `CategoryListBox` and the substring query in `SearchBox`. Updates `ResultsListView` in real time with recursion guard `IsRefreshingLauncher`.

### `IsLauncherActive()`
Context-sensitive `#HotIf` evaluation function that returns true when `LauncherGui` exists and has the active window focus (`WinActive`). Used to bind <kbd>Up</kbd>, <kbd>Down</kbd>, and <kbd>Enter</kbd> locally to the GUI.

---

## 4. JSON Serialization Engine (`Modules/Json.ahk`)

### `class JsonParser`
Pure AutoHotkey v2 recursive-descent JSON parser.
- `ParseValue()`: Dispatches parsing based on character token:
  - `{` $\rightarrow$ `ParseObject()` $\rightarrow$ Returns AHK `Map()`
  - `[` $\rightarrow$ `ParseArray()` $\rightarrow$ Returns AHK `Array()`
  - `"` $\rightarrow$ `ParseString()` (decodes `\n`, `\t`, `\r`, `\"`, `\\`, and `\uXXXX` hex unicode)
  - `t` / `f` $\rightarrow$ `ParseBoolean()`
  - `n` $\rightarrow$ `ParseNull()`
  - `[\d\-.]` $\rightarrow$ `ParseNumber()` $\rightarrow$ Returns `Integer` or `Float`

### `StringifyJson(value, indent := "    ", level := 0)`
Recursively serializes AHK `Map`, `Array`, `String`, `Number`, and `Boolean` values back into formatted, indented JSON strings.

### `LoadJsonFile(path, defaultValue := "")`
Safe file loader that reads UTF-8 content from `path` and parses it via `ParseJson()`. Returns `defaultValue` if the file does not exist or parsing throws an error.

### `SaveJsonFile(path, value)`
Serializes `value` to JSON and writes it to disk via `FileWrite()`.

---

## 5. AutoHotkey IPC & Script Control

Minou can detect and remotely control other running AutoHotkey scripts on the machine using Windows messages:

```ahk
ControlSingleScript(hwnd, action)
ControlAllAHKScripts(action)
```

- **Reload Script**:
  ```ahk
  PostMessage(0x0111, 65303, 0,, "ahk_id " . hwnd) ; WM_COMMAND 65303 = AHK Reload
  ```
- **Suspend Script**:
  ```ahk
  PostMessage(0x0111, 65305, 0,, "ahk_id " . hwnd) ; WM_COMMAND 65305 = AHK Suspend
  ```
- **Kill Script**:
  ```ahk
  WinKill("ahk_id " . hwnd)
  ```

---

## 6. Encoding Utilities

### `UrlEncode(str)`
Converts arbitrary strings into RFC-3986 percent-encoded URL query strings using a UTF-8 memory buffer and hexadecimal character conversion.

### `Base64Encode(str)`
Encodes text strings into Base64 using Windows Crypto API (`Crypt32.dll\CryptBinaryToStringW` with flag `0x40000001` = `CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF`).

---

## 7. Hotstring Manager (`Modules/Hotstrings.ahk`)

### `ShowHotstringManager()`
Instantiates a standalone `+AlwaysOnTop` GUI displaying all saved hotstrings in a Grid `ListView` with checkboxes to enable/disable them.

### `SaveHotstrings()`
Iterates through the `ListView`, determines which hotstrings are checked, packages them into `HotstringData`, and serializes the array to `Config/hotstrings.json`.

### `RegisterHotstrings()`
Turns off previously registered hotstrings and loops through `HotstringData` to dynamically invoke `Hotstring("::trigger", "replacement", "On")` for active entries.
