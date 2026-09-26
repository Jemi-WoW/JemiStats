local _, JS = ...

local Stats = JS.Stats

-- Public contract for host addons; entries are only ever added, never changed.

JS.API = {
  API_VERSION = 1,

  -- Builds the stats panel in `parent`; opts carries brand and helperText
  CreateStatsPanel = function(parent, opts)
    return JS.CreateStatsPanel(parent, opts)
  end,

  -- Opens the stats view wherever it currently lives
  OpenStatsPanel = function()
    return JS.OpenStats()
  end,

  ResetSessionStats = function()
    JS.ResetSessionStats()
    Stats.RefreshPanelIfVisible()
    return true
  end,

  ResetAllStats = function()
    JS.ResetCharacterStats()
    return true
  end,

  -- Host-owned counters. Unknown keys are rejected rather than created.
  IncStat = function(key, amount)
    if type(key) ~= "string" or key == "" then return false end

    local s = Stats.EnsureStatsDB()
    if s[key] == nil then return false end

    Stats.IncStat(key, amount)
    return true
  end,

  -- How to open the host's own stats view, see core/jsHost.lua
  SetPanelOpener = function(fn)
    return JS.SetPanelOpener(fn)
  end,

  -- Builds our settings panel in `parent`, so a host can show it in its window
  CreateSettingsPanel = function(parent)
    return JS.CreateSettingsPanel(parent)
  end,

  -- The reverse: a host's panel builder, which adds a switcher to our Settings tab
  SetSettingsProvider = function(provider)
    return JS.SetSettingsProvider(provider)
  end,
}
