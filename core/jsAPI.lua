local _, JS = ...

local Stats = JS.Stats

-- Public contract for host addons
-- Version 1. A host checks API_VERSION before calling anything and falls back
-- to running without stats if it does not recognise the number.

JS.API = {
  API_VERSION = 1,

  -- Builds the stats panel inside `parent` and returns it. Calling twice with
  -- the same parent returns the existing panel.
  -- opts.brand      wording for the "tracked by X" header line
  -- opts.helperText the hint shown top right
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
}
