local _, JS = ...
local Stats = JS.Stats

local bit_band = bit and bit.band

local MINE_FLAG = COMBATLOG_OBJECT_AFFILIATION_MINE or 0
local HOSTILE_FLAG = COMBATLOG_OBJECT_REACTION_HOSTILE or 0
local CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER or 0
local TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0
local TYPE_PET = COMBATLOG_OBJECT_TYPE_PET or 0
local TYPE_GUARDIAN = COMBATLOG_OBJECT_TYPE_GUARDIAN or 0
local TYPE_OBJECT = COMBATLOG_OBJECT_TYPE_OBJECT or 0

local DAMAGE_SUBEVENTS = {
  SWING_DAMAGE = true,
  RANGE_DAMAGE = true,
  SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
  DAMAGE_SHIELD = true,
  DAMAGE_SPLIT = true,
}

local KILL_SUBEVENTS = {
  PARTY_KILL = true,
  UNIT_DIED = true,
  UNIT_DESTROYED = true,
  UNIT_DISSIPATES = true,
}

local WATCH_UNITS = { "target", "mouseover", "focus" }

local function IsMineSource(sourceGUID, sourceFlags)
  if sourceGUID and UnitGUID and sourceGUID == UnitGUID("player") then
    return true
  end

  if not bit_band or not sourceFlags then
    return false
  end

  local isMine = bit_band(sourceFlags, MINE_FLAG) > 0
  if not isMine then
    return false
  end

  local controlled = bit_band(sourceFlags, CONTROL_PLAYER) > 0
  local typed = bit_band(sourceFlags, TYPE_PLAYER + TYPE_PET + TYPE_GUARDIAN + TYPE_OBJECT) > 0
  return controlled or typed
end

local function IsHostileDest(destFlags)
  if not bit_band or not destFlags or HOSTILE_FLAG == 0 then
    return true
  end
  return bit_band(destFlags, HOSTILE_FLAG) > 0
end

local function RememberTaggedKill(destGUID, destFlags)
  if not destGUID or destGUID == "" then return end

  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0

  s.playerKillCreditGUIDs = s.playerKillCreditGUIDs or {}
  s.playerKillCreditGUIDs[destGUID] = now

  s.killMetaByGUID = s.killMetaByGUID or {}
  local meta = s.killMetaByGUID[destGUID] or {}
  meta.lastSeen = now
  meta.hostile = IsHostileDest(destFlags)

  for i = 1, #WATCH_UNITS do
    local unit = WATCH_UNITS[i]
    if UnitGUID and UnitGUID(unit) == destGUID then
      meta.name = UnitName and UnitName(unit) or meta.name
      meta.classification = UnitClassification and UnitClassification(unit) or meta.classification
      meta.level = UnitLevel and UnitLevel(unit) or meta.level
      break
    end
  end

  s.killMetaByGUID[destGUID] = meta
end

function JS.HasTrackedKillCredit(destGUID)
  if not destGUID or destGUID == "" then return false end

  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0
  local stamp = tonumber(s.playerKillCreditGUIDs and s.playerKillCreditGUIDs[destGUID] or 0) or 0
  if stamp <= 0 then
    return false
  end

  return (now - stamp) <= 10.0
end

function JS.GetTrackedKillMeta(destGUID)
  if not destGUID or destGUID == "" then return nil end
  local s = Stats.EnsureStatsDB()
  return s.killMetaByGUID and s.killMetaByGUID[destGUID] or nil
end

local function CleanupKillCredit(destGUID)
  if not destGUID or destGUID == "" then return end
  local s = Stats.EnsureStatsDB()
  if s.playerKillCreditGUIDs then
    s.playerKillCreditGUIDs[destGUID] = nil
  end
  if s.killMetaByGUID then
    s.killMetaByGUID[destGUID] = nil
  end
end

function JS.RecordEnemySlain(destGUID)
  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0

  if destGUID and destGUID ~= "" then
    local last = tonumber(s.lastKilledGUIDs[destGUID] or 0) or 0
    if (now - last) < 1.5 then
      CleanupKillCredit(destGUID)
      return
    end
    s.lastKilledGUIDs[destGUID] = now
  end

  s.enemiesSlain = (tonumber(s.enemiesSlain or 0) or 0) + 1
  CleanupKillCredit(destGUID)
  Stats.RefreshPanelIfVisible()
end

JS.RegisterStatTracker({
  key = "enemiesSlain",
  category = "combat",
  order = 10,
  label = "Enemies Slain",
  fmt = Stats.FormatNumber,
  tooltip = "Counts enemies slain by you or your controlled companions.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnCombatLog = function(_, _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags)
    if DAMAGE_SUBEVENTS[subevent] and IsMineSource(sourceGUID, sourceFlags) then
      RememberTaggedKill(destGUID, destFlags)
      return
    end

    if not KILL_SUBEVENTS[subevent] or not JS.HasTrackedKillCredit or not JS.HasTrackedKillCredit(destGUID) then
      return
    end

    if JS.RecordEnemySlain then
      JS.RecordEnemySlain(destGUID)
    end
    if JS.CheckEliteKill then
      JS.CheckEliteKill(destGUID)
    end
  end,
})
