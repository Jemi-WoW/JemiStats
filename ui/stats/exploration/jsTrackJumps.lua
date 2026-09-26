local _, JS = ...
local Stats = JS.Stats

local debounce = 0.75

-- requireFalling separates the two hooks: only AscendStop fires mid-air.
local function CountJump(requireFalling)
  if requireFalling and not (IsFalling and IsFalling()) then return end
  if UnitOnTaxi and UnitOnTaxi("player") then return end
  if IsFlying and IsFlying() then return end
  if IsSwimming and IsSwimming() then return end

  local s = Stats.EnsureStatsDB()
  local now = GetTime and GetTime() or 0
  local last = tonumber(s.lastJumpCountAt or 0) or 0
  if (now - last) <= debounce then
    return
  end

  s.lastJumpCountAt = now
  if JS.RecordJump then
    JS.RecordJump()
  end
end

-- AscendStop preferred: it cannot mistake swimming or flying upward for a jump.
if not JS._jumpStatsHookInstalled then
  JS._jumpStatsHookInstalled = JS.HookGlobal("AscendStop", function()
    CountJump(true)
  end)

  if not JS._jumpStatsHookInstalled then
    JS._jumpStatsHookInstalled = JS.HookGlobal("JumpOrAscendStart", function()
      CountJump(false)
    end)
  end
end

function JS.RecordJump()
  Stats.IncStat("jumps", 1)
end

JS.RegisterStatTracker({
  key = "jumps",
  category = "exploration",
  label = "Jumps",
  fmt = Stats.FormatNumber,
  tooltip = "Counts how many times you jump.",
  colors = { 0.70, 0.84, 0.94, 0.78, 0.90, 1.00 },
})
