local _, JS = ...

-- One-time import of Oathbound's stats; same key names, so a straight copy.

local SOURCE_ADDON = "Oathbound"

local function CopyTable(source)
  local out = {}
  for k, v in pairs(source) do
    if type(v) == "table" then
      out[k] = CopyTable(v)
    else
      out[k] = v
    end
  end
  return out
end

-- Oathbound's saved stats for this character; only in memory while it is loaded.
local function ReadSourceStats()
  local db = _G.OathboundDB
  if type(db) ~= "table" or type(db.chars) ~= "table" then
    return nil
  end

  local chars = db.chars[JS.CharKey()]
  if type(chars) ~= "table" or type(chars.stats) ~= "table" then
    return nil
  end

  if next(chars.stats) == nil then
    return nil
  end

  return chars.stats
end

function JS.RunStatsMigration()
  local d = JS.DB()

  -- Not the flag alone: an interrupted run could set it having imported nothing
  local hasOwnStats = type(d.stats) == "table" and next(d.stats) ~= nil

  if d.statsMigrated and hasOwnStats then
    return false
  end

  if hasOwnStats then
    d.statsMigrated = true
    return false
  end

  -- Flag left alone while the source is missing, so installing it later imports
  if not JS.IsAddOnLoaded(SOURCE_ADDON) then
    return false
  end

  local source = ReadSourceStats()
  if not source then
    d.statsMigrated = true
    return false
  end

  d.stats = CopyTable(source)
  d.statsMigratedFrom = SOURCE_ADDON
  d.statsMigrated = true

  JS.Msg("Imported your existing stats from " .. SOURCE_ADDON .. ".")
  return true
end
