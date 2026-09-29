local _, JS = ...
local Stats = JS.Stats

local function ShouldCountQuest(map, questID, cooldown)
  if not questID then return false end
  map[questID] = map[questID] or 0
  local now = GetTime and GetTime() or 0
  cooldown = cooldown or 0.5
  if (now - map[questID]) < cooldown then
    return false
  end
  map[questID] = now
  return true
end

function JS.RecordQuestCompleted(questID)
  local s = Stats.EnsureStatsDB()
  if not ShouldCountQuest(s.lastQuestCompleted, questID, 0.5) then return end
  Stats.IncStat("questsCompleted", 1)
end

JS.RegisterStatTracker({
  key = "questsCompleted",
  category = "questing",
  label = "Quests Completed",
  fmt = Stats.FormatNumber,
  tooltip = "Counts quests completed on this character.",
  colors = {
    Stats.colors.GREEN[1], Stats.colors.GREEN[2], Stats.colors.GREEN[3],
    Stats.colors.GREEN[1], Stats.colors.GREEN[2], Stats.colors.GREEN[3],
  },
})
