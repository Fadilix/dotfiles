return {
    -- Rust tools and LSP configuration
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "rust-analyzer",
                "codelldb",
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "rust",
                "toml",
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                allFeatures = true,
                                loadOutDirsFromCheck = true,
                                buildScripts = {
                                    enable = true,
                                },
                            },
                            checkOnSave = {
                                allFeatures = true,
                                command = "clippy",
                                extraArgs = { "--no-deps" },
                            },
                            procMacro = {
                                enable = true,
                                ignored = {
                                    ["async-trait"] = { "async_trait" },
                                    ["napi-derive"] = { "napi" },
                                    ["async-recursion"] = { "async_recursion" },
                                },
                            },
                            inlayHints = {
                                bindingModeHints = {
                                    enable = false,
                                },
                                chainingHints = {
                                    enable = true,
                                },
                                closingBraceHints = {
                                    enable = true,
                                    minLines = 25,
                                },
                                closureReturnTypeHints = {
                                    enable = "never",
                                },
                                lifetimeElisionHints = {
                                    enable = "never",
                                    useParameterNames = false,
                                },
                                maxLength = 25,
                                parameterHints = {
                                    enable = true,
                                },
                                reborrowHints = {
                                    enable = "never",
                                },
                                renderColons = true,
                                typeHints = {
                                    enable = true,
                                    hideClosureInitialization = false,
                                    hideNamedConstructor = false,
                                },
                            },
                            diagnostics = {
                                enable = true,
                                experimental = {
                                    enable = true,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
    -- Formatting with rustfmt via conform.nvim
    {
        "stevearc/conform.nvim",
        optional = true,
        opts = function(_, opts)
            if not opts.formatters_by_ft then
                opts.formatters_by_ft = {}
            end
            opts.formatters_by_ft.rust = { "rustfmt" }
        end,
    },
    -- Debugging with codelldb
    {
        "mfussenegger/nvim-dap",
        optional = true,
        opts = function()
            local dap = require("dap")
            if not dap.adapters["codelldb"] then
                dap.adapters["codelldb"] = {
                    type = "server",
                    host = "localhost",
                    port = "${port}",
                    executable = {
                        command = "codelldb",
                        args = { "--port", "${port}" },
                    },
                }
            end
            dap.configurations.rust = {
                {
                    name = "Launch file",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                },
            }
        end,
    },
    -- Crates.nvim for Cargo.toml management
    {
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml" },
        opts = {
            completion = {
                cmp = {
                    enabled = true,
                },
            },
        },
    },
    -- Add rust to mini.icons
    {
        "echasnovski/mini.icons",
        opts = {
            file = {
                ["Cargo.toml"] = { glyph = "󰏓", hl = "MiniIconsOrange" },
                ["Cargo.lock"] = { glyph = "󰏓", hl = "MiniIconsOrange" },
            },
        },
    },
}
