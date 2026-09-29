local _, JS = ...
local Stats = JS.Stats

local BRONZE = {
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
}

JS.RegisterStatTracker({
  key = "killingBlows",
  category = "combat",
  order = 55,
  label = "Killing Blows",
  fmt = Stats.FormatNumber,
  tooltip = "Enemies you personally landed the final hit on.",
  colors = BRONZE,
  OnCombatLog = function(_, _, subevent, _, srcGUID)
    if subevent ~= "PARTY_KILL" then return end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or srcGUID ~= playerGUID then return end

    Stats.IncStat("killingBlows", 1)
  end,
})
