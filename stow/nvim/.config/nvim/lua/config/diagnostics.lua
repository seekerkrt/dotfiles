-- LSPの診断表示を“目に優しく”
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

-- 診断をフロートで見る（virtual_text=false の相棒）
vim.keymap.set("n", "gl", function()
    vim.diagnostic.open_float(nil, { focus = false })
end, { silent = true })
