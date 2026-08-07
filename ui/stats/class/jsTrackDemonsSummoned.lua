local _, JS = ...

-- Demons are summoned, so SPELL_SUMMON from the player catches every pet
-- (Imp, Voidwalker, Succubus, Felhunter, Infernal, ...) without a spell list.
JS.RegisterClassCastStat({
  key = "demonsSummoned",
  class = "WARLOCK",
  order = 10,
  label = "Demons Summoned",
  tooltip = "Counts every demon you've summoned.",
  subevent = "SPELL_SUMMON",
})
