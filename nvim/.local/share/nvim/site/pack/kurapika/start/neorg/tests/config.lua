-- Generate a simple config file
local config = {}

local path = vim.fn.getcwd()
require("neorg").setup({
    load = {
        ["core.gtd.base"] = {
            config = {
                workspace = "gtd",
                exclude = { "test_file_2.norg" },
            },
        },
        ["core.norg.dirman"] = {
            config = {
                workspaces = {
                    gtd = path .. "/tests/mocks",
                },
            },
        },
    },
})

-- Start neorg
neorg.org_file_entered(false)
neorg.modules.get_module("core.norg.dirman").set_workspace("gtd")

-- Create temporary buffer for quick use in test files
config.temp_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(config.temp_buf, "test.norg")
vim.api.nvim_buf_set_lines(config.temp_buf, 0, -1, false, {
    "* Project",
    "this is a test",
    "- [ ] test1",
    "- [ ] test2",
    "- [x] test3",
    "- [-] test4",
    "#contexts test_context test_context2",
    "#time.due 2021-10-10",
    "#time.start 2021-10-11",
    "#waiting.for test_waiting_for",
    "- [ ] test5",
})

config.get_void_buf = function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "test2.norg")
    return buf
end

return config
