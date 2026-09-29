local _, JS = ...
local Stats = JS.Stats

local BRONZE = {
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
}

-- Selling has no event of its own: a bag item used while a merchant is open is a sale
if not JS._vendorSaleHookInstalled then
  JS._vendorSaleHookInstalled = JS.HookContainerItemUse(function()
    local s = Stats.EnsureStatsDB()
    if not s._merchantOpen then return end
    Stats.IncStat("itemsSoldToVendors", 1)
  end)
end

JS.RegisterStatTracker({
  key = "itemsSoldToVendors",
  category = "economy",
  order = 50,
  label = "Items Sold to Vendors",
  fmt = Stats.FormatNumber,
  tooltip = "Items you sold at a merchant.",
  colors = BRONZE,
  OnEvent = function(_, event)
    if event == "MERCHANT_SHOW" then
      Stats.EnsureStatsDB()._merchantOpen = true
    elseif event == "MERCHANT_CLOSED" then
      Stats.EnsureStatsDB()._merchantOpen = false
    end
  end,
})
