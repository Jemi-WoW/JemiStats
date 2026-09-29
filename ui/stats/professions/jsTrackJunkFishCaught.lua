local _, JS = ...
local Stats = JS.Stats

-- Counted by the fish tracker, which already reads the quality of each catch
JS.RegisterStatTracker({
  key = "junkFishCaught",
  category = "professions",
  label = "Junk Fish Caught",
  fmt = Stats.FormatNumber,
  tooltip = "Grey-quality catches nobody wanted, out of everything you reeled in.",
  colors = Stats.PROFESSION_COLORS,
})
