-- basics (vim.opt / vim.g)
vim.opt.showcmd = true

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
local undo_dir = vim.fn.expand("~/.local/share/nvim/undo//")
if vim.fn.isdirectory(undo_dir) == 0 then
    vim.fn.mkdir(undo_dir, "p")
end
vim.opt.undodir = undo_dir

vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5

-- for grep(rg)
-- ripgrep を :grep に使う（-R は使わない）
vim.opt.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git/*' --glob '!**/node_modules/*'"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Wayland clipboard
vim.opt.clipboard = "unnamedplus"

-- leader（好みで）
vim.g.mapleader = " "
