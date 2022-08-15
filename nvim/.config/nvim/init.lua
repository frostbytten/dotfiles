-- Basic settings
vim.g.mapleader = ";"
vim.g.maplocalleader = ","
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.wo.number = true

require("nvim-treesitter.configs").setup {
  ensure_installed = { all },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

require("neorg").setup {
  load = {
    ["core.defaults"] = {},
    ["core.norg.concealer"] = {},
    ["core.norg.dirman"] = {
      config = {
        default_workspace = "gtd",
        workspaces = {
          gtd = "~/Documents/neorg/gtd",
          work = "~/Documents/neorg/work",
          kb = "~/Documents/neorg/notes",
        },
      },
    },
    ["core.gtd.base"] = {
      config = {
        workspace = "gtd",
      },
    },
    ["core.export"] = {},
    ["core.export.markdown"] = {
      config = {
        extensions = "all",
      },
    },
    ["core.norg.journal"] = {
      config = {
        workspace = "gtd",
        journal_folder = "daily",
        strategy = "flat",
      },
    },
  },
}

local cmp = require("cmp")
cmp.setup {
  snippet = {
    expand = function(args)
      require("snippy").expand_snippet(args.body)
    end,
  },
  window = {},
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-space>"] = cmp.mapping.complete(),
    ["<C-g>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({select = true }),
  }),
  sources = cmp.config.sources({
    { name = "snippy" },
    { name = "path" },
  }),
}

