local _, JS = ...

JS.RegisterClassCastStat({
  key = "timesShapeshifted",
  class = "DRUID",
  order = 10,
  label = "Times Shapeshifted",
  tooltip = "Counts every animal form you've shifted into.",
  -- The Burning Crusade forms resolve to nil on Classic Era and are skipped
  spellIDs = { 5487, 9634, 768, 783, 1066, 24858, 33943, 40120, 33891 },
  spellNames = {
    "Bear Form", "Dire Bear Form", "Cat Form", "Travel Form", "Aquatic Form", "Moonkin Form",
    "Flight Form", "Swift Flight Form", "Tree of Life",
  },
})
