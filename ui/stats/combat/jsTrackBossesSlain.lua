local _, JS = ...
local Stats = JS.Stats

local function BuildBossesTooltip()
  local s = Stats.EnsureStatsDB()
  local names = {}

  for bossName, count in pairs(s.bossKillNames or {}) do
    local pretty = tostring(bossName or "")
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
    return "No bosses slain :("
  end

  return table.concat(names, "\n")
end

local function RecordBossKillName(name)
  local s = Stats.EnsureStatsDB()
  name = tostring(name or "")
  if name == "" then return end
  s.bossKillNames[name] = (tonumber(s.bossKillNames[name] or 0) or 0) + 1
end

function JS.RecordBossSlain(name)
  local s = Stats.EnsureStatsDB()
  s.bossesSlain = (tonumber(s.bossesSlain or 0) or 0) + 1
  RecordBossKillName(name)
  Stats.RefreshPanelIfVisible()
end

JS.RegisterStatTracker({
  key = "bossesSlain",
  category = "combat",
  order = 50,
  label = "Bosses Slain",
  fmt = Stats.FormatNumber,
  tooltip = function()
    return "Bosses slain:\n" .. BuildBossesTooltip()
  end,
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
})
