return {
    "stevearc/conform.nvim",
    lazy = false,
    config = function()
        local conform = require("conform")

        conform.setup({
            formatters_by_ft = {
                c = { "clang_format" },
                cpp = { "clang_format" },
                objc = { "clang_format" },
                objcpp = { "clang_format" },

                rust = { "rustfmt" },
                zig = { "zigfmt" },
                ruby = { "rubocop" },
                python = { "ruff_format" },
                go = { "gofmt" },

                sh = { "shfmt" },
                bash = { "shfmt" },

                lua = { "stylua" },
                toml = { "taplo" },

                markdown = { "prettier" },
                ["markdown.mdx"] = { "prettier" },

                json = { "prettier" },
                jsonc = { "prettier" },
                yaml = { "prettier" },

                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },

                html = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
            },

            default_format_opts = {
                lsp_format = "fallback",
            },

            formatters = {
                clang_format = {
                    prepend_args = function(_, ctx)
                        local filename = ctx.filename or ""
                        local start_dir = vim.fn.getcwd()

                        if filename ~= "" then
                            start_dir = vim.fs.dirname(filename) or start_dir
                        end

                        local config = vim.fs.find({ ".clang-format", "_clang-format" }, {
                            path = start_dir,
                            upward = true,
                        })[1]

                        if not config then
                            local fallback = vim.fn.expand("~/.clang-format")
                            if vim.fn.filereadable(fallback) == 1 then
                                config = fallback
                            end
                        end

                        if config then
                            return { "--style=file:" .. config }
                        end

                        return {}
                    end,
                },
            },
        })

        vim.api.nvim_create_user_command("Format", function()
            require("conform").format({
                async = true,
                lsp_format = "fallback",
            })
        end, {
            desc = "Format current buffer",
        })
    end,
}
