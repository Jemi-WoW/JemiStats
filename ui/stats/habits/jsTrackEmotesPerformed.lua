local _, JS = ...
local Stats = JS.Stats

local function CountEmote()
  Stats.IncStat("emotesPerformed", 1)
end

if not JS._emoteHookInstalled then
  JS._emoteHookInstalled = JS.HookGlobal("DoEmote", CountEmote)

  -- The modern codebase routes emotes through C_ChatInfo instead
  if C_ChatInfo then
    JS.HookTableFunc(C_ChatInfo, "PerformEmote", CountEmote)
  end
end

JS.RegisterStatTracker({
  key = "emotesPerformed",
  category = "habits",
  label = "Emotes Performed",
  fmt = Stats.FormatNumber,
  tooltip = "Emotes you have played, like /dance and /wave.",
  colors = Stats.HABIT_COLORS,
})
