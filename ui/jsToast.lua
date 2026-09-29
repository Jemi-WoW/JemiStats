local _, JS = ...
local Stats = JS.Stats

local TOAST_HEIGHT = 26
local TOAST_GAP = 4
local TOAST_LIFETIME = 3.0
local TOAST_FADE = 0.4
local TOAST_MOVE_SPEED = 18
local TOAST_MAX = 8
local TOAST_MIN_WIDTH = 60
local TOAST_MAX_WIDTH = 420
local TEXT_PADDING = 12

-- Repeated hits on one stat fold into the toast already on screen
local MERGE_WINDOW = 2.0

local ANCHOR_WIDTH = 160
local PREVIEW_HEIGHT = 24
local PREVIEW_PAD = 10
local PREVIEW_GAP = 8
local CONFIRM_WIDTH = 62
local CONFIRM_HEIGHT = 18

local DEFAULT_X, DEFAULT_Y = -260, -220

local container
local toasts = {}
local activeByKey = {}

local function Clamp(value, low, high)
  if value < low then return low end
  if value > high then return high end
  return value
end

local function EnsureToastDB()
  JemiStatsDB = JemiStatsDB or {}
  JemiStatsDB.toast = JemiStatsDB.toast or {}
  return JemiStatsDB.toast
end

function JS.SaveToastPosition()
  if not container then return end

  local point, _, relPoint, x, y = container:GetPoint()
  if not point then return end

  local db = EnsureToastDB()
  db.point, db.relPoint = point, relPoint or point
  db.x, db.y = tonumber(x) or 0, tonumber(y) or 0
end

function JS.RestoreToastPosition()
  if not container then return end

  local db = EnsureToastDB()
  container:ClearAllPoints()

  if db.point then
    container:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x or 0, db.y or 0)
  else
    container:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", DEFAULT_X, DEFAULT_Y)
  end
end

-- Grow toward screen centre, so an anchor at either edge stays in view
function JS.ToastGrowsRight()
  if not container then return false end

  local centerX = container:GetCenter()
  local screenWidth = UIParent and UIParent:GetWidth() or 0
  if not centerX or screenWidth <= 0 then return false end

  return centerX < (screenWidth / 2)
end

-- Stack upward from the bottom half, for the same reason
function JS.ToastGrowsUp()
  if not container then return false end

  local _, centerY = container:GetCenter()
  local screenHeight = UIParent and UIParent:GetHeight() or 0
  if not centerY or screenHeight <= 0 then return false end

  return centerY < (screenHeight / 2)
end

local function PositionToast(toast, growsRight, growsUp, y)
  local vertical = growsUp and "BOTTOM" or "TOP"
  local horizontal = growsRight and "LEFT" or "RIGHT"
  local corner = vertical .. horizontal

  toast:ClearAllPoints()
  toast:SetPoint(corner, container, corner, 0, growsUp and y or -y)
end

local function AnyToastShown()
  for i = 1, #toasts do
    if toasts[i]:IsShown() then return true end
  end
  return false
end

local function EnsureContainer()
  if container then return container end

  container = CreateFrame("Frame", "JemiStatsToastFrame", UIParent)
  -- Kept at the marker's size, so what was dragged is where toasts land
  container:SetSize(ANCHOR_WIDTH, PREVIEW_HEIGHT)
  container:SetFrameStrata("DIALOG")
  container:SetMovable(true)
  container:EnableMouse(false)
  container:SetClampedToScreen(true)

  JS.RestoreToastPosition()

  container:SetScript("OnUpdate", function(self, elapsed)
    if not self.animating then return end

    local now = GetTime()
    local growsRight, growsUp = JS.ToastGrowsRight(), JS.ToastGrowsUp()
    local shown = false

    for i = 1, #toasts do
      local toast = toasts[i]
      if toast:IsShown() and toast.baseY then
        shown = true

        local remaining = (toast.expireAt or now) - now
        if remaining <= 0 then
          toast:SetAlpha(0)
        elseif remaining < TOAST_FADE then
          toast:SetAlpha(remaining / TOAST_FADE)
        else
          toast:SetAlpha(1)
        end

        -- Eased toward the target so a push reads as a slide, not a jump
        toast.y = toast.y or toast.baseY
        local dy = toast.baseY - toast.y
        if math.abs(dy) > 0.25 then
          toast.y = toast.y + dy * math.min(1, elapsed * TOAST_MOVE_SPEED)
        else
          toast.y = toast.baseY
        end

        PositionToast(toast, growsRight, growsUp, toast.y)
      end
    end

    if not shown then
      self.animating = false
    end
  end)

  return container
end

local function CreateToast()
  local toast = CreateFrame("Frame", nil, container, JS.PickTemplate("Frame", { "BackdropTemplate" }))
  toast:SetSize(TOAST_MIN_WIDTH, TOAST_HEIGHT)

  if type(toast.SetBackdrop) == "function" then
    toast:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    toast:SetBackdropColor(0, 0, 0, 0.92)
    toast:SetBackdropBorderColor(0.55, 0.45, 0.22, 1)
  else
    local bg = toast:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.92)
  end

  local text = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", toast, "LEFT", TEXT_PADDING, 0)
  text:SetJustifyH("LEFT")
  if text.SetWordWrap then text:SetWordWrap(false) end
  toast.text = text

  toast:Hide()
  return toast
end

local function ResizeToast(toast)
  local width = (toast.text:GetStringWidth() or 0) + (TEXT_PADDING * 2)
  toast:SetWidth(Clamp(width, TOAST_MIN_WIDTH, TOAST_MAX_WIDTH))
end

local function ToHex(value)
  return string.format("%02x", math.floor(Clamp(value, 0, 1) * 255 + 0.5))
end

local function Colored(text, r, g, b)
  return "|cff" .. ToHex(r) .. ToHex(g) .. ToHex(b) .. tostring(text) .. "|r"
end

-- "+5", or the record's new value, already colored to match its row
local function BuildText(tracker, style, delta, newValue)
  local lr, lg, lb, vr, vg, vb = Stats.ColorsForKey(tracker.key)
  local icon = JS.StatIconMarkup(tracker.key)
  local minimal = JS.GetSetting("minimalStatToasts")

  local lead
  if style == "record" then
    lead = tracker.fmt(newValue)
  elseif style == "money" then
    lead = "+" .. Stats.FormatCopper(math.abs(delta))
  else
    lead = string.format("%+d", delta)
  end

  lead = Colored(lead, vr, vg, vb)

  if icon ~= "" then
    lead = lead .. " " .. icon
  end

  if minimal then
    return lead
  end

  return lead .. "  " .. Colored(tracker.label, lr, lg, lb)
end

local function Reflow()
  local growsRight, growsUp = JS.ToastGrowsRight(), JS.ToastGrowsUp()
  local y = 0

  for i = 1, #toasts do
    local toast = toasts[i]
    if toast:IsShown() then
      toast.baseY = y
      PositionToast(toast, growsRight, growsUp, toast.y or y)
      y = y + TOAST_HEIGHT + TOAST_GAP
    end
  end
end

local function HideToast(toast)
  toast:Hide()
  if toast.statKey and activeByKey[toast.statKey] == toast then
    activeByKey[toast.statKey] = nil
  end
  Reflow()
end

function JS.PushStatToast(tracker, style, delta, newValue)
  EnsureContainer()

  local now = GetTime and GetTime() or 0

  -- Fold into the live toast for this stat rather than stacking a near-duplicate
  local existing = activeByKey[tracker.key]
  if existing and existing:IsShown() and style == "counter"
    and (now - (existing.lastAt or 0)) <= MERGE_WINDOW then
    existing.delta = (existing.delta or 0) + delta
    existing.lastAt = now
    existing.expireAt = now + TOAST_LIFETIME
    existing.text:SetText(BuildText(tracker, style, existing.delta, newValue))
    ResizeToast(existing)
    container.animating = true
    return existing
  end

  local toast
  for i = 1, #toasts do
    if not toasts[i]:IsShown() then
      toast = toasts[i]
      table.remove(toasts, i)
      break
    end
  end

  toast = toast or CreateToast()

  toast.statKey = tracker.key
  toast.delta = delta
  toast.lastAt = now
  toast.expireAt = now + TOAST_LIFETIME
  toast.y = nil
  toast.text:SetText(BuildText(tracker, style, delta, newValue))
  ResizeToast(toast)
  toast:SetAlpha(1)
  toast:Show()

  table.insert(toasts, 1, toast)
  activeByKey[tracker.key] = toast

  while #toasts > TOAST_MAX do
    local oldest = table.remove(toasts)
    if oldest then HideToast(oldest) end
  end

  Reflow()
  container.animating = true

  if C_Timer and C_Timer.After then
    C_Timer.After(TOAST_LIFETIME, function()
      if toast.expireAt and (GetTime and GetTime() or 0) < toast.expireAt - 0.05 then return end
      HideToast(toast)
    end)
  end

  return toast
end

function JS.ClearStatToasts()
  for i = 1, #toasts do
    toasts[i]:Hide()
  end
  activeByKey = {}
  if container then container.animating = false end
end

-- Repositioning, which needs something visible to grab while the stack is empty
local preview

function JS.EnableToastRepositioning()
  EnsureContainer()
  if container.repositioning then return end
  container.repositioning = true

  container:EnableMouse(true)
  container:RegisterForDrag("LeftButton")
  container:SetScript("OnDragStart", function(self) self:StartMoving() end)
  container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  if not preview then
    preview = CreateFrame("Frame", nil, container, JS.PickTemplate("Frame", { "BackdropTemplate" }))
    preview:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    preview:SetHeight(PREVIEW_HEIGHT)

    if type(preview.SetBackdrop) == "function" then
      preview:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
      })
      preview:SetBackdropColor(0, 0, 0, 0.92)
      preview:SetBackdropBorderColor(1, 0.82, 0, 1)
    end

    local label = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", preview, "LEFT", PREVIEW_PAD, 0)
    label:SetText("Toasts here")
    label:SetTextColor(1, 0.82, 0)
    preview.label = label

    local confirm = JS.CreatePanelButton(preview)
    confirm:SetSize(CONFIRM_WIDTH, CONFIRM_HEIGHT)
    confirm:SetPoint("RIGHT", preview, "RIGHT", -PREVIEW_PAD, 0)
    confirm:SetText("Confirm")
    confirm:SetScript("OnClick", function()
      JS.SaveToastPosition()
      JS.DisableToastRepositioning()
      JS.Msg("Toast position saved.")
    end)

    preview.confirm = confirm
  end

  -- The mover takes the marker's exact rect, so clamping stops where you see it
  local width = PREVIEW_PAD + (preview.label:GetStringWidth() or 60)
    + PREVIEW_GAP + CONFIRM_WIDTH + PREVIEW_PAD

  preview:SetWidth(width)
  container:SetSize(width, PREVIEW_HEIGHT)
  ANCHOR_WIDTH = width

  preview:Show()
end

function JS.DisableToastRepositioning()
  if not container then return end
  container.repositioning = false

  container:EnableMouse(false)
  container:SetScript("OnDragStart", nil)
  container:SetScript("OnDragStop", nil)

  if preview then preview:Hide() end
end

function JS.ResetToastPosition()
  local db = EnsureToastDB()
  db.point, db.relPoint, db.x, db.y = nil, nil, nil, nil
  JS.RestoreToastPosition()
  JS.Msg("Toast position reset.")
end

function JS.CreateToastFrame()
  EnsureContainer()
end
