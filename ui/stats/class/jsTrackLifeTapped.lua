local _, JS = ...

JS.RegisterClassCastStat({
  key = "lifeTapped",
  class = "WARLOCK",
  order = 20,
  label = "Times Life Tapped",
  tooltip = "Counts Life Tap casts -- trading health for mana.",
  spellIDs = { 1454 },
  spellNames = { "Life Tap" },
})
