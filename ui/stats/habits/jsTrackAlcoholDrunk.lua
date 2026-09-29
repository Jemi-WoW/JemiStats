local _, JS = ...
local Stats = JS.Stats

-- Nothing marks an item as booze, so it is a list; add ids here to widen it
local ALCOHOL = {
  [2593]  = true, -- Flask of Port
  [2594]  = true, -- Flagon of Dwarven Honeymead
  [2595]  = true, -- Jug of Bourbon
  [2596]  = true, -- Skin of Dwarven Stout
  [2723]  = true, -- Bottle of Pinot Noir
  [4595]  = true, -- Junglevine Wine
  [18269] = true, -- Gordok Green Grog
  [18284] = true, -- Kreeg's Stout Beatdown
  [20709] = true, -- Rumsey Rum Light
  [21114] = true, -- Rumsey Rum
  [21151] = true, -- Rumsey Rum Black Label
  [33036] = true, -- Mudder's Milk
  [33042] = true, -- Small Step Brew
  [33043] = true, -- Long Stride Brew
  [33044] = true, -- Path of Brew
  [33045] = true, -- Jungle River Water
  [33046] = true, -- Brewdoo Magic
  [33047] = true, -- Wild Winter Pilsner
  [33048] = true, -- Izzard's Ever Flavor
  [33049] = true, -- Aromatic Honey Brew
  [33050] = true, -- Metok's Bubble Bock
  [33051] = true, -- Springs Water
  [33052] = true, -- Blackrock Lager
  [33053] = true, -- Stout Shrunken Head
  [33054] = true, -- Gordok Grog
  [33055] = true, -- Rock Scorpion Brew
}

-- A click only counts once the cast lands, so a failed or cancelled use is ignored
local CONFIRM_WINDOW = 3

local function NoteUse(itemID)
  if not itemID or not ALCOHOL[itemID] then return end
  Stats.EnsureStatsDB()._pendingAlcohol = GetTime and GetTime() or 0
end

if not JS._alcoholHookInstalled then
  JS._alcoholHookInstalled = JS.HookContainerItemUse(function(bag, slot)
    NoteUse(JS.GetContainerItemID(bag, slot))
  end)
end

JS.RegisterStatTracker({
  key = "alcoholDrunk",
  category = "habits",
  label = "Alcohol Drunk",
  fmt = Stats.FormatNumber,
  tooltip = "Ales, wines and spirits you have put away.",
  colors = Stats.HABIT_COLORS,
  OnEvent = function(_, event, unit)
    if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" then return end

    local s = Stats.EnsureStatsDB()
    local pending = tonumber(s._pendingAlcohol or 0) or 0
    if pending <= 0 then return end

    local now = GetTime and GetTime() or 0
    s._pendingAlcohol = nil
    if (now - pending) > CONFIRM_WINDOW then return end

    Stats.IncStat("alcoholDrunk", 1)
  end,
})
