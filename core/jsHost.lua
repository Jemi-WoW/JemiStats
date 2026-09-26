local _, JS = ...

-- With a host addon loaded, JemiStats drops its own window and minimap icon.

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

-- Resolved at PLAYER_LOGIN; earlier, load order decides who exists yet.
function JS.ResolveHost()
  if resolved then return hostLoaded end
  resolved = true

  hostLoaded = JS.IsAddOnLoaded(HOST_ADDON)

  JS.FlushDeferredStatTrackers()

  return hostLoaded
end

-- A host registers how to open its own window, so we never reach into it.
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
