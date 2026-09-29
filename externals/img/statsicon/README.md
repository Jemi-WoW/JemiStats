# Stat icons

Drop a `.tga` here named after the stat key, then list it in `JS.STAT_ICONS`
in `core/jsNotify.lua`:

    JS.STAT_ICONS = {
      deaths = "deaths.tga",
      jumps  = "jumps.tga",
    }

Only listed keys are drawn, so a missing file can never show a broken square.
WoW loads `.tga` and `.blp` for addon art; `.png` will not render.
Stat keys are the `key` field on each tracker in `ui/stats/**`.
