local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "highestCritEver",
  category = "survival",
  label = "Highest Crit (Ever)",
  fmt = Stats.FormatNumber,
  tooltip = "Highest critical strike you have dealt on this character.",
  colors = {
    Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
    0.92, 0.92, 0.92,
  },
})
