# Changelog

All notable changes to **Elite Target Frame** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.7] - 2026-09-07

### Fixed

- **INSPECT_READY:** no longer compares `UnitGUID("target")` to the inspect GUID. Those IDs can be secret values in competitive content (arenas, BGs, M+, raids) and direct comparison threw `attempt to compare a secret string value`.

## [1.0.6] - 2026-08-13

### Added

- Bumped toc compatibility for wow 12.1.0

## [1.0.5] - 2026-06-13

### Added

- Bumped toc compatibility for wow 12.0.7

## [1.0.4] - 2026-05-25

### Fixed

- **Automatic** mode no longer applies EPF Custom Skins **override** textures to the target using the **player** character; overrides now match the **target** unit unless **Sync with player frame** is enabled.
- Override matching on the target uses inline criteria checks (optional read of `mode_to_override` when Custom Skins is loaded); **no dependency** on the Custom Skins addon in the TOC.

## [1.0.3] - 2026-06-01

### Fixed

- Lua error when opening the options panel (`checkDisplayLabel` nil) after the checkbox row refactor.
- Option descriptions now use `SettingsTooltip` in the modern AddOns UI; tooltip position is consistent when hovering the label or the checkbox.

## [1.0.2] - 2026-05-22

### Added

- **Players only** option (default on): apply EPF target skins only when the target is another player; NPCs and other units keep the vanilla target frame (no mirrored portrait layer).

## [1.0.1] - 2026-05-22

### Added

- Addon list icon (`assets/etf-icon.png`) via `## IconTexture` in the TOC.

## [1.0.0] - 2026-05-22

### Added

- Initial release: mirrors **Elite Player Frame (Enhanced)** skins onto the **target** unit frame with horizontal flip.
- **Automatic** mode picks textures from the **target** (class, spec, race, faction) including EPF Custom Skins definitions when present.
- **Sync with player frame** option to copy your current player skin to the target frame.
- Manual texture selection from a searchable list in **Esc → AddOns**.
- Toggle to apply skins in instances; localized options panel (all supported WoW locales).
- Requires **Elite Player Frame (Enhanced)** v1.10.3 or newer.
