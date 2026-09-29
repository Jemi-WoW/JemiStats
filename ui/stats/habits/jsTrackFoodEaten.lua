local _, JS = ...
local Stats = JS.Stats

local HABIT_COLORS = {
  Stats.colors.BLUE[1], Stats.colors.BLUE[2], Stats.colors.BLUE[3],
  Stats.colors.WHITE[1], Stats.colors.WHITE[2], Stats.colors.WHITE[3],
}

Stats.HABIT_COLORS = HABIT_COLORS

-- Resolved from spell IDs rather than hardcoded, so every locale reads them
local FOOD_SPELL, DRINK_SPELL = 433, 430

local auraNames

local function AuraNames()
  if auraNames then return auraNames end
  auraNames = { food = JS.GetSpellName(FOOD_SPELL), drink = JS.GetSpellName(DRINK_SPELL) }
  return auraNames
end

local function CurrentAuras()
  local names = AuraNames()
  local food, drink = false, false

  for i = 1, 40 do
    local name = JS.GetPlayerBuffName(i)
    if not name then break end
    if names.food and name == names.food then food = true end
    if names.drink and name == names.drink then drink = true end
  end

  return food, drink
end

-- Quiet primes the state after a loading screen, where the aura is already there
local function CheckAuras(quiet)
  local s = Stats.EnsureStatsDB()
  local food, drink = CurrentAuras()

  if food and not s._eating and not quiet then
    Stats.IncStat("foodEaten", 1)
  end

  if drink and not s._drinking then
    s._drankAt = GetTime and GetTime() or 0
    if not quiet then
      Stats.IncStat("drinksDrunk", 1)
    end
  end

  s._eating, s._drinking = food, drink
end

Stats.CheckConsumableAuras = CheckAuras

JS.RegisterStatTracker({
  key = "foodEaten",
  category = "habits",
  label = "Food Eaten",
  fmt = Stats.FormatNumber,
  tooltip = "How many times you sat down to eat.",
  colors = HABIT_COLORS,
  OnPlayerLogin = function()
    CheckAuras(true)
  end,
  OnEvent = function(_, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
      CheckAuras(false)
    elseif event == "PLAYER_ENTERING_WORLD" then
      CheckAuras(true)
    end
  end,
})
