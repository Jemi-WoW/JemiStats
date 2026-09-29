local _, JS = ...
local Stats = JS.Stats

-- Held briefly, because whether the fall was survived is only known a moment later
local CONFIRM_DELAY = 1.5

local function ConfirmFall(amount)
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return end

  local s = Stats.EnsureStatsDB()
  if amount <= (tonumber(s.biggestFallSurvived or 0) or 0) then return end

  Stats.SetStat("biggestFallSurvived", amount)
  Stats.QueueRecordAlert("New biggest fall survived", Stats.FormatNumber(amount))
end

JS.RegisterStatTracker({
  key = "biggestFallSurvived",
  category = "survival",
  label = "Biggest Fall Survived",
  fmt = Stats.FormatNumber,
  tooltip = "Most fall damage you have taken in one drop and lived through.",
  colors = Stats.SURVIVAL_COLORS,
  OnCombatLog = function(_, _, subevent, _, _, _, _, _, dstGUID, _, _, _, environmentType, amount)
    if subevent ~= "ENVIRONMENTAL_DAMAGE" or environmentType ~= "FALLING" then return end

    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or dstGUID ~= playerGUID then return end

    amount = tonumber(amount or 0) or 0
    if amount <= 0 then return end

    if C_Timer and C_Timer.After then
      C_Timer.After(CONFIRM_DELAY, function() ConfirmFall(amount) end)
    end
  end,
})
