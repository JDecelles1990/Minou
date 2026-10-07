# Documentation Index

This document serves as the master directory and cross-reference catalog for all canonical Minou documentation files.

---

## Technical Documentation Directory

| Document | Primary Audience | Scope & Contents |
| :--- | :--- | :--- |
| [**ReadMe.md**](../ReadMe.md) | Developers & Users | High-level summary, quick-start guide, prerequisites, and root navigation index. |
| [**01-Architecture.md**](01-Architecture.md) | Core Maintainers | System lifecycle (`InitMinou`), module responsibilities, custom GUI vs Win32 `Menu()`, global memory state, and WDAC security handling. |
| [**02-Configuration.md**](02-Configuration.md) | Users & Developers | Schema specification for `Config/*.json` files (`settings`, `config`, `urls`, `snippets`, `prompts`), dynamic tokens, and URI protocols. |
| [**03-Api-And-Helpers.md**](03-Api-And-Helpers.md) | Core Developers | Technical function and class reference (`SafeRun`, `ExpandEnvVars`, `LaunchItem`, `PasteText`, `JsonParser`, script IPC, and encoders). |
| [**04-Roadmap.md**](04-Roadmap.md) | Contributors | Feature milestones, dynamic software discovery, advanced snippet/prompt engines, diagnostics, and external integrations. |
| [**05_ChangeLog.md**](05_ChangeLog.md) | All | Historical changelog following Keep a Changelog conventions and semantic versioning. |
| [**06_DocumentationIndex.md**](06_DocumentationIndex.md) | All | Master reference index mapping and cross-linking the documentation repository. |
| [**AGENTS.md**](../AGENTS.md) | AI Agents & Assistants | Root authority defining coding standards, modular boundaries, doc-sync rules, and validation protocols. |

---

## Architectural Artifacts & Specifications
- [**Instructions 2 Minou F3 PCPaths.md**](../Instructions%202%20Minou%20F3%20PCPaths.md): Original master design specification detailing functional requirements, IT launcher concepts, and future integration targets.
- [**Minou AHK**](../Minou%20AHK): Monolithic reference script preserving original native Win32 menu and search GUI implementations.
