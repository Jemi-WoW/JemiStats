local _, JS = ...

-- One-time import of stats tracked by Oathbound before the split
-- Oathbound stored stats per character under the same key names, so this is a
-- straight copy. It runs before anything else touches the stats table.

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

-- Oathbound's saved stats for this character, or nil
-- OathboundDB only exists in memory when Oathbound itself is loaded, so a user
-- who removed it before this ever ran has nothing to import.
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
  if d.statsMigrated then return false end

  d.statsMigrated = true

  -- Anything already tracked here wins, the import is only for a first run
  if type(d.stats) == "table" and next(d.stats) ~= nil then
    return false
  end

  if not JS.IsAddOnLoaded(SOURCE_ADDON) then
    return false
  end

  local source = ReadSourceStats()
  if not source then return false end

  d.stats = CopyTable(source)
  d.statsMigratedFrom = SOURCE_ADDON

  JS.Msg("Imported your existing stats from " .. SOURCE_ADDON .. ".")
  return true
end
