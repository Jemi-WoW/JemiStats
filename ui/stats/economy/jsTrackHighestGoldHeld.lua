local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "highestGoldHeld",
  category = "economy",
  order = 35,
  label = "Highest Gold Held",
  fmt = Stats.FormatCopper,
  tooltip = "The most money you have ever had on you at once.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnPlayerLogin = function()
    if not GetMoney then return end
    local s = Stats.EnsureStatsDB()
    local money = tonumber(GetMoney() or 0) or 0
    if money > (tonumber(s.highestGoldHeld or 0) or 0) then
      s.highestGoldHeld = money
    end
  end,
  OnEvent = function(_, event)
    if event ~= "PLAYER_MONEY" or not GetMoney then return end

    local s = Stats.EnsureStatsDB()
    local money = tonumber(GetMoney() or 0) or 0
    if money <= (tonumber(s.highestGoldHeld or 0) or 0) then return end

    s.highestGoldHeld = money
    Stats.RefreshPanelIfVisible()
  end,
})
