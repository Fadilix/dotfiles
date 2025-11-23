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
