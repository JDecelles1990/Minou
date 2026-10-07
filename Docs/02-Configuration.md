# Configuration Guide

Minou separates configuration entirely from execution code. All settings, commands, bookmarks, prompts, and snippets are stored as JSON files within the `Config/` folder.

---

## 1. Modular Configuration Files (`Config/`)

Rather than maintaining a single monolithic JSON file, Minou splits configuration into focused, domain-specific files:

| File | Structure | Responsibility |
| :--- | :--- | :--- |
| `Config/settings.json` | `Object` | User hotkeys, UI dimensions, and active theme |
| `Config/config.json` | `Object` | Core applications, directory shortcuts, and desktop utilities |
| `Config/urls.json` | `Object (Map)` | Categorized bookmarks, dashboards, and web links |
| `Config/snippets.json` | `Object (Map)` | Quick text replacements, email templates, and variable snippets |
| `Config/prompts.json` | `Array` | LLM prompts categorized by topic (Programming, PowerShell, General) |
| `Config/hotstrings.json` | `Array` | Auto-expanding text triggers mapped to replacements (managed via GUI) |

> [!NOTE]
> The root `config.json` is maintained as a legacy monolithic reference. The active modular engine in `Minou.ahk` reads directly from the `Config/` directory.

---

## 2. File Schemas & Examples

### `Config/settings.json`
Controls global trigger hotkeys and interface presentation.
```json
{
  "hotkey": "F3",
  "searchHotkey": "+F3",
  "theme": "dark"
}
```
- `hotkey`: The primary trigger hotkey to open the launcher at the mouse cursor.
- `searchHotkey`: Directly opens the launcher with the search box focused and cleared.
- `theme`: GUI color scheme (currently `"dark"`).

---

### `Config/config.json`
Defines desktop software, directory shortcuts, and system utility commands.

```json
{
  "programs": [
    { "name": "VS Code", "path": "C:\\Program Files\\Microsoft VS Code\\Code.exe" },
    { "name": "Windows Terminal", "path": "wt.exe" },
    { "name": "PowerShell", "path": "powershell.exe" }
  ],
  "folders": [
    { "name": "Desktop", "path": "%USERPROFILE%\\Desktop" },
    { "name": "Documents", "path": "%USERPROFILE%\\Documents" },
    { "name": "Minou Folder", "path": "%A_ScriptDir%" }
  ],
  "utilities": [
    { "name": "Calculator", "cmd": "calc.exe" },
    { "name": "Notepad", "cmd": "notepad.exe" },
    { "name": "Clipboard History", "cmd": "send:#v" },
    { "name": "Snipping Tool", "cmd": "send:#+s" }
  ]
}
```

#### Special Command Formats in Utilities
- **Executable Launch**: `"cmd": "calc.exe"` or `"cmd": "C:\\Path\\To\\App.exe"`.
- **Keystroke Simulation (`send:`)**: Prefix with `send:` to simulate Windows keyboard shortcuts without launching an EXE.
  - `send:#v` $\rightarrow$ Simulates <kbd>Win</kbd> + <kbd>V</kbd> (Windows Clipboard History).
  - `send:#+s` $\rightarrow$ Simulates <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> (Snipping Tool).
  - `send:#+r` $\rightarrow$ Simulates <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> (Screen Recorder).

---

### `Config/urls.json`
Maps category names to arrays of URL entries. Ideal for IT dashboards, cybersecurity portals, and search engines.

```json
{
  "Cybersecurity": [
    { "name": "Microsoft Defender XDR", "url": "https://security.microsoft.com" },
    { "name": "VirusTotal", "url": "https://www.virustotal.com" },
    { "name": "Shodan", "url": "https://www.shodan.io" }
  ],
  "Search Engines": [
    { "name": "Google", "url": "https://www.google.com" },
    { "name": "DuckDuckGo", "url": "https://duckduckgo.com" }
  ]
}
```

---

### `Config/snippets.json`
Stores quick text replacements and templates. Supports dynamic token substitutions.

```json
{
  "Text": [
    { "name": "Email Signature", "text": "Kind regards,{ENTER}John Doe{ENTER}{DATE}" },
    { "name": "Timestamp", "text": "{TIME}" }
  ],
  "Code": [
    { "name": "Try Catch Block", "text": "try {\n    // Code\n} catch Error as err {\n    MsgBox(err.Message)\n}" }
  ]
}
```

#### Supported Snippet Dynamic Tokens
- `{DATE}` $\rightarrow$ Current date in format `YYYY-MM-DD`.
- `{TIME}` $\rightarrow$ Current time in format `HH:mm:ss`.
- `{CLIPBOARD}` $\rightarrow$ Content currently stored on the system clipboard.
- `{ENTER}` $\rightarrow$ Simulates a newline/Enter keystroke.

---

### `Config/prompts.json`
Stores LLM prompts for fast insertion into generative AI web tools or desktop clients.

```json
[
  {
    "category": "Programming",
    "name": "Debug Code",
    "prompt": "Analyze the following code for syntax errors, logic bugs, edge cases, security issues, and performance improvements. Explain each issue step by step and provide corrected code.\n\n"
  },
  {
    "category": "General",
    "name": "Summarize",
    "prompt": "Summarize the following text into concise bullet points with clear headings, key takeaways, and action items.\n\n"
  }
]
```

When activated, Minou writes the prompt directly to the clipboard and shows a non-blocking confirmation tooltip, allowing instant pasting (<kbd>Ctrl</kbd> + <kbd>V</kbd>) into any active LLM prompt box.

---

### `Config/hotstrings.json`
Stores definitions for auto-expanding text snippets (hotstrings). This file is automatically managed by the **Hotstring Manager GUI**, accessible from the Minou Tray icon.

```json
[
  {
    "active": true,
    "replacement": "By the way",
    "trigger": "btw"
  },
  {
    "active": false,
    "replacement": "Be right back",
    "trigger": "brb"
  }
]
```

When a hotstring is `active`, typing the `trigger` text followed by an ending character (like Space or Enter) will automatically replace it with the `replacement` text in any Windows application.

---

## 3. Environment Variable Expansion

All path properties (`path`, `cmd`, `target`) undergo automated environment variable expansion before launch. You can freely use standard system variables:

| Variable | Expands To |
| :--- | :--- |
| `%A_ScriptDir%` | Absolute path of the Minou script directory |
| `%USERPROFILE%` | `C:\Users\<Username>` |
| `%TEMP%` | System temporary folder |
| `%LOCALAPPDATA%` | `C:\Users\<Username>\AppData\Local` |
| `%APPDATA%` | `C:\Users\<Username>\AppData\Roaming` |
| `%ProgramFiles%` | `C:\Program Files` |

---

## 4. Deep System URIs & Special Protocols

Minou's `SafeRun` dispatcher natively supports Windows protocol handlers:
- **`ms-settings:` URIs**: Direct links to Windows 11 Settings pages:
  - `ms-settings:display` (Display Settings)
  - `ms-settings:bluetooth` (Bluetooth & Devices)
  - `ms-settings:windowsupdate` (Windows Update)
  - `ms-settings:storage` (Storage Management)
  - `ms-settings:developers` (Developer Mode)
- **`shell:` URIs**: Direct Windows Explorer virtual paths:
  - `shell:Personal` (Documents)
  - `shell:Downloads` (Downloads)
  - `shell:Desktop` (Desktop)
  - `shell:Programs` (Start Menu User Programs)
  - `shell:Common Programs` (All Users Start Menu)
