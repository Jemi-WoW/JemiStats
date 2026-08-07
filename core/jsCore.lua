local ADDON, JS = ...
JS = JS or {}
_G.JemiStats = JS

JemiStatsDB = JemiStatsDB or {}

JS.ADDON = ADDON

-- Basic helpers
-- The player GUID never changes during a session, so it is resolved once and
-- reused. JS.DB() sits in hot paths and this removes an API call from each hit.
local playerGUID

function JS.PlayerGUID()
  if not playerGUID then
    playerGUID = UnitGUID("player")
  end
  return playerGUID
end

function JS.PlayerLevel() return UnitLevel("player") or 1 end

-- Character DB key
function JS.CharKey()
  return JS.PlayerGUID() or "UNKNOWN"
end

-- Per-character DB
-- Cached: this is called from the combat log handler and every stat write
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

-- Chat message
function JS.Msg(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37[JemiStats]|r " .. text)
end

-- Debug output
function JS.Debug(text)
  local d = JS.DB()
  d.settings = d.settings or {}
  if not d.settings.debugMode then return end
  DEFAULT_CHAT_FRAME:AddMessage("|cff7fbfff[JemiStats Debug]|r " .. tostring(text or ""))
end

JS.UI = JS.UI or {}

-- Spam protection for repeated counters
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

-- Settings scaffold
-- Empty for 1.0.0. The Settings tab reads these, so adding an option later is
-- one entry here plus one key in JS.SETTINGS_ORDER.
JS.SETTINGS_DEFS = {}

JS.SETTINGS_ORDER = {}

JS.SETTINGS_SECTION_ORDER = {}

-- Get setting definition
function JS.GetSettingDef(key)
  return JS.SETTINGS_DEFS and JS.SETTINGS_DEFS[key] or nil
end

-- Get setting value
function JS.GetSetting(key)
  local d = JS.DB()
  d.settings = d.settings or {}

  local val = d.settings[key]
  if val ~= nil then
    return val and true or false
  end

  local def = JS.GetSettingDef(key)
  if def and def.default ~= nil then
    return def.default and true or false
  end

  return false
end

-- Set setting value
function JS.SetSetting(key, value, source)
  local d = JS.DB()
  d.settings = d.settings or {}
  d.settings[key] = value and true or false

  if JS.ApplySettingSideEffects then
    JS.ApplySettingSideEffects(key)
  end

  if source ~= "refresh" and JS.RefreshSettingsPanel then
    JS.RefreshSettingsPanel()
  end
end

-- Apply setting side effects
function JS.ApplySettingSideEffects(key)
  if key == "showMinimapButton" and JS.RefreshMinimapButton then
    JS.RefreshMinimapButton()
  end
end
