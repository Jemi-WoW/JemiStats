local _, JS = ...
local Stats = JS.Stats

local function AverageCombatDuration()
  local s = Stats.EnsureStatsDB()
  local count = tonumber(s.combatCount or 0) or 0
  if count <= 0 then return 0 end
  return (tonumber(s.combatDurationTotal or 0) or 0) / count
end

local function HandleCombatStarted()
  local s = Stats.EnsureStatsDB()
  if tonumber(s.combatStartedAt or 0) > 0 then
    return
  end
  s.combatStartedAt = GetTime and GetTime() or 0
end

local function HandleCombatEnded()
  local s = Stats.EnsureStatsDB()
  local started = tonumber(s.combatStartedAt or 0) or 0
  if started > 0 then
    local now = GetTime and GetTime() or 0
    local elapsed = math.max(0, now - started)
    if elapsed > 0 then
      s.combatCount = (tonumber(s.combatCount or 0) or 0) + 1
      s.combatDurationTotal = (tonumber(s.combatDurationTotal or 0) or 0) + elapsed
    end
    s.combatStartedAt = 0
  end

  if JS.FlushPendingStatRecords then
    JS.FlushPendingStatRecords()
  end
  Stats.RefreshPanelIfVisible()
end

JS.RegisterStatTracker({
  key = "combatDurationAverage",
  category = "combat",
  order = 60,
  label = "Combat Duration Average (Session)",
  fmt = Stats.FormatDuration,
  tooltip = "Average duration of your completed combats this session.",
  getValue = function()
    return AverageCombatDuration()
  end,
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnSessionReset = function()
    local s = Stats.EnsureStatsDB()
    s.combatCount = 0
    s.combatDurationTotal = 0
    s.combatStartedAt = 0
  end,
  OnEvent = function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
      HandleCombatStarted()
    elseif event == "PLAYER_REGEN_ENABLED" then
      HandleCombatEnded()
    end
  end,
})
