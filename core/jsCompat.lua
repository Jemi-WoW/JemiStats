local _, JS = ...

-- Client API compatibility layer
-- Classic 1.15.9 rebuilt the UI on the modern codebase and moved several
-- globals into C_* namespaces. Everything is resolved once here at load time so
-- the hot paths never pay for the lookup or the fallback chain.

local C_Item = C_Item
local C_AddOns = C_AddOns

-- Item info (C_Item since the 1.15.9 UI rebuild)
local rawGetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

-- Addon load state (C_AddOns since the 1.15.9 UI rebuild)
local rawIsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded

-- Spell info (still global in Classic, namespaced fallback for safety)
local rawGetSpellInfo = _G.GetSpellInfo
local rawGetSpellSubtext = _G.GetSpellSubtext

-- Cache-free item info (classID/subClassID for ammo detection)
function JS.GetItemInfoInstant(item)
  if not item or item == "" then return nil end
  if not rawGetItemInfoInstant then return nil end
  return rawGetItemInfoInstant(item)
end

-- Spell name, rank and icon
function JS.GetSpellInfo(spellID)
  if not spellID then return nil end

  if rawGetSpellInfo then
    return rawGetSpellInfo(spellID)
  end

  -- Modern-only clients return a table and keep rank in GetSpellSubtext
  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
  if not info then return nil end

  local rank = rawGetSpellSubtext and rawGetSpellSubtext(spellID) or nil
  return info.name, rank, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
end

-- Spell name only, the form most call sites want
function JS.GetSpellName(spellID)
  return (JS.GetSpellInfo(spellID))
end

-- Hook a global function only when it actually exists on this client
function JS.HookGlobal(name, callback)
  if type(name) ~= "string" or type(callback) ~= "function" then return false end
  if type(_G[name]) ~= "function" then return false end
  hooksecurefunc(name, callback)
  return true
end

-- Is another addon loaded right now
-- Only meaningful from PLAYER_LOGIN onward, load order decides it before that
function JS.IsAddOnLoaded(name)
  if not rawIsAddOnLoaded or not name then return false end
  return rawIsAddOnLoaded(name) and true or false
end
