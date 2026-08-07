local _, JS = ...
local Stats = JS.Stats

local SPECIAL_WATCH_UNITS = { "target", "mouseover", "focus" }

local function UnitIsRare(unit)
  if not unit or not UnitExists or not UnitExists(unit) then return false end
  local c = UnitClassification and UnitClassification(unit)
  return c == "rare"
end

local function UnitIsRareElite(unit)
  if not unit or not UnitExists or not UnitExists(unit) then return false end
  local c = UnitClassification and UnitClassification(unit)
  return c == "rareelite"
end

local function UnitIsNormalElite(unit)
  if not unit or not UnitExists or not UnitExists(unit) then return false end
  local c = UnitClassification and UnitClassification(unit)
  return c == "elite"
end

local function UnitIsBossLike(unit)
  if not unit or not UnitExists or not UnitExists(unit) then return false end

  local c = UnitClassification and UnitClassification(unit)
  if c == "worldboss" then
    return true
  end

  local lvl = UnitLevel and UnitLevel(unit)
  if lvl == -1 then
    return true
  end

  return false
end

local function IsBossLikeMeta(meta)
  if not meta then return false end
  if meta.classification == "worldboss" then
    return true
  end
  if tonumber(meta.level or 0) == -1 then
    return true
  end
  return false
end

local function IsRareMeta(meta)
  return meta and meta.classification == "rare"
end

local function IsRareEliteMeta(meta)
  return meta and meta.classification == "rareelite"
end

local function IsNormalEliteMeta(meta)
  return meta and meta.classification == "elite"
end

function JS.RecordEliteSlain()
  Stats.IncStat("elitesSlain", 1)
end

function JS.CheckEliteKill(destGUID)
  if not destGUID or destGUID == "" then return end

  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0
  local last = tonumber(s.lastSpecialKilledGUIDs[destGUID] or 0) or 0
  if (now - last) < 1.5 then
    return
  end

  local meta = JS.GetTrackedKillMeta and JS.GetTrackedKillMeta(destGUID) or nil

  for i = 1, #SPECIAL_WATCH_UNITS do
    local unit = SPECIAL_WATCH_UNITS[i]
    if UnitGUID and UnitGUID(unit) == destGUID then
      s.lastSpecialKilledGUIDs[destGUID] = now
      if UnitIsBossLike(unit) then
        local name = UnitName and UnitName(unit) or nil
        if JS.RecordBossSlain then
          JS.RecordBossSlain(name)
        end
        return
      end

      if UnitIsRare(unit) then
        if JS.RecordRareSlain then
          JS.RecordRareSlain()
        end
        return
      end

      if UnitIsRareElite(unit) then
        if JS.RecordRareEliteSlain then
          JS.RecordRareEliteSlain()
        end
        return
      end

      if UnitIsNormalElite(unit) then
        if JS.RecordEliteSlain then
          JS.RecordEliteSlain()
        end
        return
      end
    end
  end

  if meta and meta.hostile then
    s.lastSpecialKilledGUIDs[destGUID] = now
    if IsBossLikeMeta(meta) then
      if JS.RecordBossSlain then
        JS.RecordBossSlain(meta.name)
      end
      return
    end

    if IsRareMeta(meta) then
      if JS.RecordRareSlain then
        JS.RecordRareSlain()
      end
      return
    end

    if IsRareEliteMeta(meta) then
      if JS.RecordRareEliteSlain then
        JS.RecordRareEliteSlain()
      end
      return
    end

    if IsNormalEliteMeta(meta) then
      if JS.RecordEliteSlain then
        JS.RecordEliteSlain()
      end
      return
    end
  end

  local inInstance, instanceType = IsInInstance and IsInInstance()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    s.lastSpecialKilledGUIDs[destGUID] = now
    if JS.RecordEliteSlain then
      JS.RecordEliteSlain()
    end
  end
end

JS.RegisterStatTracker({
  key = "elitesSlain",
  category = "combat",
  order = 30,
  label = "Elites Slain",
  fmt = Stats.FormatNumber,
  tooltip = "Counts normal elite enemies slain by you or your controlled companions.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
