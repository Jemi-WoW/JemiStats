local _, JS = ...
local Stats = JS.Stats
local bit_band = bit and bit.band

local function IsMineCombatSource(srcGUID, srcFlags, playerGUID)
  if not playerGUID or not srcGUID then return false end
  if srcGUID == playerGUID then return true end
  return bit_band and srcFlags and bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE or 0) > 0
end

JS.RegisterStatTracker({
  key = "missedAttacks",
  category = "survival",
  label = "Times You Missed Attacks",
  fmt = Stats.FormatNumber,
  tooltip = "Counts your own melee, ranged, and spell miss events from the combat log.",
  colors = {
    Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
    0.92, 0.92, 0.92,
  },
  OnCombatLog = function(_, _, subevent, _, srcGUID, _, srcFlags)
    if subevent ~= "SWING_MISSED" and subevent ~= "RANGE_MISSED" and subevent ~= "SPELL_MISSED" then
      return
    end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not IsMineCombatSource(srcGUID, srcFlags, playerGUID) then
      return
    end

    Stats.IncStat("missedAttacks", 1)
  end,
})
