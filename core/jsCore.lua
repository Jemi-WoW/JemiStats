local ADDON, JS = ...
JS = JS or {}
_G.JemiStats = JS

JemiStatsDB = JemiStatsDB or {}

JS.ADDON = ADDON

-- Shipped as a texture; built-in icons do not resolve on every client.
JS.ICON_TEXTURE = "Interface\\AddOns\\JemiStats\\externals\\img\\JemiStatsIcon.tga"

-- Resolved once: JS.DB() sits in hot paths and calls this on every hit.
local playerGUID

function JS.PlayerGUID()
  if not playerGUID then
    playerGUID = UnitGUID("player")
  end
  return playerGUID
end

function JS.PlayerLevel() return UnitLevel("player") or 1 end

function JS.CharKey()
  return JS.PlayerGUID() or "UNKNOWN"
end

-- Cached; called from the combat log handler and every stat write.
local cachedDB, cachedKey

function JS.DB()
  local k = JS.CharKey()
  if cachedDB and cachedKey == k then
    return cachedDB
  end

  JemiStatsDB.chars = JemiStatsDB.chars or {}
  local d = JemiStatsDB.chars[k]
  if not d then
    d = {}
    JemiStatsDB.chars[k] = d
  end

  cachedDB, cachedKey = d, k
  return d
end

-- Drop the cached table after a reset swaps it out
function JS.InvalidateDBCache()
  cachedDB, cachedKey = nil, nil
end

function JS.Msg(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37[JemiStats]|r " .. text)
end

function JS.Debug(text)
  local d = JS.DB()
  d.settings = d.settings or {}
  if not d.settings.debugMode then return end
  DEFAULT_CHAT_FRAME:AddMessage("|cff7fbfff[JemiStats Debug]|r " .. tostring(text or ""))
end

JS.UI = JS.UI or {}

function JS.ShouldSpam(key, cooldown)
  cooldown = cooldown or 1.5
  local d = JS.DB()
  d.lastSpamCheck = type(d.lastSpamCheck) == "table" and d.lastSpamCheck or {}

  local now = (GetTime and GetTime()) or 0
  local last = tonumber(d.lastSpamCheck[key] or 0) or 0

  if last < 0 or last > now then
    last = 0
    d.lastSpamCheck[key] = 0
  end

  if (now - last) < cooldown then
    return true
  end

  d.lastSpamCheck[key] = now
  return false
end

-- Boolean options, per character; a def's get/set overrides where it is stored.

JS.SETTINGS_DEFS = {
  -- Interface
  showMinimapButton = {
    key = "showMinimapButton",
    section = "interface",
    label = "Show minimap button",
    tooltip = "Show or hide the JemiStats minimap icon.\n\nThis one is shared by every character on the account.\n\n/jstats still works with the icon hidden.",
    default = true,
    get = function()
      if JS.IsMinimapButtonShown then return JS.IsMinimapButtonShown() end
      return true
    end,
    set = function(value)
      if JS.SetMinimapButtonShown then JS.SetMinimapButtonShown(value) end
    end,
    disabled = function()
      return JS.HostLoaded and JS.HostLoaded() or false
    end,
    disabledTooltip = "Controlled by the host addon while it is loaded. Use its minimap icon instead.",
  },
  openOnLogin = {
    key = "openOnLogin",
    section = "interface",
    label = "Open the window on login",
    tooltip = "Open the stats window automatically a moment after you log in.",
    default = false,
  },
  rememberWindowPosition = {
    key = "rememberWindowPosition",
    section = "interface",
    label = "Remember window position",
    tooltip = "Put the window back where you dragged it last time.\n\nTurn this off to have it open centered every time.",
    default = true,
  },
  lockWindow = {
    key = "lockWindow",
    section = "interface",
    label = "Lock window position",
    tooltip = "Stop the window from being dragged around.",
    default = false,
  },
  closeWithEscape = {
    key = "closeWithEscape",
    section = "interface",
    label = "Close the window with Escape",
    tooltip = "Let the Escape key close the stats window.\n\nTurn this off if you would rather Escape only reach the game menu.",
    default = true,
  },

  -- Tracking
  trackDistance = {
    key = "trackDistance",
    section = "tracking",
    label = "Track distance traveled",
    tooltip = "Sample your position once per second to build the Distance Traveled stats.\n\nThis is the only thing JemiStats does on a timer, so turning it off makes the addon completely idle until something happens.",
    default = true,
  },
  trackClassStats = {
    key = "trackClassStats",
    section = "tracking",
    label = "Track class stats",
    tooltip = "Count your class's signature abilities for the CLASS STATS section.\n\nExisting counts are kept, they simply stop rising.",
    default = true,
  },
  trackUIHabits = {
    key = "trackUIHabits",
    section = "tracking",
    label = "Track interface habits",
    tooltip = "Count how often you open the map, character panel, spellbook, quest log and talents.",
    default = true,
  },

  -- Session
  keepSessionAcrossLogout = {
    key = "keepSessionAcrossLogout",
    section = "session",
    label = "Keep session stats across logout",
    tooltip = "Carry session stats over when you log out and back in, instead of starting fresh.\n\nSession length keeps counting the whole time, including while you were offline.\n\n/jstats sessionreset always starts a new session by hand.",
    default = false,
  },
  showSessionLength = {
    key = "showSessionLength",
    section = "session",
    label = "Show session length",
    tooltip = "Show how long the current session has been running at the top of the Stats tab.",
    default = true,
  },

  -- Notifications
  announceRecords = {
    key = "announceRecords",
    section = "notifications",
    label = "Announce new records in chat",
    tooltip = "Print a line in chat when you set a new highest crit, a new lowest HP or discover a zone for the first time.",
    default = true,
  },
  recordSound = {
    key = "recordSound",
    section = "notifications",
    label = "Play a sound on new records",
    tooltip = "Play a short sound alongside the record message.\n\nNeeds 'Announce new records in chat' switched on.",
    default = false,
  },
  loginMessage = {
    key = "loginMessage",
    section = "notifications",
    label = "Show the login message",
    tooltip = "Print the short JemiStats greeting in chat when you log in.",
    default = true,
  },

  -- Stats display
  hideZeroStats = {
    key = "hideZeroStats",
    section = "display",
    label = "Hide stats still at zero",
    tooltip = "Leave out any row that has not counted anything yet.\n\nA section header disappears too once every row under it is hidden.",
    default = false,
  },
  stripedRows = {
    key = "stripedRows",
    section = "display",
    label = "Striped stat rows",
    tooltip = "Tint every other stat row so the list is easier to read across.",
    default = true,
  },

  -- Advanced
  debugMode = {
    key = "debugMode",
    section = "advanced",
    label = "Enable debug mode",
    tooltip = "Print extra JemiStats diagnostic messages in chat.\n\nUseful when reporting a stat that is not counting properly.",
    default = false,
  },
}

JS.SETTINGS_ORDER = {
  interface = {
    "showMinimapButton",
    "openOnLogin",
    "rememberWindowPosition",
    "lockWindow",
    "closeWithEscape",
  },
  tracking = {
    "trackDistance",
    "trackClassStats",
    "trackUIHabits",
  },
  session = {
    "keepSessionAcrossLogout",
    "showSessionLength",
  },
  notifications = {
    "announceRecords",
    "recordSound",
    "loginMessage",
  },
  display = {
    "hideZeroStats",
    "stripedRows",
  },
  advanced = {
    "debugMode",
  },
}

JS.SETTINGS_SECTION_ORDER = {
  {
    key = "interface",
    title = "Interface",
    desc = "Where the JemiStats window and minimap icon live, and how they behave.",
  },
  {
    key = "tracking",
    title = "Tracking",
    desc = "Choose what JemiStats counts. Anything already recorded is kept, a disabled tracker simply stops rising.",
  },
  {
    key = "session",
    title = "Session",
    desc = "What counts as a session, and what happens to session stats when you log out.",
  },
  {
    key = "notifications",
    title = "Notifications",
    desc = "How JemiStats talks to you in chat.",
  },
  {
    key = "display",
    title = "Stats Display",
    desc = "How the Stats tab presents the rows it tracks.",
  },
  {
    key = "advanced",
    title = "Advanced",
    desc = "Extra tools intended for testing and troubleshooting.",
  },
}

-- An older build could have saved anything here, so nothing is trusted.
local function CoerceSettingBoolean(value, default)
  if value == nil then
    return default and true or false
  end

  local t = type(value)
  if t == "boolean" then
    return value
  end
  if t == "number" then
    return value ~= 0
  end
  if t == "string" then
    local v = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if v == "true" or v == "1" or v == "yes" or v == "on" then
      return true
    end
    if v == "false" or v == "0" or v == "no" or v == "off" or v == "" then
      return false
    end
  end

  return default and true or false
end

JS.CoerceSettingBoolean = CoerceSettingBoolean

function JS.GetSettingDef(key)
  return JS.SETTINGS_DEFS and JS.SETTINGS_DEFS[key] or nil
end

function JS.IsSettingDisabled(key)
  local def = JS.GetSettingDef(key)
  if not def or not def.disabled then return false end
  local ok, disabled = pcall(def.disabled)
  return ok and disabled and true or false
end

function JS.GetSetting(key)
  local def = JS.GetSettingDef(key)

  if def and def.get then
    local ok, value = pcall(def.get)
    if ok then
      return value and true or false
    end
    return def.default and true or false
  end

  local d = JS.DB()
  d.settings = d.settings or {}

  local val = d.settings[key]
  if val ~= nil then
    return CoerceSettingBoolean(val, def and def.default)
  end

  if def and def.default ~= nil then
    return def.default and true or false
  end

  return false
end

function JS.SetSetting(key, value, source)
  value = value and true or false

  local def = JS.GetSettingDef(key)

  if def and def.set then
    pcall(def.set, value)
  else
    local d = JS.DB()
    d.settings = d.settings or {}
    d.settings[key] = value
  end

  if JS.ApplySettingSideEffects then
    JS.ApplySettingSideEffects(key)
  end

  if source ~= "refresh" and JS.RefreshSettingsPanel then
    JS.RefreshSettingsPanel()
  end
end

-- Everything that has to happen the moment an option flips, so none need a reload.
function JS.ApplySettingSideEffects(key)
  -- Hot paths read cached copies rather than calling GetSetting per event
  if JS.Stats and JS.Stats.RefreshSettingCache then
    JS.Stats.RefreshSettingCache()
  end

  if key == "showMinimapButton" then
    if JS.RefreshMinimapButton then
      JS.RefreshMinimapButton()
    end
    return
  end

  if key == "closeWithEscape" then
    if JS.ApplyEscapeClose then
      JS.ApplyEscapeClose()
    end
    return
  end

  if key == "rememberWindowPosition" then
    if JS.SaveWindowPosition then
      -- Capture the current spot, so switching on keeps it over the last saved one
      JS.SaveWindowPosition()
    end
    return
  end

  if key == "trackDistance" then
    -- Drop the stale sample, or re-enabling credits the distance covered while off
    if JS.ResetDistanceBaseline then
      JS.ResetDistanceBaseline()
    end
    return
  end

  if key == "hideZeroStats" or key == "stripedRows" or key == "showSessionLength" then
    if JS.Stats and JS.Stats.RelayoutPanels then
      JS.Stats.RelayoutPanels()
    end
    return
  end
end
