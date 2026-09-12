-- Native LSP Setup (Neovim 0.11+)
-- POLICY: no nvim-lspconfig

local capabilities = vim.lsp.protocol.make_client_capabilities()
pcall(function()
    capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
end)

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
                vim.lsp.semantic_tokens.enable(true, {
                    bufnr = bufnr,
                    client_id = client.id,
                })
            end)
        end
    end,
})

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

vim.lsp.config["gopls"] = {
    cmd = { "gopls" },
    capabilities = capabilities,
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
}

vim.lsp.enable({
    "clangd",
    "lua_ls",
    "pyright",
    "bashls",
    "gopls",
})
