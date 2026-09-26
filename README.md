# JemiStats

![JemiStatsimg1](https://raw.githubusercontent.com/Jemi-WoW/JemiStats/main/externals/img/jsScreenshot1.png)

**JemiStats** is a World of Warcraft addon that tracks what your character actually did.

Every kill, every crit, every close call, every zone. Live, per character, saved between sessions.

Runs on **Classic Era**, **Burning Crusade Classic** and **WoW Forever** from the same download.

## **Supported clients**

| Client | Interface | TOC |
|---|---|---|
| Classic Era 1.15.9 | 11509 | `JemiStats_Vanilla.toc` |
| Burning Crusade Classic 2.5.6 | 20506 | `JemiStats_TBC.toc` |
| WoW Forever 1.60.1 | 16001 | `JemiStats_Camelot.toc` |
| fallback | 11509, 20506, 16001 | `JemiStats.toc` |

## **What it tracks**

*   **Survival** - highest crit, lowest HP, missed attacks
*   **Combat** - enemies, rares, elites, bosses, dungeons, average fight length
*   **Exploration** - distance travelled, zones visited, flight paths, jumps
*   **Class stats** - a tracked signature ability for every class
*   **Economy** - gold earned and spent, chests opened
*   **Questing** - quests accepted and completed
*   **Interface habits** - how often you open the map, bags and talents

## **Commands**

*   `/jemistats` or `/jstats` - open or close the window
*   `/jstats settings` - open the settings tab
*   `/jstats reset` - wipe this character's tracked stats
*   `/jstats sessionreset` - reset session-only stats
*   `/jstats minimap` - toggle the minimap icon

## **Forever notes**

Forever serves vanilla content on the modern codebase, so it reports itself as Retail and a few things behave differently there.

- **Stats may not persist between launches.** The beta client writes SavedVariables on logout but does not read them back, so the addon can start from defaults every session. This is a client bug, not an addon bug.
- Zones Visited counts the 40 vanilla zones, same as Classic Era.
- Arrows Shot and Bullets Shot stay at zero. The modern codebase has no ammo slot to sample.
- Times Checked Talents stays at zero while the spellbook and talents share one frame, because there is no way to tell the two apart. Opening it counts as a spellbook open.
- `ReloadUI()` is protected on the beta. Type `/reload` instead. Either way the session stats survive the reload.

## **Works with Oathbound**

Install [Oathbound](https://www.curseforge.com/wow/addons/oathbound) alongside JemiStats and the stats appear as a tab inside the Oathbound window instead, with an extra section counting what Oathbound blocked for you. JemiStats' own window and minimap icon stay out of the way.

Oathbound is Classic Era only. On Burning Crusade, JemiStats simply runs on its own.

Either addon works perfectly fine on its own.

### **Upgrading from Oathbound 1.5.0**

Stats used to live inside Oathbound. JemiStats imports your existing lifetime records on first login automatically.

**Keep Oathbound installed for that first login.** The game only hands an addon its saved data when that addon loads, so removing Oathbound before JemiStats has run once leaves the old records unreachable.

Created with love by **Jemi <3**
