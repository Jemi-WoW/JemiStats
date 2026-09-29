local _, JS = ...
local Stats = JS.Stats

local BRONZE = {
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
}

Stats.DUEL_COLORS = BRONZE

local MARK = "\1"

-- The client's own wording, turned into a pattern that remembers argument order
local function ToPattern(text)
  if not text then return nil, {} end

  local order, plain = {}, 0

  local marked = text:gsub("%%(%d)%$s", function(index)
    order[#order + 1] = tonumber(index)
    return MARK
  end)

  marked = marked:gsub("%%s", function()
    plain = plain + 1
    order[#order + 1] = plain
    return MARK
  end)

  local escaped = marked:gsub("([%^%$%(%)%.%[%]%*%+%-%?%%])", "%%%1")
  return "^" .. escaped:gsub(MARK, "(.+)") .. "$", order
end

local KNOCKOUT, KNOCKOUT_ORDER = ToPattern(DUEL_WINNER_KNOCKOUT)
local RETREAT, RETREAT_ORDER = ToPattern(DUEL_WINNER_RETREAT)

local function Argument(order, wanted, captures)
  for i = 1, #order do
    if order[i] == wanted then return captures[i] end
  end
end

-- Knockout names the winner first, retreat names the one who fled first
local function DuelResult(message)
  if KNOCKOUT then
    local captures = { message:match(KNOCKOUT) }
    if captures[1] then
      return Argument(KNOCKOUT_ORDER, 1, captures), Argument(KNOCKOUT_ORDER, 2, captures)
    end
  end

  if RETREAT then
    local captures = { message:match(RETREAT) }
    if captures[1] then
      return Argument(RETREAT_ORDER, 2, captures), Argument(RETREAT_ORDER, 1, captures)
    end
  end
end

local function HandleSystemMessage(message)
  if type(message) ~= "string" or message == "" then return end

  local winner, loser = DuelResult(message)
  if not winner or not loser then return end

  local me = UnitName and UnitName("player")
  if not me then return end

  if winner == me then
    Stats.IncStat("duelsWon", 1)
  elseif loser == me then
    Stats.IncStat("duelsLost", 1)
  end
end

JS.RegisterStatTracker({
  key = "duelsWon",
  category = "combat",
  order = 120,
  label = "Duels Won",
  fmt = Stats.FormatNumber,
  tooltip = "Duels you won, by knockout or because the other side fled.",
  colors = BRONZE,
  OnEvent = function(_, event, message)
    if event == "CHAT_MSG_SYSTEM" then
      HandleSystemMessage(message)
    end
  end,
})
