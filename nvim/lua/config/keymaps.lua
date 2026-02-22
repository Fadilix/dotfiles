-- Keymaps are automatically loaded on the VeryLazy event Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- local discipline = require("fadilix.discipline")
-- TODO : will fix this later
-- discipline.cowboy()
local dap, dapui = require("dap"), require("dapui")

keymap.set("n", "+", "<C-a>")

keymap.set("n", "-", "<C-x>")

-- delete a word backwards
keymap.set("n", "dw", "vb_d")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- jumplist
keymap.set("n", "<C-m>", "<C-i>", opts)

-- new tab
keymap.set("n", "te", ":tabedit", opts)
-- keymap.set("n", "<tab>", ":tabnext<Return>", opts)
-- keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)

-- split screen
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sl", "<C-w>l")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sk", "<C-w>k")

-- resize window
keymap.set("n", "<S-h>", "5<C-w><")
keymap.set("n", "<S-l>", "5<C-w>>")

keymap.set("n", "<C-w><up>", ":")
keymap.set("n", "<C-w><down>", "<C-w>-")

keymap.set("n", "<C-j>", function()
    vim.diagnostic.goto_next()
end, opts)

-- Debugging keybindings
keymap.set("n", "<F5>", function()
    dap.continue()
end, { desc = "Start debuggin" })

keymap.set("n", "<F9>", function()
    dap.toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

keymap.set("n", "<F10>", function()
    dap.step_over()
end, { desc = "Step over" })

keymap.set("n", "<F11>", function()
    dap.step_into()
end, { desc = "Step into" })

keymap.set("n", "<F12>", function()
    dap.step_out()
end, { desc = "Step out" })

keymap.set("n", "<leader>dr", function()
    dap.repl.open()
end, { desc = "Open Repl" })

keymap.set("n", "<leader>do", function()
    dapui.open()
end, { desc = "Open debug UI" })

keymap.set("n", "<leader>dc", function()
    dapui.close()
end, { desc = "Clode debug UI" })

keymap.set("n", "<leader>dl", function()
    dap.run_last()
end)
