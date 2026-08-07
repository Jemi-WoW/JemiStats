# JemiStats

![JemiStatsimg1](https://raw.githubusercontent.com/Jemi-WoW/JemiStats/main/externals/img/jsScreenshot1.png)

**JemiStats** is a World of Warcraft addon that tracks what your character actually did.

Every kill, every crit, every close call, every zone. Live, per character, saved between sessions.

Runs on **Classic Era (1.15.9)** and **Burning Crusade Classic (2.5.6)** from the same download.

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
*   `/jstats reset` - wipe this character's tracked stats
*   `/jstats sessionreset` - reset session-only stats
*   `/jstats minimap` - toggle the minimap icon

## **Burning Crusade**

On Burning Crusade Classic the Outland zones, Eversong Woods, Ghostlands, Azuremyst Isle, Bloodmyst Isle and Isle of Quel'Danas all count toward Zones Visited, and the druid flight and Tree of Life forms count toward Times Shapeshifted. Nothing needs configuring - the addon reads the client version and adjusts.

## **Works with Oathbound**

Install [Oathbound](https://www.curseforge.com/wow/addons/oathbound) alongside JemiStats and the stats appear as a tab inside the Oathbound window instead, with an extra section counting what Oathbound blocked for you. JemiStats' own window and minimap icon stay out of the way.

Oathbound is Classic Era only. On Burning Crusade, JemiStats simply runs on its own.

Either addon works perfectly fine on its own.

### **Upgrading from Oathbound 1.5.0**

Stats used to live inside Oathbound. JemiStats imports your existing lifetime records on first login automatically.

**Keep Oathbound installed for that first login.** The game only hands an addon its saved data when that addon loads, so removing Oathbound before JemiStats has run once leaves the old records unreachable.

Created with love by **Jemi <3**
