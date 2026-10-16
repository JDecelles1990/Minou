# Configuration Guide

Minou separates configuration entirely from execution code. All settings, commands, bookmarks, prompts, and snippets are stored as JSON files within the `Config/` folder and loaded into memory at startup.

> **See also:**
> - [01-Architecture.md § 3. Initialization Lifecycle](01-Architecture.md) — how configs are loaded at boot
> - [01-Architecture.md § 5. Global State](01-Architecture.md) — global variables that hold config data
> - [03-Api-And-Helpers.md § LoadJsonFile / SaveJsonFile](03-Api-And-Helpers.md) — the read/write API

---

## 1. Modular Configuration Files (`Config/`)

Rather than maintaining a single monolithic JSON file, Minou splits configuration into focused, domain-specific files:

| File | AHK Global | Type | Responsibility |
| :--- | :--- | :--- | :--- |
| `Config/settings.json` | `SettingsData` | `Map` | User hotkeys, UI dimensions, and active theme |
| `Config/config.json` | `ConfigData` | `Map` | Core applications, directory shortcuts, and desktop utilities |
| `Config/urls.json` | `UrlData` | `Map` | Categorized bookmarks, dashboards, and web links |
| `Config/snippets.json` | `SnippetData` | `Map` | Quick text replacements, email templates, and variable snippets |
| `Config/prompts.json` | `PromptData` | `Array` | LLM prompts categorized by topic (Programming, PowerShell, General) |
| `Config/utilities.json` | `UtilityData` | `Map` | Categorized and subcategorized system, developer, and diagnostics utilities |
| `Config/hotstrings.json` | `HotstringData` | `Array` | Auto-expanding text triggers mapped to replacements (managed via GUI) |

> [!NOTE]
> The root `config.json` is maintained as a legacy monolithic reference. The active modular engine in `Minou.ahk` reads exclusively from the `Config/` directory.

> [!IMPORTANT]
> **Memory-Disk Parity Rule:** Any code that mutates a config value at runtime **must** simultaneously update both the in-memory variable AND call `SaveJsonFile()` to persist to disk. Failure to do so creates config drift between sessions.

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

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `hotkey` | `String` | `"F3"` | Primary trigger — opens launcher at mouse cursor |
| `searchHotkey` | `String` | `"+F3"` | Opens launcher with search box focused and cleared |
| `theme` | `String` | `"dark"` | GUI color scheme (currently only `"dark"` is implemented) |

**AHK hotkey notation:**
- `"F3"` — plain F3 key
- `"+F3"` — Shift+F3 (`+` = Shift)
- `"^F3"` — Ctrl+F3 (`^` = Ctrl)
- `"!F3"` — Alt+F3 (`!` = Alt)
- `"#F3"` — Win+F3 (`#` = Win)

---

### `Config/config.json`

Defines desktop software, directory shortcuts, and system utility commands.

```json
{
  "programs": [
    { "name": "VS Code",          "path": "C:\\Program Files\\Microsoft VS Code\\Code.exe" },
    { "name": "Windows Terminal", "path": "wt.exe" },
    { "name": "PowerShell",       "path": "powershell.exe" }
  ],
  "folders": [
    { "name": "Desktop",       "path": "%USERPROFILE%\\Desktop" },
    { "name": "Documents",     "path": "%USERPROFILE%\\Documents" },
    { "name": "Minou Folder",  "path": "%A_ScriptDir%" }
  ],
  "utilities": [
    { "name": "Calculator",        "cmd": "calc.exe" },
    { "name": "Notepad",           "cmd": "notepad.exe" },
    { "name": "Clipboard History", "cmd": "send:#v" },
    { "name": "Snipping Tool",     "cmd": "send:#+s" }
  ]
}
```

#### Schema: `programs` array items

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display name shown in launcher |
| `path` | `String` | ✅ | Executable path — supports environment variables (see § 3) |

> If `FileExist(path)` returns false, `LaunchItem()` shows `"⚠ Not installed: <name>"` tooltip instead of failing silently.

#### Schema: `folders` array items

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display name shown in launcher |
| `path` | `String` | ✅ | Directory path — supports environment variables |

> Folder paths are expanded via `ExpandEnvVars()` at `BuildMenuEntries()` time, so the resolved absolute path is stored in `entry.target`.

#### Schema: `utilities` array items

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display name shown in launcher |
| `cmd` | `String` | ✅ | Command to execute — supports `send:` prefix for keystrokes |

#### Special Command Formats in Utilities

| Prefix | Behavior | Example |
| :--- | :--- | :--- |
| *(none)* | Launch executable via `SafeRun()` | `"calc.exe"` |
| `send:` | Simulate keyboard shortcut via `Send()` | `"send:#v"` |

**`send:` key notation** (AHK v2 `Send()` syntax):

| Notation | Key | Result |
| :--- | :--- | :--- |
| `send:#v` | Win+V | Windows Clipboard History |
| `send:#+s` | Win+Shift+S | Snipping Tool |
| `send:#+r` | Win+Shift+R | Screen Recorder |
| `send:^c` | Ctrl+C | Copy |
| `send:{PrintScreen}` | Print Screen | Screenshot |

> [!NOTE]
> `send:` commands are dispatched by `LaunchItem()` when `entry.kind = "utility"`. The `send:` prefix is detected and passed through `SafeRun()` which calls `Send()` in the appropriate branch.

---

### `Config/utilities.json`

Houses organized, subcategorized utility groups for system administrators, DevOps, and software developers.

```json
{
  "Network & SysAdmin": {
    "DNS & Connectivity": [
      {
        "name": "Flush DNS Cache",
        "action": "internal",
        "target": "FlushDns",
        "feedback": "DNS Cache Flushed"
      },
      {
        "name": "Renew DHCP Lease",
        "action": "cmd",
        "target": "ipconfig /release && ipconfig /renew",
        "feedback": "Renewing DHCP..."
      }
    ],
    "Ports & Sockets": [
      {
        "name": "Show Listening Ports",
        "action": "internal",
        "target": "ShowListeningPorts"
      }
    ]
  },
  "Developer Tools": {
    "Encoders & Generators": [
      {
        "name": "Generate UUID v4",
        "action": "internal",
        "target": "GenerateGuid"
      },
      {
        "name": "Unix Timestamp (Epoch)",
        "action": "internal",
        "target": "GenerateUnixTimestamp"
      }
    ],
    "Code & Data Formatting": [
      {
        "name": "Beautify Clipboard JSON",
        "action": "internal",
        "target": "BeautifyClipboardJson"
      }
    ]
  }
}
```

#### Schema: Utility Item Objects

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display label shown in launcher |
| `action` | `String` | ✅ | Execution model: `"internal"` (AHK function in `Modules/Utilities.ahk`), `"cmd"` (shell execution), or `"powershell"` |
| `target` | `String` | ✅ | Target function name or command-line string |
| `feedback` | `String` | 🔲 | Optional tooltip message displayed upon completion |

---

### `Config/urls.json`

Maps category names to arrays of URL entries. Ideal for IT dashboards, cybersecurity portals, and search engines.

```json
{
  "Cybersecurity": [
    { "name": "Microsoft Defender XDR", "url": "https://security.microsoft.com" },
    { "name": "VirusTotal",             "url": "https://www.virustotal.com" },
    { "name": "Shodan",                 "url": "https://www.shodan.io" }
  ],
  "Search Engines": [
    { "name": "Google",     "url": "https://www.google.com" },
    { "name": "DuckDuckGo", "url": "https://duckduckgo.com" }
  ],
  "Development": [
    { "name": "GitHub",          "url": "https://github.com" },
    { "name": "AHK v2 Docs",    "url": "https://www.autohotkey.com/docs/v2/" }
  ]
}
```

#### Schema: URL entry object

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display name shown in launcher |
| `url` | `String` | ✅ | Full URL including `https://` protocol |

> The JSON object's **key** (e.g., `"Cybersecurity"`) becomes the `category` field in the unified entry. Each category appears as a distinct item in the `CategoryListBox`.

---

### `Config/snippets.json`

Stores quick text replacements and templates. Supports dynamic token substitutions.

```json
{
  "Text": [
    { "name": "Email Signature", "text": "Kind regards,{ENTER}John Doe{ENTER}{DATE}" },
    { "name": "Timestamp",       "text": "{TIME}" },
    { "name": "Clipboard Wrap",  "text": "--- START ---{ENTER}{CLIPBOARD}{ENTER}--- END ---" }
  ],
  "Code": [
    { "name": "Try Catch Block",  "text": "try {\n    \n} catch Error as err {\n    MsgBox(err.Message)\n}" },
    { "name": "AHK v2 Header",   "text": "#Requires AutoHotkey v2.0\n#SingleInstance Force\nPersistent\n" }
  ]
}
```

#### Schema: snippet entry object

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `name` | `String` | ✅ | Display name shown in launcher |
| `text` | `String` | ✅ | Template text — may contain dynamic tokens |

#### Supported Dynamic Tokens

Tokens are substituted by `PasteText()` in `Minou.ahk` before clipboard injection:

| Token | Replaced With | AHK Expression |
| :--- | :--- | :--- |
| `{DATE}` | Current date: `2026-10-16` | `FormatTime(, "yyyy-MM-dd")` |
| `{TIME}` | Current time: `16:30:00` | `FormatTime(, "HH:mm:ss")` |
| `{CLIPBOARD}` | Current clipboard text | `A_Clipboard` (at moment of paste) |
| `{ENTER}` | Newline character | `` `n `` |

> **Clipboard safety:** `PasteText()` backs up the user's clipboard to `oldClip`, injects the snippet, and restores `oldClip` via a one-shot `SetTimer` after 1 000 ms. The user's clipboard is never permanently overwritten.
>
> For implementation details, see [03-Api-And-Helpers.md § PasteText](03-Api-And-Helpers.md).

#### Planned Additional Tokens (Milestone 3)

| Token | Planned Value |
| :--- | :--- |
| `{Selection}` | Text highlighted before pressing F3 |
| `{ComputerName}` | `A_ComputerName` |
| `{Username}` | `A_UserName` |
| `{Name}` | User-configured display name |

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
  },
  {
    "category": "PowerShell",
    "name": "Write Script",
    "prompt": "Write a PowerShell 7 script that accomplishes the following task. Include error handling, parameter validation, and inline comments.\n\n"
  }
]
```

#### Schema: prompt entry object

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `category` | `String` | ✅ | Used as display category in launcher (shown in CategoryListBox) |
| `name` | `String` | ✅ | Display name shown in launcher |
| `prompt` | `String` | ✅ | Full prompt text copied to clipboard on activation |

> **Activation behavior:** When a prompt entry is selected and launched, `LaunchItem()` runs:
> ```ahk
> A_Clipboard := entry.target   ; entry.target = the "prompt" string
> ToolTip("Prompt copied to clipboard")
> SetTimer((*) => ToolTip(), -1500)
> ```
> No `ClipWait()` or `Send("^v")` — the user manually pastes into their AI tool.

> **Note:** `PromptData` is a flat `Array` (not a `Map`). The `"category"` field is embedded in each object, and `BuildMenuEntries()` uses it as the `category` field in the unified entry.

---

### `Config/hotstrings.json`

Stores definitions for auto-expanding text snippets (hotstrings). This file is automatically managed by the **Hotstring Manager GUI**, accessible from the Minou tray icon. Direct editing is supported but the GUI is preferred.

```json
[
  {
    "active": true,
    "trigger": "btw",
    "replacement": "By the way"
  },
  {
    "active": false,
    "trigger": "brb",
    "replacement": "Be right back"
  },
  {
    "active": true,
    "trigger": "addr",
    "replacement": "123 Main Street, Suite 100, New York, NY 10001"
  }
]
```

#### Schema: hotstring entry object

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `active` | `Boolean` | ✅ | `true` = registered with AHK engine; `false` = disabled |
| `trigger` | `String` | ✅ | Abbreviation to type (e.g., `"btw"`) |
| `replacement` | `String` | ✅ | Text to substitute when trigger + ending char is typed |

> **Registration:** Active hotstrings are registered via `Hotstring("::" . trigger, replacement)` in `ApplyHotstrings()` (`Modules/Hotstrings.ahk`). Typing the trigger followed by a word-ending character (Space, Enter, Tab, punctuation) substitutes the replacement.
>
> For full implementation details, see [03-Api-And-Helpers.md § Hotstring Manager](03-Api-And-Helpers.md).

---

## 3. Environment Variable Expansion

All `path`, `cmd`, and `target` string properties undergo automated environment variable expansion via `ExpandEnvVars()` before launch. You can freely use standard system variables:

| Variable | Expands To | Example |
| :--- | :--- | :--- |
| `%A_ScriptDir%` | Absolute path of the Minou script directory | `C:\LAB\AHK\Minou` |
| `%USERPROFILE%` | Current user's profile root | `C:\Users\Jo` |
| `%TEMP%` | System temporary folder | `C:\Users\Jo\AppData\Local\Temp` |
| `%LOCALAPPDATA%` | Local AppData | `C:\Users\Jo\AppData\Local` |
| `%APPDATA%` | Roaming AppData | `C:\Users\Jo\AppData\Roaming` |
| `%ProgramFiles%` | Primary Program Files directory | `C:\Program Files` |

> **Order note:** `ExpandEnvVars()` checks `%LOCALAPPDATA%` before `%APPDATA%` to prevent partial string replacement (`LOCALAPPDATA` contains the substring `APPDATA`).
>
> For the full implementation, see [03-Api-And-Helpers.md § ExpandEnvVars](03-Api-And-Helpers.md).

---

## 4. Deep System URIs & Special Protocols

Minou's `SafeRun` dispatcher natively supports Windows protocol handlers. These are dispatched via the `ms-settings:` / `shell:` branch in `SafeRun()` using native `Run()`:

### `ms-settings:` — Windows 11 Settings Pages

| URI | Opens |
| :--- | :--- |
| `ms-settings:display` | Display Settings |
| `ms-settings:bluetooth` | Bluetooth & Devices |
| `ms-settings:windowsupdate` | Windows Update |
| `ms-settings:storage` | Storage Management |
| `ms-settings:clipboard` | Clipboard Settings |
| `ms-settings:developers` | Developer Mode |
| `ms-settings:network-wifi` | Wi-Fi Settings |
| `ms-settings:privacy` | Privacy & Security |
| `ms-settings:recovery` | Recovery Options |
| `ms-settings:activation` | Activation |

> These are hardcoded in `BuildMenuEntries()` (`Modules/MenuBuilder.ahk`) under the `"Windows Settings"` category.

### `shell:` — Windows Explorer Virtual Paths

| URI | Opens |
| :--- | :--- |
| `shell:Personal` | Documents folder |
| `shell:Downloads` | Downloads folder |
| `shell:Desktop` | Desktop folder |
| `shell:Programs` | Start Menu — User programs |
| `shell:Common Programs` | Start Menu — All users programs |
| `shell:AppData` | Roaming AppData |
| `shell:Local AppData` | Local AppData |
| `shell:Startup` | User Startup folder |

---

## 5. Configuration at Runtime

### Modifying Config Without Restarting

1. **Edit via Tray**: Right-click Minou tray icon → *Edit config* — opens `Config/config.json` in Notepad
2. **Edit file directly**: Modify any `Config/*.json` file in a text editor
3. **Reload**: Right-click tray → *Reload* — re-runs `LoadConfiguration()` and rebuilds all data

### Programmatic Config Updates (Code Guidelines)

When writing code that modifies configuration at runtime, always update both memory and disk:

```ahk
; Correct — dual update
HotstringData.Push(Map("active", true, "trigger", "eg", "replacement", "for example"))
SaveJsonFile(HotstringFile, HotstringData)

; Wrong — memory only, lost on restart
HotstringData.Push(Map("active", true, "trigger", "eg", "replacement", "for example"))
```

### Config Validation

`LoadJsonFile()` returns a safe `defaultValue` (empty `Map()` or `Array()`) if a file is missing or contains invalid JSON — Minou never crashes on config errors. `LoadConfiguration()` additionally guards against missing top-level keys with:

```ahk
if (!ConfigData.Has("programs"))
    ConfigData["programs"] := []
if (!ConfigData.Has("folders"))
    ConfigData["folders"] := []
if (!ConfigData.Has("utilities"))
    ConfigData["utilities"] := []
```

---

## 6. Cross-References

| Topic | See |
| :--- | :--- |
| How configs are loaded at boot | [01-Architecture.md § 3](01-Architecture.md) |
| Global variables holding config data | [01-Architecture.md § 5](01-Architecture.md) |
| `LoadJsonFile()` / `SaveJsonFile()` API | [03-Api-And-Helpers.md § JSON Engine](03-Api-And-Helpers.md) |
| `ExpandEnvVars()` implementation | [03-Api-And-Helpers.md § ExpandEnvVars](03-Api-And-Helpers.md) |
| `PasteText()` token substitution | [03-Api-And-Helpers.md § PasteText](03-Api-And-Helpers.md) |
| `BuildMenuEntries()` data pipeline | [03-Api-And-Helpers.md § MenuBuilder](03-Api-And-Helpers.md) |
| Planned advanced snippet tokens | [04-Roadmap.md § Milestone 3](04-Roadmap.md) |
| Hotstring Manager GUI | [03-Api-And-Helpers.md § Hotstring Manager](03-Api-And-Helpers.md) |
