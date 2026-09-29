local _, JS = ...
local Stats = JS.Stats

-- One debuff covers every bandage, from linen to netherweave
local RECENTLY_BANDAGED = 11196

JS.RegisterStatTracker({
  key = "bandagesUsed",
  category = "professions",
  label = "Bandages Used",
  fmt = Stats.FormatNumber,
  tooltip = "First aid bandages you applied, to yourself or to someone else.",
  colors = Stats.PROFESSION_COLORS,
  OnCombatLog = function(_, _, subevent, _, srcGUID, _, _, _, _, _, _, _, spellID)
    if subevent ~= "SPELL_AURA_APPLIED" or spellID ~= RECENTLY_BANDAGED then return end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or srcGUID ~= playerGUID then return end

    Stats.IncStat("bandagesUsed", 1)
  end,
})
