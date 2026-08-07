local _, JS = ...
local Stats = JS.Stats

local RANGED_SLOT = 18 -- INVSLOT_RANGED (equipped ranged weapon)

-- Locale-independent weapon subclass IDs from JS.GetItemInfoInstant.
local SUBCLASS_BOW      = 2
local SUBCLASS_GUN      = 3
local SUBCLASS_CROSSBOW = 18

-- Only Hunters track ammo fired (Class Stats section is Hunter-only).
local function IsHunter()
  if not UnitClass then return false end
  local _, token = UnitClass("player")
  return token == "HUNTER"
end

-- Number of arrows/bullets currently sitting in the equipped ammo slot.
local function GetAmmoCount()
  if not GetInventorySlotInfo or not GetInventoryItemCount then return 0 end
  local slot = GetInventorySlotInfo("AmmoSlot")
  if not slot then return 0 end

  local count = tonumber(GetInventoryItemCount("player", slot) or 0) or 0

  -- Empty-slot quirk: an empty ammo slot can report a phantom count of 1.
  if count == 1 and GetInventoryItemTexture and not GetInventoryItemTexture("player", slot) then
    count = 0
  end

  return count
end

-- "arrow" for bows/crossbows, "bullet" for guns, nil otherwise.
local function GetEquippedAmmoType()
  if not GetInventoryItemLink then return nil end
  local link = GetInventoryItemLink("player", RANGED_SLOT)
  if not link then return nil end

  local _, _, _, _, _, classID, subClassID = JS.GetItemInfoInstant(link)
  if classID ~= 2 then return nil end -- 2 = Weapon

  if subClassID == SUBCLASS_BOW or subClassID == SUBCLASS_CROSSBOW then
    return "arrow"
  elseif subClassID == SUBCLASS_GUN then
    return "bullet"
  end

  return nil
end

-- Baseline the ammo count so the stack we already own is never counted as "shot".
local function ResetAmmoBaseline()
  local s = Stats.EnsureStatsDB()
  s._lastAmmoCount = GetAmmoCount()
end

-- Sampled once per second. When the equipped ammo slot drops, credit the
-- difference to arrowsShot or bulletsShot based on the equipped ranged weapon.
-- Restocking (an increase) just re-baselines without counting. This single
-- sampler feeds BOTH the Arrows Shot and Bullets Shot stats, mirroring how the
-- distance tracker's session file also maintains the "ever" total.
local function SampleAmmoFired()
  if not IsHunter() then return end

  local s = Stats.EnsureStatsDB()
  local current = GetAmmoCount()
  local last = tonumber(s._lastAmmoCount or -1) or -1

  if last < 0 then
    s._lastAmmoCount = current
    return
  end

  if current < last then
    local fired = last - current
    local kind = GetEquippedAmmoType()
    if kind == "arrow" then
      s.arrowsShot = (tonumber(s.arrowsShot or 0) or 0) + fired
      Stats.RefreshPanelIfVisible()
    elseif kind == "bullet" then
      s.bulletsShot = (tonumber(s.bulletsShot or 0) or 0) + fired
      Stats.RefreshPanelIfVisible()
    end
  end

  s._lastAmmoCount = current
end

JS.RegisterStatTracker({
  key = "arrowsShot",
  category = "class",
  class = "HUNTER",
  order = 10,
  label = "Arrows Shot",
  fmt = Stats.FormatNumber,
  tooltip = "Counts arrows you've fired from bows and crossbows.",
  colors = {
    Stats.colors.GREEN[1], Stats.colors.GREEN[2], Stats.colors.GREEN[3],
    Stats.colors.WHITE[1], Stats.colors.WHITE[2], Stats.colors.WHITE[3],
  },
  OnPlayerLogin = function()
    ResetAmmoBaseline()
  end,
  OnUpdate = function()
    SampleAmmoFired()
  end,
})
