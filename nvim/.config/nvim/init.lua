-- Basic settings
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.wo.number = true

require('nvim-treesitter.configs').setup {
  ensure_installed = { all },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
