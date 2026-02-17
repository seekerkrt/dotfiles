-- =============================================================================
-- Neovim init.lua (Pure v0.11 Native Config + Lazy.nvim)
--   - no nvim-lspconfig
--   - Treesitter + Native LSP + nvim-cmp
--   - Theme: vscode.nvim (darker + transparent)
--   - Terminal: Terminator (透過は端末側で opacity 設定)
--   - Format: clang-format (global ~/.clang-format forced)
--   - Telescope: builtin direct call (avoid extension confusion)
-- =============================================================================

-- --- compat: telescope vs nvim 0.11 treesitter API ---------------------------
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

-- 誤爆しやすい <C-x> を無効化（挿入モード）
vim.keymap.set("i", "<C-x>", "<Nop>", { noremap = true, silent = true })

-- === basics ===
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
vim.opt.grepprg = "rg --vimgrep --smart-case --hidden"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Wayland clipboard
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })
vim.g.mapleader = " "

-- =============================================================================
-- filetype tweaks (zsh / Arch configs)
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
-- === colors / transparency ===================================================
-- =============================================================================
vim.opt.termguicolors = true
vim.opt.background = "dark"

local function Transparent()
    local groups = {
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

    for _, g in ipairs(groups) do
        vim.api.nvim_set_hl(0, g, { bg = "none" })
    end
end

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        Transparent()
    end,
})
Transparent()

-- =============================================================================
-- === lazy.nvim bootstrap ======================================================
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
-- plugins
-- =============================================================================
require("lazy").setup({
    { "hrsh7th/cmp-nvim-lsp", lazy = false },

    {
        "Mofiqul/vscode.nvim",
        priority = 1000,
        config = function()
            vim.opt.termguicolors = true
            vim.opt.background = "dark"

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

            vim.cmd.colorscheme("vscode")
            pcall(function()
                Transparent()
            end)
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

    -- Treesitter textobjects
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- READMEのselect APIを使って vaf/vif を作る（configs 経由じゃない） :contentReference[oaicite:2]{index=2}
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

-- =============================================================================
-- Native LSP Setup (Neovim 0.11+)
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

        if client.server_capabilities and client.server_capabilities.semanticTokensProvider then
            pcall(function()
                vim.lsp.semantic_tokens.start(bufnr, client.id)
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
    cmd = { "clangd", "--background-index" },
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

-- =============================================================================
-- Terminator 側のメモ（init.lua外だけど重要）
-- =============================================================================
-- 透過は Terminator のプロファイルで設定する：
--   Preferences -> Profiles -> (使ってるProfile)
--     - Background: "Transparent background" を有効
--     - 透明度(Opacity)を 0.85 前後（好みで）
-- 背景を「もっと黒」寄りにしたい場合：
--   Terminator の背景色を #0b0b0b とかに寄せると “黒 + 透過” が締まる
