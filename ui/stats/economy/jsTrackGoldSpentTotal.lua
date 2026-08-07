local _, JS = ...
local Stats = JS.Stats

local function FormatSpentCopper(v)
  v = tonumber(v) or 0
  if v <= 0 then
    return Stats.FormatCopper(0)
  end
  return "-" .. Stats.FormatCopper(v)
end

JS.RegisterStatTracker({
  key = "goldSpentTotal",
  category = "economy",
  label = "Gold Spent (Ever)",
  fmt = FormatSpentCopper,
  tooltip = "Negative gold changes recorded on this character overall.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})