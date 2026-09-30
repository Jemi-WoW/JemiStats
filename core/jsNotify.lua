local _, JS = ...
local Stats = JS.Stats

-- Stats that move every second or mean nothing as a single step
local NEVER_TOAST = {
  distanceSession = true,
  distanceEver = true,
  combatDurationAverage = true,
  levelsWithoutDying = true,
  combatCount = true,
  combatDurationTotal = true,
}

-- Only listed keys draw, so a missing file can never leave a broken square.
JS.STAT_ICONS = {
  -- deaths = "deaths.tga",
}

local ICON_PATH = "Interface\\AddOns\\JemiStats\\externals\\img\\statsicon\\"
local ICON_SIZE = 14

function JS.StatIconMarkup(key)
  local file = key and JS.STAT_ICONS[key]
  if not file then return "" end
  return string.format("|T%s%s:%d:%d:0:0|t", ICON_PATH, file, ICON_SIZE, ICON_SIZE)
end

-- A record replaces its value, a counter adds to it, money reads as gold
local styleCache = {}

local function ResolveStyle(tracker)
  local key = tracker.key
  local cached = styleCache[key]
  if cached ~= nil then return cached end

  local style

  if tracker.toastStyle ~= nil then
    style = tracker.toastStyle
  elseif NEVER_TOAST[key] then
    style = false
  elseif tracker.fmt == Stats.FormatCopper then
    style = "money"
  elseif key:match("^highest") or key:match("^lowest") or key:match("^biggest") then
    style = "record"
  else
    style = "counter"
  end

  styleCache[key] = style
  return style
end

JS.ResolveToastStyle = ResolveStyle

-- Stats that fire often enough to be background noise on their own
local ROUTINE_KEYS = {
  jumps = true,
  missedAttacks = true,
  enemiesSlain = true,
  elitesSlain = true,
  interrupts = true,
  dispels = true,
  goldEarnedSession = true,
  goldEarnedTotal = true,
  goldSpentTotal = true,
  itemsSoldToVendors = true,
  itemsCrafted = true,
  nodesGathered = true,
  fishCaught = true,
  junkFishCaught = true,
  foodEaten = true,
  drinksDrunk = true,
  emotesPerformed = true,
  arrowsShot = true,
  bulletsShot = true,
}

-- Class stats are per-cast and routine, bar the few that are a moment in themselves
local NOTABLE_KEYS = {
  battleRezzes = true,
  layOnHandsCast = true,
  timesBubbled = true,
  mindControlsCast = true,
}

local function IsNotable(tracker, style)
  if tracker.toastPriority then return tracker.toastPriority == "notable" end
  if NOTABLE_KEYS[tracker.key] then return true end
  if style == "record" then return true end
  if ROUTINE_KEYS[tracker.key] then return false end
  return tracker.category ~= "class"
end

JS.IsStatNotable = IsNotable

-- Where every counted stat write reports in
function Stats.OnStatChanged(key, newValue, oldValue)
  if not JS.PushStatToast then return end
  if not JS.GetSetting("showStatToasts") then return end

  local tracker = Stats.trackersByKey[key]
  if not tracker then return end

  local style = ResolveStyle(tracker)
  if not style then return end

  local mode = JS.GetToastMode()
  if mode == "window" and not JS.IsStatInWindow(key) then return end
  if mode == "notable" and not IsNotable(tracker, style) then return end

  -- A class stat belonging to another class should never surface
  if tracker.class and UnitClass then
    local _, token = UnitClass("player")
    if token ~= tracker.class then return end
  end

  JS.PushStatToast(tracker, style, newValue - oldValue, newValue)
end
