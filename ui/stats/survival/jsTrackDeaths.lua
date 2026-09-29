local _, JS = ...
local Stats = JS.Stats

local SURVIVAL_COLORS = {
  Stats.colors.OFFGOLD[1], Stats.colors.OFFGOLD[2], Stats.colors.OFFGOLD[3],
  Stats.colors.REDVAL[1], Stats.colors.REDVAL[2], Stats.colors.REDVAL[3],
}

Stats.SURVIVAL_COLORS = SURVIVAL_COLORS

-- Environmental damage says what kind it was, so the last one before dying is the cause.
local function HandleDeath()
  local s = Stats.EnsureStatsDB()

  s.deaths = (tonumber(s.deaths or 0) or 0) + 1

  -- The level reached before the first death is what Levels Without Dying reports
  if (tonumber(s.levelAtFirstDeath or 0) or 0) <= 0 then
    s.levelAtFirstDeath = JS.PlayerLevel()
  end

  local cause = s._lastEnvironment
  if cause == "FALLING" then
    s.deathsByFalling = (tonumber(s.deathsByFalling or 0) or 0) + 1
  elseif cause == "DROWNING" then
    s.deathsByDrowning = (tonumber(s.deathsByDrowning or 0) or 0) + 1
  end

  s._lastEnvironment = nil
  s._pendingFall = nil
  s._deadAt = GetTime and GetTime() or 0

  Stats.RefreshPanelIfVisible()
end

JS.RegisterStatTracker({
  key = "deaths",
  category = "survival",
  label = "Deaths",
  fmt = Stats.FormatNumber,
  tooltip = "How many times you have died on this character.",
  colors = SURVIVAL_COLORS,
  OnEvent = function(_, event)
    if event == "PLAYER_DEAD" then
      HandleDeath()
    end
  end,
  OnCombatLog = function(_, _, subevent, _, srcGUID, _, _, _, dstGUID, _, _, _, environmentType)
    local playerGUID = JS.PlayerGUID and JS.PlayerGUID() or nil
    if not playerGUID or dstGUID ~= playerGUID then return end

    local s = Stats.EnsureStatsDB()

    if subevent == "ENVIRONMENTAL_DAMAGE" then
      s._lastEnvironment = environmentType
    elseif subevent ~= "UNIT_DIED" and srcGUID and srcGUID ~= playerGUID then
      -- Something else hurt us, so the fall or the water is no longer the story
      s._lastEnvironment = nil
    end
  end,
})
