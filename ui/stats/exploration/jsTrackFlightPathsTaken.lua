local _, JS = ...
local Stats = JS.Stats

local function HandleTaxiStateCheck()
  local s = Stats.EnsureStatsDB()
  local onTaxi = UnitOnTaxi and UnitOnTaxi("player") and true or false

  if onTaxi and not s._onTaxi then
    s._onTaxi = true
    s.flightPathsTaken = (tonumber(s.flightPathsTaken or 0) or 0) + 1
    Stats.RefreshPanelIfVisible()
    return
  end

  if not onTaxi and s._onTaxi then
    s._onTaxi = false
  end
end

JS.RegisterStatTracker({
  key = "flightPathsTaken",
  category = "exploration",
  label = "Flight Paths Taken",
  fmt = Stats.FormatNumber,
  tooltip = "Counts each time you start a taxi flight path.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
  OnPlayerLogin = function()
    HandleTaxiStateCheck()
  end,
  OnEvent = function(_, event)
    if event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
      HandleTaxiStateCheck()
    end
  end,
  OnUpdate = function()
    HandleTaxiStateCheck()
  end,
})
