local _, JS = ...

JS.RegisterClassCastStat({
  key = "layOnHandsCast",
  class = "PALADIN",
  order = 20,
  label = "Lay on Hands Cast",
  tooltip = "Counts the clutch Lay on Hands you've used.",
  spellIDs = { 633 },
  spellNames = { "Lay on Hands" },
})
