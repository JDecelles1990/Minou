# Minou Popup Launcher

Minou is a highly customizable, dark-themed, and blazingly fast popup launcher built using AutoHotkey v2. Designed for power users, it replaces standard context menus with a centralized, data-driven hub for your most used programs, scripts, AI tools, and text snippets.

## Features
- **Data-Driven Configuration**: Easily modify menus via JSON files without touching code.
- **Contextual Deployment**: Summons right at your cursor, regardless of monitor or window state.
- **Smart Launching**: Understands URLs, executables, deep system links (`ms-settings:`), and dynamic text expansion (`{DATE}`, `{CLIPBOARD}`).
- **Built for AHK v2**: Leveraging modern, robust syntax.

## Quick Start
1. Ensure you have **AutoHotkey v2.0+** installed.
2. Clone or download this repository.
3. Run `Minou.ahk` to start the process. It will sit silently in your system tray.
4. Press `F3` to summon the menu, or `Shift+F3` for search mode (if configured).

## Documentation Index
Detailed technical documentation and guides are split into focused files within the `Docs/` directory:

- 🗂️ [**Documentation Index**](Docs/06_DocumentationIndex.md): Master directory for all documentation.
- 📖 [**Architecture Overview**](Docs/01-Architecture.md): Understand the lifecycle, global state, and module structure.
- ⚙️ [**Configuration Guide**](Docs/02-Configuration.md): Learn how to define items in the JSON files.
- 🛠️ [**API & Helpers**](Docs/03-Api-And-Helpers.md): Reference for core functions like `SafeRun` and `PasteText`.
- 🚀 [**Roadmap**](Docs/04-Roadmap.md): Future goals, planned GUI enhancements, and features.
- 📝 [**Changelog**](Docs/05_ChangeLog.md): History of updates and bug fixes.
- 🤖 [**AI Guidelines**](AGENTS.md): Strict rules for AI assistants on how to maintain this project.

---
*Created as a foundation for advanced, frictionless Windows workflows.*