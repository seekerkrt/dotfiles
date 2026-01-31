-- =============================================================================
-- Neovim init.lua (Pure v0.11 Native Config + Lazy.nvim)
--   - no nvim-lspconfig
--   - Treesitter + Native LSP + nvim-cmp
--   - Theme: monokai-pro (machine, darker background, high contrast)
--   - Format: clang-format (global ~/.clang-format forced)
--   - Telescope: builtin direct call (avoid extension confusion)
-- =============================================================================

-- --- compat: telescope vs nvim 0.11 treesitter API ---------------------------
-- Telescope が vim.treesitter.ft_to_lang を呼ぶ前提のコードを持つ場合があるので
-- 0.11系で確実に function を生やす（無条件で安全側）
vim.treesitter = vim.treesitter or {}
if type(vim.treesitter.ft_to_lang) ~= "function" then
    vim.treesitter.ft_to_lang = function(ft)
    local ok, lang = pcall(function()
    if vim.treesitter.language and type(vim.treesitter.language.get_lang) == "function" then
        return vim.treesitter.language.get_lang(ft)
        end
        return nil
        end)
    if ok and lang then return lang end
        return ft
        end
        end

        -- 誤爆しやすい <C-x> を無効化（挿入モード）
        vim.keymap.set('i', '<C-x>', '<Nop>', { noremap = true, silent = true })
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

            -- Wayland clipboard
            vim.opt.clipboard = "unnamedplus"

            vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })
            vim.g.mapleader = " "

            -- zsh settings
            vim.filetype.add({
                extension = { zsh = "sh" },
                filename = {
                    [".zshrc"] = "sh",
                    [".zshenv"] = "sh",
                    [".zprofile"] = "sh",
                    [".zlogin"] = "sh",
                },
            })

            -- === lazy.nvim bootstrap ===
            local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
            if not (vim.uv or vim.loop).fs_stat(lazypath) then
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
                    -- Theme: monokai-pro
                    {
                        "loctvl842/monokai-pro.nvim",
                        lazy = false,
                        priority = 1000,
                        config = function()
                        require("monokai-pro").setup({ filter = "machine" })
                        vim.cmd.colorscheme("monokai-pro")

                        -- darker bg
                        local bg = "#0b0c10"
                        vim.api.nvim_set_hl(0, "Normal",      { bg = bg })
                        vim.api.nvim_set_hl(0, "NormalNC",    { bg = bg })
                        vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg })
                        vim.api.nvim_set_hl(0, "SignColumn",  { bg = bg })
                        vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg })

                        -- high contrast tweaks
                        vim.api.nvim_set_hl(0, "Comment", { fg = "#8b93a7", italic = false })
                        vim.api.nvim_set_hl(0, "Keyword",  { bold = true })
                        vim.api.nvim_set_hl(0, "@keyword", { bold = true })
                        vim.api.nvim_set_hl(0, "@type",    { bold = true })
                        end,
                    },

                    -- Treesitter (main)
                {
                    "nvim-treesitter/nvim-treesitter",
                    branch = "main",
                    build = ":TSUpdate",
                    event = { "BufReadPost", "BufNewFile" },
                    config = function()
                    require("nvim-treesitter.install").compilers = { "gcc" }
                    require("nvim-treesitter").setup({})

                    -- ensure parse→start (stability)
                vim.api.nvim_create_autocmd("FileType", {
                    group = vim.api.nvim_create_augroup("ts_autostart", { clear = true }),
                                            callback = function()
                                            local ok, p = pcall(vim.treesitter.get_parser, 0)
                                            if ok and p then
                                                pcall(function() p:parse() end)
                                                end
                                                pcall(vim.treesitter.start)
                                                end,
                })
                end,
                },

                -- Completion Engine
                {
                    "hrsh7th/nvim-cmp",
                    event = "InsertEnter",
                    dependencies = {
                        "hrsh7th/cmp-nvim-lsp",
                        "L3MON4D3/LuaSnip",
                        "saadparwaiz1/cmp_luasnip",
                    },
                    config = function()
                    local cmp = require("cmp")
                    cmp.setup({
                        snippet = {
                            expand = function(args)
                            require("luasnip").lsp_expand(args.body)
                            end,
                        },
                        mapping = cmp.mapping.preset.insert({
                            ["<CR>"] = cmp.mapping.confirm({ select = true }),
                                                            ["<Tab>"] = cmp.mapping.select_next_item(),
                                                            ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                        }),
                        sources = cmp.config.sources({
                            { name = "nvim_lsp" },
                            { name = "luasnip" },
                        }),
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
                            -- ここを切っておくと “プレビューのTS絡み” で落ちる系を確実に回避できる
                            preview = { treesitter = false },
                        },
                    })

                    vim.keymap.set("n", "<leader>ff", builtin.find_files, { silent = true })
                    vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { silent = true })
                    vim.keymap.set("n", "<leader>fb", builtin.buffers,    { silent = true })
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
                local cf = vim.fn.expand("~/.clang-format")
                local cmd = "clang-format --style=file:" .. vim.fn.shellescape(cf)
                vim.cmd("silent %!" .. cmd)
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
                    if not client then return end

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
