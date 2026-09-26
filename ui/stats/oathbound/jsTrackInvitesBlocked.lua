local _, JS = ...
local Stats = JS.Stats

-- Registered only with Oathbound loaded; it pushes the count through the API.
JS.DeferStatTracker("Oathbound", {
  key = "invitesBlocked",
  category = "oathbound",
  label = "Invites Blocked",
  fmt = Stats.FormatNumber,
  tooltip = "Counts blocked group invites while Oathbound protection was active.",
  colors = {
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
  },
})
