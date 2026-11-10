# Changelog

All notable changes to **Elite Target Frame** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2026-11-10

### Fixed

- Live retail loads again: `Interface` lists 120105 (12.1.5) as well as 120107. Listing only the newer interface made the addon incompatible with the current retail client.
- Read target textures from `GetTextures()` on each update. Elite Player Frame (Enhanced) 1.11.7 no longer exposes the live texture table through `CopyTable`.

## [1.2.1] - 2026-11-10

### Fixed

- Ship `Modules/SpecCompat.lua` in the release. The TOC loads it, but the file was not in git, so Forever failed to resolve the target specialization.
- Load WoW Forever from the main TOC: `Interface` lists 16001 first, `X-GameType` declares Forever the same way as Elite Player Frame (Enhanced), and `*_Camelot.toc` is removed.

## [1.2.0] - 2026-11-09

### Added

- Camelot (`*_Camelot.toc`, Interface 16001) load support for WoW Forever.

### Fixed

- Auto target skins on Forever: resolve specialization via EPF `GetCurrentSpecID` (trait group points) and map retail texture-def spec IDs to Forever group IDs.
- Target auto skin no longer flashes class → spec while inspect / Forever trait data is still loading (cache by GUID; skip class-only fallbacks until spec is known).

## [1.1.0] - 2026-11-09

### Changed

- Requires Elite Player Frame (Enhanced) 1.11.0+ (string `frameMode` / `FRAME_MODES` ids).
- Interface tags updated for WoW 12.1.5 / 12.1.7.
- Target skin resolution uses string texture keys (`GetTextures` / Custom Skins core capture); migrates legacy numeric `frameMode` SavedVariables.

### Fixed

- Skin selection list and auto/manual target textures work again with EPF 1.11.
- Skin list paints on first open in the Settings canvas (`ScrollBox` `FullUpdate` after real layout size).

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
