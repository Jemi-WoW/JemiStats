local _, JS = ...

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local Stats = JS.Stats

-- Main event frame
local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("PLAYER_CONTROL_LOST")
f:RegisterEvent("PLAYER_CONTROL_GAINED")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("QUEST_ACCEPTED")
f:RegisterEvent("QUEST_TURNED_IN")

-- Player-only events, filtered by the client instead of by us
f:RegisterUnitEvent("UNIT_HEALTH", "player")
f:RegisterUnitEvent("UNIT_MAXHEALTH", "player")

-- Combat log fan-out
-- The event is unpacked once here and handed to every consumer, instead of each
-- tracker calling CombatLogGetCurrentEventInfo again.
local function DispatchCombatLog(timestamp, subevent, hideCaster,
                                 srcGUID, srcName, srcFlags, srcRaidFlags,
                                 dstGUID, dstName, dstFlags, dstRaidFlags, ...)
  local trackers = Stats.combatLogTrackers
  for i = 1, #trackers do
    local tracker = trackers[i]
    tracker.OnCombatLog(tracker, timestamp, subevent, hideCaster,
                        srcGUID, srcName, srcFlags, srcRaidFlags,
                        dstGUID, dstName, dstFlags, dstRaidFlags, ...)
  end
end

-- Main event handler
f:SetScript("OnEvent", function(self, event, ...)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    DispatchCombatLog(CombatLogGetCurrentEventInfo())
    return
  end

  if event == "PLAYER_LOGIN" then
    -- Import must land before anything normalizes or resets the stats table
    JS.RunStatsMigration()

    -- Every addon has loaded by now, so the host check can finally resolve
    JS.ResolveHost()

    JS.HandleStatsPlayerLogin()
    JS.CreateMinimapButton()

    if not JS.HostLoaded() then
      JS.Msg("Loaded. Use /jstats or minimap icon. By Jemi")
    end
    return
  end

  if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    if JS.RecordLowestHP then
      JS.RecordLowestHP("player")
    end
    return
  end

  if event == "QUEST_ACCEPTED" then
    local _, questID = ...
    if JS.RecordQuestAccepted then
      JS.RecordQuestAccepted(questID)
    end
    return
  end

  if event == "QUEST_TURNED_IN" then
    local questID = ...
    if JS.RecordQuestCompleted then
      JS.RecordQuestCompleted(questID)
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
    Stats.EnsureUIFrameHooks()
    Stats.DispatchEvent(event, ...)
    return
  end

  Stats.DispatchEvent(event, ...)
end)
