-- File type detection configuration
vim.filetype.add({
  pattern = {
    [".*/hypr/.*%.conf"] = "hyprlang",
    [".*hyprland%.conf"] = "hyprlang",
    [".*hypr%.conf"] = "hyprlang",
  },
})

-- Ensure the filetype is set correctly for Hyprland files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.conf" },
  callback = function(args)
    local filename = vim.fn.expand("%:p")
    if filename:match("hypr") then
      vim.bo[args.buf].filetype = "hyprlang"
    end
  end,
}) 