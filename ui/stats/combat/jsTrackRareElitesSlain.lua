local _, JS = ...
local Stats = JS.Stats

function JS.RecordRareEliteSlain()
  Stats.IncStat("rareElitesSlain", 1)
end

JS.RegisterStatTracker({
  key = "rareElitesSlain",
  category = "combat",
  order = 40,
  label = "Rare Elites Slain",
  fmt = Stats.FormatNumber,
  tooltip = "Counts rare elite enemies slain by you.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
