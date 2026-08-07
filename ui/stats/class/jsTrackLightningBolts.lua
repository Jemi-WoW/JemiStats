local _, JS = ...

JS.RegisterClassCastStat({
  key = "lightningBoltsCast",
  class = "SHAMAN",
  order = 20,
  label = "Lightning Bolts Cast",
  tooltip = "Counts the Lightning Bolts you've hurled.",
  spellIDs = { 403 },
  spellNames = { "Lightning Bolt" },
})
