I want to use AutoHotKey v.2 to use the 'F3' \& 'Shift + F3' hotkey so a (dark style) menu with submenus pop up near the mouse cursor in this PATH:



**C:\\Users\\Jo\\OneDrive\\Desktop\\LAB\\AHK\\Minou**





**## Project: Minou PoPup**



**A Windows 11 Fluent-style launcher built in \*\*AutoHotkey v2\*\*.**



**### Core requirements**



**1. F3 opens launcher beside mouse cursor.**

**2. Shift+F3 opens search mode.**

**3. Dark acrylic UI.**

**4. Keyboard driven.**

**5. Mouse friendly.**

**6. External JSON configuration.**

**7. Portable.**

**8. Plugin architecture.**

**9. Live reload.**

**10. Dynamic menus.**



**---**



**## Architecture**



**```**

**Minou\\**

**│**

**├── Minou.ahk**

**├── Config\\**

**│      config.json**

**│      urls.json**

**│      snippets.json**

**│      prompts.json**

**│      settings.json**

**│**

**├── Modules\\**

**│      MenuBuilder.ahk**

**│      Search.ahk**

**│      Launcher.ahk**

**│      Icons.ahk**

**│      Json.ahk**

**│      Settings.ahk**

**│      Utilities.ahk**

**│      WindowManager.ahk**

**│      Snippets.ahk**

**│      Prompts.ahk**

**│**

**├── Cache\\**

**│      icons.db**

**│      recent.json**

**│**

**├── Plugins\\**

**│**

**└── Assets\\**

&#x20;     **Icons\\**

**```**



**---**



**## Replace the standard AHK Menu object**



**Use a custom GUI.**



**Reasons:**



**\* smooth scrolling**

**\* dark theme**

**\* Fluent styling**

**\* search box**

**\* icons**

**\* keyboard navigation**

**\* live filtering**

**\* expandable tree**



**---**



**## Dynamic detection**



**Instead of hardcoding:**



**```**

**VS Code**

**Chrome**

**Everything**

**Cursor**

**```**



**Automatically detect using**



**\* Registry**



**```**

**HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths**

**```**



**and**



**```**

**Uninstall keys**

**```**



**Also detect**



**\* Start Menu shortcuts**



**```**

**shell:Programs**

**shell:Common Programs**

**```**



**---**



**## Validate URLs**



**The current config contains several entries that will commonly fail because they assume local services or executable names.**



**Examples:**



**\* Ollama Dashboard**

**\* OpenWebUI**

**\* Continue**

**\* GPT4All**

**\* AnythingLLM**



**Those should support**



**```**

**Executable**



**OR**



**URL**



**OR**



**Both**

**```**



**If unavailable:**



**Show**



**⚠ Not Installed**



**instead of throwing an error.**



**---**



**## Smarter launching**



**Instead of**



**```**

**Run "cursor.exe"**

**```**



**Search**



**```**

**PATH**



**Registry**



**Start Menu**



**Winget**



**Scoop**



**Chocolatey**

**```**



**---**



**## Running Scripts**



**Detect**



**```**

**AutoHotkey.exe**



**AutoHotkey64.exe**



**AutoHotkey32.exe**

**```**



**List**



**\* script name**

**\* memory usage**

**\* PID**



**Allow**



**\* Reload**

**\* Suspend**

**\* Exit**

**\* Restart**



**---**



**## Windows Settings**



**Expand to the complete Windows 11 URI catalog.**



**Include**



**\* Bluetooth**

**\* Windows Update**

**\* Storage**

**\* Clipboard**

**\* Optional Features**

**\* Recovery**

**\* Activation**

**\* Nearby Sharing**

**\* Remote Desktop**

**\* Developer Mode**



**---**



**## Search**



**Instead of searching one menu:**



**Search everything.**



**```**

**Programs**



**Folders**



**URLs**



**PowerShell**



**Prompts**



**Snippets**



**Utilities**



**Windows Settings**

**```**



**Fuzzy search.**



**Example**



**Typing**



**```**

**pow**

**```**



**returns**



**```**

**PowerShell**



**PowerToys**



**PowerShell snippets**



**Prompt Engineering**



**PowerShell 7**

**```**



**---**



**## Snippet Engine**



**Instead of storing text directly,**



**Support variables.**



**Example**



**```**

**{Name}**



**{Date}**



**{Time}**



**{Clipboard}**



**{Selection}**



**{ComputerName}**



**{Username}**

**```**



**---**



**## Prompt Library**



**Each prompt stored as Markdown.**



**```**

**Prompts/**



**PowerShell.md**



**Python.md**



**Debug.md**



**Networking.md**



**Azure.md**



**Helpdesk.md**

**```**



**Searchable.**



**Preview before copy.**



**---**



**## Clipboard Manager**



**History**



**Favorites**



**Pinned**



**Search**



**Delete**



**Preview**



**---**



**## Better JSON**



**Instead of one giant config,**



**Split into**



**```**

**settings.json**



**urls.json**



**apps.json**



**folders.json**



**powershell.json**



**snippets.json**



**prompts.json**



**utilities.json**

**```**



**Much easier to maintain.**



**---**



**## Plugins**



**Allow drop-in plugins.**



**Example**



**```**

**Plugins/**



**VSCode**



**GitHub**



**PowerShell**



**Everything**



**Obsidian**



**Notion**

**```**



**Each plugin provides**



**\* menu entries**

**\* icons**

**\* actions**



**---**



**## Diagnostics**



**New page**



**```**

**Diagnostics**

**```**



**Checks**



**✔ Missing executables**



**✔ Broken URLs**



**✔ Invalid JSON**



**✔ Duplicate shortcuts**



**✔ Missing icons**



**✔ Missing folders**



**✔ Startup time**



**✔ Memory usage**



**---**



**## Automatic icon extraction**



**Icons should come from**



**\* executable**

**\* URL favicon**

**\* shell icons**



**Cached locally.**



**---**



**## Future integrations**



**\* Everything SDK**

**\* PowerToys Command Palette**

**\* Windows Search**

**\* Winget**

**\* Ollama**

**\* LM Studio**

**\* MCP servers**

**\* ChatGPT**

**\* Claude**

**\* Gemini**

**\* Perplexity**

**\* Copilot**

**\* AutoHotkey Hub**



**### My assessment of your current project**



**Based on the uploaded `config.json`, the concept is excellent, but it looks like an early proof of concept rather than a production launcher.** 



**The biggest improvements would be:**



**1. Replace the built-in AHK `Menu` with a custom Fluent GUI.**

**2. Eliminate hardcoded executable paths by auto-discovering installed applications.**

**3. Split the configuration into multiple JSON files.**

**4. Add a validation engine that detects broken apps, URLs, and folders before displaying the menu.**

**5. Make the launcher extensible with plugins so you never have to edit the core script again.**



**I think this could become something comparable to a lightweight, highly customizable Windows launcher specifically tailored for IT professionals.**



**\*\*Yes/No:\*\* Would you like to evolve this into a polished open-source project with a professional architecture, documentation, installer, and GitHub repository structure?**











\----



High-Level Design

Hotkey: F3

Behavior:

&#x09;• Show menu at mouse cursor position.

&#x09;• Modern dark theme by default.

&#x09;• Configurable light/dark toggle.

&#x09;• Icons for menu items where possible.

&#x09;• Tooltips for some entries.

&#x09;• Search/filter mode (optional enhancement).

&#x09;• Auto-refresh dynamic menus (running scripts, open windows, etc.).

Main Menu Structure

F2 Menu

│

├─ 🌐 URLs

├─ 🤖 AI Tools

├─ 🚀 Programs

├─ 📜 Running Scripts

├─ 📁 Folders

├─ ✂ Text Shortcuts

├─ ⌨ Autofill Text

├─ 🪟 Windows Settings

├─ 💻 PowerShell

├─ 📋 LLM Prompts

├─ 🧰 Utilities

├─ ⚙ Edit \& Settings

└─ ❌ Exit Menu



1\. URLs Submenu

URLs

│

├─ Search Engines

│  ├─ Google

│  ├─ Bing

│  ├─ DuckDuckGo

│

├─ Microsoft

│  ├─ Copilot

│  ├─ Outlook

│  ├─ OneDrive

│

├─ Development

│  ├─ GitHub

│  ├─ Stack Overflow

│  ├─ MDN

│

├─ Productivity

│  ├─ Notion

│  ├─ Trello

│  ├─ Airtable

│

├─ Media

│  ├─ YouTube

│  ├─ Spotify

│

└─ User Custom URLs



2\. AI Tools Submenu

Web LLMs

AI Hyperlinks

│

├─ ChatGPT

├─ Microsoft Copilot

├─ Claude

├─ Gemini

├─ Grok

├─ Perplexity

├─ Poe

├─ Mistral

├─ DeepSeek

└─ OpenRouter



AI Desktop Apps

AI PC Apps

│

├─ LM Studio

├─ Ollama Dashboard

├─ GPT4All

├─ AnythingLLM

├─ Jan AI

├─ OpenWebUI

├─ Continue

└─ Cursor



3\. Launch Programs

Programs

│

├─ File Explorer

├─ Windows Terminal

├─ PowerShell

├─ VS Code

├─ Notepad++

├─ Obsidian

├─ Chrome

├─ Edge

├─ Firefox

├─ Everything

├─ ShareX

├─ Paint.NET

└─ User Defined Apps



Support:

Programs := \[

&#x20; {Name:"VS Code", Path:"C:\\Program Files\\Microsoft VS Code\\Code.exe"}

]



4\. Running Scripts

Dynamic submenu:

Running Scripts

│

├─ Script1.ahk

├─ Script2.ahk

├─ Script3.ahk

│

├─ Reload All

├─ Suspend All

└─ Kill Script...



Should automatically detect:

AutoHotkey.exe windows

AutoHotkey64.exe windows



5\. Folder Paths

Folders

│

├─ Documents

├─ Downloads

├─ Desktop

├─ Pictures

├─ Videos

├─ Music

├─ OneDrive

├─ Projects

├─ AI

├─ Scripts

├─ Temp

└─ Network Locations



Each item opens Explorer.

6\. Text Shortcuts

Text Shortcuts

│

├─ Email Address

├─ Full Name

├─ Address

├─ Phone Number

├─ Signature

├─ Today's Date

├─ Timestamp

└─ Custom Snippets



Clicking inserts text into active window.

7\. Autofill Text

Autofill

│

├─ Common Responses

├─ Support Templates

├─ Meeting Notes

├─ Coding Templates

├─ SQL Templates

├─ Markdown Templates

└─ Clipboard Templates



Example:

Kind Regards,

John Smith



Automatically pasted.

8\. Windows 11 Settings

Windows Settings

│

├─ System

│  ├─ Display

│  ├─ Sound

│  ├─ Notifications

│

├─ Personalization

│  ├─ Themes

│  ├─ Colors

│

├─ Apps

│

├─ Gaming

│

├─ Privacy

│

├─ Network

│

└─ Advanced



Using:

ms-settings:



URIs.

Examples:

ms-settings:display

ms-settings:colors

ms-settings:sound



9\. PowerShell Snippets

Copy selected snippet to clipboard.

PowerShell

│

├─ Get Processes

├─ Running Services

├─ Network Info

├─ IP Config

├─ Installed Apps

├─ Event Log Query

├─ Restart Explorer

├─ File Search

├─ Kill Process

└─ User Snippets



Example:

Get-Process | Sort CPU -Descending



10\. LLM Prompt Library

LLM Prompts

│

├─ Programming

├─ Writing

├─ Research

├─ Summarization

├─ Translation

├─ Excel

├─ PowerShell

├─ AutoHotkey

├─ Debugging

└─ Prompt Engineering



Examples:

Debug Code

Analyze this code and identify bugs,

performance issues and improvements.



Summarize

Summarize the following text into concise bullet points.



Copies prompt to clipboard.

11\. Utilities

Utilities

│

├─ Clipboard History

├─ Character Map

├─ Calculator

├─ Screenshot

├─ Screen Recorder

├─ Color Picker

├─ OCR Image

├─ QR Generator

├─ URL Encoder

├─ Base64 Encode

└─ Timestamp Generator



12\. Edit \& Settings

Edit \& Settings

│

├─ Edit This Script

├─ Reload Script

├─ Restart Script

├─ Open Config File

├─ Export Settings

├─ Import Settings

│

├─ Theme

│  ├─ Dark

│  ├─ Light

│  ├─ OLED Black

│

├─ Menu Font Size

│

├─ Menu Width

│

├─ Enable Icons

│

└─ Refresh Dynamic Menus



Advanced Features to Ask Copilot Tasks For

&#x09;1. AHK v2 Compatible

&#x09;2. Single-file architecture with external JSON config

&#x09;3. Dark theme GUI menu instead of standard Menu object

&#x09;4. Multi-monitor support

&#x09;5. Display next to current cursor

&#x09;6. Keyboard navigation

&#x09;7. Search box at top of menu

&#x09;8. Favorites section

&#x09;9. Recent items tracking

&#x09;10. Pinned URLs

&#x09;11. Tray icon integration

&#x09;12. Portable mode

&#x09;13. Configurable hotkey

&#x09;14. Icons beside menu entries

&#x09;15. Persistent settings in JSON

&#x09;16. Live reload without restart

&#x09;17. Dynamic generation of running AHK scripts

&#x09;18. Dynamic generation of installed applications

&#x09;19. Category collapse/expand support

&#x09;20. Windows 11 Fluent Design style dark theme

