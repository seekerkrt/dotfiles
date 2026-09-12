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
