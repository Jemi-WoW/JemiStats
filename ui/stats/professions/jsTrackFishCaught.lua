local _, JS = ...
local Stats = JS.Stats

local FISHING_SPELL = 7620
local POOR_QUALITY = 0

-- IsFishingLoot only answers while the loot window is up, which auto-loot skips
local CAST_WINDOW = 5

local fishingName

local function IsFishingCast(spellID)
  if not spellID then return false end

  fishingName = fishingName or JS.GetSpellName(FISHING_SPELL)
  if not fishingName then return false end

  return JS.GetSpellName(spellID) == fishingName
end

local function FromTheWater()
  if IsFishingLoot and IsFishingLoot() then return true end

  local s = Stats.EnsureStatsDB()
  local castAt = tonumber(s._fishingCastAt or 0) or 0
  local now = GetTime and GetTime() or 0

  return castAt > 0 and (now - castAt) <= CAST_WINDOW
end

-- LOOT_READY and LOOT_OPENED both land for one window, so a catch counts once
local function HandleFishingLoot()
  local s = Stats.EnsureStatsDB()
  if s._lootCounted then return end
  if not FromTheWater() then return end
  if type(GetNumLootItems) ~= "function" then return end

  local caught, junk = 0, 0

  for slot = 1, (GetNumLootItems() or 0) do
    local link = LootSlotHasItem and LootSlotHasItem(slot) and GetLootSlotLink and GetLootSlotLink(slot)
    if link then
      caught = caught + 1
      if JS.GetItemQuality(link) == POOR_QUALITY then
        junk = junk + 1
      end
    end
  end

  if caught <= 0 then return end

  s._lootCounted = true
  s._fishingCastAt = 0
  Stats.IncStat("junkFishCaught", junk)
  Stats.IncStat("fishCaught", caught)
end

JS.RegisterStatTracker({
  key = "fishCaught",
  category = "professions",
  label = "Fish Caught",
  fmt = Stats.FormatNumber,
  tooltip = "Everything you have pulled out of the water, fish or otherwise.",
  colors = Stats.PROFESSION_COLORS,
  OnEvent = function(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
      if unit == "player" and IsFishingCast(spellID) then
        Stats.EnsureStatsDB()._fishingCastAt = GetTime and GetTime() or 0
      end
      return
    end

    if event == "LOOT_READY" or event == "LOOT_OPENED" then
      HandleFishingLoot()
    elseif event == "LOOT_CLOSED" then
      Stats.EnsureStatsDB()._lootCounted = nil
    end
  end,
})
