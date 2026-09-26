local _, JS = ...
local Stats = JS.Stats

-- Registered only with Oathbound loaded; it pushes the count through the API.
JS.DeferStatTracker("Oathbound", {
  key = "tradesBlocked",
  category = "oathbound",
  label = "Trades Blocked",
  fmt = Stats.FormatNumber,
  tooltip = "Counts blocked trade attempts while Oathbound protection was active.",
  colors = {
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
  },
})
