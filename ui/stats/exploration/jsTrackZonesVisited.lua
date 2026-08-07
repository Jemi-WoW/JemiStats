local _, JS = ...
local Stats = JS.Stats

local MAIN_ZONES = {
  -- Eastern Kingdoms
  ["dun morogh"] = "Dun Morogh",
  ["elwynn forest"] = "Elwynn Forest",
  ["tirisfal glades"] = "Tirisfal Glades",
  ["loch modan"] = "Loch Modan",
  ["westfall"] = "Westfall",
  ["redridge mountains"] = "Redridge Mountains",
  ["duskwood"] = "Duskwood",
  ["wetlands"] = "Wetlands",
  ["hillsbrad foothills"] = "Hillsbrad Foothills",
  ["alterac mountains"] = "Alterac Mountains",
  ["arathi highlands"] = "Arathi Highlands",
  ["the hinterlands"] = "The Hinterlands",
  ["silverpine forest"] = "Silverpine Forest",
  ["western plaguelands"] = "Western Plaguelands",
  ["eastern plaguelands"] = "Eastern Plaguelands",
  ["badlands"] = "Badlands",
  ["searing gorge"] = "Searing Gorge",
  ["burning steppes"] = "Burning Steppes",
  ["swamp of sorrows"] = "Swamp of Sorrows",
  ["blasted lands"] = "Blasted Lands",
  ["deadwind pass"] = "Deadwind Pass",
  ["stranglethorn vale"] = "Stranglethorn Vale",

  -- Kalimdor
  ["durotar"] = "Durotar",
  ["mulgore"] = "Mulgore",
  ["teldrassil"] = "Teldrassil",
  ["darkshore"] = "Darkshore",
  ["ashenvale"] = "Ashenvale",
  ["stonetalon mountains"] = "Stonetalon Mountains",
  ["desolace"] = "Desolace",
  ["dustwallow marsh"] = "Dustwallow Marsh",
  ["thousand needles"] = "Thousand Needles",
  ["feralas"] = "Feralas",
  ["tanaris"] = "Tanaris",
  ["azshara"] = "Azshara",
  ["felwood"] = "Felwood",
  ["un'goro crater"] = "Un'Goro Crater",
  ["moonglade"] = "Moonglade",
  ["silithus"] = "Silithus",
  ["winterspring"] = "Winterspring",
  ["the barrens"] = "The Barrens",
}

local function NormalizeMainZone(zoneName)
  zoneName = tostring(zoneName or "")
  zoneName = zoneName:gsub("^%s+", ""):gsub("%s+$", "")
  if zoneName == "" then return nil end
  return MAIN_ZONES[string.lower(zoneName)]
end

local function SanitizeVisitedZones()
  local s = Stats.EnsureStatsDB()
  local cleaned = {}
  local count = 0

  for zoneName in pairs(s.visitedZones or {}) do
    local canonical = NormalizeMainZone(zoneName)
    if canonical then
      local key = string.lower(canonical)
      if not cleaned[key] then
        cleaned[key] = true
        count = count + 1
      end
    end
  end

  s.visitedZones = cleaned
  s.visitedZoneCount = count
  return s
end

local function BuildVisitedZonesTooltip()
  local s = SanitizeVisitedZones()
  local names = {}

  for zoneName in pairs(s.visitedZones or {}) do
    local canonical = MAIN_ZONES[zoneName]
    if canonical then
      table.insert(names, canonical)
    end
  end

  table.sort(names)

  if #names == 0 then
    return "No zones recorded yet."
  end

  return table.concat(names, "\n")
end

function JS.RecordZoneVisit(zoneName)
  local canonical = NormalizeMainZone(zoneName)
  if not canonical then return end

  local s = SanitizeVisitedZones()
  local key = string.lower(canonical)
  if s.visitedZones[key] then return end

  s.visitedZones[key] = true
  s.visitedZoneCount = (tonumber(s.visitedZoneCount or 0) or 0) + 1
  Stats.QueueRecordAlert("New zone visited", canonical)
  Stats.RefreshPanelIfVisible()
end

local function TrackCurrentZone()
  local zone = Stats.GetCurrentZoneName and Stats.GetCurrentZoneName() or ""
  if zone ~= "" and JS.RecordZoneVisit then
    JS.RecordZoneVisit(zone)
  end
end

JS.RegisterStatTracker({
  key = "visitedZoneCount",
  category = "exploration",
  label = "Zones Visited",
  fmt = Stats.FormatZonesVisited,
  tooltip = function()
    return "Visited zones:\n" .. BuildVisitedZonesTooltip()
  end,
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
  OnPlayerLogin = function()
    SanitizeVisitedZones()
    TrackCurrentZone()
  end,
  OnEvent = function(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
      TrackCurrentZone()
    end
  end,
})
