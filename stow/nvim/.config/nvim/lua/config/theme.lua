-- colors / transparency / theme switcher

vim.opt.termguicolors = true
vim.opt.background = "dark"

local kTransparentGroups = {
    "Normal",
    "NormalNC",
    "EndOfBuffer",

    "SignColumn",
    "FoldColumn",
    "LineNr",
    "CursorLineNr",

    "VertSplit",
    "WinSeparator",

    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "TabLineSel",

    "Pmenu",
    "PmenuSbar",
    "PmenuThumb",
    "FloatBorder",
    "NormalFloat",

    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopePromptNormal",
    "TelescopePromptBorder",
    "TelescopeResultsNormal",
    "TelescopeResultsBorder",
    "TelescopePreviewNormal",
    "TelescopePreviewBorder",

    "CmpPmenu",
    "CmpPmenuBorder",
    "CmpDoc",
    "CmpDocBorder",
}

local function ApplyTransparentHighlights()
    for _, g in ipairs(kTransparentGroups) do
        vim.api.nvim_set_hl(0, g, { bg = "none" })
    end
end

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        ApplyTransparentHighlights()
    end,
})
ApplyTransparentHighlights()

-- --- Theme switcher -----------------------------------------------------------

-- 起動時のテーマ（ここを変えるだけでデフォルト切替）
vim.g.my_theme = "monokai" -- "monokai" / "onedark" / "tokyonight" / "vscode"

local M = {}

function M.apply(theme)
    theme = theme or vim.g.my_theme or "monokai"
    vim.g.my_theme = theme

    local ok = pcall(vim.cmd.colorscheme, theme)
    if not ok then
        vim.notify("colorscheme not found: " .. tostring(theme), vim.log.levels.WARN)
        return
    end

    -- 透明化（今の運用を維持）
    pcall(ApplyTransparentHighlights)

    -- テーマ別の微調整（コメント色/視認性）
    if theme == "monokai" then
        vim.api.nvim_set_hl(0, "Comment", { fg = "#8b949e", italic = false })
        vim.api.nvim_set_hl(0, "@comment", { fg = "#8b949e", italic = false })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#202020" })
    elseif theme == "onedark" then
        vim.api.nvim_set_hl(0, "Comment", { fg = "#7f848e", italic = false })
        vim.api.nvim_set_hl(0, "@comment", { fg = "#7f848e", italic = false })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#242b38" })
    elseif theme == "tokyonight" then
        vim.api.nvim_set_hl(0, "Comment", { fg = "#6A9955", italic = false })
        vim.api.nvim_set_hl(0, "@comment", { fg = "#6A9955", italic = false })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1a1f2a" })
    elseif theme == "vscode" then
        vim.api.nvim_set_hl(0, "Comment", { fg = "#7f848e", italic = true })
        vim.api.nvim_set_hl(0, "@comment", { fg = "#7f848e", italic = true })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#101010" })
    end
end

-- コマンドで切替
vim.api.nvim_create_user_command("Theme", function(opts)
    M.apply(opts.args)
end, {
    nargs = 1,
    complete = function()
        return { "monokai", "onedark", "tokyonight", "vscode" }
    end,
})

-- よく使うテーマをキーで直指定
vim.keymap.set("n", "<leader>tm", function()
    M.apply("monokai")
end, { silent = true, desc = "Theme: monokai" })
vim.keymap.set("n", "<leader>to", function()
    M.apply("onedark")
end, { silent = true, desc = "Theme: onedark" })
vim.keymap.set("n", "<leader>tt", function()
    M.apply("tokyonight")
end, { silent = true, desc = "Theme: tokyonight" })
vim.keymap.set("n", "<leader>tv", function()
    M.apply("vscode")
end, { silent = true, desc = "Theme: vscode" })

-- 巡回トグル
vim.keymap.set("n", "<leader>tn", function()
    local order = { "monokai", "onedark", "tokyonight", "vscode" }
    local cur = vim.g.my_theme or order[1]
    local idx = 1
    for i, name in ipairs(order) do
        if name == cur then
            idx = i
            break
        end
    end
    M.apply(order[(idx % #order) + 1])
end, { silent = true, desc = "Theme: next" })

return M
