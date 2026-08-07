local _, JS = ...
local Stats = JS.Stats

function JS.RecordLowestHP(unit)
  if unit and unit ~= "player" then return end

  local maxHP = UnitHealthMax and (UnitHealthMax("player") or 0) or 0
  if maxHP <= 0 then return end

  local hp = UnitHealth and (UnitHealth("player") or maxHP) or maxHP
  local pct = (hp / maxHP) * 100
  local s = Stats.EnsureStatsDB()

  if Stats.InCombatNow() then
    local p = Stats.EnsurePendingCombatStats()

    if pct < (tonumber(p.lowestHPPctSession or 100) or 100) then
      p.lowestHPPctSession = pct
    end

    if pct < (tonumber(p.lowestHPPctEver or 100) or 100) then
      p.lowestHPPctEver = pct
    end
    return
  end

  local changed = false

  if pct < (tonumber(s.lowestHPPctSession or 100) or 100) then
    s.lowestHPPctSession = pct
    Stats.QueueRecordAlert("New lowest HP this session", Stats.FormatPercent(pct))
    changed = true
  end

  if pct < (tonumber(s.lowestHPPctEver or 100) or 100) then
    s.lowestHPPctEver = pct
    Stats.QueueRecordAlert("New lowest HP ever", Stats.FormatPercent(pct))
    changed = true
  end

  if changed then
    Stats.RefreshPanelIfVisible()
  end
end

JS.RegisterStatTracker({
  key = "lowestHPPctSession",
  category = "survival",
  label = "Lowest HP (Session)",
  fmt = Stats.FormatPercent,
  tooltip = "Lowest health percentage reached during this session.",
  colors = {
    Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
    Stats.colors.REDVAL[1], Stats.colors.REDVAL[2], Stats.colors.REDVAL[3],
  },
  OnEvent = function(_, event, unit)
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and unit == "player" and JS.RecordLowestHP then
      JS.RecordLowestHP(unit)
    end
  end,
})
