local _, JS = ...
local Stats = JS.Stats

-- A summon is offered, then the world reloads around you only if it was taken
local ACCEPT_WINDOW = 120

JS.RegisterStatTracker({
  key = "summonsAccepted",
  category = "exploration",
  label = "Summons Accepted",
  fmt = Stats.FormatNumber,
  tooltip = "Warlock summons and meeting stones you accepted a ride from.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
  OnEvent = function(_, event)
    local s = Stats.EnsureStatsDB()
    local now = GetTime and GetTime() or 0

    if event == "CONFIRM_SUMMON" then
      s._summonOfferedAt = now
      return
    end

    if event ~= "PLAYER_ENTERING_WORLD" then return end

    local offered = tonumber(s._summonOfferedAt or 0) or 0
    if offered <= 0 or (now - offered) > ACCEPT_WINDOW then return end

    s._summonOfferedAt = nil
    Stats.IncStat("summonsAccepted", 1)
  end,
})
