-- Hyprland LSP configuration
vim.api.nvim_create_augroup("hyprland_lsp", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = "hyprland_lsp",
  pattern = { "*.hl", "hypr*.conf", "*.hypr" },
  callback = function(event)
    -- Check if hyprls is available in PATH
    local has_hyprls = vim.fn.executable("hyprls") == 1
    
    -- If not in PATH, check Go bin directory
    local go_hyprls = vim.fn.expand("$HOME/go/bin/hyprls")
    local has_go_hyprls = vim.fn.executable(go_hyprls) == 1
    
    if has_hyprls then
      vim.lsp.start({
        name = "hyprlang",
        cmd = { "hyprls" },
        root_dir = vim.fn.getcwd(),
      })
    elseif has_go_hyprls then
      vim.lsp.start({
        name = "hyprlang",
        cmd = { go_hyprls },
        root_dir = vim.fn.getcwd(),
      })
    else
      vim.notify("hyprls not found. Install it with 'go install github.com/hyprland-community/hyprls/cmd/hyprls@latest'", vim.log.levels.WARN)
    end
  end,
})