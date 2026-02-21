return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = opts.inlay_hints or {}
      opts.inlay_hints.exclude = opts.inlay_hints.exclude or {}
      -- Disable inlay hints for C and C++ files specifically
      if not vim.tbl_contains(opts.inlay_hints.exclude, "c") then
        table.insert(opts.inlay_hints.exclude, "c")
      end
      if not vim.tbl_contains(opts.inlay_hints.exclude, "cpp") then
        table.insert(opts.inlay_hints.exclude, "cpp")
      end
    end,
  },
}
