local _, JS = ...
local Stats = JS.Stats

local function HandleMoneyChanged()
  local s = Stats.EnsureStatsDB()
  if not GetMoney then return end
  local money = tonumber(GetMoney() or 0) or 0
  local prev = tonumber(s.lastMoney or money) or money
  local diff = money - prev

  if diff > 0 then
    Stats.IncStat("goldEarnedSession", diff)
    Stats.IncStat("goldEarnedTotal", diff)
  elseif diff < 0 then
    Stats.IncStat("goldSpentTotal", math.abs(diff))
  end

  s.lastMoney = money
end

JS.RegisterStatTracker({
  key = "goldEarnedSession",
  category = "economy",
  label = "Gold Earned (Session)",
  fmt = Stats.FormatCopper,
  tooltip = "Positive gold changes recorded during this session.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnEvent = function(_, event)
    if event == "PLAYER_MONEY" then
      HandleMoneyChanged()
    end
  end,
})
