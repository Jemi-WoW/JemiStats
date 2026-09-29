local _, JS = ...
local Stats = JS.Stats

local BRONZE = {
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
}

JS.RegisterStatTracker({
  key = "resurrectionsCast",
  category = "combat",
  order = 110,
  label = "Resurrections Cast",
  fmt = Stats.FormatNumber,
  tooltip = "Players you brought back to life.",
  colors = BRONZE,
  OnCombatLog = function(_, _, subevent, _, srcGUID)
    if subevent ~= "SPELL_RESURRECT" then return end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or srcGUID ~= playerGUID then return end

    Stats.IncStat("resurrectionsCast", 1)
  end,
})
