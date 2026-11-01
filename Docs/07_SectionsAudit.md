# Sections & Entries Audit

> **Audience:** AI coding agents and maintainers. This is the canonical map of every launcher **section** (category), its **entries** (names) and where each one is stored. Read it before touching `MenuBuilder.ahk`, `EntryEditor.ahk` or any `Config/*.json` file.
>
> Last audited: **2026-11-01** (all entries were tested; results are in the *Test* column and in the verdict table).

## 1. How sections are produced

`BuildMenuEntries()` in `Modules/MenuBuilder.ahk` merges every data source into one flat list of entry objects. The left-hand list of the launcher shows each distinct `category`; the right-hand list shows the entries (second column = category when "All" is selected, **sub-category** otherwise).

| Source (disk) | Memory | Section (category) | Sub-category | Editable in launcher |
| :--- | :--- | :--- | :--- | :---: |
| `Config/urls.json` | `UrlData` | Key of each object (e.g. `Cybersecurity`) | - | Yes (name, category) |
| `Config/config.json` -> `programs` | `ProgramData` | `Programs & Folders` (default) | `Programs` (default) | Yes (name, category, sub-category) |
| `Config/config.json` -> `folders` | `FolderData` | `Programs & Folders` (default) | `Folders` (default) | Yes (name, category, sub-category) |
| `Config/snippets.json` | `SnippetData` | Key of each object (default `Snippets`) | - | Yes (name, category) |
| `Config/prompts.json` | `PromptData` | `Prompts` (fixed) | Item `category` field | Yes (name, sub-category) |
| `Config/utilities.json` | `UtilityData` | Top-level key (`Network & SysAdmin`, `Developer Tools`) | Second-level key | Yes (name, category, sub-category) |
| Hard-coded in `MenuBuilder.ahk` | - | `Windows Settings` | - | No (built-in) |
| Live window scan (`ahk_class AutoHotkey`) | - | `Running Scripts` | - | No (dynamic) |

> [!NOTE]
> `Config/config.json` -> `utilities` (Calculator, Notepad) is a legacy fallback. It is **ignored** whenever `Config/utilities.json` exists and is not editable.

## 2. Verdict per section

**Rule:** a section needs **at least 4 entries**. Smaller sections must be merged into another section or extended (Running Scripts is dynamic and exempt).

| Section | Entries | Verdict |
| :--- | ---: | :--- |
| Cloud Platforms | 8 | Keep |
| Cybersecurity | 12 | Keep |
| Developer Tools | 15 | Keep |
| Documentation | 8 | Keep |
| Finance | 6 | Keep |
| Housing | 6 | Keep |
| Learning | 9 | Keep |
| Network & SysAdmin | 11 | Keep |
| Networking | 8 | Keep |
| Programs & Folders | 15 | Keep - 12 programs + 3 folders |
| Prompts | 25 | Keep - grouped by sub-category |
| Québec & Canada Government | 8 | Keep |
| Remote Support | 5 | Keep |
| Running Scripts | 0 | Keep - dynamic (0..n live scripts), exempt from the minimum |
| Shopping | 6 | Keep |
| Snippets | 6 | Keep - renamed from `Text` (2) and extended with 4 snippets |
| Windows Settings | 6 | Keep |

### 2.1 Section Color Palette & Visual Formatting

Every section is assigned a distinct, high-contrast, WCAG AA compliant color. In `ResultsListView`, both Name and Category/Subcategory text share the parent section's color. In `CategoryListBox`, each section name is rendered in its matching color:

| Section | RGB Hex | BGR (COLORREF) | Accent Description | Contrast vs #232323 |
| :--- | :---: | :---: | :--- | :---: |
| Cloud Platforms | `#4FC3F7` | `0xF7C34F` | Sky Blue | 9.5:1 |
| Cybersecurity | `#FF5252` | `0x5252FF` | Bright Coral | 5.8:1 |
| Developer Tools | `#FFA726` | `0x26A7FF` | Warm Amber | 9.1:1 |
| Documentation | `#CE93D8` | `0xD893CE` | Soft Orchid | 8.0:1 |
| Finance | `#69F0AE` | `0xAEF069` | Mint Emerald | 12.3:1 |
| Housing | `#FFD54F` | `0x4FD5FF` | Golden Yellow | 12.4:1 |
| Learning | `#00E5FF` | `0xFFE500` | Bright Aqua | 11.5:1 |
| Network & SysAdmin | `#B388FF` | `0xFF88B3` | Lavender Purple | 7.3:1 |
| Networking | `#40C4FF` | `0xFFC440` | Vivid Light Blue | 9.7:1 |
| Programs & Folders | `#64FFDA` | `0xDAFF64` | Seafoam Green | 13.3:1 |
| Prompts | `#FF4081` | `0x8140FF` | Hot Pink | 6.0:1 |
| Québec & Canada Government | `#FF7043` | `0x4370FF` | Tangerine Red | 6.8:1 |
| Remote Support | `#1DE9B6` | `0xB6E91D` | Bright Teal | 11.4:1 |
| Running Scripts | `#AEEA00` | `0x00EAAE` | Lime | 11.7:1 |
| Shopping | `#FFAB91` | `0x91ABFF` | Peach | 10.2:1 |
| Snippets | `#76FF03` | `0x03FF76` | Electric Spring Green | 12.5:1 |
| Windows Settings | `#B0BEC5` | `0xC5BEB0` | Slate Ice Blue | 9.5:1 |
| *All / Default* | `#E0E0E0` | `0xE0E0E0` | Silver White | 13.7:1 |

### Audit findings applied on 2026-11-01

| Finding | Action |
| :--- | :--- |
| `Programs` (3), `Folders` (3), `Text` (2) were under the 4-entry minimum | `Programs`+`Folders` merged into **Programs & Folders**; `Text` renamed **Snippets** and extended to 6 |
| Dead links: PacketLife (DNS gone), JuriBistro (domain gone), Microsoft Quick Assist (HTTP 404) | Removed from `Config/urls.json` |
| VS Code path `C:\Program Files\Microsoft VS Code\Code.exe` did not exist | Changed to `%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe` and program paths are now expanded with `ExpandEnvVars()` |
| `Learning` -> *Microsoft Learn* duplicates `Documentation` -> *Microsoft Learn* | Kept (different intent); candidate for cleanup in the roadmap |
| 5 URLs time out on automated requests (Canada.ca x3, BMO, Best Buy Canada) | Kept: bot-protected sites that load in a normal browser |
| `GenerateUnixTimestamp()` called the non-existent `TimeAdd()` and `GetIpSummary()` used the removed `A_IPAddress1` | Fixed (these raised load-time warning dialogs that blocked startup) |
| `ParseNumber()` in `Json.ahk` threw on any numeric JSON value | Fixed with `IsDigit()` (needed for `opacity`) |

## 3. Entries by section

Test legend: **OK** = passed, **Timeout** = no answer to an automated request (bot protection), **Dynamic** = built at runtime.

### Cloud Platforms

Source: `Config/urls.json` -> `Cloud Platforms` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Microsoft Azure | https://portal.azure.com | OK |
| 2 | AWS Console | https://console.aws.amazon.com | OK |
| 3 | Google Cloud Console | https://console.cloud.google.com | OK |
| 4 | Oracle Cloud | https://cloud.oracle.com | OK |
| 5 | Cloudflare Dashboard | https://dash.cloudflare.com | OK |
| 6 | DigitalOcean | https://cloud.digitalocean.com | OK |
| 7 | Linode | https://cloud.linode.com | OK |
| 8 | Vultr | https://my.vultr.com | OK |

### Cybersecurity

Source: `Config/urls.json` -> `Cybersecurity` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Microsoft Defender XDR | https://security.microsoft.com | OK |
| 2 | Microsoft Security Response Center | https://msrc.microsoft.com | OK |
| 3 | VirusTotal | https://www.virustotal.com | OK |
| 4 | Hybrid Analysis | https://www.hybrid-analysis.com | OK |
| 5 | AbuseIPDB | https://www.abuseipdb.com | OK |
| 6 | Cisco Talos | https://talosintelligence.com | OK |
| 7 | Shodan | https://www.shodan.io | OK |
| 8 | URLVoid | https://www.urlvoid.com | OK |
| 9 | Have I Been Pwned | https://haveibeenpwned.com | OK |
| 10 | MITRE ATT&CK | https://attack.mitre.org | OK |
| 11 | NIST | https://www.nist.gov | OK |
| 12 | CISA | https://www.cisa.gov | OK |

### Documentation

Source: `Config/urls.json` -> `Documentation` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Microsoft Learn | https://learn.microsoft.com | OK |
| 2 | PowerShell Documentation | https://learn.microsoft.com/powershell | OK |
| 3 | Microsoft Graph | https://learn.microsoft.com/graph | OK |
| 4 | MDN Web Docs | https://developer.mozilla.org | OK |
| 5 | DevDocs | https://devdocs.io | OK |
| 6 | Read the Docs | https://readthedocs.org | OK |
| 7 | AutoHotkey Docs | https://www.autohotkey.com/docs/v2/ | OK |
| 8 | PowerShell Gallery | https://www.powershellgallery.com | OK |

### Finance

Source: `Config/urls.json` -> `Finance` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Wealthsimple | https://my.wealthsimple.com | OK |
| 2 | Desjardins | https://www.desjardins.com | OK |
| 3 | RBC | https://www.rbcroyalbank.com | OK |
| 4 | BMO | https://www.bmo.com | Timeout (kept) |
| 5 | CIBC | https://www.cibc.com | OK |
| 6 | TD Canada Trust | https://www.td.com | OK |

### Housing

Source: `Config/urls.json` -> `Housing` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Tribunal administratif du logement | https://www.tal.gouv.qc.ca | OK |
| 2 | Éducaloi | https://educaloi.qc.ca | OK |
| 3 | CanLII | https://www.canlii.org | OK |
| 4 | SOQUIJ | https://soquij.qc.ca | OK |
| 5 | Protecteur du citoyen | https://protecteurducitoyen.qc.ca | OK |
| 6 | Commission des droits de la personne | https://www.cdpdj.qc.ca | OK |

### Learning

Source: `Config/urls.json` -> `Learning` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | My Microsoft Learn | https://learn.microsoft.com/en-us/users/JonathanDecelles1990 | OK |
| 2 | Microsoft Learn | https://learn.microsoft.com | OK |
| 3 | LinkedIn Learning | https://www.linkedin.com/learning | OK |
| 4 | freeCodeCamp | https://www.freecodecamp.org | OK |
| 5 | Codecademy | https://www.codecademy.com | OK |
| 6 | Coursera | https://www.coursera.org | OK |
| 7 | Udemy | https://www.udemy.com | OK |
| 8 | W3Schools | https://www.w3schools.com | OK |
| 9 | Professor Messer | https://www.professormesser.com | OK |

### Networking

Source: `Config/urls.json` -> `Networking` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | IPinfo | https://ipinfo.io | OK |
| 2 | WhatIsMyIP | https://whatismyipaddress.com | OK |
| 3 | MXToolbox | https://mxtoolbox.com | OK |
| 4 | DNS Checker | https://dnschecker.org | OK |
| 5 | Speedtest | https://www.speedtest.net | OK |
| 6 | Cloudflare Radar | https://radar.cloudflare.com | OK |
| 7 | BGP.he.net | https://bgp.he.net | OK |
| 8 | Wireshark | https://www.wireshark.org | OK |

### Québec & Canada Government

Source: `Config/urls.json` -> `Québec & Canada Government` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Canada.ca | https://www.canada.ca | Timeout (kept) |
| 2 | Service Canada | https://www.canada.ca/en/employment-social-development/corporate/portfolio/service-canada.html | Timeout (kept) |
| 3 | CRA | https://www.canada.ca/en/revenue-agency.html | Timeout (kept) |
| 4 | Revenu Québec | https://www.revenuquebec.ca | OK |
| 5 | Québec.ca | https://www.quebec.ca | OK |
| 6 | SAAQ | https://saaq.gouv.qc.ca | OK |
| 7 | RAMQ | https://www.ramq.gouv.qc.ca | OK |
| 8 | CNESST | https://www.cnesst.gouv.qc.ca | OK |

### Remote Support

Source: `Config/urls.json` -> `Remote Support` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | AnyDesk | https://my.anydesk.com | OK |
| 2 | TeamViewer | https://web.teamviewer.com | OK |
| 3 | RustDesk | https://rustdesk.com | OK |
| 4 | Chrome Remote Desktop | https://remotedesktop.google.com | OK |
| 5 | Splashtop | https://my.splashtop.com | OK |

### Shopping

Source: `Config/urls.json` -> `Shopping` | Kind: URL | Editable: name, category

| # | Name | URL | Test |
| ---: | :--- | :--- | :--- |
| 1 | Amazon Canada | https://www.amazon.ca | OK |
| 2 | Best Buy Canada | https://www.bestbuy.ca | Timeout (kept) |
| 3 | Newegg Canada | https://www.newegg.ca | OK |
| 4 | Canada Computers | https://www.canadacomputers.com | OK |
| 5 | Memory Express | https://www.memoryexpress.com | OK |
| 6 | Staples Canada | https://www.staples.ca | OK |

### Programs & Folders

Source: `Config/config.json` -> `programs`, `folders` | Kind: program / folder | Editable: name, category, sub-category

| # | Name | Sub-category | Target | Test |
| ---: | :--- | :--- | :--- | :--- |
| 1 | VS Code | Programs | `%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe` | OK (path exists) |
| 2 | PowerShell | Programs | `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` | OK (path exists) |
| 3 | Windows Terminal | Programs | `%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe` | OK (path exists) |
| 4 | Microsoft Edge | Programs | `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` | OK (path exists) |
| 5 | Notepad | Programs | `C:\Program Files\Notepad++\notepad++.exe` | OK (path exists) |
| 6 | Snipping Tool | Programs | `%LOCALAPPDATA%\Microsoft\WindowsApps\SnippingTool.exe` | OK (path exists) |
| 7 | Photos | Programs | `ms-photos:` | OK (URI protocol) |
| 8 | Paint | Programs | `%LOCALAPPDATA%\Microsoft\WindowsApps\mspaint.exe` | OK (path exists) |
| 9 | ChatGPT | Programs | `%LOCALAPPDATA%\Microsoft\WindowsApps\chatgpt-desktop.exe` | OK (path exists) |
| 10 | Antigravity | Programs | `%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe` | OK (path exists) |
| 11 | Word | Programs | `C:\Program Files\Git\mingw64\bin\antiword.exe` | OK (path exists) |
| 12 | Settings | Programs | `C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\ServiceHub\Hosts\ServiceHub.Host.AnyCPU\ServiceHub.SettingsHost.exe` | OK (path exists) |
| 13 | Desktop | Folders | `%USERPROFILE%\Desktop` | OK (path exists) |
| 14 | Documents | Folders | `%USERPROFILE%\Documents` | OK (path exists) |
| 15 | Minou Folder | Folders | `%A_ScriptDir%` | OK (path exists) |

### Snippets

Source: `Config/snippets.json` -> `Snippets` | Kind: snippet | Editable: name, category | Tokens: `{DATE}` `{TIME}` `{CLIPBOARD}` `{ENTER}`

| # | Name | Text | Test |
| ---: | :--- | :--- | :--- |
| 1 | Email Signature | `Kind regards,{ENTER}{DATE}` | OK |
| 2 | Timestamp | `{TIME}` | OK |
| 3 | ISO Date | `{DATE}` | OK |
| 4 | Date & Time | `{DATE} {TIME}` | OK |
| 5 | Email Greeting | `Hello,{ENTER}{ENTER}Thank you for reaching out.{ENTER}{ENTER}` | OK |
| 6 | Ticket Note Template | `Ticket update - {DATE} {TIME}{ENTER}Issue: {ENTER}Troubleshooting performed: {ENTER}Resolution / next steps: {ENTER}` | OK |

### Prompts

Source: `Config/prompts.json` | Kind: prompt (copied to clipboard) | Editable: name, sub-category

| # | Name | Sub-category | Test |
| ---: | :--- | :--- | :--- |
| 1 | Summarize | General | OK |
| 2 | Explain Simply | General | OK |
| 3 | Improve Writing | General | OK |
| 4 | Translate | General | OK |
| 5 | Debug Code | Programming | OK |
| 6 | Explain Code | Programming | OK |
| 7 | Refactor Code | Programming | OK |
| 8 | PowerShell Script | PowerShell | OK |
| 9 | PowerShell Troubleshooting | PowerShell | OK |
| 10 | AHK v2 Script | AutoHotkey | OK |
| 11 | Optimize AHK | AutoHotkey | OK |
| 12 | Troubleshooting Workflow | Helpdesk | OK |
| 13 | Ticket Notes | Helpdesk | OK |
| 14 | M365 Admin | Microsoft 365 | OK |
| 15 | Network Troubleshooting | Networking | OK |
| 16 | Security Analysis | Cybersecurity | OK |
| 17 | Research Assistant | Research | OK |
| 18 | Improve Prompt | Prompt Engineering | OK |
| 19 | Professional Email | Documents | OK |
| 20 | Excel Formula | Excel | OK |
| 21 | Validate JSON | JSON | OK |
| 22 | Markdown Formatter | Markdown | OK |
| 23 | Study Guide | Learning | OK |
| 24 | Mock Interview | Interview | OK |
| 25 | Generate Ideas | Brainstorming | OK |

### Network & SysAdmin

Source: `Config/utilities.json` -> `Network & SysAdmin` | Kind: utility | Editable: name, category, sub-category

| # | Name | Sub-category | Action | Target | Test |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | Flush DNS Cache | DNS & Connectivity | internal | `FlushDns` | OK (function defined + dispatched) |
| 2 | Renew DHCP Lease | DNS & Connectivity | cmd | `ipconfig /release && ipconfig /renew` | OK (`ipconfig` found) |
| 3 | Ping Gateway & DNS | DNS & Connectivity | internal | `PingGatewayAndDns` | OK (function defined + dispatched) |
| 4 | Copy Local & Public IP | DNS & Connectivity | internal | `GetIpSummary` | OK (function defined + dispatched) |
| 5 | Show Listening Ports | Ports & Sockets | internal | `ShowListeningPorts` | OK (function defined + dispatched) |
| 6 | Inspect Dev Ports (3000, 8080) | Ports & Sockets | internal | `InspectDevPorts` | OK (function defined + dispatched) |
| 7 | Restart WSL2 Network | Ports & Sockets | cmd | `wsl.exe --shutdown` | OK (`wsl.exe` found) |
| 8 | Restart Windows Explorer | Service & Shell Recovery | internal | `RestartExplorer` | OK (function defined + dispatched) |
| 9 | Restart Audio Engine | Service & Shell Recovery | cmd | `net stop audiosrv & net start audiosrv` | OK (`net` found) |
| 10 | Kill Unresponsive Apps | Service & Shell Recovery | cmd | `taskkill /f /fi "status eq not responding"` | OK (`taskkill` found) |
| 11 | Purge %TEMP% Files | Service & Shell Recovery | internal | `PurgeTempFiles` | OK (function defined + dispatched) |

### Developer Tools

Source: `Config/utilities.json` -> `Developer Tools` | Kind: utility | Editable: name, category, sub-category

| # | Name | Sub-category | Action | Target | Test |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | Generate UUID v4 | Encoders & Generators | internal | `GenerateGuid` | OK (function defined + dispatched) |
| 2 | Unix Timestamp (Epoch) | Encoders & Generators | internal | `GenerateUnixTimestamp` | OK (function defined + dispatched) |
| 3 | URL Encode Clipboard | Encoders & Generators | internal | `UrlEncodeClipboard` | OK (function defined + dispatched) |
| 4 | URL Decode Clipboard | Encoders & Generators | internal | `UrlDecodeClipboard` | OK (function defined + dispatched) |
| 5 | Base64 Encode Clipboard | Encoders & Generators | internal | `Base64EncodeClipboard` | OK (function defined + dispatched) |
| 6 | Base64 Decode Clipboard | Encoders & Generators | internal | `Base64DecodeClipboard` | OK (function defined + dispatched) |
| 7 | SHA-256 Checksum | Encoders & Generators | internal | `GenerateSha256Clipboard` | OK (function defined + dispatched) |
| 8 | Beautify Clipboard JSON | Code & Data Formatting | internal | `BeautifyClipboardJson` | OK (function defined + dispatched) |
| 9 | Minify Clipboard JSON | Code & Data Formatting | internal | `MinifyClipboardJson` | OK (function defined + dispatched) |
| 10 | Escape Code String | Code & Data Formatting | internal | `EscapeClipboardString` | OK (function defined + dispatched) |
| 11 | Capitalize SQL Keywords | Code & Data Formatting | internal | `CapitalizeSqlKeywords` | OK (function defined + dispatched) |
| 12 | Open Terminal at Active Folder | Git & Environment | internal | `OpenTerminalAtActiveExplorer` | OK (function defined + dispatched) |
| 13 | Git Status at Active Folder | Git & Environment | internal | `GitStatusAtActiveExplorer` | OK (function defined + dispatched) |
| 14 | Inspect & Split %PATH% | Git & Environment | internal | `InspectPathEnvironment` | OK (function defined + dispatched) |
| 15 | Toggle Hidden Files & Extensions | Git & Environment | internal | `ToggleExplorerHiddenAndExt` | OK (function defined + dispatched) |

### Windows Settings

Source: hard-coded in `MenuBuilder.ahk` | Kind: setting (`ms-settings:` URI) | Editable: no

| # | Name | Target | Test |
| ---: | :--- | :--- | :--- |
| 1 | Display | `ms-settings:display` | OK |
| 2 | Bluetooth | `ms-settings:bluetooth` | OK |
| 3 | Windows Update | `ms-settings:windowsupdate` | OK |
| 4 | Storage | `ms-settings:storage` | OK |
| 5 | Clipboard | `ms-settings:clipboard` | OK |
| 6 | Developer Mode | `ms-settings:developers` | OK |

### Running Scripts

Source: live scan of `ahk_class AutoHotkey` windows | Kind: script (activates the script window) | Editable: no | Test: Dynamic

## 4. Maintenance checklist for agents

1. After adding/removing/renaming a section or entry, regenerate or edit this file in the **same turn** (AGENTS.md, Phase 4).
2. Keep every section at **4 or more entries**; merge or extend otherwise.
3. Re-test links (HTTP status), program/folder paths and internal utility targets before listing them here.
4. Internal utility `target` values must exist as a function in `Modules/Utilities.ahk` **and** as a `case` in `DispatchInternalUtility()`.
