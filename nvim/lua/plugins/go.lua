return {
    -- nvim-dap-go: Go debugger integration
    {
        "leoluz/nvim-dap-go",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
        },
        opts = {
            delve = {
                detached = true,
            },
        },
        config = function(_, opts)
            require("dap-go").setup(opts or {})
            require("dapui").setup()
        end,
    },

    -- neotest-golang: Go testing framework
    {
        "nvim-neotest/neotest",
        optional = true,
        dependencies = {
            "fredrikaverpil/neotest-golang",
        },
        opts = function(_, opts)
            opts = opts or {}
            if not opts.adapters then
                opts.adapters = {}
            end
            opts.adapters["neotest-golang"] = {
                go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
                dap_go_enabled = true,
            }
        end,
    },

    -- mini.icons: Filetype icons for Go
    {
        "nvim-mini/mini.icons",
        opts = {
            file = {
                [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
            },
            filetype = {
                gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
            },
        },
    },

    -- none-ls.nvim: Code actions and formatting
    {
        "nvimtools/none-ls.nvim",
        optional = true,
        opts = function(_, opts)
            local nls = require("null-ls")
            if not opts.sources then
                opts.sources = {}
            end
            vim.list_extend(opts.sources, {
                nls.builtins.code_actions.gomodifytags,
                nls.builtins.code_actions.impl,
                nls.builtins.formatting.goimports,
                nls.builtins.formatting.gofumpt,
            })
        end,
    },

    -- nvim-lint: Linting integration
    {
        "mfussenegger/nvim-lint",
        optional = true,
        opts = function(_, opts)
            if not opts.linters_by_ft then
                opts.linters_by_ft = {}
            end
            -- opts.linters_by_ft.go = { "golangci-lint" }
        end,
    },

    -- conform.nvim: Formatting integration
    {
        "stevearc/conform.nvim",
        optional = true,
        opts = function(_, opts)
            if not opts.formatters_by_ft then
                opts.formatters_by_ft = {}
            end
            opts.formatters_by_ft.go = { "goimports", "gofumpt" }
        end,
    },

    -- Explicitly fix nvim-dap by providing an empty config to avoid 'nil setup' error
    {
        "mfussenegger/nvim-dap",
        lazy = true,
        config = function() end,
    },
}
