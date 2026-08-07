local _, JS = ...

JS.RegisterClassCastStat({
  key = "pocketsPicked",
  class = "ROGUE",
  order = 10,
  label = "Pockets Picked",
  tooltip = "Counts how many pockets you've picked.",
  spellIDs = { 921 },
  spellNames = { "Pick Pocket" },
})
