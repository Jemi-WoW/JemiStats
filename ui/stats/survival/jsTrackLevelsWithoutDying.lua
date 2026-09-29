local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "levelsWithoutDying",
  category = "survival",
  label = "Levels Without Dying",
  fmt = Stats.FormatNumber,
  tooltip = "The level you reached before dying for the first time. Still climbing while the death count is zero.",
  colors = Stats.SURVIVAL_COLORS,
  getValue = function(_, s)
    if (tonumber(s.deaths or 0) or 0) > 0 then
      return tonumber(s.levelAtFirstDeath or 0) or 0
    end
    return JS.PlayerLevel()
  end,
})
