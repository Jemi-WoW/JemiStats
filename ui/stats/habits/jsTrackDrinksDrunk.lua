local _, JS = ...
local Stats = JS.Stats

-- Counted by the food tracker, which reads both auras in one pass
JS.RegisterStatTracker({
  key = "drinksDrunk",
  category = "habits",
  label = "Drinks Drunk",
  fmt = Stats.FormatNumber,
  tooltip = "How many times you sat down to drink.",
  colors = Stats.HABIT_COLORS,
})
