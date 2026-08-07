local _, JS = ...
local UI = JS.UI

-- Minimap button
-- Driven by LibDBIcon, which parents the icon to the Minimap frame so it follows
-- the minimap wherever the player puts it and however it is scaled. Position is
-- stored as the angle LibDBIcon expects, in account-wide saved data.

local MINIMAP_ICON = "Interface\\Icons\\INV_Scroll_15"
local LDB_NAME = "JemiStats"
local DEFAULT_ANGLE = 200

local ldb, dbicon

-- Wrap an angle into 0-359
local function NormalizeAngle(angle)
  angle = tonumber(angle) or DEFAULT_ANGLE
  angle = angle % 360
  if angle < 0 then
    angle = angle + 360
  end
  return angle
end

-- Saved minimap settings
local function EnsureMinimapDB()
  JemiStatsDB = JemiStatsDB or {}
  JemiStatsDB.minimap = JemiStatsDB.minimap or {}
  local db = JemiStatsDB.minimap

  db.minimapPos = NormalizeAngle(db.minimapPos)

  if db.hide == nil then
    db.hide = false
  end

  return db
end

-- Resolve the embedded libraries once
local function GetLibs()
  if ldb and dbicon then
    return ldb, dbicon
  end
  if not LibStub then return nil, nil end

  ldb = ldb or LibStub:GetLibrary("LibDataBroker-1.1", true)
  dbicon = dbicon or LibStub:GetLibrary("LibDBIcon-1.0", true)
  return ldb, dbicon
end

-- Broker object backing the icon
local function EnsureDataBroker()
  if UI.minimapDataObject then
    return UI.minimapDataObject
  end

  local broker = GetLibs()
  if not broker then return nil end

  -- NewDataObject returns nil if the name is already taken, so reuse that one
  local existing = broker:GetDataObjectByName(LDB_NAME)
  if existing then
    UI.minimapDataObject = existing
    return existing
  end

  UI.minimapDataObject = broker:NewDataObject(LDB_NAME, {
    type = "launcher",
    icon = MINIMAP_ICON,
    iconCoords = { 0.07, 0.93, 0.07, 0.93 },
    label = "JemiStats",
    OnClick = function(_, button)
      if button == "LeftButton" or button == "RightButton" then
        JS.ToggleUI()
      end
    end,
    OnTooltipShow = function(tt)
      if not tt or not tt.AddLine then return end
      tt:AddLine("JemiStats", 1, 0.82, 0)
      tt:AddLine("Click: Open/Close", 1, 1, 1)
      tt:AddLine("Drag: Move icon", 1, 1, 1)
    end,
  })

  return UI.minimapDataObject
end

-- Register the icon with LibDBIcon exactly once
local function EnsureRegisteredButton()
  local dataObject = EnsureDataBroker()
  local _, icons = GetLibs()
  if not dataObject or not icons then
    return nil, nil
  end

  local db = EnsureMinimapDB()

  if not icons:IsRegistered(LDB_NAME) then
    icons:Register(LDB_NAME, dataObject, db)
  end

  UI.minimapBtn = icons:GetMinimapButton(LDB_NAME)

  return icons, db
end

-- Apply the current show/hide state, no reload needed
-- A loaded host owns the interface, so its icon is the only one on the minimap.
-- The stored preference is left alone, so removing the host brings it back.
function JS.ApplyMinimapButtonVisibility()
  local icons, db = EnsureRegisteredButton()
  if not icons or not db then
    return
  end

  local show = not db.hide
  if JS.HostLoaded() then
    show = false
  end

  if show then
    icons:Show(LDB_NAME)
  else
    icons:Hide(LDB_NAME)
  end
end

function JS.RefreshMinimapButton()
  JS.ApplyMinimapButtonVisibility()
end

function JS.CreateMinimapButton()
  JS.ApplyMinimapButtonVisibility()
end

-- Flip the icon on or off, returns the new state
function JS.ToggleMinimapButton()
  local db = EnsureMinimapDB()
  db.hide = not db.hide
  JS.ApplyMinimapButtonVisibility()
  return not db.hide
end
