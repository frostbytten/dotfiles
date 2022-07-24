--[[
    File: Defaults
    Summary: Metamodule for storing the most necessary modules.
    Internal: true
    ---
This file contains all of the most important
modules that any user would want to have a "just works" experience.
--]]

require("neorg.modules.base")

return neorg.modules.create_meta(
    "core.defaults",
    "core.autocommands",
    "core.integrations.treesitter",
    "core.keybinds",
    "core.looking-glass",
    "core.mode",
    "core.neorgcmd",
    "core.norg.esupports.hop",
    "core.norg.esupports.indent",
    "core.norg.esupports.metagen",
    "core.norg.news",
    "core.norg.qol.todo_items",
    "core.storage",
    "core.syntax",
    "core.tangle"
)
