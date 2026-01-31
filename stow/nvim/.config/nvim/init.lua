
vim.opt.number = true
vim.opt.cursorline = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.opt.smarttab = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.local/share/nvim/undo//")

vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5

vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- === lazy.nvim bootstrap ===
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- === plugins ===
require("lazy").setup({
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "cpp", "c", "lua", "vim", "bash" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },

  -- LSP (clangd)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.clangd.setup({
        cmd = { "clangd", "--background-index" },
      })

      -- 便利キー（最小）
      vim.keymap.set("n", "gd", vim.lsp.buf.definition)
      vim.keymap.set("n", "gr", vim.lsp.buf.references)
      vim.keymap.set("n", "K",  vim.lsp.buf.hover)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
    end
  },

  -- completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
        },
      })
    end
  },

  -- Telescope (検索)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      telescope.setup({})
      vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
      vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
    end
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function() require("gitsigns").setup() end
  },
}, {
  defaults = { lazy = true },
})

-- leader（好みで）
vim.g.mapleader = " "
