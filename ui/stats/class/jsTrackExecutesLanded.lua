local _, JS = ...

JS.RegisterClassCastStat({
  key = "executesLanded",
  class = "WARRIOR",
  order = 20,
  label = "Executes Landed",
  tooltip = "Counts the finishing Executes you've landed.",
  subevent = "SPELL_DAMAGE",
  spellIDs = { 5308 },
  spellNames = { "Execute" },
})
