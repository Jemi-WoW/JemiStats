local _, JS = ...

JS.RegisterClassCastStat({
  key = "polymorphsCast",
  class = "MAGE",
  order = 10,
  label = "Polymorphs Cast",
  tooltip = "Counts how many enemies you've turned into critters.",
  spellIDs = { 118 },
  spellNames = { "Polymorph" },
})
