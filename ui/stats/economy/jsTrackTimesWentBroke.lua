local _, JS = ...
local Stats = JS.Stats

JS.RegisterStatTracker({
  key = "timesWentBroke",
  category = "economy",
  order = 70,
  label = "Times Went Broke",
  fmt = Stats.FormatNumber,
  tooltip = "How many times your last copper left you with nothing.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnPlayerLogin = function()
    if not GetMoney then return end
    Stats.EnsureStatsDB()._wasBroke = (tonumber(GetMoney() or 0) or 0) <= 0
  end,
  OnEvent = function(_, event)
    if event ~= "PLAYER_MONEY" or not GetMoney then return end

    local s = Stats.EnsureStatsDB()
    local broke = (tonumber(GetMoney() or 0) or 0) <= 0

    -- Only the moment of hitting zero counts, not every change made while there
    if broke and not s._wasBroke then
      Stats.IncStat("timesWentBroke", 1)
    end

    s._wasBroke = broke
  end,
})
