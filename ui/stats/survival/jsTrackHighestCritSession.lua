local _, JS = ...
local Stats = JS.Stats
local bit_band = bit and bit.band

local function IsMineCombatSource(srcGUID, srcFlags, playerGUID)
  if not playerGUID or not srcGUID then return false end
  if srcGUID == playerGUID then return true end
  return bit_band and srcFlags and bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE or 0) > 0
end

function JS.RecordHighestCrit(amount)
  amount = tonumber(amount or 0) or 0
  if amount <= 0 then return end

  local s = Stats.EnsureStatsDB()

  if Stats.InCombatNow() then
    local p = Stats.EnsurePendingCombatStats()
    if amount > (tonumber(p.highestCritSession or 0) or 0) then
      p.highestCritSession = amount
    end
    return
  end

  local changed = false

  if amount > (tonumber(s.highestCritSession or 0) or 0) then
    s.highestCritSession = amount
    Stats.QueueRecordAlert("New highest crit this session", Stats.FormatNumber(amount))
    changed = true
  end

  if amount > (tonumber(s.highestCritEver or 0) or 0) then
    s.highestCritEver = amount
    changed = true
  end

  if changed then
    Stats.RefreshPanelIfVisible()
  end
end


function JS.FlushPendingStatRecords()
  local s = Stats.EnsureStatsDB()
  local p = s.pendingCombatRecords
  if not p then return end

  local changed = false

  local pendingCrit = tonumber(p.highestCritSession or 0) or 0
  if pendingCrit > 0 then
    if pendingCrit > (tonumber(s.highestCritSession or 0) or 0) then
      s.highestCritSession = pendingCrit
      Stats.QueueRecordAlert("New highest crit this session", Stats.FormatNumber(pendingCrit))
      changed = true
    end
    if pendingCrit > (tonumber(s.highestCritEver or 0) or 0) then
      s.highestCritEver = pendingCrit
      changed = true
    end
  end

  local pendingLowSession = tonumber(p.lowestHPPctSession or 100) or 100
  if pendingLowSession < (tonumber(s.lowestHPPctSession or 100) or 100) then
    s.lowestHPPctSession = pendingLowSession
    Stats.QueueRecordAlert("New lowest HP this session", Stats.FormatPercent(pendingLowSession))
    changed = true
  end

  local pendingLowEver = tonumber(p.lowestHPPctEver or 100) or 100
  if pendingLowEver < (tonumber(s.lowestHPPctEver or 100) or 100) then
    s.lowestHPPctEver = pendingLowEver
    Stats.QueueRecordAlert("New lowest HP ever", Stats.FormatPercent(pendingLowEver))
    changed = true
  end

  s.pendingCombatRecords = {
    highestCritSession = 0,
    lowestHPPctSession = 100,
    lowestHPPctEver = 100,
  }

  if changed then
    Stats.RefreshPanelIfVisible()
  end
end

JS.RegisterStatTracker({
  key = "highestCritSession",
  category = "survival",
  label = "Highest Crit (Session)",
  fmt = Stats.FormatNumber,
  tooltip = "Highest critical strike you have dealt during this session.",
  colors = {
    Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
    0.92, 0.92, 0.92,
  },
  OnCombatLog = function(_, _, subevent, _, srcGUID, _, srcFlags, _, _, _, _, _,
                         arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21)
    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    local isPlayerSource = playerGUID and srcGUID == playerGUID
    local isMineSource = IsMineCombatSource(srcGUID, srcFlags, playerGUID)

    if not isMineSource then
      return
    end

    if subevent == "SWING_DAMAGE" then
      if arg18 then
        JS.RecordHighestCrit(arg12)
      end
      return
    end

    if isPlayerSource and (subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") then
      if arg21 then
        JS.RecordHighestCrit(arg15)
      end
    end
  end,
})
