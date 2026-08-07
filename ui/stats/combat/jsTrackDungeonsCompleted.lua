local _, JS = ...
local Stats = JS.Stats

local function BuildCompletedDungeonsTooltip()
  local s = Stats.EnsureStatsDB()
  local names = {}

  for dungeonName, count in pairs(s.completedDungeons or {}) do
    local pretty = tostring(dungeonName or "")
    local n = tonumber(count or 0) or 0
    if pretty ~= "" and n > 0 then
      if n > 1 then
        table.insert(names, string.format("%s x%d", pretty, n))
      else
        table.insert(names, pretty)
      end
    end
  end

  table.sort(names)

  if #names == 0 then
    return "No dungeons completed :("
  end

  return table.concat(names, "\n")
end

JS.RegisterStatTracker({
  key = "dungeonsCompleted",
  category = "combat",
  order = 80,
  label = "Dungeons Completed",
  fmt = Stats.FormatNumber,
  tooltip = function()
    return "Completed dungeons:\n" .. BuildCompletedDungeonsTooltip()
  end,
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
