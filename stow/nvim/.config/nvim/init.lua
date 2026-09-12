-- =============================================================================
-- Neovim init.lua (Pure v0.11 Native Config + Lazy.nvim)
--
-- [MAP]
--   1) config.compat      -- shims
--   2) config.options     -- vim.opt / vim.g
--   3) config.keymaps     -- global keymaps
--   4) config.diagnostics
--   5) config.filetypes
--   6) config.theme       -- colors / transparency / theme switcher
--   7) config.lazy        -- lazy.nvim bootstrap + lua/plugins import
--   8) plugins.*          -- plugin specs
--   9) config.lsp         -- native LSP
--
-- [POLICY]
--   - no nvim-lspconfig
--   - Treesitter + Native LSP + nvim-cmp
--   - Theme: runtime switchable (monokai / onedark / tokyonight / vscode)
--   - Terminal transparency is managed by terminal app (Terminator opacity)
--   - clang-format: prefer project-local .clang-format / _clang-format, fallback to ~/.clang-format
--   - Telescope: builtin direct call (avoid extension confusion)
-- =============================================================================

require("config.compat")
require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.filetypes")

local theme = require("config.theme")

require("config.lazy")
require("config.lsp")

-- lazy読み込み後にテーマを適用（起動時）
vim.schedule(function()
    theme.apply(vim.g.my_theme)
end)
