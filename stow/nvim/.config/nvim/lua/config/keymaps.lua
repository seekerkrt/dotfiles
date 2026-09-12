-- global keymaps

-- 誤爆しやすい <C-x> を無効化（挿入モード）
vim.keymap.set("i", "<C-x>", "<Nop>", { noremap = true, silent = true })

-- 検索ハイライト消し
vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- バッファ全体をフォーマット
vim.keymap.set("n", "<leader>f", "<cmd>Format<CR>", {
    silent = true,
    desc = "Format buffer",
})
