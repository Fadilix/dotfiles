return {
  -- {
  --   "sainnhe/sonokai",
  --   priority = 1000,
  --   config = function()
  --     vim.g.sonokai_transparent_background = "1"
  --     vim.g.sonokai_enable_italic = "0"
  --     vim.g.sonokai_style = "shusia"
  --     vim.g.sonokai_disable_italic_comment = "1"
  --     vim.cmd.colorscheme("sonokai")
  --   end,
  -- },
  -- {
  --   "ellisonleao/gruvbox.nvim",
  --   priority = 1000,
  --   config = function()
  --     require("gruvbox").setup({
  --       transparent_mode = true,
  --       bold = false,
  --       italic = {
  --         strings = false,
  --         emphasis = false,
  --         comments = false,
  --         operators = false,
  --         folds = false,
  --       },
  --       dim_inactive = false,
  --     })
  --     vim.cmd.colorschem("gruvbox")
  --   end,
  -- },
  -- {
  --   "projekt0n/github-nvim-theme",
  --   name = "github-theme",
  --   lazy = false, -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require("github-theme").setup({
  --       options = {
  --         transparent = true,
  --       },
  --     })
  --     vim.cmd("colorscheme github_dark_colorblind")
  --   end,
  -- },
  {

    "oxfist/night-owl.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      require("night-owl").setup({
        italics = false,
        transparent_background = true,
        undercurl = true,
        bold = false,
        underline = false,
      })
      vim.cmd.colorscheme("night-owl")
    end,
  },
  -- {
  --   "tiagovla/tokyodark.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("tokyodark").setup({
  --       transparent_background = true,
  --       styles = {
  --         comments = { italic = false }, -- style for comments
  --         keywords = { italic = false }, -- style for keywords
  --         identifiers = { italic = false }, -- style for identifiers
  --       },
  --     })
  --   end,
  -- },

  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   priority = 1000,
  --   config = function()
  --     require("catppuccin").setup({
  --       transparent_background = true,
  --       no_italic = true,
  --     })
  --     vim.cmd.colorscheme("catppuccin")
  --   end,
  -- },

  --   "rebelot/kanagawa.nvim",
  --   name = "kanagawa",
  --   priority = 1000,
  --   config = function()
  --     require("kanagawa").setup({
  --       compile = false, -- enable compiling the colorscheme
  --       undercurl = true, -- enable undercurls
  --       commentStyle = { italic = true },
  --       functionStyle = {},
  --       keywordStyle = { italic = true },
  --       statementStyle = { bold = true },
  --       typeStyle = {},
  --       transparent = true, -- do not set background color
  --       dimInactive = false, -- dim inactive window `:h hl-NormalNC`
  --       terminalColors = true, -- define vim.g.terminal_color_{0,17}
  --       colors = { -- add/modify theme and palette colors
  --         palette = {},
  --         theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
  --       },
  --       overrides = function(colors) -- add/modify highlights
  --         return {}
  --       end,
  --       theme = "wave", -- Load "wave" theme when 'background' option is not set
  --       background = { -- map the value of 'background' option to a theme
  --         dark = "wave", -- try "dragon" !
  --         light = "lotus",
  --       },
  --     })
  --   end,
  -- },
  --
  --
}
