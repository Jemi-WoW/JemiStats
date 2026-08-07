local _, JS = ...

JS.RegisterClassCastStat({
  key = "battleRezzes",
  class = "DRUID",
  order = 20,
  label = "Battle Rezzes",
  tooltip = "Counts Rebirth combat resurrections you've cast.",
  spellIDs = { 20484 },
  spellNames = { "Rebirth" },
})
