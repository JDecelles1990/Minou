# Development Roadmap & Feature Specifications

This document outlines the planned architectural milestones and future feature roadmap for Minou, synthesizing specifications from `Instructions 2 Minou F3 PCPaths.md`.

---

## Milestone 1: Modular Migration Completion

The core modular framework is established in `Minou.ahk`, `Modules/Json.ahk`, `Modules/Launcher.ahk`, and `Modules/MenuBuilder.ahk`. The next step is populating the remaining module stubs in `Modules/`:

- [ ] **`Modules/Search.ahk`**: Implement a fuzzy search and multi-token ranking algorithm across all item types (Commands, URLs, Folders, Prompts, Snippets, Windows Settings).
- [ ] **`Modules/Icons.ahk`**: Automatic icon extraction from `.exe` resources, shell icons, and website favicons, caching them to `Cache/icons.db`.
- [ ] **`Modules/Settings.ahk`**: Interactive settings UI, runtime hotkey rebound, and live theme customization.
- [ ] **`Modules/Snippets.ahk`**: Dedicated token parsing engine supporting advanced dynamic placeholders.
- [ ] **`Modules/Prompts.ahk`**: Prompt indexing, markdown file loader, and template parameter injector.
- [ ] **`Modules/Utilities.ahk`**: Encoders (Base64, URL), character maps, quick converters, and system automation tools.
- [ ] **`Modules/WindowManager.ahk`**: Multi-monitor DPI awareness, mouse cursor boundary detection, and window placement logic.

---

## Milestone 2: Dynamic Detection & Smart Launching

Eliminate hardcoded application paths by discovering installed software automatically at runtime:

### 1. Multi-Source Discovery Engine
- **Windows Registry App Paths**:
  ```
  HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths
  HKCU\Software\Microsoft\Windows\CurrentVersion\App Paths
  ```
- **Windows Uninstall Keys**:
  ```
  HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall
  HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
  HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall
  ```
- **Start Menu Shortcuts**:
  - `shell:Programs` (Per-user shortcuts)
  - `shell:Common Programs` (System-wide shortcuts)
- **Package Manager Paths**: Auto-detect CLI and GUI binaries managed by Winget, Scoop (`%USERPROFILE%\scoop\shims`), and Chocolatey (`%ProgramData%\chocolatey\bin`).

### 2. Validation & Graceful Fallback
- Prevent launch failures for hybrid AI tools (e.g., Ollama, OpenWebUI, Continue, GPT4All, AnythingLLM) that can run as either a local desktop executable, a web URL (`http://localhost:11434`), or both.
- If an application is not found locally, display a subtle visual indicator:
  ```
  ⚠ Not Installed
  ```
  rather than throwing a blocking error or terminating the launcher.

---

## Milestone 3: Advanced Snippet & Prompt Engines

### 1. Expanded Snippet Tokens
Enhance `PasteText()` in `Modules/Snippets.ahk` with context-aware variables:
- `{Date}` / `{Time}`: Formatted timestamps.
- `{Clipboard}`: Current clipboard text.
- `{Selection}`: Text highlighted by the user prior to pressing <kbd>F3</kbd>.
- `{ComputerName}`: Local machine hostname.
- `{Username}`: Active Windows user profile name.
- `{Name}`: Prompted or user-configured display name.

### 2. File-Based Markdown Prompt Library
Transition prompts from JSON strings to individual Markdown documents inside a dedicated `Prompts/` directory:
```
Prompts/
├── PowerShell.md
├── Python.md
├── Debug.md
├── Networking.md
├── Azure.md
└── Helpdesk.md
```
- Provide an integrated preview pane in the launcher to review prompt contents before copying or inserting.

---

## Milestone 4: Clipboard Manager & Caching

Implement an IT-centric clipboard history module:
- **History Tracking**: Maintain an indexed history of recent text and image clips.
- **Favorites & Pinned Items**: Pin frequent scripts, SQL queries, or email responses to prevent eviction.
- **Search & Filter**: Search clipboard history directly within the unified <kbd>Shift</kbd> + <kbd>F3</kbd> search view.
- **Cache Persistence**: Store metadata in `Cache/recent.json` for fast session restoration.

---

## Milestone 5: Drop-In Plugin Architecture

Enable extending Minou without modifying core script code:
```
Plugins/
├── VSCode/
│   ├── plugin.json
│   └── actions.ahk
├── Everything/
├── GitHub/
└── Obsidian/
```
Each plugin provides:
- Custom menu entries and categories.
- Associated icons and shortcut handlers.
- Isolated action hooks.

---

## Milestone 6: Built-In System Diagnostics

Add a self-testing diagnostic tool to monitor health and performance:
- [ ] Scan for missing executable paths.
- [ ] Validate HTTP status codes for web bookmarks.
- [ ] Lint all JSON configuration files for syntax correctness.
- [ ] Flag duplicate hotkeys or keyboard shortcuts.
- [ ] Report launcher startup time (ms) and RAM footprint (MB).

---

## Milestone 7: External Ecosystem Integrations

- **Everything Search SDK**: Sub-second full-disk file search integration directly from the Minou search box.
- **PowerToys Command Palette Interop**: Seamless invocation between Minou and PowerToys Run.
- **Local AI Provider IPC**: Direct prompt dispatch to local Ollama / LM Studio HTTP APIs without opening a browser.
