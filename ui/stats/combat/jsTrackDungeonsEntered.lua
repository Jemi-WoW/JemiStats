local _, JS = ...
local Stats = JS.Stats

function JS.HandleDungeonStateChange()
  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0
  local inInstance, instanceType = IsInInstance and IsInInstance()

  if inInstance and instanceType == "party" then
    local name, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
    if not s.currentDungeon or s.currentDungeon.mapID ~= instanceMapID then
      s.currentDungeon = {
        mapID = instanceMapID,
        name = name,
        enteredAt = now,
      }
      s.dungeonsEntered = (tonumber(s.dungeonsEntered or 0) or 0) + 1
      Stats.RefreshPanelIfVisible()
    end
    return
  end

  local cur = s.currentDungeon
  if cur and cur.mapID then
    local elapsed = now - (tonumber(cur.enteredAt or now) or now)
    if elapsed >= 60 then
      s.dungeonsCompleted = (tonumber(s.dungeonsCompleted or 0) or 0) + 1

      local dungeonName = tostring(cur.name or "")
      if dungeonName ~= "" then
        s.completedDungeons[dungeonName] = (tonumber(s.completedDungeons[dungeonName] or 0) or 0) + 1
      end

      Stats.RefreshPanelIfVisible()
    end
  end
  s.currentDungeon = nil
end

JS.RegisterStatTracker({
  key = "dungeonsEntered",
  category = "combat",
  order = 70,
  label = "Times Entered Dungeons",
  fmt = Stats.FormatNumber,
  tooltip = "Counts how many times you entered a dungeon.",
  colors = {
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
    Stats.colors.BRONZE[1], Stats.colors.BRONZE[2], Stats.colors.BRONZE[3],
  },
  OnEvent = function(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
      if JS.HandleDungeonStateChange then
        JS.HandleDungeonStateChange()
      end
    end
  end,
})
