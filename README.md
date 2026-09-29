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

*   **Survival** - highest crit, lowest HP, missed attacks, deaths and what killed you, biggest fall survived
*   **Combat** - enemies, rares, elites, bosses, dungeons, average fight length, killing blows, interrupts, dispels, resurrections, duels
*   **Exploration** - distance travelled, zones visited, flight paths, jumps, hearthstones, summons
*   **Class stats** - a tracked signature ability for every class
*   **Professions** - nodes gathered, fish caught, bandages used
*   **Economy** - gold earned and spent, highest gold held, chests, vendor sales, auctions, crafting
*   **Questing** - quests accepted and completed
*   **Habits** - food, drink, alcohol and emotes
*   **Interface habits** - how often you open the map, bags and talents

Deaths are tracked too, so the addon reads the same on a normal character as it does on Hardcore.

## **On-screen window and toasts**

Tick the box to the left of any stat on the Stats tab and it joins a small window on your screen. Untick them all and the window goes away. Ticking a stat only decides whether it is *shown* there - everything keeps tracking either way. Drag the window wherever you like.

The window shows your portrait and name, sizes itself to whatever you put in it, and scrolls once the list passes fourteen rows. A fresh character starts with a handful already ticked.

Toasts pop up whenever a tracked stat goes up. Repeated hits on the same stat fold into one, so a busy pull reads `+5 Enemies Slain` rather than five separate pop-ups. Stats that move constantly, like Distance Traveled, never toast.

Both live under **Settings - Toast Notifications**, along with a minimal style and a button to move the toasts.

## **Commands**

*   `/jemistats` or `/jstats` - open or close the window
*   `/jstats settings` - open the settings tab
*   `/jstats reset` - wipe this character's tracked stats
*   `/jstats sessionreset` - reset session-only stats
*   `/jstats minimap` - toggle the minimap icon
*   `/jstats toast` - move where toasts appear
*   `/jstats window` - put the on-screen window back in its corner

## **WoW Forever notes**

Forever serves vanilla content on the modern codebase, so it reports itself as Retail and a few things behave differently there. Please expect bugs/issues.

## **Works with Oathbound**

Install [Oathbound](https://www.curseforge.com/wow/addons/oathbound) alongside JemiStats and the stats appear as a tab inside the Oathbound window instead, with an extra section counting what Oathbound blocked for you. JemiStats' own window and minimap icon stay out of the way.

Oathbound is Classic Era only. On Burning Crusade, JemiStats simply runs on its own.

Either addon works perfectly fine on its own.

### **Upgrading from Oathbound 1.5.0**

Stats used to live inside Oathbound. JemiStats imports your existing lifetime records on first login automatically.

**Keep Oathbound installed for that first login.** The game only hands an addon its saved data when that addon loads, so removing Oathbound before JemiStats has run once leaves the old records unreachable.

Created with love by **Jemi <3**
