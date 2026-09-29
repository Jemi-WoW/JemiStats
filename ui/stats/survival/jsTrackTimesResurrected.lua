local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "timesResurrected",
  category = "survival",
  label = "Times Resurrected",
  fmt = Stats.FormatNumber,
  tooltip = "How many times you came back from a death, by corpse run or by rez.",
  colors = Stats.SURVIVAL_COLORS,
  OnEvent = function(_, event)
    if event ~= "PLAYER_UNGHOST" and event ~= "PLAYER_ALIVE" then return end

    local s = Stats.EnsureStatsDB()
    if not s._deadAt then return end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return end

    s._deadAt = nil
    Stats.IncStat("timesResurrected", 1)
  end,
})
