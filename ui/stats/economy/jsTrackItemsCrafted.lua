local _, JS = ...
local Stats = JS.Stats

-- "You create: %s" as the client writes it, numbered placeholders and all
local function ToPattern(message)
  local pattern = message:gsub("%.", "%%.")

  for i = 1, 4 do
    pattern = pattern:gsub("%%" .. i .. "%$s", "(.+)"):gsub("%%" .. i .. "%$d", "(%%d+)")
  end

  return (pattern:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"))
end

local CREATED = ToPattern(LOOT_ITEM_CREATED_SELF or "You create: %s.")
local CREATED_MULTIPLE = ToPattern(LOOT_ITEM_CREATED_SELF_MULTIPLE or "You create: %sx%d.")

-- Renamed on the modern codebase, so every name this addon supports is checked
local PROFESSION_FRAMES = { "TradeSkillFrame", "CraftFrame", "ProfessionsFrame" }

-- Looting a crafted item and crafting it read the same, so the window settles it
local function ProfessionOpen()
  for i = 1, #PROFESSION_FRAMES do
    local frame = _G[PROFESSION_FRAMES[i]]
    if frame and frame.IsShown and frame:IsShown() then return true end
  end
  return false
end

local function HandleLootMessage(message, initiator, _, _, playerName)
  if type(message) ~= "string" or message == "" then return end

  local who = playerName or initiator
  if who and UnitName and who ~= UnitName("player") then return end
  if not ProfessionOpen() then return end

  local _, quantity = message:match(CREATED_MULTIPLE)
  if quantity then
    Stats.IncStat("itemsCrafted", tonumber(quantity) or 1)
  elseif message:match(CREATED) then
    Stats.IncStat("itemsCrafted", 1)
  end
end

JS.RegisterStatTracker({
  key = "itemsCrafted",
  category = "economy",
  order = 80,
  label = "Items Crafted",
  fmt = Stats.FormatNumber,
  tooltip = "Items you made at a profession window, counting stacks by the item.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnEvent = function(_, event, ...)
    if event == "CHAT_MSG_LOOT" then
      HandleLootMessage(...)
    end
  end,
})
