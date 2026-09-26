local _, JS = ...
local Stats = JS.Stats

-- Display only; the value is kept by the ammo sampler in jsTrackArrowsShot.lua.
JS.RegisterStatTracker({
  key = "bulletsShot",
  category = "class",
  class = "HUNTER",
  order = 20,
  label = "Bullets Shot",
  fmt = Stats.FormatNumber,
  tooltip = "Counts bullets you've fired from guns.",
  colors = {
    Stats.colors.GREEN[1], Stats.colors.GREEN[2], Stats.colors.GREEN[3],
    Stats.colors.WHITE[1], Stats.colors.WHITE[2], Stats.colors.WHITE[3],
  },
})
