local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "lowestHPPctEver",
  category = "survival",
  label = "Lowest HP (Ever)",
  fmt = Stats.FormatPercent,
  tooltip = "Lowest health percentage ever reached on this character.",
  colors = {
    Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
    Stats.colors.REDVAL[1], Stats.colors.REDVAL[2], Stats.colors.REDVAL[3],
  },
})
