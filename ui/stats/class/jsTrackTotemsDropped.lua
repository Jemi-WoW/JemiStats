local _, JS = ...

-- Totems are summoned, so SPELL_SUMMON from the player catches every totem
-- without needing a per-totem spell list.
JS.RegisterClassCastStat({
  key = "totemsDropped",
  class = "SHAMAN",
  order = 10,
  label = "Totems Dropped",
  tooltip = "Counts every totem you've dropped.",
  subevent = "SPELL_SUMMON",
})
