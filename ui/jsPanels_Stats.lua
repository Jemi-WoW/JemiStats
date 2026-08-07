local _, JS = ...
local Stats = JS.Stats

local GOLD  = Stats.colors.GOLD
local WHITE = Stats.colors.WHITE
local DIM   = Stats.colors.DIM

local DEFAULT_BRAND = "JemiStats"
local DEFAULT_HELPER = "Issues with Stats not tracking correctly? Try '/jstats sessionreset'\nIf issues persist, Try '/jstats reset'"

-- Show stat tooltip
local function ShowStatTooltip(widget, title, body)
  if not widget or not body or body == "" then return end
  GameTooltip:SetOwner(widget, "ANCHOR_TOP")
  GameTooltip:ClearLines()
  if title and title ~= "" then
    GameTooltip:AddLine(title, GOLD[1], GOLD[2], GOLD[3], true)
    GameTooltip:AddLine(" ")
  end
  GameTooltip:AddLine(body, WHITE[1], WHITE[2], WHITE[3], true)
  GameTooltip:Show()
end

-- STATS PANEL
-- Built into whatever frame it is handed, so the same panel works inside this
-- addon's window and inside a host addon's tab. opts carries the wording that
-- differs per host: opts.brand for the header line, opts.helperText for the hint.
function JS.CreateStatsPanel(parent, opts)
  if not parent then return nil end
  if parent._jsStatsPanel then return parent._jsStatsPanel end

  opts = opts or {}
  local brand = opts.brand or DEFAULT_BRAND
  local helper = opts.helperText or DEFAULT_HELPER

  local PAD = 10
  local ROW_H = 28
  local HEADER_H = 22
  local SECTION_GAP = 8

  local panel = CreateFrame("Frame", nil, parent)
  panel:SetAllPoints(parent)
  parent._jsStatsPanel = panel

  local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", 8, -6)
  header:SetText("Stats")

  local helperText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  helperText:SetPoint("TOPRIGHT", -10, -10)
  helperText:SetWidth(310)
  helperText:SetJustifyH("RIGHT")
  helperText:SetJustifyV("TOP")
  helperText:SetTextColor(0.62, 0.62, 0.62)
  helperText:SetText(helper)

  local inset = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
  inset:SetPoint("TOPLEFT", 8, -30)
  inset:SetPoint("BOTTOMRIGHT", -8, 10)

  local topInset = CreateFrame("Frame", nil, inset, "InsetFrameTemplate3")
  topInset:SetPoint("TOPLEFT", PAD, -PAD)
  topInset:SetPoint("TOPRIGHT", -PAD, -PAD)
  topInset:SetHeight(46)

  local topText = topInset:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  topText:SetPoint("LEFT", 12, 0)
  topText:SetPoint("RIGHT", -12, 0)
  topText:SetJustifyH("LEFT")
  topText:SetTextColor(DIM[1], DIM[2], DIM[3])

  local listInset = CreateFrame("Frame", nil, inset, "InsetFrameTemplate3")
  listInset:SetPoint("TOPLEFT", topInset, "BOTTOMLEFT", 0, -10)
  listInset:SetPoint("BOTTOMRIGHT", -PAD, PAD)

  local scroll = CreateFrame("ScrollFrame", nil, listInset, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -12)
  scroll:SetPoint("BOTTOMRIGHT", -28, 12)
  scroll:EnableMouseWheel(true)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  local ENTRY_LAYOUT = Stats.BuildTrackerEntryLayout()

  -- Build stat rows
  local widgets = {}
  for i = 1, #ENTRY_LAYOUT do
    local def = ENTRY_LAYOUT[i]

    if def.type == "header" then
      local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      fs:SetJustifyH("LEFT")
      fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
      fs:SetText(def.label)
      widgets[i] = { kind = "header", fs = fs, def = def }
    else
      local row = CreateFrame("Frame", nil, content)
      row:EnableMouse(true)
      row.bg = row:CreateTexture(nil, "BACKGROUND")
      row.bg:SetAllPoints(true)
      row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")

      row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.label:SetPoint("LEFT", 8, 0)
      row.label:SetJustifyH("LEFT")
      row.label:SetText(def.label)

      row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.value:SetPoint("RIGHT", -8, 0)
      row.value:SetJustifyH("RIGHT")

      row:SetScript("OnEnter", function(self)
        ShowStatTooltip(self, def.label, Stats.TooltipBodyForKey(def.key))
      end)
      row:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)

      widgets[i] = { kind = "row", row = row, def = def }
    end
  end

  -- Layout all stat rows
  local function RefreshLayout()
    local scrollW = scroll:GetWidth() or 0
    if scrollW > 0 then
      content:SetWidth(math.max(1, scrollW))
    end

    local y = 0
    local rowStripe = 0

    for i = 1, #widgets do
      local w = widgets[i]
      if w.kind == "header" then
        w.fs:ClearAllPoints()
        w.fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        w.fs:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -y)
        y = y + HEADER_H
      else
        rowStripe = rowStripe + 1
        local row = w.row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
        row:SetHeight(ROW_H)
        row.bg:SetVertexColor(1, 1, 1, (rowStripe % 2 == 0) and 0.03 or 0.06)
        y = y + ROW_H
      end

      if i < #widgets and ENTRY_LAYOUT[i + 1].type == "header" then
        y = y + SECTION_GAP
      end
    end

    local totalHeight = math.max(scroll:GetHeight() or 1, y + 4)
    content:SetHeight(totalHeight)

    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
    end
  end

  local function QueueRefreshLayout()
    if panel._jsLayoutQueued then return end
    panel._jsLayoutQueued = true

    C_Timer.After(0, function()
      panel._jsLayoutQueued = nil
      RefreshLayout()
    end)
  end

  -- Refresh visible values
  panel.Refresh = function()
    local s = Stats.EnsureStatsDB()
    local started = tonumber(s.sessionStartedAt or 0) or 0
    local elapsed = math.max(0, (GetTime and GetTime() or 0) - started)
    topText:SetText(string.format("Live character stats tracked by %s. Session length: %s", brand, Stats.FormatSessionLength(elapsed)))

    for i = 1, #widgets do
      local w = widgets[i]
      if w.kind == "row" then
        local def = w.def
        local tracker = def.tracker
        local value

        if tracker and tracker.getValue then
          value = tracker.getValue(tracker, s)
        else
          value = s[def.key]
        end

        local lr, lg, lb, vr, vg, vb = Stats.ColorsForKey(def.key)
        w.row.label:SetText(def.label)
        w.row.label:SetTextColor(lr, lg, lb)
        w.row.value:SetText(def.fmt(value))
        w.row.value:SetTextColor(vr, vg, vb)
      end
    end
  end

  scroll:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll() or 0
    local maxScroll = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
    local nextValue = current - (delta * 36)
    if nextValue < 0 then nextValue = 0 end
    if nextValue > maxScroll then nextValue = maxScroll end
    self:SetVerticalScroll(nextValue)
  end)

  listInset:SetScript("OnSizeChanged", function()
    QueueRefreshLayout()
  end)

  scroll:SetScript("OnSizeChanged", function()
    QueueRefreshLayout()
  end)

  panel:SetScript("OnShow", function(self)
    if self.Refresh then
      self:Refresh()
    end
    RefreshLayout()
  end)

  panel:SetScript("OnHide", function(self)
    self._jsLayoutQueued = nil
  end)

  Stats.RegisterPanel(panel)
  panel:Refresh()

  return panel
end
