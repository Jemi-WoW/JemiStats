local _, JS = ...

-- Slash command registration
SLASH_JEMISTATS1 = "/jemistats"
SLASH_JEMISTATS2 = "/jstats"

-- Print the command list
local function PrintHelp()
  JS.Msg("Commands:")
  JS.Msg("  |cffffd100/jstats|r - open or close the stats window")
  JS.Msg("  |cffffd100/jstats minimap|r - toggle the minimap icon")
  JS.Msg("  |cffffd100/jstats sessionreset|r - reset this session's stats only")
  JS.Msg("  |cffffd100/jstats reset|r - wipe this character's tracked stats")
end

SlashCmdList["JEMISTATS"] = function(msg)
  -- Normalize input
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

  -- Command list
  if msg == "help" or msg == "?" then
    PrintHelp()
    return
  end

  -- Minimap icon toggle
  if msg == "minimap" then
    if JS.HostLoaded() then
      JS.Msg("The minimap icon is hidden while " .. JS.HostName() .. " is loaded. Use its icon instead.")
      return
    end

    local show = JS.ToggleMinimapButton()
    JS.Msg("Minimap icon " .. (show and "shown." or "hidden."))
    return
  end

  -- Session-only reset
  if msg == "sessionreset" then
    JS.ResetSessionStats()
    JS.Stats.RefreshPanelIfVisible()
    JS.Msg("Session stats reset for this character.")
    return
  end

  -- Full stats reset
  if msg == "reset" then
    JS.ResetCharacterStats()
    JS.Msg("Stats reset done for this character.")
    return
  end

  -- Anything unrecognised shows the command list
  if msg ~= "" then
    PrintHelp()
    return
  end

  -- Open or close the stats view, wherever it lives
  JS.ToggleStats()
end
