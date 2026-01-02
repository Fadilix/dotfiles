-- return {
--   "oxfist/night-owl.nvim",
--   lazy = false, -- make sure we load this during startup if it is your main colorscheme
--   priority = 1000, -- make sure to load this before all the other start plugins
--   config = function()
--     -- load the colorscheme here
--     require("night-owl").setup({
--       transparent_background = true,
--     })
--     vim.cmd.colorscheme("night-owl")
--   end,
-- }
-- return { "catppuccin/nvim", name = "catppuccin", priority = 1000 }

return {
  -- Default options:
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true, -- Enables base transparency
      theme = "wave",
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- 1. Main Windows & Gutters
          Normal = { bg = "none" },
          NormalNC = { bg = "none" },
          LineNr = { bg = "none" },
          SignColumn = { bg = "none" },
          StatusLine = { bg = "none" },
          StatusLineNC = { bg = "none" },
          FoldColumn = { bg = "none" },

          -- 2. Floating Windows & Menus (LSP, Diagnostics, etc.)
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          Pmenu = { bg = "none" },
          PmenuSel = { bg = theme.ui.bg_p2 }, -- Subtle selection highlight
          PmenuSbar = { bg = "none" },
          PmenuThumb = { bg = theme.ui.bg_p2 },

          -- 3. Noice UI (Cmdline & Popups)
          NoiceCmdlinePopup = { bg = "none" },
          NoiceCmdlinePopupBorder = { fg = theme.ui.bg_p2, bg = "none" },
          NoiceCmdline = { bg = "none" },
          NoiceCmdlineIcon = { bg = "none" },

          -- 4. Subtle Indent Guides (Snacks.nvim)
          SnacksIndent = { fg = theme.ui.bg_p1 },
          SnacksIndentScope = { fg = theme.ui.bg_p2 },

          -- 5. Telescope (If you use it)
          TelescopeNormal = { bg = "none" },
          TelescopeBorder = { bg = "none" },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd("colorscheme kanagawa") -- Ensures Kanagawa loads with these overrides
    end,
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
    },
  },
  {
    "oxfist/night-owl.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      require("night-owl").setup({
        transparent_background = true,
      })
      vim.cmd.colorscheme("night-owl")
    end,
  },
}
