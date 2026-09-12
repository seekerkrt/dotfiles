return {
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
}
