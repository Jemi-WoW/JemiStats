local _, JS = ...
local Stats = JS.Stats

if not JS._auctionPostHookInstalled then
  JS._auctionPostHookInstalled = JS.HookAuctionPost(function()
    Stats.IncStat("auctionsPosted", 1)
  end)
end

JS.RegisterStatTracker({
  key = "auctionsPosted",
  category = "economy",
  order = 60,
  label = "Auctions Posted",
  fmt = Stats.FormatNumber,
  tooltip = "Items you put up for sale at the auction house.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
