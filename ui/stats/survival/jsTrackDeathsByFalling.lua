local _, JS = ...
local Stats = JS.Stats

-- Counted by the deaths tracker, which knows what the last damage was
JS.RegisterStatTracker({
  key = "deathsByFalling",
  category = "survival",
  label = "Deaths by Falling",
  fmt = Stats.FormatNumber,
  tooltip = "Deaths where the last thing to hurt you was the ground.",
  colors = Stats.SURVIVAL_COLORS,
})
