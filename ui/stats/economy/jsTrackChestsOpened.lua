local _, JS = ...
local Stats = JS.Stats

local CHEST_NEEDLES = {
  "chest",
  "cache",
  "crate",
  "box",
  "coffer",
  "stash",
  "supply",
  "lockbox",
  "footlocker",
  "treasure",
  "strongbox",
  "trunk",
}

local EXCLUDE_NEEDLES = {
  "clam",
  "oyster",
  "shellfish",
  "shell",
  "mussel",
}

local function NormalizeName(text)
  text = tostring(text or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
  text = text:gsub("|r", "")
  text = text:gsub("^%s+", "")
  text = text:gsub("%s+$", "")
  return text:lower()
end

local function TextLooksLikeChest(name)
  name = NormalizeName(name)
  if name == "" then return false end

  for i = 1, #EXCLUDE_NEEDLES do
    if name:find(EXCLUDE_NEEDLES[i], 1, true) then
      return false
    end
  end

  for i = 1, #CHEST_NEEDLES do
    if name:find(CHEST_NEEDLES[i], 1, true) then
      return true
    end
  end

  return false
end

local function GetLootTitleText()
  if LootFrame then
    if LootFrame.TitleContainer and LootFrame.TitleContainer.TitleText and LootFrame.TitleContainer.TitleText.GetText then
      return LootFrame.TitleContainer.TitleText:GetText()
    end
    if LootFrame.TitleText and LootFrame.TitleText.GetText then
      return LootFrame.TitleText:GetText()
    end
  end

  if LootFrameTitleText and LootFrameTitleText.GetText then
    return LootFrameTitleText:GetText()
  end

  return nil
end

local function GetTooltipTitleText()
  if GameTooltipTextLeft1 and GameTooltipTextLeft1.GetText then
    return GameTooltipTextLeft1:GetText()
  end
  return nil
end

local function LootSourceHasGameObject()
  if type(GetNumLootItems) ~= "function" or type(GetLootSourceInfo) ~= "function" then
    return false
  end

  local numItems = tonumber(GetNumLootItems() or 0) or 0
  if numItems <= 0 then
    return false
  end

  for slot = 1, numItems do
    local info = { GetLootSourceInfo(slot) }
    for i = 1, #info, 2 do
      local guid = tostring(info[i] or "")
      if guid ~= "" then
        if guid:find("GameObject", 1, true) or guid:find("GameObject%-", 1, true) then
          return true
        end
        if guid:find("Vehicle", 1, true) or guid:find("Vehicle%-", 1, true) then
          return true
        end
      end
    end
  end

  return false
end

local function AnyKnownNameLooksLikeChest()
  local title = GetLootTitleText()
  if TextLooksLikeChest(title) then
    return true
  end

  local tooltipTitle = GetTooltipTitleText()
  if TextLooksLikeChest(tooltipTitle) then
    return true
  end

  if UnitExists and UnitExists("target") and UnitName then
    if TextLooksLikeChest(UnitName("target")) then
      return true
    end
  end

  return false
end

local function AnyKnownNameIsExcluded()
  local candidates = {
    GetLootTitleText(),
    GetTooltipTitleText(),
    UnitExists and UnitExists("target") and UnitName and UnitName("target") or nil,
  }

  for i = 1, #candidates do
    local name = NormalizeName(candidates[i])
    if name ~= "" then
      for j = 1, #EXCLUDE_NEEDLES do
        if name:find(EXCLUDE_NEEDLES[j], 1, true) then
          return true
        end
      end
    end
  end

  return false
end

local function LootLooksLikeChest()
  if AnyKnownNameLooksLikeChest() then
    return true
  end

  if AnyKnownNameIsExcluded() then
    return false
  end

  return LootSourceHasGameObject()
end

local function HandleLootOpened()
  if not LootLooksLikeChest() then return end
  Stats.IncStat("chestsOpened", 1)
end

JS.RegisterStatTracker({
  key = "chestsOpened",
  category = "economy",
  label = "Chests Opened",
  fmt = Stats.FormatNumber,
  tooltip = "Counts chest-like objects opened, including chests, crates, boxes, caches, footlockers, and similar world loot objects.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnEvent = function(_, event)
    if event == "LOOT_OPENED" then
      HandleLootOpened()
    end
  end,
})
