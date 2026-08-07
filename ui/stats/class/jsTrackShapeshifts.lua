local _, JS = ...

JS.RegisterClassCastStat({
  key = "timesShapeshifted",
  class = "DRUID",
  order = 10,
  label = "Times Shapeshifted",
  tooltip = "Counts every animal form you've shifted into.",
  spellIDs = { 5487, 9634, 768, 783, 1066, 24858 },
  spellNames = { "Bear Form", "Dire Bear Form", "Cat Form", "Travel Form", "Aquatic Form", "Moonkin Form" },
})
