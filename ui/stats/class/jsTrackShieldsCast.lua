local _, JS = ...

JS.RegisterClassCastStat({
  key = "shieldsCast",
  class = "PRIEST",
  order = 10,
  label = "Shields Cast",
  tooltip = "Counts Power Word: Shield casts.",
  spellIDs = { 17 },
  spellNames = { "Power Word: Shield" },
})
