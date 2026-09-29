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
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("MERCHANT_SHOW")
f:RegisterEvent("MERCHANT_CLOSED")
f:RegisterEvent("CONFIRM_SUMMON")
f:RegisterEvent("LOOT_READY")
f:RegisterEvent("LOOT_CLOSED")

-- Player-only events, filtered by the client instead of by us
f:RegisterUnitEvent("UNIT_HEALTH", "player")
f:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
f:RegisterUnitEvent("UNIT_AURA", "player")

-- Unpacked once and handed to every tracker, rather than each re-fetching it.
local function DispatchCombatLog(timestamp, subevent, hideCaster,
                                 srcGUID, srcName, srcFlags, srcRaidFlags,
                                 dstGUID, dstName, dstFlags, dstRaidFlags, ...)
  local trackers = Stats.combatLogTrackers
  local muteClassStats = not Stats.classStatsEnabled

  for i = 1, #trackers do
    local tracker = trackers[i]
    if not (muteClassStats and tracker.category == "class") then
      tracker.OnCombatLog(tracker, timestamp, subevent, hideCaster,
                          srcGUID, srcName, srcFlags, srcRaidFlags,
                          dstGUID, dstName, dstFlags, dstRaidFlags, ...)
    end
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

    if not JS.HostLoaded() and JS.GetSetting("loginMessage") then
      JS.Msg("Loaded. Use /jstats or minimap icon. By Jemi")
    end

    -- Delayed so a host has registered its opener and the window lands right
    if JS.GetSetting("openOnLogin") then
      C_Timer.After(1.0, function()
        JS.OpenStats()
      end)
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
    -- Classic passes (questLogIndex, questID), the modern codebase only (questID)
    local first, second = ...
    local questID = second or first
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
