# Elite Target Frame

[![Version](https://img.shields.io/badge/Version-1.0.6-informational)](EliteTargetFrame.toc)
[![WoW](https://img.shields.io/badge/WoW-12.1.0%20(Midnight)-orange)](https://worldofwarcraft.blizzard.com/)
[![Lua](https://img.shields.io/badge/Lua-5.x-blue)](https://www.lua.org/)

Companion add-on for **[Elite Player Frame (Enhanced)](https://www.curseforge.com/wow/addons/elite-player-frame-enhanced)** that applies the same frame skins to your **target** unit frame, mirrored for the target layout.

---

## Requirements

- **Elite Player Frame (Enhanced)** v1.10.3 or newer (enabled).
- Optional: **EPF Custom Skins** — extra textures are picked up automatically when that add-on is installed; Elite Target Frame does not depend on it at load time.

---

## Installation

1. Install **Elite Player Frame (Enhanced)** first.
2. Download the latest release ZIP or clone this repository.
3. Place the **EliteTargetFrame** folder in `World of Warcraft\_retail_\Interface\AddOns\`.
4. Enable **Elite Target Frame** on the character selection or in-game AddOns list.

---

## Options

**Esc → AddOns → Elite Target Frame**

| Option | Description |
|--------|-------------|
| **Display** | Show or hide target frame skins. |
| **Sync with player frame** | Use the same texture mode as your player frame (overrides manual/auto target choice). |
| **Display in instances** | Apply target skins in dungeons, raids, battlegrounds, and arenas. |
| **Players only** | Apply skins only when the target is another player (default: on). NPCs keep the normal target frame. |
| **Available textures** | Searchable list of all EPF frame modes; click a row to set the target frame texture. Choosing **Automatic** disables sync. |

---

## Behaviour

- **Automatic (frame mode 1):** Selects a skin from the **target** unit (class, specialization, race, faction), including custom skins registered by EPF Custom Skins when available.
- **Sync:** Copies whatever skin your player frame is currently using.
- **Manual:** Fixed texture from the list until you change it or switch back to automatic/sync.

Textures are provided by Elite Player Frame (Enhanced); this add-on does not ship its own art assets beyond the add-on list icon.

---

## Author

**Drakeinhart**
