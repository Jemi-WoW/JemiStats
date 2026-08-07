local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "distanceEver",
  category = "exploration",
  label = "Distance Traveled (Ever)",
  fmt = Stats.FormatDistance,
  tooltip = "Approximate distance traveled ever on this character.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
})
