-- =============================================================================
-- Neovim init.lua (Pure v0.11 Native Config + Lazy.nvim)
--
-- [MAP]
--   1) compat / shims
--   2) basics (vim.opt / vim.g)
--   3) keymaps (global)
--   4) diagnostics
--   5) filetype tweaks
--   6) colors / transparency
--   7) lazy.nvim bootstrap
--   8) plugins
--   9) native LSP + format
--
-- [POLICY]
--   - no nvim-lspconfig
--   - Treesitter + Native LSP + nvim-cmp
--   - Theme: runtime switchable (monokai / onedark / tokyonight / vscode)
--   - Terminal transparency is managed by terminal app (Terminator opacity)
--   - clang-format: always force ~/.clang-format
--   - Telescope: builtin direct call (avoid extension confusion)
-- =============================================================================

-- =============================================================================
-- 1) compat / shims
-- =============================================================================

-- --- compat: telescope vs nvim 0.11 treesitter API ----------------------------
vim.treesitter = vim.treesitter or {}
if type(vim.treesitter.ft_to_lang) ~= "function" then
    vim.treesitter.ft_to_lang = function(ft)
        local ok, lang = pcall(function()
            if vim.treesitter.language and type(vim.treesitter.language.get_lang) == "function" then
                return vim.treesitter.language.get_lang(ft)
            end
            return nil
        end)
        if ok and lang then
            return lang
        end
        return ft
    end
end

-- =============================================================================
-- 2) basics (vim.opt / vim.g)
-- =============================================================================
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

-- =============================================================================
-- 3) keymaps (global)
-- =============================================================================

-- 誤爆しやすい <C-x> を無効化（挿入モード）
vim.keymap.set("i", "<C-x>", "<Nop>", { noremap = true, silent = true })

-- 検索ハイライト消し
vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- =============================================================================
-- 4) diagnostics
-- =============================================================================

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

-- =============================================================================
-- 5) filetype tweaks (zsh / Arch configs)
-- =============================================================================

vim.filetype.add({
    extension = {
        zsh = "zsh",
    },
    filename = {
        [".zshrc"] = "zsh",
        [".zshenv"] = "zsh",
        [".zprofile"] = "zsh",
        [".zlogin"] = "zsh",

        ["pacman.conf"] = "dosini",
        ["/etc/pacman.conf"] = "dosini",
        ["makepkg.conf"] = "bash",
        ["/etc/makepkg.conf"] = "bash",
    },
    pattern = {
        [".*/etc/pacman%.d/.*%.conf"] = "dosini",
        [".*/etc/makepkg%.conf%.d/.*"] = "bash",
        [".*/makepkg%.conf%.d/.*"] = "bash",

        [".*/%.config/zsh/.*"] = "zsh",
    },
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "pacman.conf", "/etc/pacman.conf", "/etc/pacman.d/*.conf" },
    callback = function()
        vim.cmd("setfiletype dosini")
    end,
})

-- =============================================================================
-- 6) colors / transparency
-- =============================================================================

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

local function ApplyTheme(theme)
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
    ApplyTheme(opts.args)
end, {
    nargs = 1,
    complete = function()
        return { "monokai", "onedark", "tokyonight", "vscode" }
    end,
})

-- よく使うテーマをキーで直指定
vim.keymap.set("n", "<leader>tm", function() ApplyTheme("monokai") end, { silent = true, desc = "Theme: monokai" })
vim.keymap.set("n", "<leader>to", function() ApplyTheme("onedark") end, { silent = true, desc = "Theme: onedark" })
vim.keymap.set("n", "<leader>tt", function() ApplyTheme("tokyonight") end, { silent = true, desc = "Theme: tokyonight" })
vim.keymap.set("n", "<leader>tv", function() ApplyTheme("vscode") end, { silent = true, desc = "Theme: vscode" })

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
    ApplyTheme(order[(idx % #order) + 1])
end, { silent = true, desc = "Theme: next" })

-- =============================================================================
-- 7) lazy.nvim bootstrap
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- 8) plugins
-- =============================================================================

require("lazy").setup({
    { "hrsh7th/cmp-nvim-lsp",   lazy = false },

    {
        "tanvirtin/monokai.nvim",
        priority = 1000,
        config = function()
            require("monokai").setup({
                palette = require("monokai").pro, -- pro / classic / soda / ristretto / machine
                italics = false,
                custom_hlgroups = {
                    Comment = { fg = "#8b949e" },
                    CursorLine = { bg = "#202020" },
                },
            })
            -- NOTE:
            -- 実際の適用は ApplyTheme() で一元管理する
        end,
    },

    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require("onedark").setup({
                style = "darker", -- dark / darker / cool / deep / warm / warmer / light
                transparent = false,
                term_colors = true,
                code_style = {
                    comments = "none",
                },
                lualine = {
                    transparent = false,
                },
                highlights = {
                    Comment = { fg = "#7f848e", italic = false },
                    ["@comment"] = { fg = "#7f848e", italic = false },
                    CursorLine = { bg = "#242b38" },
                },
            })
            -- NOTE:
            -- 実際の適用は ApplyTheme() で一元管理する
        end,
    },

    -- おまけ：青・緑が綺麗な Nightfox
    { "EdenEast/nightfox.nvim", lazy = false, priority = 1000 },

    -- Tokyo Night (VS風カスタム設定)
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "storm",
            transparent = false, -- 背景黒重視なら一旦false
            styles = {
                comments = { italic = true },
                keywords = { italic = false },
            },
            on_colors = function(colors)
                -- 背景を漆黒にするならここを #000000 に
                colors.bg = "#000000"
            end,
            on_highlights = function(hl, _)
                -- コメントをVS風の緑 (#6A9955) に強制
                hl.Comment = { fg = "#6A9955" }
                -- 型指定や予約語を水色・青系に調整
                hl["@type"] = { fg = "#4EC9B0" }
                hl["@keyword"] = { fg = "#569CD6" }
            end,
        },
    },

    -- VSCode.nvim
    {
        "Mofiqul/vscode.nvim",
        priority = 1000,
        config = function()
            require("vscode").setup({
                style = "dark",
                transparent = true,
                italic_comments = true,
                disable_nvimtree_bg = true,
                group_overrides = {
                    CursorLine = { bg = "#101010" },
                    Visual = { bg = "#1a1a1a" },
                    Search = { fg = "#000000", bg = "#c8c8c8" },
                    IncSearch = { fg = "#000000", bg = "#e0e0e0" },
                },
            })
            -- NOTE:
            -- 実際の適用は ApplyTheme() で一元管理する
        end,
    },

    -- Treesitter (main branch API)
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvim-treesitter.install").compilers = { "gcc" }

            -- mainブランチでは configs モジュールが無いので、このAPIを使う
            require("nvim-treesitter").setup({})

            -- ensure parse→start (stability)
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("ts_autostart", { clear = true }),
                callback = function()
                    local ok, p = pcall(vim.treesitter.get_parser, 0)
                    if ok and p then
                        pcall(function()
                            p:parse()
                        end)
                    end
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },

    -- Treesitter textobjects (select API direct call)
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            local ok, select = pcall(require, "nvim-treesitter-textobjects.select")
            if not ok then
                return
            end

            for _, mode in ipairs({ "x", "o" }) do
                vim.keymap.set(mode, "af", function()
                    select.select_textobject("@function.outer", "textobjects", mode)
                end, { silent = true })

                vim.keymap.set(mode, "if", function()
                    select.select_textobject("@function.inner", "textobjects", mode)
                end, { silent = true })

                vim.keymap.set(mode, "ac", function()
                    select.select_textobject("@class.outer", "textobjects", mode)
                end, { silent = true })

                vim.keymap.set(mode, "ic", function()
                    select.select_textobject("@class.inner", "textobjects", mode)
                end, { silent = true })
            end
        end,
    },

    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")

            cmp.setup({
                completion = {
                    autocomplete = false, -- 検索直後に戻る問題の回避
                },

                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },

                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<Esc>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),

                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }),

                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
            })
        end,
    },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup({
                defaults = {
                    preview = { treesitter = false },
                },
            })

            vim.keymap.set("n", "<leader>ff", builtin.find_files, { silent = true })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { silent = true })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { silent = true })
        end,
    },

    -- GitSigns
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },
})

-- lazy読み込み後にテーマを適用（起動時）
vim.schedule(function()
    ApplyTheme(vim.g.my_theme)
end)

-- =============================================================================
-- 9) Native LSP Setup (Neovim 0.11+)
-- =============================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
pcall(function()
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
end)

-- clang-format: always use ~/.clang-format
local function clang_format_buffer()
    local view = vim.fn.winsaveview()

    local cf = vim.fn.expand("~/.clang-format")
    local cmd = "clang-format --style=file:" .. vim.fn.shellescape(cf)
    vim.cmd("silent keepjumps keeppatterns %!" .. cmd)

    vim.fn.winrestview(view)
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local opts = { buffer = bufnr, silent = true }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        if client.server_capabilities and client.server_capabilities.inlayHintProvider then
            pcall(function()
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end)
        end

        if client.server_capabilities
            and client.server_capabilities.semanticTokensProvider then
            pcall(function()
             vim.lsp.semantic_tokens.enable(true, {
                    bufnr = bufnr,
                    client_id = client.id,
                })
            end)
        end

        if client.name == "clangd" then
            vim.keymap.set("n", "<leader>f", clang_format_buffer, opts)
        else
            vim.keymap.set("n", "<leader>f", function()
                vim.lsp.buf.format({ async = true })
            end, opts)
        end
    end,
})

vim.api.nvim_create_user_command("Format", function()
    local ft = vim.bo.filetype
    if ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        clang_format_buffer()
        return
    end
    vim.lsp.buf.format({ async = true })
end, {})

vim.lsp.config["clangd"] = {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
    capabilities = capabilities,
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = { "compile_commands.json", ".git" },
}

vim.lsp.config["lua_ls"] = {
    cmd = { "lua-language-server" },
    capabilities = capabilities,
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
}

vim.lsp.config["pyright"] = {
    cmd = { "pyright-langserver", "--stdio" },
    capabilities = capabilities,
    filetypes = { "python" },
    root_markers = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        "pyrightconfig.json",
        ".git",
    },
}

vim.lsp.config["bashls"] = {
    cmd = { "bash-language-server", "start" },
    capabilities = capabilities,
    filetypes = { "sh", "bash", "zsh" },
    root_markers = { ".git" },
}

vim.lsp.enable({ "clangd", "lua_ls", "pyright", "bashls" })
