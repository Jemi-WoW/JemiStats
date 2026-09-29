local _, JS = ...
local Stats = JS.Stats

local BRONZE = {
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
}

JS.RegisterStatTracker({
  key = "dispels",
  category = "combat",
  order = 100,
  label = "Dispels",
  fmt = Stats.FormatNumber,
  tooltip = "Buffs and debuffs you removed, including spells you stole.",
  colors = BRONZE,
  OnCombatLog = function(_, _, subevent, _, srcGUID)
    if subevent ~= "SPELL_DISPEL" and subevent ~= "SPELL_STOLEN" then return end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or srcGUID ~= playerGUID then return end

    Stats.IncStat("dispels", 1)
  end,
})
