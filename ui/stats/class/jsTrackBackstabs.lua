local _, JS = ...

JS.RegisterClassCastStat({
  key = "backstabsLanded",
  class = "ROGUE",
  order = 20,
  label = "Backstabs Landed",
  tooltip = "Counts Backstabs landed from the shadows.",
  subevent = "SPELL_DAMAGE",
  spellIDs = { 53 },
  spellNames = { "Backstab" },
})
