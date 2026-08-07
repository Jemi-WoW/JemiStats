local _, JS = ...

JS.RegisterClassCastStat({
  key = "mindControlsCast",
  class = "PRIEST",
  order = 20,
  label = "Mind Controls Cast",
  tooltip = "Counts how many minds you've controlled.",
  spellIDs = { 605 },
  spellNames = { "Mind Control" },
})
