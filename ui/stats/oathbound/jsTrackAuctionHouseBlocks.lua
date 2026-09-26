local _, JS = ...
local Stats = JS.Stats

-- Registered only with Oathbound loaded; it pushes the count through the API.
JS.DeferStatTracker("Oathbound", {
  key = "auctionHouseBlocks",
  category = "oathbound",
  label = "Auction House Blocks",
  fmt = Stats.FormatNumber,
  tooltip = "Counts Auction House openings blocked by Oathbound.",
  colors = {
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
  },
})
