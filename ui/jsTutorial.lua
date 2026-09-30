local _, JS = ...

local WIDTH = 270
local PAD = 14
local GAP = 18
local SHOW_DELAY = 2.5

local BODY_TEXT = "Thanks for using my stats addon.\n\n"
  .. "|cffffd100Right click|r the stats window to open the addon.\n"
  .. "|cffffd100Shift + right click|r to open the settings.\n\n"
  .. "/ Jemi"

local frame

local function TutorialSeen()
  local d = JS.DB()
  return d.tutorialSeen and true or false
end

function JS.MarkTutorialSeen()
  JS.DB().tutorialSeen = true
end

local function Build()
  if frame then return frame end

  frame = CreateFrame("Frame", "JemiStatsTutorialFrame", UIParent,
    JS.PickTemplate("Frame", { "BackdropTemplate" }))
  frame:SetWidth(WIDTH)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
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
    frame:SetBackdropColor(0, 0, 0, 0.92)
    frame:SetBackdropBorderColor(0.7, 0.6, 0.35, 1)
  else
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.92)
  end

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
  title:SetText("JemiStats")
  title:SetTextColor(1, 0.82, 0)
  frame.title = title

  local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  body:SetWidth(WIDTH - (PAD * 2))
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetSpacing(2)
  body:SetText(BODY_TEXT)
  frame.body = body

  -- Sits on the sign-off line rather than below it
  local okay = JS.CreatePanelButton(frame)
  okay:SetSize(90, 22)
  okay:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, -4)
  okay:SetText("Okay")
  okay:SetScript("OnClick", function()
    JS.MarkTutorialSeen()
    frame:Hide()
  end)
  frame.okay = okay

  return frame
end

-- Beside the stats window, on whichever side has room
local function PlaceBeside(target)
  frame:ClearAllPoints()

  if not target then
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 420, -220)
    return
  end

  local centerX = target:GetCenter()
  local screenWidth = UIParent and UIParent:GetWidth() or 0
  local onRightHalf = centerX and screenWidth > 0 and centerX >= (screenWidth / 2)

  if onRightHalf then
    frame:SetPoint("TOPRIGHT", target, "TOPLEFT", -GAP, 0)
  else
    frame:SetPoint("TOPLEFT", target, "TOPRIGHT", GAP, 0)
  end
end

function JS.ShowTutorial(force)
  if not force and TutorialSeen() then return end

  Build()

  local target = _G.JemiStatsWindowFrame
  if target and not target:IsShown() then target = nil end
  PlaceBeside(target)

  -- Sized to whatever the body wrapped to, so the Okay button never overlaps it
  local bodyHeight = frame.body:GetStringHeight() or 70
  frame:SetHeight(PAD + (frame.title:GetStringHeight() or 14) + 8 + bodyHeight + 6 + PAD)

  frame:Show()
end

-- Shown a beat after login, once the stats window has settled where it belongs
function JS.ScheduleTutorial()
  if TutorialSeen() then return end
  if not C_Timer or not C_Timer.After then return end

  C_Timer.After(SHOW_DELAY, function()
    JS.ShowTutorial(false)
  end)
end
