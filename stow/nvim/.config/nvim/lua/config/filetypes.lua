-- filetype tweaks (zsh / Arch configs)

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
