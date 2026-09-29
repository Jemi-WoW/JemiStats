local _, JS = ...
local Stats = JS.Stats

local HEARTHSTONE = 8690

JS.RegisterStatTracker({
  key = "hearthstonesUsed",
  category = "exploration",
  label = "Hearthstones Used",
  fmt = Stats.FormatNumber,
  tooltip = "How many times you hearthed back to your home inn.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
  OnEvent = function(_, event, unit, _, spellID)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" then return end
    if spellID ~= HEARTHSTONE then return end
    Stats.IncStat("hearthstonesUsed", 1)
  end,
})
