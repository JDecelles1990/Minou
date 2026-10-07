# AI Agent Guidelines

This document provides documentation-specific workflow guidelines for AI coding assistants (such as Antigravity, GitHub Copilot, Cursor, and Gemini).

> [!IMPORTANT]
> The primary authority for all architectural, coding, and operational rules is the root [**AGENTS.md**](../AGENTS.md). All AI agents must review and strictly obey that file.

---

## 1. Documentation Integrity & Parity

When implementing new features or making architectural changes, you **MUST** update the relevant documentation concurrently in the same turn:

1. **New JSON Config Features**: If you add a new configurable property or schema, update [02-Configuration.md](02-Configuration.md).
2. **New Helper Functions**: If you introduce a utility function in `Minou.ahk` or the `Modules/` directory, document it in [03-Api-And-Helpers.md](03-Api-And-Helpers.md).
3. **Major Architectural Changes**: Any change to how Minou boots, loads modules, or manages global state must be reflected in [01-Architecture.md](01-Architecture.md).
4. **Completed Roadmap Items**: If you implement a feature from [04-Roadmap.md](04-Roadmap.md), mark it as completed or move it to [05_ChangeLog.md](05_ChangeLog.md).
5. **New Documentation**: If you create a new documentation file, link it in [06_DocumentationIndex.md](06_DocumentationIndex.md) and the root [ReadMe.md](../ReadMe.md).

---

## 2. Core Operational Constraints

1. **AutoHotkey v2 Exclusive**: Zero tolerance for v1 commands, legacy `%var%` dereferencing, or hybrid constructs. All code must be pure AutoHotkey v2.0+.
2. **Strict Modularity**: Keep `Minou.ahk` minimal as an orchestrator. Implement all new features inside dedicated modules under `Modules/`.
3. **Configuration Protocol**: Treat root `config.json` as legacy/deprecated. Exclusively read from and write to `Config/*.json`.
4. **Memory-Disk Parity**: Keep runtime in-memory maps/arrays synchronized with disk serialization (`SaveJsonFile()`).
5. **Execution Safety**: Route program, URL, and system launches through `SafeRun()` to ensure WDAC compliance and prevent script crashes.
