local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "goldEarnedTotal",
  category = "economy",
  label = "Gold Earned (Total)",
  fmt = Stats.FormatCopper,
  tooltip = "Positive gold changes recorded on this character overall.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
