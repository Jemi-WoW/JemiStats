local _, JS = ...
local UI = JS.UI

local GOLD = { 1.0, 0.82, 0.0 }
local DIM  = { 0.82, 0.82, 0.82 }

local ROW_H = 26
local SECTION_GAP = 14
local SCROLL_STEP = 36

local settingsPanel

-- Tooltip helper
local function AttachTooltip(widget, title, body)
  if not widget then return end
  widget:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if title and title ~= "" then
      GameTooltip:AddLine(title, GOLD[1], GOLD[2], GOLD[3], true)
    end
    if body and body ~= "" then
      GameTooltip:AddLine(body, 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  widget:HookScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end

-- One option row
local function CreateCheckbox(parent, def)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  if cb.Text then
    cb.Text:SetText("")
    cb.Text:Hide()
  end

  cb.settingKey = def.key

  cb:SetScript("OnClick", function(self)
    JS.SetSetting(def.key, self:GetChecked() and true or false, "panel")
  end)

  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
  label:SetJustifyH("LEFT")
  label:SetText(def.label)
  label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  cb.label = label

  AttachTooltip(cb, def.label, def.tooltip)

  return cb
end

-- SETTINGS PANEL
-- Empty on purpose for now. Everything below is driven by JS.SETTINGS_DEFS,
-- JS.SETTINGS_ORDER and JS.SETTINGS_SECTION_ORDER, so a new option is three
-- table entries and nothing here changes.
function JS.BuildSettingsPanel(panel)
  if panel._built then return end
  panel._built = true

  local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", 8, -6)
  header:SetText("Settings")

  local inset = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
  inset:SetPoint("TOPLEFT", 8, -30)
  inset:SetPoint("BOTTOMRIGHT", -8, 10)

  local listInset = CreateFrame("Frame", nil, inset, "InsetFrameTemplate3")
  listInset:SetPoint("TOPLEFT", 10, -10)
  listInset:SetPoint("BOTTOMRIGHT", -10, 10)

  local scroll = CreateFrame("ScrollFrame", nil, listInset, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -12)
  scroll:SetPoint("BOTTOMRIGHT", -28, 12)
  scroll:EnableMouseWheel(true)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  -- Shown while there is nothing to configure
  local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  emptyText:SetJustifyH("LEFT")
  emptyText:SetJustifyV("TOP")
  emptyText:SetTextColor(DIM[1], DIM[2], DIM[3])
  emptyText:SetText("No settings yet.\n\nOptions for JemiStats will land here in a later version.")

  local widgets = {}
  local checksByKey = {}

  -- Build every section that has options declared
  for _, section in ipairs(JS.SETTINGS_SECTION_ORDER) do
    local order = JS.SETTINGS_ORDER[section.key] or {}
    local sectionWidgets = {}

    for _, key in ipairs(order) do
      local def = JS.GetSettingDef(key)
      if def then
        local check = CreateCheckbox(content, def)
        checksByKey[key] = check
        sectionWidgets[#sectionWidgets + 1] = check
      end
    end

    if #sectionWidgets > 0 then
      local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      title:SetJustifyH("LEFT")
      title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
      title:SetText(section.title or section.key)

      widgets[#widgets + 1] = { kind = "header", fs = title }
      for i = 1, #sectionWidgets do
        widgets[#widgets + 1] = { kind = "row", check = sectionWidgets[i] }
      end
    end
  end

  -- Stack sections and rows
  function panel:Layout()
    local sw = scroll:GetWidth() or 0
    local sh = scroll:GetHeight() or 0
    if sw <= 0 or sh <= 0 then return end

    content:SetWidth(math.max(1, sw))

    if #widgets == 0 then
      emptyText:ClearAllPoints()
      emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
      emptyText:SetWidth(math.max(1, sw - 8))
      emptyText:Show()
      content:SetHeight(math.max(sh + 1, (emptyText:GetStringHeight() or 40) + 12))
      if scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
      end
      return
    end

    emptyText:Hide()

    local y = 0
    for i = 1, #widgets do
      local w = widgets[i]
      if w.kind == "header" then
        if i > 1 then y = y + SECTION_GAP end
        w.fs:ClearAllPoints()
        w.fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        y = y + ROW_H
      else
        w.check:ClearAllPoints()
        w.check:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -y)
        y = y + ROW_H
      end
    end

    content:SetHeight(math.max(sh + 1, y + 4))

    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
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

  panel.Refresh = function()
    for key, check in pairs(checksByKey) do
      check:SetChecked(JS.GetSetting(key))
    end

    C_Timer.After(0, function()
      if panel.Layout then panel:Layout() end
    end)
  end

  settingsPanel = panel
  panel.Refresh()
end

-- Called after a setting changes from anywhere
function JS.RefreshSettingsPanel()
  if settingsPanel and settingsPanel.Refresh then
    settingsPanel.Refresh()
  end
end
