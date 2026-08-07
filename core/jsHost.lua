local _, JS = ...

-- Host addon detection
-- JemiStats works alone. When a host addon renders the stats panel in its own
-- window, JemiStats steps out of the way: no window of its own, no minimap icon.

local HOST_ADDON = "Oathbound"

local hostLoaded = false
local resolved = false
local panelOpener

-- Only meaningful from PLAYER_LOGIN onward
function JS.HostLoaded()
  return hostLoaded
end

function JS.HostName()
  return HOST_ADDON
end

-- Resolve once, at PLAYER_LOGIN, when every addon has finished loading
-- Checking any earlier is meaningless, since load order decides who exists yet.
function JS.ResolveHost()
  if resolved then return hostLoaded end
  resolved = true

  hostLoaded = JS.IsAddOnLoaded(HOST_ADDON)

  JS.FlushDeferredStatTrackers()

  return hostLoaded
end

-- A host that shows the stats panel inside its own window registers how to open
-- it here, so JemiStats never has to reach back into the host addon.
function JS.SetPanelOpener(fn)
  if type(fn) ~= "function" then return false end
  panelOpener = fn
  return true
end

-- Open the stats view wherever it currently lives
function JS.OpenStats()
  if panelOpener then
    local ok, shown = pcall(panelOpener)
    if ok and shown then return true end
  end

  JS.OpenStatsWindow()
  return true
end

-- Same, but the standalone window toggles instead of only opening
function JS.ToggleStats()
  if panelOpener then
    local ok, shown = pcall(panelOpener)
    if ok and shown then return true end
  end

  JS.ToggleUI()
  return true
end
