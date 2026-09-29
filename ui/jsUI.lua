local _, JS = ...
local UI = JS.UI

function UI:FixCloseButton(frame, xOff, yOff)
  if not frame then return end
  xOff = xOff or -5
  yOff = yOff or -5

  local btn = frame.CloseButton or frame.closeButton

  if not btn then
    local name = frame.GetName and frame:GetName()
    if name then
      btn = _G[name .. "CloseButton"] or _G[name .. "Close"] or _G[name .. "CloseBtn"]
    end
  end

  if not btn and frame.GetChildren then
    local kids = { frame:GetChildren() }
    for i = 1, #kids do
      local c = kids[i]
      if c and c.GetObjectType and c:GetObjectType() == "Button" then
        local n = c.GetName and c:GetName()
        if n and n:find("CloseButton") then
          btn = c
          break
        end
      end
    end
  end

  -- A bare frame carries no close button, so it gets one
  if not btn then
    local template
    btn, template = JS.CreateFromTemplates("Button", nil, frame, { "UIPanelCloseButton" })
    btn:SetSize(32, 32)

    if not template then
      btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
      btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
      btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
      btn:SetScript("OnClick", function() frame:Hide() end)
    end
  end

  btn:ClearAllPoints()
  btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", xOff, yOff)
  btn:SetFrameLevel(frame:GetFrameLevel() + 20)
  btn:Show()

  frame.CloseButton = btn
end

-- Tab list, left to right
local TAB_DEFS = {
  { key = "stats",    label = "Stats" },
  { key = "settings", label = "Settings" },
}

UI.tabIndex = {}

for i = 1, #TAB_DEFS do
  UI.tabIndex[TAB_DEFS[i].key] = i
end

-- Stored account-wide: where a window sits belongs to the screen, not a character.
local function EnsureWindowDB()
  JemiStatsDB = JemiStatsDB or {}
  JemiStatsDB.window = JemiStatsDB.window or {}
  return JemiStatsDB.window
end

function JS.SaveWindowPosition()
  if not UI.frame then return end
  if not JS.GetSetting("rememberWindowPosition") then return end

  local point, _, relPoint, x, y = UI.frame:GetPoint()
  if not point then return end

  local db = EnsureWindowDB()
  db.point = point
  db.relPoint = relPoint or point
  db.x = tonumber(x) or 0
  db.y = tonumber(y) or 0
end

function JS.RestoreWindowPosition()
  if not UI.frame then return end

  local db = EnsureWindowDB()

  UI.frame:ClearAllPoints()

  if JS.GetSetting("rememberWindowPosition") and db.point then
    -- UIParent named explicitly: GetPoint() reports nil for a parent anchor
    UI.frame:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x or 0, db.y or 0)
  else
    UI.frame:SetPoint("CENTER")
  end
end

-- Removed before re-adding, so the name never lands in the list twice.
function JS.ApplyEscapeClose()
  local name = "JemiStatsFrame"

  for i = #UISpecialFrames, 1, -1 do
    if UISpecialFrames[i] == name then
      table.remove(UISpecialFrames, i)
    end
  end

  if JS.GetSetting("closeWithEscape") then
    tinsert(UISpecialFrames, name)
  end
end

-- Window and tab templates, best first; the modern codebase renamed them.
local FRAME_TEMPLATES = { "UIPanelDialogTemplate", "BasicFrameTemplateWithInset", "BasicFrameTemplate" }
local TAB_TEMPLATES = { "CharacterFrameTabButtonTemplate", "PanelTabButtonTemplate", "TabButtonTemplate" }

function JS.CreateMainFrame()
  local frame, frameTemplate = JS.CreateFromTemplates("Frame", "JemiStatsFrame", UIParent, FRAME_TEMPLATES)

  -- Hidden first: a frame is created shown, and children skip OnShow while it is
  frame:Hide()

  -- Nothing to sit in front of on a bare frame, so it brings its own panel art
  if not frameTemplate then
    local bg, canBackdrop = JS.CreateBackdropFrame(frame)
    bg:SetAllPoints()
    bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))

    if canBackdrop then
      bg:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
      })
    else
      local flat = bg:CreateTexture(nil, "BACKGROUND")
      flat:SetAllPoints()
      flat:SetColorTexture(0.05, 0.05, 0.06, 0.94)
    end
  end

  frame:SetSize(560, 460)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")

  -- Checked on drag start, so the lock takes effect while the window is open
  frame:SetScript("OnDragStart", function(self)
    if JS.GetSetting("lockWindow") then return end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    JS.SaveWindowPosition()
  end)

  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(200)
  local titleText = "JemiStats - Made by Jemi"

  -- Not every template ships a title fontstring, so one is made to anchor against
  if not frame.Title then
    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Title:SetPoint("TOP", frame, "TOP", 0, -5)
  end

  frame.Title:SetText("")

  if not frame.TitleGroup then
    local g = CreateFrame("Frame", nil, frame)

    local icon = g:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetTexture(JS.ICON_TEXTURE)
    icon:SetPoint("LEFT", 0, 0)

    local fs = g:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    fs:SetTextColor(1, 0.82, 0)

    g.icon = icon
    g.text = fs
    frame.TitleGroup = g
  end

  local g = frame.TitleGroup
  g.text:SetText(titleText)

  g:SetSize(g.text:GetStringWidth() + 16 + 4, 16)

  g:ClearAllPoints()
  g:SetPoint("CENTER", frame.Title, "CENTER", 0, -7)

  -- Fix controls on show
  UI:FixCloseButton(frame, -3, -3)
  frame:HookScript("OnShow", function(self)
    UI:FixCloseButton(self, 2, 0.5)
  end)

  JS.ApplyEscapeClose()

  local tabCount = #TAB_DEFS

  local tabTemplate = JS.PickTemplate("Button", TAB_TEMPLATES)

  -- PanelTemplates_* needs regions only the real templates have
  UI.usePanelTabs = tabTemplate ~= nil and PanelTemplates_SetTab ~= nil

  frame.tabs = {}
  for i = 1, tabCount do
    local tab = CreateFrame("Button", "JemiStatsFrameTab" .. i, frame, tabTemplate)
    tab:SetID(i)

    if not tabTemplate then
      tab:SetSize(100, 26)
      local fs = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fs:SetPoint("CENTER")
      tab:SetFontString(fs)
      tab:SetHighlightFontObject("GameFontHighlightSmall")
    end

    tab:SetText(TAB_DEFS[i].label)
    tab:SetScript("OnClick", function(self)
      UI:ShowTab(self:GetID())
    end)
    frame.tabs[i] = tab
  end

  frame.tabs[1]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 7)
  for i = 2, tabCount do
    frame.tabs[i]:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", UI.usePanelTabs and -15 or 2, 0)
  end

  if UI.usePanelTabs then
    PanelTemplates_SetNumTabs(frame, tabCount)
    PanelTemplates_SetTab(frame, 1)
  end

  frame.panels = {}
  for i = 1, tabCount do
    local p = CreateFrame("Frame", nil, frame)
    p:SetPoint("TOPLEFT", 16, -36)
    p:SetPoint("BOTTOMRIGHT", -16, 16)
    p:Hide()
    frame.panels[i] = p
  end

  UI.frame = frame
  JS.RestoreWindowPosition()
end

function UI:ShowTab(id)
  if not UI.frame then return end

  UI.selectedTab = id
  if UI.usePanelTabs then
    PanelTemplates_SetTab(UI.frame, id)
  end

  for i = 1, #UI.frame.panels do UI.frame.panels[i]:Hide() end
  local p = UI.frame.panels[id]
  if not p then return end
  p:Show()
  if p.Refresh then p.Refresh() end
end

-- Show a tab by name, so callers never carry an index
function UI:ShowTabByKey(key)
  local id = UI.tabIndex[key]
  if not id then return end
  UI:ShowTab(id)
end

function JS.BuildUI()
  if UI.frame then return end
  JS.CreateMainFrame()
  JS.CreateStatsPanel(UI.frame.panels[UI.tabIndex.stats])
  JS.BuildSettingsPanel(UI.frame.panels[UI.tabIndex.settings])
  UI:ShowTab(1)
end

function JS.ToggleUI()
  if not UI.frame then
    JS.BuildUI()
  end

  if not UI.frame then return end

  if UI.frame:IsShown() then
    UI.frame:Hide()
  else
    UI.frame:Show()
    if UI.ShowTab then
      local active = UI.usePanelTabs and PanelTemplates_GetSelectedTab(UI.frame) or UI.selectedTab or 1
      UI:ShowTab(active)
    end
  end
end

-- Open the window straight on the stats tab
function JS.OpenStatsWindow()
  JS.BuildUI()
  if not UI.frame then return end
  UI.frame:Show()
  UI.frame:Raise()
  UI:ShowTabByKey("stats")
end

-- Always our own window: a host renders the stats panel but not these options.
function JS.OpenSettingsWindow()
  JS.BuildUI()
  if not UI.frame then return end
  UI.frame:Show()
  UI.frame:Raise()
  UI:ShowTabByKey("settings")
end
