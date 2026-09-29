local _, JS = ...
local Stats = JS.Stats

-- Counted by the deaths tracker, which knows what the last damage was
JS.RegisterStatTracker({
  key = "deathsByDrowning",
  category = "survival",
  label = "Deaths by Drowning",
  fmt = Stats.FormatNumber,
  tooltip = "Deaths where you ran out of air underwater.",
  colors = Stats.SURVIVAL_COLORS,
})
