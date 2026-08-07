local _, JS = ...

JS.RegisterClassCastStat({
  key = "timesBlinked",
  class = "MAGE",
  order = 20,
  label = "Times Blinked",
  tooltip = "Counts how many times you've Blinked.",
  spellIDs = { 1953 },
  spellNames = { "Blink" },
})
