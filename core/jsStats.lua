local _, JS = ...

-- Stats colors

local GOLD   = { 1.0, 0.82, 0.0 }
local WHITE  = { 1.0, 1.0, 1.0 }
local DIM    = { 0.82, 0.82, 0.82 }
local BLUE   = { 0.28, 0.60, 1.00 }
local PURPLE = { 0.72, 0.48, 0.90 }
local BRONZE = { 0.82, 0.60, 0.30 }
local GREEN  = { 0.62, 0.82, 0.38 }
local REDVAL = { 0.92, 0.36, 0.36 }
local OFFGOLD= { 1.00, 0.90, 0.62 }

-- Frame to habit counter; names differ per codebase, only the present ones hook.
local UI_OPEN_COUNTERS = {
  WorldMapFrame = "mapOpened",
  CharacterFrame = "characterOpened",
  SpellBookFrame = "spellbookOpened",
  PlayerSpellsFrame = "spellbookOpened",
  QuestLogFrame = "questLogOpened",
  TalentFrame = "talentsChecked",
  PlayerTalentFrame = "talentsChecked",
  ClassTalentFrame = "talentsChecked",
}

local UI_FRAME_NAMES = {}
for frameName in pairs(UI_OPEN_COUNTERS) do
  UI_FRAME_NAMES[#UI_FRAME_NAMES + 1] = frameName
end

-- A merged spellbook/talent frame is absent here, or it would count as both.
local UI_TOGGLE_HOOKS = {
  { toggle = "ToggleWorldMap",    counter = "mapOpened",       frames = { "WorldMapFrame" } },
  { toggle = "ToggleCharacter",   counter = "characterOpened", frames = { "CharacterFrame" } },
  { toggle = "ToggleSpellBook",   counter = "spellbookOpened", frames = { "SpellBookFrame", "PlayerSpellsFrame" } },
  { toggle = "ToggleQuestLog",    counter = "questLogOpened",  frames = { "QuestLogFrame" } },
  { toggle = "ToggleTalentFrame", counter = "talentsChecked",  frames = { "PlayerTalentFrame", "TalentFrame", "ClassTalentFrame" } },
}

JS.Stats = JS.Stats or {}
local Stats = JS.Stats

Stats.trackers = Stats.trackers or {}
Stats.trackersByKey = Stats.trackersByKey or {}

-- Split by callback, so the hot paths only touch the trackers that care
Stats.combatLogTrackers = Stats.combatLogTrackers or {}
Stats.updateTrackers = Stats.updateTrackers or {}
Stats.categoryOrder = { "survival", "combat", "exploration", "class", "professions", "economy", "questing", "habits", "oathbound" }
Stats.categoryLabels = {
  survival = "SURVIVAL",
  combat = "COMBAT",
  exploration = "EXPLORATION",
  class = "CLASS STATS",
  professions = "PROFESSIONS",
  economy = "ECONOMY",
  questing = "QUESTING",
  habits = "HABITS",
  oathbound = "OATHBOUND",
}

Stats.rowOrderByCategory = {
  survival = {
    highestCritSession = 10,
    highestCritEver = 20,
    lowestHPPctSession = 30,
    lowestHPPctEver = 40,
    missedAttacks = 50,
    deaths = 60,
    deathsByFalling = 70,
    deathsByDrowning = 80,
    biggestFallSurvived = 90,
    timesResurrected = 100,
    levelsWithoutDying = 110,
  },
  combat = {
    enemiesSlain = 10,
    raresSlain = 20,
    elitesSlain = 30,
    rareElitesSlain = 40,
    bossesSlain = 50,
    killingBlows = 55,
    combatDurationAverage = 60,
    dungeonsEntered = 70,
    dungeonsCompleted = 80,
    interrupts = 90,
    dispels = 100,
    resurrectionsCast = 110,
    duelsWon = 120,
    duelsLost = 130,
  },
  exploration = {
    distanceSession = 10,
    distanceEver = 20,
    visitedZoneCount = 30,
    flightPathsTaken = 40,
    jumps = 50,
    hearthstonesUsed = 60,
    summonsAccepted = 70,
  },
  professions = {
    nodesGathered = 10,
    fishCaught = 20,
    junkFishCaught = 30,
    bandagesUsed = 40,
  },
  economy = {
    goldEarnedSession = 10,
    goldEarnedTotal = 20,
    goldSpentTotal = 30,
    highestGoldHeld = 35,
    chestsOpened = 40,
    itemsSoldToVendors = 50,
    auctionsPosted = 60,
    timesWentBroke = 70,
    itemsCrafted = 80,
    itemsDisenchanted = 90,
  },
  habits = {
    foodEaten = 10,
    drinksDrunk = 20,
    alcoholDrunk = 30,
    emotesPerformed = 40,
  },
}

Stats.colors = {
  GOLD = GOLD,
  WHITE = WHITE,
  DIM = DIM,
  BLUE = BLUE,
  PURPLE = PURPLE,
  BRONZE = BRONZE,
  GREEN = GREEN,
  REDVAL = REDVAL,
  OFFGOLD = OFFGOLD,
}

Stats.UI_OPEN_COUNTERS = UI_OPEN_COUNTERS

local EnsureUIOpenHooks
local EnsureUIFrameHooks

function JS.RegisterStatTracker(def)
  if not def or not def.key then return end

  if Stats.trackersByKey[def.key] then
    return Stats.trackersByKey[def.key]
  end

  table.insert(Stats.trackers, def)
  Stats.trackersByKey[def.key] = def

  if def.OnCombatLog then
    table.insert(Stats.combatLogTrackers, def)
  end
  if def.OnUpdate then
    table.insert(Stats.updateTrackers, def)
  end

  return def
end

-- Held until PLAYER_LOGIN, when the host check can finally resolve.
Stats.deferredTrackers = Stats.deferredTrackers or {}

function JS.DeferStatTracker(hostAddon, def)
  if not def or not def.key then return end
  table.insert(Stats.deferredTrackers, { host = hostAddon, def = def })
end

function JS.FlushDeferredStatTrackers()
  local pending = Stats.deferredTrackers
  if not pending then return end

  for i = 1, #pending do
    local entry = pending[i]
    if JS.IsAddOnLoaded(entry.host) then
      JS.RegisterStatTracker(entry.def)
    end
  end

  Stats.deferredTrackers = {}
end

-- Normalizes only when the table is new, because trackers call this constantly.
local normalizedStats

local function EnsureStatsDB()
  local d = JS.DB()
  d.stats = d.stats or {}
  local s = d.stats

  if s == normalizedStats then
    return s
  end
  normalizedStats = s

  s.highestCritSession   = tonumber(s.highestCritSession or 0) or 0
  s.highestCritEver      = tonumber(s.highestCritEver or 0) or 0
  s.lowestHPPctSession   = tonumber(s.lowestHPPctSession or 100) or 100
  s.lowestHPPctEver      = tonumber(s.lowestHPPctEver or 100) or 100

  s.enemiesSlain         = tonumber(s.enemiesSlain or 0) or 0
  s.raresSlain           = tonumber(s.raresSlain or 0) or 0
  s.elitesSlain          = tonumber(s.elitesSlain or 0) or 0
  s.rareElitesSlain      = tonumber(s.rareElitesSlain or 0) or 0
  s.bossesSlain          = tonumber(s.bossesSlain or 0) or 0
  s.missedAttacks        = tonumber(s.missedAttacks or 0) or 0
  s.bossKillNames        = type(s.bossKillNames) == "table" and s.bossKillNames or {}

  s.dungeonsCompleted    = tonumber(s.dungeonsCompleted or 0) or 0
  s.dungeonsEntered      = tonumber(s.dungeonsEntered or 0) or 0
  s.completedDungeons    = type(s.completedDungeons) == "table" and s.completedDungeons or {}
  s.jumps                = tonumber(s.jumps or 0) or 0
  s.questsAccepted       = tonumber(s.questsAccepted or 0) or 0
  s.questsCompleted      = tonumber(s.questsCompleted or 0) or 0
  s.flightPathsTaken     = tonumber(s.flightPathsTaken or 0) or 0
  s.mapOpened            = tonumber(s.mapOpened or 0) or 0
  s.characterOpened      = tonumber(s.characterOpened or 0) or 0
  s.spellbookOpened      = tonumber(s.spellbookOpened or 0) or 0
  s.questLogOpened       = tonumber(s.questLogOpened or 0) or 0
  s.talentsChecked       = tonumber(s.talentsChecked or 0) or 0
  s.chestsOpened         = tonumber(s.chestsOpened or 0) or 0
  s.timesLoggedIn        = tonumber(s.timesLoggedIn or 0) or 0

  s.arrowsShot           = tonumber(s.arrowsShot or 0) or 0
  s.bulletsShot          = tonumber(s.bulletsShot or 0) or 0

  s.timesCharged         = tonumber(s.timesCharged or 0) or 0
  s.executesLanded       = tonumber(s.executesLanded or 0) or 0
  s.timesBubbled         = tonumber(s.timesBubbled or 0) or 0
  s.layOnHandsCast       = tonumber(s.layOnHandsCast or 0) or 0
  s.pocketsPicked        = tonumber(s.pocketsPicked or 0) or 0
  s.backstabsLanded      = tonumber(s.backstabsLanded or 0) or 0
  s.shieldsCast          = tonumber(s.shieldsCast or 0) or 0
  s.mindControlsCast     = tonumber(s.mindControlsCast or 0) or 0
  s.totemsDropped        = tonumber(s.totemsDropped or 0) or 0
  s.lightningBoltsCast   = tonumber(s.lightningBoltsCast or 0) or 0
  s.polymorphsCast       = tonumber(s.polymorphsCast or 0) or 0
  s.timesBlinked         = tonumber(s.timesBlinked or 0) or 0
  s.demonsSummoned       = tonumber(s.demonsSummoned or 0) or 0
  s.lifeTapped           = tonumber(s.lifeTapped or 0) or 0
  s.timesShapeshifted    = tonumber(s.timesShapeshifted or 0) or 0
  s.battleRezzes         = tonumber(s.battleRezzes or 0) or 0

  s.distanceSession      = tonumber(s.distanceSession or 0) or 0
  s.distanceEver         = tonumber(s.distanceEver or 0) or 0

  s.goldEarnedSession    = tonumber(s.goldEarnedSession or 0) or 0
  s.goldEarnedTotal      = tonumber(s.goldEarnedTotal or 0) or 0
  s.goldSpentTotal       = tonumber(s.goldSpentTotal or 0) or 0

  s.combatCount          = tonumber(s.combatCount or 0) or 0
  s.combatDurationTotal  = tonumber(s.combatDurationTotal or 0) or 0
  s.combatStartedAt      = tonumber(s.combatStartedAt or 0) or 0

  s.deaths               = tonumber(s.deaths or 0) or 0
  s.deathsByFalling      = tonumber(s.deathsByFalling or 0) or 0
  s.deathsByDrowning     = tonumber(s.deathsByDrowning or 0) or 0
  s.biggestFallSurvived  = tonumber(s.biggestFallSurvived or 0) or 0
  s.timesResurrected     = tonumber(s.timesResurrected or 0) or 0
  s.levelAtFirstDeath    = tonumber(s.levelAtFirstDeath or 0) or 0

  s.killingBlows         = tonumber(s.killingBlows or 0) or 0
  s.interrupts           = tonumber(s.interrupts or 0) or 0
  s.dispels              = tonumber(s.dispels or 0) or 0
  s.resurrectionsCast    = tonumber(s.resurrectionsCast or 0) or 0
  s.duelsWon             = tonumber(s.duelsWon or 0) or 0
  s.duelsLost            = tonumber(s.duelsLost or 0) or 0

  s.hearthstonesUsed     = tonumber(s.hearthstonesUsed or 0) or 0
  s.summonsAccepted      = tonumber(s.summonsAccepted or 0) or 0

  s.nodesGathered        = tonumber(s.nodesGathered or 0) or 0
  s.gatheredByKind       = type(s.gatheredByKind) == "table" and s.gatheredByKind or {}
  s.fishCaught           = tonumber(s.fishCaught or 0) or 0
  s.junkFishCaught       = tonumber(s.junkFishCaught or 0) or 0
  s.bandagesUsed         = tonumber(s.bandagesUsed or 0) or 0

  s.highestGoldHeld      = tonumber(s.highestGoldHeld or 0) or 0
  s.itemsSoldToVendors   = tonumber(s.itemsSoldToVendors or 0) or 0
  s.auctionsPosted       = tonumber(s.auctionsPosted or 0) or 0
  s.timesWentBroke       = tonumber(s.timesWentBroke or 0) or 0
  s.itemsCrafted         = tonumber(s.itemsCrafted or 0) or 0
  s.itemsDisenchanted    = tonumber(s.itemsDisenchanted or 0) or 0

  s.foodEaten            = tonumber(s.foodEaten or 0) or 0
  s.drinksDrunk          = tonumber(s.drinksDrunk or 0) or 0
  s.alcoholDrunk         = tonumber(s.alcoholDrunk or 0) or 0
  s.emotesPerformed      = tonumber(s.emotesPerformed or 0) or 0

  s.tradesBlocked        = tonumber(s.tradesBlocked or 0) or 0
  s.invitesBlocked       = tonumber(s.invitesBlocked or 0) or 0
  s.mailboxBlocks        = tonumber(s.mailboxBlocks or 0) or 0
  s.auctionHouseBlocks   = tonumber(s.auctionHouseBlocks or 0) or 0

  s.sessionStartedAt     = s.sessionStartedAt or (GetTime and GetTime() or 0)

  -- Wall clock, because GetTime() restarts at zero on every login
  s.sessionStartedAtEpoch = tonumber(s.sessionStartedAtEpoch or 0) or 0
  if s.sessionStartedAtEpoch <= 0 then
    s.sessionStartedAtEpoch = (time and time()) or 0
  end

  s.currentDungeon       = s.currentDungeon or nil
  s.lastQuestAccepted    = type(s.lastQuestAccepted) == "table" and s.lastQuestAccepted or {}
  s.lastQuestCompleted   = type(s.lastQuestCompleted) == "table" and s.lastQuestCompleted or {}
  s.lastKilledGUIDs      = type(s.lastKilledGUIDs) == "table" and s.lastKilledGUIDs or {}
  s.lastSpecialKilledGUIDs = type(s.lastSpecialKilledGUIDs) == "table" and s.lastSpecialKilledGUIDs or {}
  s.visitedZones         = type(s.visitedZones) == "table" and s.visitedZones or {}
  s.visitedZoneCount     = tonumber(s.visitedZoneCount or 0) or 0

  s.pendingCombatRecords = type(s.pendingCombatRecords) == "table" and s.pendingCombatRecords or {}
  s.pendingCombatRecords.highestCritSession = tonumber(s.pendingCombatRecords.highestCritSession or 0) or 0
  s.pendingCombatRecords.lowestHPPctSession = tonumber(s.pendingCombatRecords.lowestHPPctSession or 100) or 100
  s.pendingCombatRecords.lowestHPPctEver    = tonumber(s.pendingCombatRecords.lowestHPPctEver or 100) or 100

  if s._onTaxi == nil then
    s._onTaxi = false
  end

  return s
end

Stats.EnsureStatsDB = EnsureStatsDB

-- Repair legacy stats tables from older addon versions without wiping progress.
local function MigrateLegacyStatsState()
  local s = EnsureStatsDB()

  s._uiHooksInstalled = nil
  s._seenLoginThisSession = nil

  s.currentDungeon = nil
  s.combatStartedAt = 0
  s.pendingCombatRecords = {
    highestCritSession = 0,
    lowestHPPctSession = 100,
    lowestHPPctEver = 100,
  }
  s.lastQuestAccepted = {}
  s.lastQuestCompleted = {}
  s.lastKilledGUIDs = {}
  s.lastSpecialKilledGUIDs = {}
  s.lastMoney = GetMoney and (GetMoney() or 0) or 0
  s.lastPosX = nil
  s.lastPosY = nil
  s.lastPosInstanceID = nil
  s._onTaxi = false
  s.lastJumpCountAt = 0
  s._lastEnvironment = nil
  s._pendingFall = nil
  s._merchantOpen = false
  s._summonOfferedAt = nil
  s._fishingCastAt = 0
  s._lootCounted = nil
  s._eating = false
  s._drinking = false
  s._pendingAlcohol = nil
  s._wasBroke = nil

  return s
end

Stats.MigrateLegacyStatsState = MigrateLegacyStatsState

-- Fully reset this character's stats without touching any other saved data.
function JS.ResetCharacterStats()
  local d = JS.DB()
  d.stats = nil

  local s = EnsureStatsDB()
  s.lastMoney = GetMoney and (GetMoney() or 0) or 0
  s.lastPosX = nil
  s.lastPosY = nil
  s.lastPosInstanceID = nil
  s.lastJumpCountAt = 0

  Stats.RefreshPanelIfVisible()
  return s
end

local function FormatNumber(n)
  n = tonumber(n or 0) or 0
  local s = tostring(math.floor(n + 0.5))
  local out = s
  while true do
    local nextOut, changed = out:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
    out = nextOut
    if changed == 0 then break end
  end
  return out
end

local function FormatPercent(v)
  v = tonumber(v or 100) or 100
  if v < 0 then v = 0 end
  return string.format("%.1f%%", v)
end

local function FormatDistance(v)
  v = tonumber(v or 0) or 0
  return FormatNumber(v) .. " yd"
end

-- The exploration tracker overwrites the total for this client's expansion.
Stats.ZONE_TOTAL = 40

local function FormatZonesVisited(v)
  v = tonumber(v or 0) or 0
  return string.format("%d/%d", v, Stats.ZONE_TOTAL)
end

local function FormatCopper(v)
  v = tonumber(v or 0) or 0
  if v < 0 then v = 0 end
  local g = math.floor(v / 10000)
  local s = math.floor((v % 10000) / 100)
  local c = math.floor(v % 100)
  return string.format("%dg %02ds %02dc", g, s, c)
end

local function FormatDuration(seconds)
  seconds = tonumber(seconds or 0) or 0
  if seconds < 0 then seconds = 0 end
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)
  return string.format("%02d:%02d", mins, secs)
end

local function FormatSessionLength(seconds)
  seconds = tonumber(seconds or 0) or 0
  if seconds < 0 then seconds = 0 end

  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  local secs = math.floor(seconds % 60)

  if hours > 0 then
    return string.format("%d:%02d:%02d", hours, mins, secs)
  end

  return string.format("%02d:%02d", mins, secs)
end

Stats.FormatNumber = FormatNumber
Stats.FormatPercent = FormatPercent
Stats.FormatDistance = FormatDistance
Stats.FormatZonesVisited = FormatZonesVisited
Stats.FormatCopper = FormatCopper
Stats.FormatDuration = FormatDuration
Stats.FormatSessionLength = FormatSessionLength

-- Panels register themselves, since only they know which window they live in.
Stats.panels = Stats.panels or {}

function Stats.RegisterPanel(panel)
  if not panel then return end
  table.insert(Stats.panels, panel)
end

function Stats.RefreshPanelIfVisible()
  local panels = Stats.panels
  for i = 1, #panels do
    local panel = panels[i]
    if panel:IsVisible() and panel.Refresh then
      panel:Refresh()
    end
  end
end

-- Full re-stack, for when a display option changes which rows exist at all.
function Stats.RelayoutPanels()
  local panels = Stats.panels
  for i = 1, #panels do
    local panel = panels[i]
    if panel.Refresh then
      panel:Refresh()
    end
    if panel.RefreshLayout then
      panel:RefreshLayout()
    end
  end
end

-- Read once per change instead of once per event; defaults match the settings.
Stats.classStatsEnabled = true
Stats.uiHabitsEnabled = true
Stats.distanceEnabled = true

function Stats.RefreshSettingCache()
  if not JS.GetSetting then return end
  Stats.classStatsEnabled = JS.GetSetting("trackClassStats")
  Stats.uiHabitsEnabled = JS.GetSetting("trackUIHabits")
  Stats.distanceEnabled = JS.GetSetting("trackDistance")
end

-- Falls through SOUNDKIT entries, so a missing one never errors.
local RECORD_SOUND = SOUNDKIT and (
  SOUNDKIT.IG_QUEST_LIST_COMPLETE or
  SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or
  SOUNDKIT.IG_CHARACTER_INFO_OPEN
)

local function QueueRecordAlert(title, valueText)
  title = tostring(title or "")
  if title == "" then return end

  if not JS.GetSetting("announceRecords") then return end

  valueText = tostring(valueText or "")
  if valueText ~= "" then
    JS.Msg(title .. ": |cffffd100" .. valueText .. "|r")
  else
    JS.Msg(title)
  end

  if RECORD_SOUND and PlaySound and JS.GetSetting("recordSound") then
    PlaySound(RECORD_SOUND)
  end
end

Stats.QueueRecordAlert = QueueRecordAlert

local function InCombatNow()
  return InCombatLockdown and InCombatLockdown() or false
end

Stats.InCombatNow = InCombatNow

local function EnsurePendingCombatStats()
  local s = EnsureStatsDB()
  s.pendingCombatRecords = type(s.pendingCombatRecords) == "table" and s.pendingCombatRecords or {}

  s.pendingCombatRecords.highestCritSession = tonumber(s.pendingCombatRecords.highestCritSession or 0) or 0
  s.pendingCombatRecords.lowestHPPctSession = tonumber(s.pendingCombatRecords.lowestHPPctSession or 100) or 100
  s.pendingCombatRecords.lowestHPPctEver    = tonumber(s.pendingCombatRecords.lowestHPPctEver or 100) or 100

  return s.pendingCombatRecords
end

Stats.EnsurePendingCombatStats = EnsurePendingCombatStats

local function IncStat(key, amount)
  local s = EnsureStatsDB()
  amount = tonumber(amount or 1) or 1
  s[key] = (tonumber(s[key] or 0) or 0) + amount
  Stats.RefreshPanelIfVisible()
end

Stats.IncStat = IncStat

local function ShortUISpamKey(name)
  return "STAT_UI_" .. tostring(name or "unknown")
end

-- Mark current session so ReloadUI does not reset session-only stats.
local function MarkSessionForReloadPreserve()
  local s = EnsureStatsDB()
  s._preserveSessionOnNextLogin = true
  s._preserveSessionStamp = (time and time()) or 0
end

-- Detect whether the current PLAYER_LOGIN came from a recent ReloadUI.
local function ShouldPreserveSessionAcrossLogin()
  local s = EnsureStatsDB()
  local preserve = s._preserveSessionOnNextLogin and true or false
  local stamp = tonumber(s._preserveSessionStamp or 0) or 0
  local now = (time and time()) or 0

  s._preserveSessionOnNextLogin = nil
  s._preserveSessionStamp = nil

  if not preserve then
    return false
  end

  if stamp > 0 and now > 0 and (now - stamp) <= 15 then
    return true
  end

  return false
end

-- Post-hooked, not replaced: ReloadUI is protected on Forever.
local _reloadUIHookInstalled = false
local function EnsureReloadUIHook()
  if _reloadUIHookInstalled then return end

  _reloadUIHookInstalled = JS.HookGlobal("ReloadUI", function()
    MarkSessionForReloadPreserve()
  end)

  -- The modern codebase also reloads straight through C_UI, bypassing the global
  if C_UI and type(C_UI.Reload) == "function" then
    hooksecurefunc(C_UI, "Reload", MarkSessionForReloadPreserve)
    _reloadUIHookInstalled = true
  end
end

local function GetCurrentZoneName()
  local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
  zone = tostring(zone or ""):gsub("^%s+", ""):gsub("%s+$", "")
  return zone
end

Stats.GetCurrentZoneName = GetCurrentZoneName

local function ForEachTracker(fnName, ...)
  for i = 1, #Stats.trackers do
    local tracker = Stats.trackers[i]
    local fn = tracker and tracker[fnName]
    if fn then
      fn(tracker, ...)
    end
  end
end

-- Skipped entirely, so the option saves the work rather than hiding the result.
function Stats.IsTrackerMuted(tracker)
  return tracker.category == "class" and not Stats.classStatsEnabled
end

function Stats.DispatchEvent(event, ...)
  for i = 1, #Stats.trackers do
    local tracker = Stats.trackers[i]
    local fn = tracker and tracker.OnEvent
    if fn and not Stats.IsTrackerMuted(tracker) then
      fn(tracker, event, ...)
    end
  end
end

function Stats.DispatchUpdate(elapsed)
  local trackers = Stats.updateTrackers
  for i = 1, #trackers do
    local tracker = trackers[i]
    if not Stats.IsTrackerMuted(tracker) then
      tracker.OnUpdate(tracker, elapsed)
    end
  end
end

function JS.HandleStatsPlayerLogin()
  EnsureReloadUIHook()
  Stats.RefreshSettingCache()

  local preserveSession = ShouldPreserveSessionAcrossLogin()
  local s = MigrateLegacyStatsState()

  if not preserveSession then
    -- A real login only keeps the session when the player asked for that
    if not JS.GetSetting("keepSessionAcrossLogout") then
      JS.ResetSessionStats()
    end
    s.timesLoggedIn = (tonumber(s.timesLoggedIn or 0) or 0) + 1
  end

  EnsureUIOpenHooks()
  EnsureUIFrameHooks()
  ForEachTracker("OnPlayerLogin", preserveSession)
  Stats.RefreshPanelIfVisible()
end

function JS.ResetSessionStats()
  local s = EnsureStatsDB()
  s.highestCritSession = 0
  s.lowestHPPctSession = 100
  s.distanceSession = 0
  s.goldEarnedSession = 0
  s.sessionStartedAt = GetTime and GetTime() or 0
  s.sessionStartedAtEpoch = (time and time()) or 0
  s.pendingCombatRecords = {
    highestCritSession = 0,
    lowestHPPctSession = 100,
    lowestHPPctEver = 100,
  }

  ForEachTracker("OnSessionReset")
end

-- Keyed on the counter, so a window reached two ways still counts once.
local function CountUIOpenCounter(counterKey)
  if not counterKey then return end
  if not Stats.uiHabitsEnabled then return end

  if JS.ShouldSpam and JS.ShouldSpam(ShortUISpamKey(counterKey), 0.40) then
    return
  end

  local s = EnsureStatsDB()
  s[counterKey] = (tonumber(s[counterKey] or 0) or 0) + 1
  Stats.RefreshPanelIfVisible()
end

local function CountUIOpen(name)
  CountUIOpenCounter(UI_OPEN_COUNTERS[name])
end

local function AnyFrameShown(frameNames)
  for i = 1, #frameNames do
    local frame = _G[frameNames[i]]
    if frame and frame.IsShown and frame:IsShown() then
      return true
    end
  end
  return false
end

local _uiHooksInstalled = false
local _uiFrameHooks = {}

EnsureUIOpenHooks = function()
  if _uiHooksInstalled then return end
  _uiHooksInstalled = true

  if not hooksecurefunc then return end

  JS.HookGlobal("ShowUIPanel", function(frame)
    if not frame or not frame.GetName or not frame:IsShown() then return end
    CountUIOpen(frame:GetName())
  end)

  for i = 1, #UI_TOGGLE_HOOKS do
    local entry = UI_TOGGLE_HOOKS[i]
    JS.HookGlobal(entry.toggle, function()
      if AnyFrameShown(entry.frames) then
        CountUIOpenCounter(entry.counter)
      end
    end)
  end
end

-- The retry gives up, rather than waiting forever on a frame never coming.
local MAX_UI_HOOK_RETRIES = 10
local _uiHookRetries = 0

EnsureUIFrameHooks = function()
  local missing = false

  for i = 1, #UI_FRAME_NAMES do
    local frameName = UI_FRAME_NAMES[i]
    if not _uiFrameHooks[frameName] then
      local frame = _G[frameName]
      if frame and frame.HookScript then
        frame:HookScript("OnShow", function(self)
          local name = self and self.GetName and self:GetName() or frameName
          CountUIOpen(name)
        end)
        _uiFrameHooks[frameName] = true
      else
        missing = true
      end
    end
  end

  if not missing then return end

  _uiHookRetries = _uiHookRetries + 1
  if _uiHookRetries > MAX_UI_HOOK_RETRIES then return end

  if C_Timer and C_Timer.After then
    C_Timer.After(1.0, EnsureUIFrameHooks)
  end
end

Stats.EnsureUIFrameHooks = function()
  EnsureUIFrameHooks()
end

-- Locale-independent class token for the player, e.g. "HUNTER".
local function PlayerClassToken()
  if not UnitClass then return nil end
  local _, token = UnitClass("player")
  return token
end

-- Ordered header and row list for the panel to render
function Stats.BuildTrackerEntryLayout()
  local out = {}
  local playerClass = PlayerClassToken()

  for i = 1, #Stats.categoryOrder do
    local category = Stats.categoryOrder[i]
    local insertedHeader = false
    local categoryTrackers = {}

    for j = 1, #Stats.trackers do
      local tracker = Stats.trackers[j]
      -- A `class` field limits the row to that class; an empty section loses its header
      if tracker.category == category and (not tracker.class or tracker.class == playerClass) then
        table.insert(categoryTrackers, tracker)
      end
    end

    local categoryRowOrder = Stats.rowOrderByCategory and Stats.rowOrderByCategory[category]
    table.sort(categoryTrackers, function(a, b)
      local ao = tonumber(a.order or (categoryRowOrder and categoryRowOrder[a.key]) or 9999) or 9999
      local bo = tonumber(b.order or (categoryRowOrder and categoryRowOrder[b.key]) or 9999) or 9999
      if ao ~= bo then
        return ao < bo
      end
      return tostring(a.label or a.key or "") < tostring(b.label or b.key or "")
    end)

    for j = 1, #categoryTrackers do
      local tracker = categoryTrackers[j]
      if not insertedHeader then
        table.insert(out, { type = "header", label = Stats.categoryLabels[category] or string.upper(category) })
        insertedHeader = true
      end

      table.insert(out, {
        type = "row",
        key = tracker.key,
        label = tracker.label,
        fmt = tracker.fmt,
        tracker = tracker,
      })
    end

    if category == "exploration" then
      table.insert(out, { type = "header", label = "INTERFACE HABITS" })
      table.insert(out, { type = "row", key = "mapOpened", label = "Times Opened Map", fmt = FormatNumber })
      table.insert(out, { type = "row", key = "characterOpened", label = "Times Opened Character Panel", fmt = FormatNumber })
      table.insert(out, { type = "row", key = "spellbookOpened", label = "Times Opened Spellbook", fmt = FormatNumber })
      table.insert(out, { type = "row", key = "questLogOpened", label = "Times Opened Quest Log", fmt = FormatNumber })
      table.insert(out, { type = "row", key = "talentsChecked", label = "Times Checked Talents", fmt = FormatNumber })
      table.insert(out, { type = "row", key = "timesLoggedIn", label = "Times Logged Into Current Character", fmt = FormatNumber })
    end
  end

  return out
end

function Stats.ColorsForKey(key)
  local tracker = Stats.trackersByKey[key]
  if tracker and tracker.colors then
    local c = tracker.colors
    return c[1], c[2], c[3], c[4], c[5], c[6]
  end

  if key == "mapOpened" or key == "characterOpened" or key == "spellbookOpened" or key == "questLogOpened" or key == "talentsChecked" or key == "timesLoggedIn" then
    return 0.90, 0.90, 0.90, 0.90, 0.90, 0.90
  end

  return GOLD[1], GOLD[2], GOLD[3], WHITE[1], WHITE[2], WHITE[3]
end

function Stats.TooltipBodyForKey(key)
  local tracker = Stats.trackersByKey[key]
  if tracker then
    if type(tracker.tooltip) == "function" then
      return tracker.tooltip(tracker)
    end
    return tracker.tooltip
  end

  if key == "mapOpened" then
    return "Counts how many times the world map has been opened."
  elseif key == "characterOpened" then
    return "Counts how many times the character panel has been opened."
  elseif key == "spellbookOpened" then
    return "Counts how many times the spellbook has been opened."
  elseif key == "questLogOpened" then
    return "Counts how many times the quest log has been opened."
  elseif key == "talentsChecked" then
    return "Counts how many times the talent window has been opened."
  elseif key == "timesLoggedIn" then
    return "Counts how many times you logged into this character."
  end

  return nil
end

-- Once-per-second sampler; a ticker, so nothing runs between beats.
C_Timer.NewTicker(1.0, function()
  Stats.DispatchUpdate(1.0)
  Stats.RefreshPanelIfVisible()
end)
