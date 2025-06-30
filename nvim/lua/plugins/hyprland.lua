-- Add this to your lua/plugins/hyprland.lua
return {
  -- Other configurations...
  
  -- Official Hyprland syntax highlighting
  {
    "luckasRanarison/tree-sitter-hyprlang",
    ft = { "hyprlang" },
    init = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*hypr*.conf", "*.hypr", "*.hl", "*/hypr/*.conf" },
        callback = function()
          vim.bo.filetype = "hyprlang"
        end
      })
    end
  }
}