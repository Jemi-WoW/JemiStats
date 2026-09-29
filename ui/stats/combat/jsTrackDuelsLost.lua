local _, JS = ...
local Stats = JS.Stats

-- Counted by the duels-won tracker, which parses both results from one message
JS.RegisterStatTracker({
  key = "duelsLost",
  category = "combat",
  order = 130,
  label = "Duels Lost",
  fmt = Stats.FormatNumber,
  tooltip = "Duels you lost, by knockout or because you fled.",
  colors = Stats.DUEL_COLORS,
})
