local _, JS = ...
local Stats = JS.Stats

-- Shared factory for class stats counted from the combat log.

local function PlayerGUID()
  return (JS.PlayerGUID and JS.PlayerGUID()) or (UnitGUID and UnitGUID("player")) or nil
end

-- Spell IDs resolve to localized names, merged with any explicit ones.
local function BuildNameSet(spellIDs, spellNames)
  local set = {}

  if spellIDs then
    for i = 1, #spellIDs do
      local name = JS.GetSpellName(spellIDs[i])
      if name then set[name] = true end
    end
  end

  if spellNames then
    for i = 1, #spellNames do
      set[spellNames[i]] = true
    end
  end

  if next(set) == nil then return nil end
  return set
end

function JS.RegisterClassCastStat(def)
  if not def or not def.key then return end

  local subevent = def.subevent or "SPELL_CAST_SUCCESS"
  -- No spell list means every matching subevent from the player counts
  local wantsNameMatch = (def.spellIDs ~= nil) or (def.spellNames ~= nil)

  local nameSet            -- built lazily so spell data is available
  local nameSetBuilt = false

  -- Class never changes, so resolve it once and no-op for everyone else.
  local classChecked = false
  local classMatches = false

  local colors = def.colors or {
    Stats.colors.GREEN[1], Stats.colors.GREEN[2], Stats.colors.GREEN[3],
    Stats.colors.WHITE[1], Stats.colors.WHITE[2], Stats.colors.WHITE[3],
  }

  JS.RegisterStatTracker({
    key = def.key,
    category = "class",
    class = def.class,
    order = def.order,
    label = def.label,
    fmt = Stats.FormatNumber,
    tooltip = def.tooltip,
    colors = colors,
    OnCombatLog = function(_, _, sub, _, srcGUID, _, _, _, _, _, _, _, _, spellName)
      if sub ~= subevent then return end

      if not classChecked then
        classChecked = true
        if not def.class then
          classMatches = true
        elseif UnitClass then
          local _, token = UnitClass("player")
          classMatches = (token == def.class)
        end
      end
      if not classMatches then return end

      local guid = PlayerGUID()
      if not guid or srcGUID ~= guid then return end

      if wantsNameMatch then
        if not nameSetBuilt then
          nameSet = BuildNameSet(def.spellIDs, def.spellNames)
          nameSetBuilt = true
        end
        if not nameSet or not spellName or not nameSet[spellName] then return end
      end

      Stats.IncStat(def.key, 1)
    end,
  })
end
