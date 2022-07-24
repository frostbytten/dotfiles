local module = neorg.modules.extend("core.keybinds.keybinds")

---@class core.keybinds
module.config.public = {
    keybind_presets = {
        neorg = function(keybinds)
            local leader = keybinds.leader

            -- Map all the below keybinds only when the "norg" mode is active
            keybinds.map_event_to_mode("norg", {
                n = { -- Bind keys in normal mode

                    --> Keys for managing TODO items

                    -- Marks the task under the cursor as "undone"
                    -- ^mark Task as Undone
                    { "gtu", "core.norg.qol.todo_items.todo.task_undone" },

                    -- Marks the task under the cursor as "pending"
                    -- ^mark Task as Pending
                    { "gtp", "core.norg.qol.todo_items.todo.task_pending" },

                    -- Marks the task under the cursor as "done"
                    -- ^mark Task as Done
                    { "gtd", "core.norg.qol.todo_items.todo.task_done" },

                    -- Marks the task under the cursor as "on_hold"
                    -- ^mark Task as on Hold
                    { "gth", "core.norg.qol.todo_items.todo.task_on_hold" },

                    -- Marks the task under the cursor as "cancelled"
                    -- ^mark Task as Cancelled
                    { "gtc", "core.norg.qol.todo_items.todo.task_cancelled" },
                    
                    -- Marks the task under the cursor as "recurring"
                    -- ^mark Task as Recurring
                    { "gtr", "core.norg.qol.todo_items.todo.task_recurring" },

                    -- Marks the task under the cursor as "important"
                    -- ^mark Task as Important
                    { "gti", "core.norg.qol.todo_items.todo.task_important" },

                    -- Switches the task under the cursor between a select few states
                    { "<C-Space>", "core.norg.qol.todo_items.todo.task_cycle" },

                    --> Keys for managing GTD

                    -- Captures a task
                    -- ^Task Capture
                    { leader .. "tc", "core.gtd.base.capture" },

                    -- Short for "task views", show a view selection menu
                    -- ^Task View
                    { leader .. "tv", "core.gtd.base.views" },

                    -- Short for "task edit", lets you edit a task
                    -- ^Task Edit
                    { leader .. "te", "core.gtd.base.edit" },

                    -- Creates a new .norg file to take notes in
                    -- ^New Note
                    { leader .. "nn", "core.norg.dirman.new.note" },

                    -- Hop to the destination of the link under the cursor
                    { "<CR>", "core.norg.esupports.hop.hop-link" },

                    -- Same as `<CR>`, except opens the destination in a vertical split
                    { "<M-CR>", "core.norg.esupports.hop.hop-link", "vsplit" },
                },
            }, {
                silent = true,
                noremap = true,
            })

            -- Map the below keys only when traverse-heading mode is active
            keybinds.map_event_to_mode("traverse-heading", {
                n = {
                    -- Move to the next heading in the document
                    { "j", "core.integrations.treesitter.next.heading" },
                    
                    -- Move to the previous heading in the document
                    { "k", "core.integrations.treesitter.previous.heading" },
                },
            }, {
                silent = true,
                noremap = true,
            })

            keybinds.map_event_to_mode("toc-split", {
                n = {
                    -- Hop to the target of the TOC link
                    { "<CR>", "core.norg.qol.toc.hop-toc-link" },

                    -- Closes the TOC split
                    -- ^Quit
                    { "q", "core.norg.qol.toc.close" },

                    -- Closes the TOC split
                    -- ^Escape
                    { "<Esc>", "core.norg.qol.toc.close" },
                },
            }, {
                silent = true,
                noremap = true,
                nowait = true,
            })

            -- Map the below keys on gtd displays
            keybinds.map_event_to_mode("gtd-displays", {
                n = {
                    { "<CR>", "core.gtd.ui.goto_task" },

                    -- Keys for closing the current display
                    { "q", "core.gtd.ui.close" },
                    { "<Esc>", "core.gtd.ui.close" },

                    { "e", "core.gtd.ui.edit_task" },
                    { "<Tab>", "core.gtd.ui.details" },
                },
            }, {
                silent = true,
                noremap = true,
                nowait = true,
            })

            -- Map the below keys on presenter mode
            keybinds.map_event_to_mode("presenter", {
                n = {
                    { "<CR>", "core.presenter.next_page" },
                    { "l", "core.presenter.next_page" },
                    { "h", "core.presenter.previous_page" },

                    -- Keys for closing the current display
                    { "q", "core.presenter.close" },
                    { "<Esc>", "core.presenter.close" },
                },
            }, {
                silent = true,
                noremap = true,
                nowait = true,
            })
            -- Apply the below keys to all modes
            keybinds.map_to_mode("all", {
                n = {
                    { leader .. "mn", ":Neorg mode norg<CR>" },
                    { leader .. "mh", ":Neorg mode traverse-heading<CR>" },
                },
            }, {
                silent = true,
                noremap = true,
            })
        end,
    },
}

return module
