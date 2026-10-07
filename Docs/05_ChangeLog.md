# Changelog

All notable changes to Minou will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - Modular Architecture Phase

### Added
- **Custom Fluent Dark GUI**: Implemented `Modules/Launcher.ahk` replacing native Win32 menus with a two-pane ListBox/ListView interface styled in dark theme (`0x1A1A1A`, `0x232323`).
- **Interactive Search Engine**: Real-time filtering across all categories directly via search input.
- **Split Configuration Schema**: Created `Config/` directory with dedicated JSON files:
  - `settings.json` (hotkeys, visual styles)
  - `config.json` (programs, folders, utilities)
  - `urls.json` (curated cyber, development, and productivity bookmarks)
  - `snippets.json` (dynamic text replacements)
  - `prompts.json` (structured LLM prompt library)
- **Object-Oriented JSON Engine**: Added `Modules/Json.ahk` providing custom `JsonParser` and `StringifyJson` with unicode escape handling and Map/Array mapping.
- **WDAC / Application Control Protection Bypass**: Implemented COM-based `Shell.Application.ShellExecute` delegation inside `SafeRun` to run applications without AHK policy restrictions.
- **Dynamic Window Position & Clamping**: Mouse coordinate detection with automatic screen edge bounding logic.
- **Process IPC & Script Management**: AutoHotkey script detection and remote control (Reload, Suspend, Kill) via `PostMessage` WM_COMMAND hooks.
- **Hotstring Manager Module**: Implemented a standalone GUI editor (`Modules/Hotstrings.ahk`) for managing and live-syncing auto-expansion triggers to `Config/hotstrings.json`.
- **Dynamic Text Snippet Substitution**: Variable replacement for `{DATE}`, `{TIME}`, `{CLIPBOARD}`, and `{ENTER}`.
- **Comprehensive Canonical Documentation**:
  - `Docs/01-Architecture.md`
  - `Docs/02-Configuration.md`
  - `Docs/03-Api-And-Helpers.md`
  - `Docs/04-Roadmap.md`
  - `Docs/05_ChangeLog.md`
  - `Docs/06_DocumentationIndex.md`
  - `Docs/AGENTS.md`
  - `AGENTS.md` (Root authority with Agent Change Implementation Protocol)

### Changed
- Refactored monolithic prototype (`Minou AHK`, 789 lines) into modular coordinator `Minou.ahk` with discrete module boundaries (`Modules/Launcher.ahk`, `Modules/MenuBuilder.ahk`, `Modules/Json.ahk`).
- Updated root `ReadMe.md` into a streamlined index and overview.

### Fixed
- **AHK v2 String Literal Escaping in `Json.ahk`**: Replaced C-style backslash quote escapes (`\"`) with standard AHK single-quote and string literals, resolving the parser startup crash on line 44.
- **Map-Safe Property Access in `MenuBuilder.ahk`**: Updated item property retrieval to safely handle both `Map` and `Object` models.
- **Filtered Row Execution in `Launcher.ahk`**: Bound `RunSelectedEntry` to `VisibleEntries` rather than raw `CurrentEntries` to ensure filtered selections launch the expected target.
- **GUI Event Crash Fix in `Launcher.ahk`**: Removed invalid `KeyDown` event listener from the search `Edit` control which caused crashes in AHK v2, and restored full keyboard navigation (`Up`, `Down`, `Enter`, `Escape`) using an isolated `#HotIf` scope and native `Escape` GUI event binding.

---

## [0.1.0] - Monolithic Prototype
- Initial proof-of-concept single-file script using native Windows `Menu()` objects.
- Integration of `uxtheme.dll` ordinals 135/136 for experimental Win11 dark menu styling.
- Baseline JSON configuration loading from root `config.json`.
