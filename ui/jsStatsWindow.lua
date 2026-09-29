local _, JS = ...
local Stats = JS.Stats

local ROW_HEIGHT = 16
local PAD_TOP = 10
local PAD_BOTTOM = 10
local PAD_SIDE = 12
local HEADER_GAP = 7
local LABEL_VALUE_GAP = 18

local PORTRAIT_SIZE = 22
local PORTRAIT_GAP = 6
local BRAND_GAP = 14
local LEVEL_GAP = 6

local MIN_WIDTH = 190
local MAX_WIDTH = 460
local MAX_ROWS_SHOWN = 14
local SCROLLBAR_WIDTH = 18

local DEFAULT_X, DEFAULT_Y = 130, -220

-- Ticked for a character that has never touched the list
local DEFAULT_ROWS = {
  "highestCritEver",
  "lowestHPPctEver",
  "enemiesSlain",
  "distanceEver",
  "jumps",
  "questsAccepted",
}

local frame, scroll, content
local rows = {}

local function EnsureWindowDB()
  JemiStatsDB = JemiStatsDB or {}
  JemiStatsDB.statsWindow = JemiStatsDB.statsWindow or {}
  return JemiStatsDB.statsWindow
end

function JS.SaveStatsWindowPosition()
  if not frame then return end

  local point, _, relPoint, x, y = frame:GetPoint()
  if not point then return end

  local db = EnsureWindowDB()
  db.point, db.relPoint = point, relPoint or point
  db.x, db.y = tonumber(x) or 0, tonumber(y) or 0
end

function JS.RestoreStatsWindowPosition()
  if not frame then return end

  local db = EnsureWindowDB()
  frame:ClearAllPoints()

  if db.point then
    frame:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x or 0, db.y or 0)
  else
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DEFAULT_X, DEFAULT_Y)
  end
end

-- Which rows the player ticked, per character
local function PickedRows()
  local d = JS.DB()

  if not d.statsWindowRows then
    d.statsWindowRows = {}
    for i = 1, #DEFAULT_ROWS do
      d.statsWindowRows[DEFAULT_ROWS[i]] = true
    end
  end

  return d.statsWindowRows
end

function JS.IsStatInWindow(key)
  return PickedRows()[key] and true or false
end

function JS.SetStatInWindow(key, shown)
  PickedRows()[key] = shown and true or nil
  JS.RebuildStatsWindow()
end

local function ApplyClassPortrait(texture)
  local _, token = UnitClass("player")
  local coords = token and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]

  texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
  if coords then
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  end
end

-- SetPortraitTexture reports nothing, so the texture itself is what gets checked
local function ApplyPortrait(texture)
  if not texture then return false end

  if SetPortraitTexture then
    texture:SetTexture(nil)
    pcall(SetPortraitTexture, texture, "player")

    if texture:GetTexture() then
      texture:SetTexCoord(0.14, 0.86, 0.14, 0.86)
      return true
    end
  end

  ApplyClassPortrait(texture)
  return false
end

-- The model is not ready at login, so the header keeps asking until it is
function JS.RefreshStatsWindowPortrait()
  if not frame or not frame.portrait then return end
  if frame.portraitReady then return end
  frame.portraitReady = ApplyPortrait(frame.portrait)
end

local function BuildFrame()
  if frame then return frame end

  frame = CreateFrame("Frame", "JemiStatsWindowFrame", UIParent,
    JS.PickTemplate("Frame", { "BackdropTemplate" }))
  frame:SetSize(MIN_WIDTH, 60)
  frame:SetFrameStrata("MEDIUM")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:Hide()

  if type(frame.SetBackdrop) == "function" then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 24,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.88)
    frame:SetBackdropBorderColor(0.7, 0.6, 0.35, 1)
  else
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.88)
  end

  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    JS.SaveStatsWindowPosition()
  end)

  local portrait = frame:CreateTexture(nil, "ARTWORK")
  portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
  portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD_SIDE, -PAD_TOP)
  frame.portrait = portrait
  frame.portraitReady = ApplyPortrait(portrait)

  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("LEFT", portrait, "RIGHT", PORTRAIT_GAP, 0)
  name:SetJustifyH("LEFT")
  name:SetTextColor(1, 0.82, 0)
  frame.nameText = name

  local level = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  level:SetPoint("LEFT", name, "RIGHT", LEVEL_GAP, 0)
  level:SetJustifyH("LEFT")
  level:SetTextColor(0.75, 0.75, 0.75)
  frame.levelText = level

  local brand = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  brand:SetPoint("RIGHT", frame, "TOPRIGHT", -PAD_SIDE, -(PAD_TOP + (PORTRAIT_SIZE / 2)))
  brand:SetJustifyH("RIGHT")
  brand:SetText("JemiStats")
  brand:SetTextColor(0.62, 0.62, 0.62)
  frame.brandText = brand

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD_SIDE, -(PAD_TOP + PORTRAIT_SIZE + 3))
  divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD_SIDE, -(PAD_TOP + PORTRAIT_SIZE + 3))
  divider:SetHeight(1)
  divider:SetTexture("Interface\\Buttons\\WHITE8X8")
  divider:SetVertexColor(0.7, 0.6, 0.35, 0.45)
  frame.divider = divider

  scroll = JS.CreateScrollFrame(frame)
  scroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -HEADER_GAP)
  scroll:EnableMouseWheel(true)
  -- Mouse input stays off so a drag anywhere still moves the window
  scroll:EnableMouse(false)

  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  scroll:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll() or 0
    local maxScroll = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
    local nextValue = current - (delta * ROW_HEIGHT * 2)
    if nextValue < 0 then nextValue = 0 end
    if nextValue > maxScroll then nextValue = maxScroll end
    self:SetVerticalScroll(nextValue)
  end)

  frame.scroll = scroll
  frame.content = content

  JS.RestoreStatsWindowPosition()
  return frame
end

local function AcquireRow(index)
  local row = rows[index]
  if row then return row end

  row = {}
  row.label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.label:SetJustifyH("LEFT")
  row.value = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.value:SetJustifyH("RIGHT")

  rows[index] = row
  return row
end

local function ScrollBarFor(scrollFrame)
  local name = scrollFrame.GetName and scrollFrame:GetName()
  local bar = scrollFrame.ScrollBar or (name and _G[name .. "ScrollBar"]) or nil
  if type(bar) == "table" and bar.SetShown then return bar end
  return nil
end

-- Same layout the Stats tab builds, so order and class filtering match it
function JS.RebuildStatsWindow()
  BuildFrame()

  local picked = PickedRows()
  local s = Stats.EnsureStatsDB()
  local layout = Stats.BuildTrackerEntryLayout()

  frame.nameText:SetText(UnitName("player") or "")
  frame.levelText:SetText("Level " .. JS.PlayerLevel())
  frame.shownLevel = JS.PlayerLevel()
  JS.RefreshStatsWindowPortrait()

  local used = 0
  local widestLabel, widestValue = 0, 0

  for i = 1, #layout do
    local entry = layout[i]
    if entry.type == "row" and picked[entry.key] then
      used = used + 1

      local row = AcquireRow(used)
      row.entry = entry

      local tracker = entry.tracker
      local value = tracker and tracker.getValue and tracker.getValue(tracker, s) or s[entry.key]
      local lr, lg, lb, vr, vg, vb = Stats.ColorsForKey(entry.key)

      row.label:SetText(entry.label)
      row.label:SetTextColor(lr, lg, lb)
      row.value:SetText(entry.fmt(value))
      row.value:SetTextColor(vr, vg, vb)

      -- Released first, or last pass's cap reads back as the text's own width
      row.label:SetWidth(0)
      widestLabel = math.max(widestLabel, row.label:GetStringWidth() or 0)
      widestValue = math.max(widestValue, row.value:GetStringWidth() or 0)

      row.label:Show()
      row.value:Show()
    end
  end

  for i = used + 1, #rows do
    rows[i].label:Hide()
    rows[i].value:Hide()
  end

  frame.rowCount = used
  frame.valueWidth = widestValue

  -- No ticks means no window, which is how it is switched off
  if used == 0 then
    frame:Hide()
    return
  end

  local scrolling = used > MAX_ROWS_SHOWN
  local shownRows = scrolling and MAX_ROWS_SHOWN or used
  local barWidth = scrolling and SCROLLBAR_WIDTH or 0

  -- Wide enough for the longest row and for the header, whichever wins
  local headerWidth = PORTRAIT_SIZE + PORTRAIT_GAP
    + (frame.nameText:GetStringWidth() or 0) + LEVEL_GAP
    + (frame.levelText:GetStringWidth() or 0) + BRAND_GAP
    + (frame.brandText:GetStringWidth() or 0)

  local rowsWidth = widestLabel + LABEL_VALUE_GAP + widestValue + barWidth
  local inner = math.max(headerWidth, rowsWidth)
  local width = math.max(MIN_WIDTH, math.min(MAX_WIDTH, inner + (PAD_SIDE * 2)))

  frame:SetWidth(width)

  local viewportWidth = math.max(1, width - (PAD_SIDE * 2) - barWidth)
  local listHeight = shownRows * ROW_HEIGHT

  scroll:SetSize(viewportWidth, listHeight)
  content:SetSize(viewportWidth, used * ROW_HEIGHT)

  -- Capped so an over-long label clips instead of running into its own value
  local labelWidth = math.max(20, viewportWidth - widestValue - LABEL_VALUE_GAP)

  for i = 1, used do
    local row = rows[i]
    local y = -((i - 1) * ROW_HEIGHT)

    row.label:ClearAllPoints()
    row.value:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    row.value:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)

    if row.label.SetWordWrap then row.label:SetWordWrap(false) end
    row.label:SetWidth(labelWidth)
    row.label:SetHeight(ROW_HEIGHT)
  end

  local bar = ScrollBarFor(scroll)
  if bar then
    bar:SetShown(scrolling)
  end

  if not scrolling then
    scroll:SetVerticalScroll(0)
  end

  if scroll.UpdateScrollChildRect then
    scroll:UpdateScrollChildRect()
  end

  frame:SetHeight(PAD_TOP + PORTRAIT_SIZE + 3 + HEADER_GAP + listHeight + PAD_BOTTOM)
  frame:Show()
end

-- The tick only rewrites values; rows change only when a tick box does
function JS.RefreshStatsWindow()
  if not frame or not frame:IsShown() then return end

  local s = Stats.EnsureStatsDB()
  local widest = 0

  for i = 1, (frame.rowCount or 0) do
    local row = rows[i]
    if row and row.entry then
      local tracker = row.entry.tracker
      local value = tracker and tracker.getValue and tracker.getValue(tracker, s) or s[row.entry.key]
      row.value:SetText(row.entry.fmt(value))
      widest = math.max(widest, row.value:GetStringWidth() or 0)
    end
  end

  -- A growing number, or a level up, can outrun the last rebuild's width
  if widest > (frame.valueWidth or 0) or frame.shownLevel ~= JS.PlayerLevel() then
    JS.RebuildStatsWindow()
  end
end

function JS.CreateStatsWindow()
  JS.RebuildStatsWindow()
end
