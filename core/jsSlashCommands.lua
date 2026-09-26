local _, JS = ...

SLASH_JEMISTATS1 = "/jemistats"
SLASH_JEMISTATS2 = "/jstats"

local function PrintHelp()
  JS.Msg("Commands:")
  JS.Msg("  |cffffd100/jstats|r - open or close the stats window")
  JS.Msg("  |cffffd100/jstats settings|r - open the settings tab")
  JS.Msg("  |cffffd100/jstats minimap|r - toggle the minimap icon")
  JS.Msg("  |cffffd100/jstats sessionreset|r - reset this session's stats only")
  JS.Msg("  |cffffd100/jstats reset|r - wipe this character's tracked stats")
end

SlashCmdList["JEMISTATS"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

  if msg == "help" or msg == "?" then
    PrintHelp()
    return
  end

  if msg == "settings" or msg == "config" or msg == "options" then
    JS.OpenSettingsWindow()
    return
  end

  -- Routed through the setting, so the Settings checkbox stays in step
  if msg == "minimap" then
    if JS.HostLoaded() then
      JS.Msg("The minimap icon is hidden while " .. JS.HostName() .. " is loaded. Use its icon instead.")
      return
    end

    local show = not JS.GetSetting("showMinimapButton")
    JS.SetSetting("showMinimapButton", show, "slash")
    JS.Msg("Minimap icon " .. (show and "shown." or "hidden."))
    return
  end

  if msg == "sessionreset" then
    JS.ResetSessionStats()
    JS.Stats.RefreshPanelIfVisible()
    JS.Msg("Session stats reset for this character.")
    return
  end

  if msg == "reset" then
    JS.ResetCharacterStats()
    JS.Msg("Stats reset done for this character.")
    return
  end

  if msg ~= "" then
    PrintHelp()
    return
  end

  -- Open or close the stats view, wherever it lives
  JS.ToggleStats()
end
