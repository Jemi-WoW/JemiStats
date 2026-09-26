local _, JS = ...

-- SPELL_SUMMON from the player catches every totem, so no spell list.
JS.RegisterClassCastStat({
  key = "totemsDropped",
  class = "SHAMAN",
  order = 10,
  label = "Totems Dropped",
  tooltip = "Counts every totem you've dropped.",
  subevent = "SPELL_SUMMON",
})
