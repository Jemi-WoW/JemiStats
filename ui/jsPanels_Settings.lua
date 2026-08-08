local _, JS = ...
local UI = JS.UI

-- Color palette
local GOLD = { 1.0, 0.82, 0.0 }
local WHITE = { 1.0, 1.0, 1.0 }
local DIM   = { 0.82, 0.82, 0.82 }
local GREY  = { 0.55, 0.55, 0.55 }

-- Layout constants
local PAD = 10
local INNER_PAD = 10
local SECTION_GAP = 10
local ROW_H = 32
local HEADER_H = 26
local SCROLL_STEP = 36
local SWITCH_BTN_W = 94
local SWITCH_BTN_H = 22

-- Every JemiStats settings body built this session.
-- With a host addon loaded the same body exists twice, once in each window, and
-- both have to move together when a value changes.
local settingsPanels = {}

-- A host addon that can render its own settings inside our window registers it
-- here, so this file never has to know which addon that is.
local settingsProvider

-- Saved collapse state
-- Sections start collapsed, so the tab opens as a short list of headings rather
-- than one long wall of checkboxes.
local function EnsurePanelState()
  local d = JS.DB()
  d.uiState = d.uiState or {}
  d.uiState.settingsCollapsed = d.uiState.settingsCollapsed or {}

  for _, section in ipairs(JS.SETTINGS_SECTION_ORDER) do
    if d.uiState.settingsCollapsed[section.key] == nil then
      d.uiState.settingsCollapsed[section.key] = true
    end
  end

  return d.uiState.settingsCollapsed
end

local function IsCollapsed(sectionKey)
  local state = EnsurePanelState()
  return state[sectionKey] and true or false
end

local function SetCollapsed(sectionKey, collapsed)
  local state = EnsurePanelState()
  state[sectionKey] = collapsed and true or false
end

-- Normalize text for the filter box
local function NormalizeText(s)
  if not s or s == "" then return "" end
  return string.lower(s)
end

-- Tooltip above the hovered row
local function ShowTooltipNear(widget, title, body)
  if (not title or title == "") and (not body or body == "") then return end

  GameTooltip:SetOwner(widget, "ANCHOR_TOP")
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", 0, 10)
  GameTooltip:SetFrameStrata("TOOLTIP")

  if title and title ~= "" then
    GameTooltip:AddLine(title, GOLD[1], GOLD[2], GOLD[3], true)
  end
  if body and body ~= "" then
    GameTooltip:AddLine(body, WHITE[1], WHITE[2], WHITE[3], true)
  end
  GameTooltip:Show()
end

-- Gold button style
local function StyleAddonButton(btn)
  if not btn then return end
  btn:SetNormalFontObject("GameFontNormalSmall")
  btn:SetHighlightFontObject("GameFontNormalSmall")
  btn:SetDisabledFontObject("GameFontDisableSmall")

  local fs = btn:GetFontString()
  if fs then
    fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
  end
end

-- Hover and enabled state for one setting row
local function ApplySettingRowState(check, hovered)
  if not check then return end

  local disabled = check.isDisabled and true or false

  if check.hover then
    check.hover:SetShown(hovered and not disabled)
  end

  local label = check.label
  if not label then return end

  if disabled then
    label:SetTextColor(GREY[1], GREY[2], GREY[3])
  elseif hovered then
    label:SetTextColor(1.00, 1.00, 1.00)
  else
    label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  end
end

-- Create one clickable setting row
-- The whole row is the button and the checkbox itself takes no mouse input, so
-- clicking anywhere along the line toggles the option.
local function CreateCheckbox(parent, def)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(ROW_H)
  row:RegisterForClicks("LeftButtonUp")
  row:EnableMouse(true)
  row:SetHitRectInsets(0, 0, 0, 0)

  local hover = row:CreateTexture(nil, "BACKGROUND")
  hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  hover:SetBlendMode("ADD")
  hover:SetAlpha(0.9)
  hover:Hide()

  -- UICheckButtonTemplate ships its own label. It is dropped for the custom gold
  -- one, and the guard matters: on Burning Crusade that fontstring is reached as
  -- $parentText, which does not resolve for a frame created without a name.
  local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  if check.Text then
    check.Text:SetText("")
    check.Text:Hide()
  end

  check:SetHitRectInsets(0, 0, 0, 0)
  check:EnableMouse(false)
  check.settingKey = def.key
  check.row = row
  check.hover = hover
  check.searchText = NormalizeText((def.label or "") .. " " .. (def.tooltip or ""))

  local labelFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  labelFS:SetJustifyH("LEFT")
  labelFS:SetJustifyV("MIDDLE")
  labelFS:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  labelFS:SetText(def.label)
  labelFS:EnableMouse(false)

  check.label = labelFS

  row:SetScript("OnClick", function()
    if check.isDisabled then return end
    check:SetChecked(not check:GetChecked())
    JS.SetSetting(def.key, check:GetChecked() and true or false, "panel")
  end)

  row:SetScript("OnEnter", function(self)
    ApplySettingRowState(check, true)

    local body = def.tooltip or ""
    if check.isDisabled and def.disabledTooltip then
      body = (body ~= "" and (body .. "\n\n") or "") .. "|cffff7f7f" .. def.disabledTooltip .. "|r"
    end

    ShowTooltipNear(self, def.label, body)
  end)

  row:SetScript("OnLeave", function()
    ApplySettingRowState(check, false)
    GameTooltip:Hide()
  end)

  return check
end

-- Create one collapsible section
local function CreateSection(parent, sectionKey, title, desc)
  local section = CreateFrame("Frame", nil, parent)
  section.sectionKey = sectionKey
  section.sectionSearchText = NormalizeText((title or "") .. " " .. (desc or ""))
  section.checks = {}
  section.visibleChecks = {}

  -- Header
  local headerBtn = CreateFrame("Button", nil, section)
  headerBtn:SetHeight(HEADER_H)
  headerBtn:RegisterForClicks("LeftButtonUp")
  headerBtn:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
  headerBtn:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
  headerBtn:EnableMouse(true)
  section.header = headerBtn

  local shell = CreateFrame("Frame", nil, headerBtn, BackdropTemplateMixin and "BackdropTemplate")
  shell:SetAllPoints()
  shell:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  shell:SetBackdropColor(0.42, 0.31, 0.17, 0.92)
  shell:SetBackdropBorderColor(0.35, 0.35, 0.45, 0.8)
  headerBtn.shell = shell

  local bottomShade = shell:CreateTexture(nil, "ARTWORK")
  bottomShade:SetPoint("BOTTOMLEFT", 9, 6)
  bottomShade:SetPoint("BOTTOMRIGHT", -9, 6)
  bottomShade:SetHeight(1)
  bottomShade:SetTexture("Interface/Buttons/WHITE8X8")
  bottomShade:SetVertexColor(0.00, 0.00, 0.00, 0.18)
  headerBtn.bottomShade = bottomShade

  local innerShade = shell:CreateTexture(nil, "BORDER")
  innerShade:SetPoint("TOPLEFT", 10, -7)
  innerShade:SetPoint("BOTTOMRIGHT", -10, 7)
  innerShade:SetTexture("Interface/Buttons/WHITE8X8")
  innerShade:SetVertexColor(0.22, 0.16, 0.08, 0.08)
  headerBtn.innerShade = innerShade

  -- Collapse toggle
  local toggleBtn = CreateFrame("Button", nil, headerBtn, "UIPanelButtonTemplate")
  toggleBtn:SetSize(22, 18)
  toggleBtn:SetPoint("LEFT", 9, 0)
  StyleAddonButton(toggleBtn)
  section.toggleBtn = toggleBtn

  local toggleFS = toggleBtn:GetFontString()
  if not toggleFS then
    toggleFS = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleBtn:SetFontString(toggleFS)
  end
  toggleFS:ClearAllPoints()
  toggleFS:SetPoint("CENTER", -0.5, 0)
  toggleFS:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

  local titleFS = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  titleFS:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
  titleFS:SetJustifyH("LEFT")
  titleFS:SetText(title)
  titleFS:SetTextColor(1.00, 1.00, 1.00)
  section.title = titleFS

  -- How many options in this section are switched on
  local countFS = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  countFS:SetPoint("RIGHT", -14, 0)
  countFS:SetJustifyH("RIGHT")
  countFS:SetTextColor(1.00, 0.84, 0.20)
  section.countText = countFS

  -- Body
  local body = CreateFrame("Frame", nil, section, "InsetFrameTemplate3")
  body:SetPoint("TOPLEFT", headerBtn, "BOTTOMLEFT", 0, -1)
  body:SetPoint("TOPRIGHT", headerBtn, "BOTTOMRIGHT", 0, -1)
  section.body = body

  -- Drop the inset's top edge so the body reads as one piece with the header
  if body.TopEdge then body.TopEdge:Hide() end
  if body.TopLeftCorner then body.TopLeftCorner:Hide() end
  if body.TopRightCorner then body.TopRightCorner:Hide() end
  if body.Center then
    body.Center:ClearAllPoints()
    body.Center:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    body.Center:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
  end

  local descFS = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  descFS:SetPoint("TOPLEFT", INNER_PAD + 4, -INNER_PAD)
  descFS:SetJustifyH("LEFT")
  descFS:SetJustifyV("TOP")
  descFS:SetTextColor(DIM[1], DIM[2], DIM[3])
  descFS:SetSpacing(1)
  descFS:SetText(desc or "")
  section.desc = descFS

  local function ToggleCollapsed()
    SetCollapsed(section.sectionKey, not IsCollapsed(section.sectionKey))
    if section._layoutOwner and section._layoutOwner.Layout then
      section._layoutOwner:Layout()
    end
  end

  headerBtn:SetScript("OnClick", ToggleCollapsed)
  toggleBtn:SetScript("OnClick", ToggleCollapsed)

  headerBtn:SetScript("OnEnter", function(self)
    self.shell:SetBackdropColor(0.50, 0.37, 0.20, 0.96)
    self.shell:SetBackdropBorderColor(0.60, 0.60, 0.70, 1.00)
    self.bottomShade:SetVertexColor(0.00, 0.00, 0.00, 0.10)
    self.innerShade:SetVertexColor(0.28, 0.20, 0.10, 0.05)
    section.countText:SetTextColor(1.00, 0.88, 0.30)
  end)

  headerBtn:SetScript("OnLeave", function(self)
    self.shell:SetBackdropColor(0.42, 0.31, 0.17, 0.92)
    self.shell:SetBackdropBorderColor(0.35, 0.35, 0.45, 0.8)
    self.bottomShade:SetVertexColor(0.00, 0.00, 0.00, 0.18)
    self.innerShade:SetVertexColor(0.22, 0.16, 0.08, 0.08)
    section.countText:SetTextColor(1.00, 0.84, 0.20)
  end)

  return section
end

-- Lay out one section and report how tall it ended up
local function LayoutSection(section, width, query)
  section:SetWidth(width)
  section.header:SetWidth(width)

  local totalChecks = #section.checks
  local checkedCount = 0
  for i = 1, totalChecks do
    if section.checks[i]:GetChecked() then
      checkedCount = checkedCount + 1
    end
  end
  section.countText:SetText(string.format("%d/%d", checkedCount, totalChecks))

  wipe(section.visibleChecks)

  local hasQuery = query and query ~= ""

  if hasQuery then
    for i = 1, totalChecks do
      local check = section.checks[i]
      if string.find(check.searchText or "", query, 1, true) then
        table.insert(section.visibleChecks, check)
      end
    end
  else
    for i = 1, totalChecks do
      table.insert(section.visibleChecks, section.checks[i])
    end
  end

  local visibleCount = #section.visibleChecks
  local sectionMatches = hasQuery and string.find(section.sectionSearchText or "", query, 1, true) ~= nil
  section.isVisible = (not hasQuery) or visibleCount > 0 or sectionMatches

  if not section.isVisible then
    section:Hide()
    section:SetHeight(0)
    return
  end

  section:Show()

  -- A filter forces every matching section open, otherwise nothing would be
  -- visible to read the results in
  local collapsed = (not hasQuery) and IsCollapsed(section.sectionKey)
  section.toggleBtn:SetText(collapsed and ">" or "v")

  for i = 1, totalChecks do
    local row = section.checks[i].row or section.checks[i]
    row:Hide()
  end

  if collapsed then
    section.body:Hide()
    section:SetHeight(HEADER_H)
    return
  end

  section.body:Show()
  section.desc:SetWidth(math.max(180, width - (INNER_PAD * 2) - 26))

  local descHeight = math.max(18, section.desc:GetStringHeight() or 18)
  local y = -(INNER_PAD + descHeight + 12)

  for i = 1, visibleCount do
    local check = section.visibleChecks[i]
    local row = check.row or check
    row:Show()

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", section.body, "TOPLEFT", INNER_PAD + 6, y)
    row:SetPoint("TOPRIGHT", section.body, "TOPRIGHT", -(INNER_PAD + 6), y)
    row:SetHeight(ROW_H)

    if check.hover then
      check.hover:ClearAllPoints()
      check.hover:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
      check.hover:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    end

    check:ClearAllPoints()
    check:SetPoint("LEFT", row, "LEFT", 0, 0)
    check:SetSize(26, 26)

    check.label:ClearAllPoints()
    check.label:SetPoint("LEFT", check, "RIGHT", 8, 0)
    check.label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    check.label:SetHeight(ROW_H)

    y = y - ROW_H
  end

  local bodyHeight = INNER_PAD + descHeight + 12 + (visibleCount * ROW_H) + 10
  section.body:SetHeight(bodyHeight)
  section:SetHeight(HEADER_H + 1 + bodyHeight)
end

-- SETTINGS PANEL
-- Driven entirely by JS.SETTINGS_DEFS, JS.SETTINGS_ORDER and
-- JS.SETTINGS_SECTION_ORDER, so a new option is three table entries in
-- core/jsCore.lua and nothing in here changes.
--
-- Built as a child filling `parent` rather than into `parent` itself, so a host
-- addon can drop it into one of its own frames and show or hide it as a block.
function JS.CreateSettingsPanel(parent)
  if not parent then return nil end
  if parent._jsSettingsPanel then return parent._jsSettingsPanel end

  local panel = CreateFrame("Frame", nil, parent)
  panel:SetAllPoints(parent)
  parent._jsSettingsPanel = panel

  local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", 8, -6)
  header:SetText("Settings")

  local inset = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
  inset:SetPoint("TOPLEFT", 8, -30)
  inset:SetPoint("BOTTOMRIGHT", -8, 10)

  -- Filter bar
  local searchInset = CreateFrame("Frame", nil, inset, "InsetFrameTemplate3")
  searchInset:SetPoint("TOPLEFT", 12, -12)
  searchInset:SetPoint("TOPRIGHT", -12, -12)
  searchInset:SetHeight(48)

  local filterLabel = searchInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  filterLabel:SetPoint("LEFT", 14, 0)
  filterLabel:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  filterLabel:SetText("Filter")

  local search = CreateFrame("EditBox", nil, searchInset, "InputBoxTemplate")
  search:SetSize(220, 20)
  search:SetPoint("LEFT", filterLabel, "RIGHT", 10, 0)
  search:SetAutoFocus(false)
  search:SetText("")
  search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  panel.search = search

  local hint = searchInset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("LEFT", search, "RIGHT", 10, 0)
  hint:SetText("type to filter")

  -- Scrolling section list
  local listInset = CreateFrame("Frame", nil, inset, "InsetFrameTemplate3")
  listInset:SetPoint("TOPLEFT", searchInset, "BOTTOMLEFT", 0, -10)
  listInset:SetPoint("TOPRIGHT", searchInset, "BOTTOMRIGHT", 0, -10)
  listInset:SetPoint("BOTTOMLEFT", 12, 12)
  listInset:SetPoint("BOTTOMRIGHT", -12, 12)

  local scroll = CreateFrame("ScrollFrame", nil, listInset, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -12)
  scroll:SetPoint("BOTTOMRIGHT", -28, 12)
  scroll:EnableMouseWheel(true)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  -- Shown only if there is genuinely nothing to configure
  local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  emptyText:SetJustifyH("LEFT")
  emptyText:SetJustifyV("TOP")
  emptyText:SetTextColor(DIM[1], DIM[2], DIM[3])
  emptyText:SetText("No settings available.")
  emptyText:Hide()

  local sections = {}
  local checksByKey = {}

  for _, info in ipairs(JS.SETTINGS_SECTION_ORDER) do
    local order = (JS.SETTINGS_ORDER and JS.SETTINGS_ORDER[info.key]) or {}
    local section = CreateSection(content, info.key, info.title or info.key, info.desc)
    section._layoutOwner = panel

    for _, key in ipairs(order) do
      local def = JS.GetSettingDef(key)
      if def then
        local check = CreateCheckbox(section.body, def)
        section.checks[#section.checks + 1] = check
        checksByKey[key] = check
      end
    end

    -- A section with no surviving options never makes it onto the page
    if #section.checks > 0 then
      sections[#sections + 1] = section
    else
      section:Hide()
    end
  end

  local function CurrentQuery()
    return NormalizeText(search:GetText())
  end

  search:SetScript("OnTextChanged", function(self)
    hint:SetShown((self:GetText() or "") == "")
    if panel.Layout then
      panel:Layout()
    end
  end)

  -- Stack the visible sections
  function panel:Layout()
    local sw = scroll:GetWidth() or 0
    local sh = scroll:GetHeight() or 0
    if sw <= 0 or sh <= 0 then return end

    local contentWidth = math.max(360, sw - 8)
    local sectionWidth = contentWidth - 2
    local query = CurrentQuery()

    content:SetWidth(contentWidth)

    if #sections == 0 then
      emptyText:ClearAllPoints()
      emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
      emptyText:SetWidth(math.max(1, contentWidth - 8))
      emptyText:Show()
      content:SetHeight(sh + 1)
      if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
      end
      return
    end

    emptyText:Hide()

    local prev
    local totalHeight = 0
    local visibleSections = 0

    for i = 1, #sections do
      local section = sections[i]
      LayoutSection(section, sectionWidth, query)

      if section.isVisible then
        section:ClearAllPoints()
        if visibleSections == 0 then
          section:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        else
          section:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -SECTION_GAP)
        end
        prev = section
        visibleSections = visibleSections + 1
        totalHeight = totalHeight + section:GetHeight() + SECTION_GAP
      end
    end

    if visibleSections > 0 then
      totalHeight = totalHeight - SECTION_GAP
    end

    totalHeight = math.max(sh + 1, totalHeight + 2)
    content:SetHeight(totalHeight)

    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
    end

    -- Collapsing a section can leave the view scrolled past the new bottom
    local maxScroll = math.max(0, totalHeight - sh)
    if (scroll:GetVerticalScroll() or 0) > maxScroll then
      scroll:SetVerticalScroll(maxScroll)
    end
  end

  scroll:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll() or 0
    local maxScroll = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
    local nextValue = current - (delta * SCROLL_STEP)
    if nextValue < 0 then nextValue = 0 end
    if nextValue > maxScroll then nextValue = maxScroll end
    self:SetVerticalScroll(nextValue)
  end)

  inset:SetScript("OnSizeChanged", function()
    C_Timer.After(0, function()
      if panel.Layout then panel:Layout() end
    end)
  end)

  -- Pull every checkbox back in line with the stored values
  local function RefreshPanel()
    EnsurePanelState()

    for key, check in pairs(checksByKey) do
      check.isDisabled = JS.IsSettingDisabled(key)
      check:SetChecked(JS.GetSetting(key))
      check:SetAlpha(check.isDisabled and 0.5 or 1.0)
      ApplySettingRowState(check, false)
    end

    hint:SetShown((search:GetText() or "") == "")

    C_Timer.After(0, function()
      if panel.Layout then panel:Layout() end
    end)
  end

  panel.Refresh = RefreshPanel
  settingsPanels[#settingsPanels + 1] = panel
  RefreshPanel()

  return panel
end

-- Called after a setting changes from anywhere
-- Every copy is refreshed, not just the visible one, so switching back to a
-- window that was open the whole time never shows a stale checkbox.
function JS.RefreshSettingsPanel()
  for i = 1, #settingsPanels do
    local panel = settingsPanels[i]
    if panel.Refresh then
      panel.Refresh()
    end
  end
end

-- A host addon offering its own settings for our window
-- provider.label  button text
-- provider.Create function(parent) -> frame filling parent, ideally with .Refresh
function JS.SetSettingsProvider(provider)
  if type(provider) ~= "table" then return false end
  if type(provider.Create) ~= "function" then return false end
  if type(provider.label) ~= "string" or provider.label == "" then return false end

  settingsProvider = provider
  return true
end

function JS.HasSettingsProvider()
  return settingsProvider ~= nil
end

-- Source switcher
-- Two buttons top right that swap which addon's settings fill the panel. Only
-- built when a host registered a provider, so on Burning Crusade or a solo
-- install the tab looks exactly as it always did.
local function BuildSourceSwitcher(parent, sources, activeKey)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetSize(1, SWITCH_BTN_H)
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -4)
  bar:SetFrameLevel((parent:GetFrameLevel() or 0) + 10)

  bar.activeKey = activeKey
  bar.buttons = {}

  -- The other addon's panel is only built the first time it is asked for, so a
  -- player who never switches never pays for it
  local function ResolvePanel(source)
    if not source.panel and source.Create then
      source.panel = source.Create(parent)
    end
    return source.panel
  end

  local function ActiveSource()
    for i = 1, #sources do
      if sources[i].key == bar.activeKey then return sources[i] end
    end
    return sources[1]
  end

  local function Apply()
    for i = 1, #bar.buttons do
      local btn = bar.buttons[i]
      local isActive = (btn.sourceKey == bar.activeKey)
      local fs = btn:GetFontString()
      if fs then
        if isActive then
          fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
        else
          fs:SetTextColor(0.62, 0.62, 0.62)
        end
      end
      if isActive then
        btn:LockHighlight()
      else
        btn:UnlockHighlight()
      end
    end

    for i = 1, #sources do
      local source = sources[i]
      if source.key == bar.activeKey then
        local panel = ResolvePanel(source)
        if panel then
          panel:Show()
          if panel.Refresh then panel.Refresh() end
        end
      elseif source.panel then
        source.panel:Hide()
      end
    end
  end

  -- Built right to left so the list still reads left to right on screen
  local prev
  for i = #sources, 1, -1 do
    local source = sources[i]

    local btn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btn:SetSize(SWITCH_BTN_W, SWITCH_BTN_H)
    btn:SetText(source.label)
    btn.sourceKey = source.key
    StyleAddonButton(btn)

    if prev then
      btn:SetPoint("RIGHT", prev, "LEFT", -4, 0)
    else
      btn:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    end

    btn:SetScript("OnClick", function(self)
      if bar.activeKey == self.sourceKey then return end
      bar.activeKey = self.sourceKey
      Apply()
    end)

    table.insert(bar.buttons, btn)
    prev = btn
  end

  bar.Apply = Apply
  bar.ActiveSource = ActiveSource
  Apply()

  return bar
end

-- The Settings tab of JemiStats' own window
function JS.BuildSettingsPanel(tabPanel)
  if not tabPanel or tabPanel._built then return end
  tabPanel._built = true

  local own = JS.CreateSettingsPanel(tabPanel)

  -- Solo install, or a host that does not offer its settings: nothing to switch
  -- between, so the panel stays exactly as it is without a switcher
  if not settingsProvider then
    tabPanel.Refresh = function()
      if own and own.Refresh then own.Refresh() end
    end
    return
  end

  local sources = {
    {
      key = "host",
      label = settingsProvider.label,
      Create = function(parent)
        return settingsProvider.Create(parent)
      end,
    },
    {
      key = "jemistats",
      label = "JemiStats",
      panel = own,
    },
  }

  local switcher = BuildSourceSwitcher(tabPanel, sources, "jemistats")
  tabPanel.switcher = switcher

  tabPanel.Refresh = function()
    local source = switcher.ActiveSource()
    local panel = source and source.panel
    if panel and panel.Refresh then
      panel.Refresh()
    end
  end
end
