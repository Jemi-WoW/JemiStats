local _, JS = ...

-- SPELL_SUMMON from the player catches every demon, so no spell list.
JS.RegisterClassCastStat({
  key = "demonsSummoned",
  class = "WARLOCK",
  order = 10,
  label = "Demons Summoned",
  tooltip = "Counts every demon you've summoned.",
  subevent = "SPELL_SUMMON",
})
