return {
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
            -- 実際の適用は config.theme.apply() で一元管理する
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
            -- 実際の適用は config.theme.apply() で一元管理する
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
            -- 実際の適用は config.theme.apply() で一元管理する
        end,
    },
}
