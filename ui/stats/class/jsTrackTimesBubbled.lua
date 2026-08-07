local _, JS = ...

JS.RegisterClassCastStat({
  key = "timesBubbled",
  class = "PALADIN",
  order = 10,
  label = "Times Bubbled",
  tooltip = "Counts Divine Shield casts -- the bubble that saves lives.",
  spellIDs = { 642 },
  spellNames = { "Divine Shield" },
})
