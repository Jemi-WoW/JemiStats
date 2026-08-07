local _, JS = ...
local Stats = JS.Stats

function JS.RecordRareSlain()
  Stats.IncStat("raresSlain", 1)
end

JS.RegisterStatTracker({
  key = "raresSlain",
  category = "combat",
  order = 20,
  label = "Rares Slain",
  fmt = Stats.FormatNumber,
  tooltip = "Counts rare enemies slain by you or your controlled companions.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
