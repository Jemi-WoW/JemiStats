local _, JS = ...
local Stats = JS.Stats

local DISENCHANT = 13262

local disenchantName

JS.RegisterStatTracker({
  key = "itemsDisenchanted",
  category = "economy",
  order = 90,
  label = "Items Disenchanted",
  fmt = Stats.FormatNumber,
  tooltip = "Items you broke down into enchanting materials.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnEvent = function(_, event, unit, _, spellID)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" or not spellID then return end

    disenchantName = disenchantName or JS.GetSpellName(DISENCHANT)
    if not disenchantName or JS.GetSpellName(spellID) ~= disenchantName then return end

    Stats.IncStat("itemsDisenchanted", 1)
  end,
})
