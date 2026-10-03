return {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent = true,
            theme = "wave",
            overrides = function(colors)
                local theme = colors.theme
                return {
                    Normal = { bg = "none" },
                    NormalNC = { bg = "none" },
                    LineNr = { bg = "none" },
                    SignColumn = { bg = "none" },
                    StatusLine = { bg = "none" },
                    StatusLineNC = { bg = "none" },
                    FoldColumn = { bg = "none" },
                    NormalFloat = { bg = "none" },
                    FloatBorder = { bg = "none" },
                    Pmenu = { bg = "none" },
                    PmenuSel = { bg = theme.ui.bg_p2 },
                    PmenuSbar = { bg = "none" },
                    PmenuThumb = { bg = theme.ui.bg_p2 },
                    NoiceCmdlinePopup = { bg = "none" },
                    NoiceCmdlinePopupBorder = { fg = theme.ui.bg_p2, bg = "none" },
                    NoiceCmdline = { bg = "none" },
                    NoiceCmdlineIcon = { bg = "none" },
                    SnacksIndent = { fg = theme.ui.bg_p1 },
                    SnacksIndentScope = { fg = theme.ui.bg_p2 },
                    TelescopeNormal = { bg = "none" },
                    TelescopeBorder = { bg = "none" },
                }
            end,
        },
        config = function(_, opts)
            require("kanagawa").setup(opts)
            vim.cmd("colorscheme kanagawa")
        end,
    },
    {
        "https://github.com/vague-theme/vague.nvim",
        opts = {
            transparent = true,
        },
        config = function(_, opts)
            require("vague").setup(opts)
        end,
    },
}
