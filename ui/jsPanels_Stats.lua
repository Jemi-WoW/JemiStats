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

  -- Header area
  local HELPER_TOP = 8         -- gap above the first helper line
  local HELPER_LINE_GAP = 2    -- gap between helper lines
  local HELPER_BOTTOM_PAD = 6  -- clearance between the helper and the body
  local INSET_TOP_MIN = 30     -- room for the "Stats" title on its own

  local panel = CreateFrame("Frame", nil, parent)
  panel:SetAllPoints(parent)
  parent._jsStatsPanel = panel

  local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", 8, -6)
  header:SetText("Stats")

  -- Helper text
  -- One fontstring per line, and no SetWidth on any of them. A fontstring with
  -- no width auto-sizes to its text instead of wrapping, so a command like
  -- '/oath statsreset' can never be split across two lines. The host's wording
  -- arrives through opts.helperText and is measured the same way, so the panel
  -- looks identical standalone and inside Oathbound.
  local helperLines = {}

  do
    local lines = {}
    for line in tostring(helper or ""):gmatch("[^\n]+") do
      lines[#lines + 1] = line
    end

    local prev
    for i = 1, #lines do
      local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetJustifyH("RIGHT")
      fs:SetJustifyV("TOP")
      fs:SetTextColor(0.62, 0.62, 0.62)
      if fs.SetWordWrap then fs:SetWordWrap(false) end
      fs:SetText(lines[i])

      if prev then
        fs:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -HELPER_LINE_GAP)
      else
        fs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -HELPER_TOP)
      end

      helperLines[i] = fs
      prev = fs
    end
  end

  local inset = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
  inset:SetPoint("BOTTOMRIGHT", -8, 10)

  -- Push the body below whichever is taller, the "Stats" title or the helper.
  -- Driven by the measured text rather than a fixed offset, so a longer helper
  -- string moves the body down instead of being clipped by it.
  local appliedInsetTop

  local function LayoutHeaderArea()
    local helperHeight = 0
    for i = 1, #helperLines do
      helperHeight = helperHeight + (helperLines[i]:GetStringHeight() or 12)
      if i > 1 then helperHeight = helperHeight + HELPER_LINE_GAP end
    end

    local top = math.max(INSET_TOP_MIN, HELPER_TOP + helperHeight + HELPER_BOTTOM_PAD)

    -- Only re-anchor on a real change, so this never ping-pongs with the
    -- OnSizeChanged handler that calls back into the layout
    if appliedInsetTop == top then return end
    appliedInsetTop = top

    inset:SetPoint("TOPLEFT", 8, -top)
  end

  LayoutHeaderArea()

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
      widgets[i] = { kind = "header", fs = fs, def = def, visible = true }
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

      widgets[i] = { kind = "row", row = row, def = def, visible = true }
    end
  end

  -- Layout all stat rows
  -- Only widgets flagged visible are stacked, so hiding zeroed rows closes the
  -- gap instead of leaving a hole. The section gap is added ahead of each header
  -- rather than behind the last row, which keeps it correct no matter how many
  -- rows in between are hidden.
  local function RefreshLayout()
    -- Re-measured here as well as at build, because string heights only settle
    -- once the panel has actually been shown
    LayoutHeaderArea()

    local scrollW = scroll:GetWidth() or 0
    if scrollW > 0 then
      content:SetWidth(math.max(1, scrollW))
    end

    local striped = JS.GetSetting("stripedRows")

    local y = 0
    local rowStripe = 0
    local placedAny = false

    for i = 1, #widgets do
      local w = widgets[i]

      if not w.visible then
        if w.kind == "header" then
          w.fs:Hide()
        else
          w.row:Hide()
        end
      elseif w.kind == "header" then
        w.fs:Show()
        if placedAny then y = y + SECTION_GAP end
        w.fs:ClearAllPoints()
        w.fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        w.fs:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -y)
        y = y + HEADER_H
        placedAny = true
      else
        local row = w.row
        row:Show()
        rowStripe = rowStripe + 1
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
        row:SetHeight(ROW_H)
        if striped then
          row.bg:SetVertexColor(1, 1, 1, (rowStripe % 2 == 0) and 0.03 or 0.06)
        else
          row.bg:SetVertexColor(1, 1, 1, 0)
        end
        y = y + ROW_H
        placedAny = true
      end
    end

    local totalHeight = math.max(scroll:GetHeight() or 1, y + 4)
    content:SetHeight(totalHeight)

    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
    end
  end

  panel.RefreshLayout = RefreshLayout

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

    -- Measured from the wall-clock stamp, so a session kept across a logout
    -- still reads correctly once GetTime() has restarted at zero
    if JS.GetSetting("showSessionLength") then
      local started = tonumber(s.sessionStartedAtEpoch or 0) or 0
      local now = (time and time()) or 0
      local elapsed = (started > 0 and now > 0) and math.max(0, now - started) or 0
      topText:SetText(string.format("Live character stats tracked by %s. Session length: %s", brand, Stats.FormatSessionLength(elapsed)))
    else
      topText:SetText(string.format("Live character stats tracked by %s.", brand))
    end

    local hideZero = JS.GetSetting("hideZeroStats")
    local visibilityChanged = false

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

        local visible = not (hideZero and (tonumber(value) or 0) == 0)
        if w.visible ~= visible then
          w.visible = visible
          visibilityChanged = true
        end
      end
    end

    -- A header survives only while at least one row under it is still showing
    for i = 1, #widgets do
      local w = widgets[i]
      if w.kind == "header" then
        local visible = false

        for j = i + 1, #widgets do
          local following = widgets[j]
          if following.kind == "header" then break end
          if following.visible then
            visible = true
            break
          end
        end

        if w.visible ~= visible then
          w.visible = visible
          visibilityChanged = true
        end
      end
    end

    -- The once-per-second tick calls this too, so the re-stack only runs when
    -- the set of rows actually changed
    if visibilityChanged then
      QueueRefreshLayout()
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
