local _, JS = ...
local UI = JS.UI

local TITLE_ICON = "Interface\\Icons\\INV_Scroll_15"

-- Fix close button position
function UI:FixCloseButton(frame, xOff, yOff)
  if not frame then return end
  xOff = xOff or -5
  yOff = yOff or -5

  -- Try common close button refs
  local btn = frame.CloseButton or frame.closeButton

  if not btn then
    local name = frame.GetName and frame:GetName()
    if name then
      btn = _G[name .. "CloseButton"] or _G[name .. "Close"] or _G[name .. "CloseBtn"]
    end
  end

  -- Fallback: search child buttons
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

  if not btn then return end

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

-- Main addon frame
function JS.CreateMainFrame()
  local frame = CreateFrame("Frame", "JemiStatsFrame", UIParent, "UIPanelDialogTemplate")
  frame:SetSize(560, 460)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(200)
  local titleText = "JemiStats - Made by Jemi"

  frame.Title:SetText("")

  -- Custom title group
  if not frame.TitleGroup then
    local g = CreateFrame("Frame", nil, frame)

    local icon = g:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetTexture(TITLE_ICON)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
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

  tinsert(UISpecialFrames, "JemiStatsFrame")

  local tabCount = #TAB_DEFS

  frame.tabs = {}
  for i = 1, tabCount do
    local tab = CreateFrame("Button", "JemiStatsFrameTab" .. i, frame, "CharacterFrameTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(TAB_DEFS[i].label)
    tab:SetScript("OnClick", function(self)
      PanelTemplates_SetTab(frame, self:GetID())
      UI:ShowTab(self:GetID())
    end)
    frame.tabs[i] = tab
  end

  -- Tab positions
  frame.tabs[1]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 7)
  for i = 2, tabCount do
    frame.tabs[i]:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", -15, 0)
  end

  PanelTemplates_SetNumTabs(frame, tabCount)
  PanelTemplates_SetTab(frame, 1)

  -- Content panels
  frame.panels = {}
  for i = 1, tabCount do
    local p = CreateFrame("Frame", nil, frame)
    p:SetPoint("TOPLEFT", 16, -36)
    p:SetPoint("BOTTOMRIGHT", -16, 16)
    p:Hide()
    frame.panels[i] = p
  end

  UI.frame = frame
end

-- Show one tab panel
function UI:ShowTab(id)
  if not UI.frame then return end
  if PanelTemplates_SetTab then
    PanelTemplates_SetTab(UI.frame, id)
  end

  -- Hide all panels first
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

-- Build full UI once
function JS.BuildUI()
  if UI.frame then return end
  JS.CreateMainFrame()
  JS.CreateStatsPanel(UI.frame.panels[UI.tabIndex.stats])
  JS.BuildSettingsPanel(UI.frame.panels[UI.tabIndex.settings])
  UI:ShowTab(1)
end

-- Toggle main frame
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
      local active = PanelTemplates_GetSelectedTab(UI.frame) or 1
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
