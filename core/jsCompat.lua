local _, JS = ...

-- Client differences, resolved once at load so hot paths never pay for them.

local C_Item = C_Item
local C_AddOns = C_AddOns
local C_Spell = C_Spell

-- Build number, not WOW_PROJECT_*: Forever reports itself as Retail.
local interfaceVersion = 0

if GetBuildInfo then
  -- Named locals, not select(): the extra returns would hit tonumber's base arg
  local _, _, _, tocVersion = GetBuildInfo()
  interfaceVersion = tonumber(tocVersion) or 0
end

local isForever = interfaceVersion >= 16000 and interfaceVersion < 20000

-- Forever serves vanilla content, so it sits at expansion 1
local expansionLevel = 1

if not isForever and interfaceVersion > 0 then
  expansionLevel = math.floor(interfaceVersion / 10000)
end

function JS.InterfaceVersion()
  return interfaceVersion
end

function JS.ExpansionLevel()
  return expansionLevel
end

function JS.IsBurningCrusade()
  return expansionLevel >= 2
end

function JS.IsForever()
  return isForever
end

-- True on any client built from the modern codebase
function JS.IsModernCodebase()
  return isForever
end

-- Item info (C_Item since the 1.15.9 UI rebuild)
local rawGetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

-- Addon load state (C_AddOns since the 1.15.9 UI rebuild)
local rawIsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded

-- C_Spell first: the modern codebase removed the plain GetSpellInfo global.
local cGetSpellInfo = C_Spell and C_Spell.GetSpellInfo
local rawGetSpellInfo = _G.GetSpellInfo
local getSpellSubtext = (C_Spell and C_Spell.GetSpellSubtext) or _G.GetSpellSubtext

-- Cache-free item info (classID/subClassID for ammo detection)
function JS.GetItemInfoInstant(item)
  if not item or item == "" then return nil end
  if not rawGetItemInfoInstant then return nil end
  return rawGetItemInfoInstant(item)
end

-- Spell name, rank and icon
function JS.GetSpellInfo(spellID)
  if not spellID then return nil end

  if cGetSpellInfo then
    -- Returns a table, and rank lives in its own call
    local info = cGetSpellInfo(spellID)
    if not info then return nil end

    local rank = getSpellSubtext and getSpellSubtext(spellID) or nil
    return info.name, rank, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
  end

  if rawGetSpellInfo then
    return rawGetSpellInfo(spellID)
  end

  return nil
end

-- Spell name only, the form most call sites want
function JS.GetSpellName(spellID)
  return (JS.GetSpellInfo(spellID))
end

-- Probed with a throwaway unnamed frame, so a failed try never burns a name.
local templateCache = {}

local function TemplateExists(frameType, template)
  local cacheKey = frameType .. "\0" .. template
  local cached = templateCache[cacheKey]
  if cached ~= nil then
    return cached
  end

  local ok, frame = pcall(CreateFrame, frameType, nil, UIParent, template)
  if ok and frame then
    frame:Hide()
    frame:SetParent(nil)
  end

  templateCache[cacheKey] = ok and true or false
  return templateCache[cacheKey]
end

-- First usable template from the list, or nil for a bare frame
function JS.PickTemplate(frameType, templates)
  for i = 1, #templates do
    if TemplateExists(frameType, templates[i]) then
      return templates[i]
    end
  end
  return nil
end

-- Returns the frame and the template used, nil when it ended up bare.
function JS.CreateFromTemplates(frameType, name, parent, templates)
  local template = JS.PickTemplate(frameType, templates)
  return CreateFrame(frameType, name, parent, template), template
end

local INSET_TEMPLATES = { "InsetFrameTemplate3", "InsetFrameTemplate2", "InsetFrameTemplate" }
local SCROLL_TEMPLATES = { "UIPanelScrollFrameTemplate", "ScrollFrameTemplate" }
local CHECKBOX_TEMPLATES = { "UICheckButtonTemplate", "InterfaceOptionsCheckButtonTemplate" }

-- Sunken panel background
function JS.CreateInset(parent)
  local inset, template = JS.CreateFromTemplates("Frame", nil, parent, INSET_TEMPLATES)

  if not template then
    local bg = inset:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.35)
  end

  return inset
end

local BUTTON_TEMPLATES = { "UIPanelButtonTemplate", "SharedButtonSmallTemplate" }
local EDITBOX_TEMPLATES = { "InputBoxTemplate", "SearchBoxTemplate" }

-- Push button, with its own label when no template supplied one
function JS.CreatePanelButton(parent)
  local btn = (JS.CreateFromTemplates("Button", nil, parent, BUTTON_TEMPLATES))

  if not btn:GetFontString() then
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    btn:SetFontString(fs)
    btn:SetHighlightFontObject("GameFontHighlightSmall")
  end

  return btn
end

-- Single-line text entry
function JS.CreateEditBox(parent)
  local box, template = JS.CreateFromTemplates("EditBox", nil, parent, EDITBOX_TEMPLATES)

  if not template then
    box:SetFontObject("GameFontHighlightSmall")
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
  end

  box:SetAutoFocus(false)
  return box
end

-- Frame plus whether SetBackdrop works on it; the mixin does not prove it does.
function JS.CreateBackdropFrame(parent)
  local frame = JS.CreateFromTemplates("Frame", nil, parent, { "BackdropTemplate" })
  return frame, type(frame.SetBackdrop) == "function"
end

-- Callers drive the wheel themselves, so a bare frame only loses the scrollbar.
function JS.CreateScrollFrame(parent)
  return (JS.CreateFromTemplates("ScrollFrame", nil, parent, SCROLL_TEMPLATES))
end

-- Checkbox, with its own artwork when no template is available
function JS.CreateCheckButton(parent)
  local check, template = JS.CreateFromTemplates("CheckButton", nil, parent, CHECKBOX_TEMPLATES)

  if not template then
    check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
  end

  return check
end

-- Slot ID, or nil; GetInventorySlotInfo throws on a name the client lacks.
function JS.GetInventorySlot(slotName)
  if type(GetInventorySlotInfo) ~= "function" or not slotName then return nil end

  local ok, slot = pcall(GetInventorySlotInfo, slotName)
  if not ok then return nil end

  return slot
end

-- Hook a global function only when it actually exists on this client
function JS.HookGlobal(name, callback)
  if type(name) ~= "string" or type(callback) ~= "function" then return false end
  if type(_G[name]) ~= "function" then return false end
  hooksecurefunc(name, callback)
  return true
end

-- Only meaningful from PLAYER_LOGIN onward; load order decides it before that.
function JS.IsAddOnLoaded(name)
  if not rawIsAddOnLoaded or not name then return false end
  return rawIsAddOnLoaded(name) and true or false
end
