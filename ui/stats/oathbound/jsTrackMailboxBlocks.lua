local _, JS = ...
local Stats = JS.Stats

-- Oathbound does the blocking and pushes the count in through the API, so this
-- row is only registered when Oathbound is actually loaded
JS.DeferStatTracker("Oathbound", {
  key = "mailboxBlocks",
  category = "oathbound",
  label = "Mailbox Blocks",
  fmt = Stats.FormatNumber,
  tooltip = "Counts mailbox openings blocked by Oathbound.",
  colors = {
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
    Stats.colors.GOLD[1], Stats.colors.GOLD[2], Stats.colors.GOLD[3],
  },
})
