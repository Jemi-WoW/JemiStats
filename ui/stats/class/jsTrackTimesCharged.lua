local _, JS = ...

JS.RegisterClassCastStat({
  key = "timesCharged",
  class = "WARRIOR",
  order = 10,
  label = "Times Charged",
  tooltip = "Counts how many times you've charged into battle.",
  spellIDs = { 100 },
  spellNames = { "Charge" },
})
