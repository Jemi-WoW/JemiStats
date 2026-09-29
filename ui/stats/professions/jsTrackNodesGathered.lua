local _, JS = ...
local Stats = JS.Stats

local PURPLE = {
  Stats.colors.PURPLE[1], Stats.colors.PURPLE[2], Stats.colors.PURPLE[3],
  Stats.colors.WHITE[1], Stats.colors.WHITE[2], Stats.colors.WHITE[3],
}

Stats.PROFESSION_COLORS = PURPLE

-- Every rank shares a name, so one known rank per profession resolves them all
local GATHER_SPELLS = {
  Mining = 2575,
  Herbalism = 2366,
  Skinning = 8613,
}

local names
local function GatherNames()
  if names then return names end

  names = {}
  for kind, spellID in pairs(GATHER_SPELLS) do
    local name = JS.GetSpellName(spellID)
    if name then names[name] = kind end
  end

  return names
end

local function BuildTooltip()
  local s = Stats.EnsureStatsDB()
  local lines = {}

  for kind, count in pairs(s.gatheredByKind or {}) do
    local n = tonumber(count or 0) or 0
    if n > 0 then
      table.insert(lines, string.format("%s: %d", kind, n))
    end
  end

  table.sort(lines)

  if #lines == 0 then
    return "Nothing gathered yet."
  end

  return table.concat(lines, "\n")
end

JS.RegisterStatTracker({
  key = "nodesGathered",
  category = "professions",
  label = "Nodes Gathered",
  fmt = Stats.FormatNumber,
  tooltip = function()
    return "Ore, herbs and skins you worked out of the world.\nAn interrupted gather never counts.\n\n" .. BuildTooltip()
  end,
  colors = PURPLE,
  OnEvent = function(_, event, unit, _, spellID)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" then return end

    local castName = spellID and JS.GetSpellName(spellID)
    local kind = castName and GatherNames()[castName]
    if not kind then return end

    local s = Stats.EnsureStatsDB()
    s.gatheredByKind[kind] = (tonumber(s.gatheredByKind[kind] or 0) or 0) + 1
    Stats.IncStat("nodesGathered", 1)
  end,
})
