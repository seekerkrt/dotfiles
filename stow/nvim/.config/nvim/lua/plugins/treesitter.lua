return {
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

            -- parser を確保（既にあれば no-op）
            require("nvim-treesitter").install({
                -- C/C++ family
                "c",
                "cpp",

                -- language-lab / main languages
                "rust",
                "zig",
                "ruby",
                "python",
                "java",

                -- Go family
                "go",
                "gomod",
                "gosum",
                "gotmpl",
                "gowork",

                -- config / scripting
                "lua",
                "bash",
                "toml",
                "json",
                "yaml",
                "markdown",
                "markdown_inline",
            })
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
}
