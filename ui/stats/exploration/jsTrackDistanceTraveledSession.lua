local _, JS = ...
local Stats = JS.Stats

local function UpdateDistanceTravelled()
  local s = Stats.EnsureStatsDB()
  if not UnitExists or not UnitExists("player") then return end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
    return
  end

  if not UnitPosition then return end
  local y, x, z, instanceID = UnitPosition("player")
  if not x or not y then return end

  local px = tonumber(x) or 0
  local py = tonumber(y) or 0
  local pid = instanceID

  local prevX = tonumber(s.lastPosX or 0) or 0
  local prevY = tonumber(s.lastPosY or 0) or 0
  local prevID = s.lastPosInstanceID

  if prevID ~= nil and prevID == pid then
    local dx = px - prevX
    local dy = py - prevY
    local dist = math.sqrt((dx * dx) + (dy * dy))
    if dist > 0 and dist < 300 then
      s.distanceSession = (tonumber(s.distanceSession or 0) or 0) + dist
      s.distanceEver = (tonumber(s.distanceEver or 0) or 0) + dist
    end
  end

  s.lastPosX = px
  s.lastPosY = py
  s.lastPosInstanceID = pid
end

-- Forget where the player was standing.
-- Called when distance tracking is switched off or back on, so the ground
-- covered while it was disabled is never credited in one lump on the next sample.
function JS.ResetDistanceBaseline()
  local s = Stats.EnsureStatsDB()
  s.lastPosX = nil
  s.lastPosY = nil
  s.lastPosInstanceID = nil
end

JS.RegisterStatTracker({
  key = "distanceSession",
  category = "exploration",
  label = "Distance Traveled (Session)",
  fmt = Stats.FormatDistance,
  tooltip = "Approximate distance traveled this session, sampled from your position once per second.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
  OnUpdate = function(_, elapsed)
    if not Stats.distanceEnabled then return end
    UpdateDistanceTravelled()
  end,
})
