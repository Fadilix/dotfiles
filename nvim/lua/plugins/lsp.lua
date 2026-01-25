return {
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "stylua",
                "selene",
                "luacheck",
                "shfmt",
                "tailwindcss-language-server",
                -- "typescript-language-server",
                "css-lsp",
                "java-debug-adapter",
                "java-test",
                "gopls",
                "goimports",
                "gofumpt",
                "gomodifytags",
                "impl",
                "golangci-lint",
                "delve",
                -- "prisma-language-server",
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = {
            ensure_installed = {
                "lua",
                -- "typescript",
                -- "javascript",
                "css",
                "html",
                "prisma",
                "java",
                "go",
                "gomod",
                "gowork",
                "gosum",
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            -- make sure mason installs the server
            servers = {
                --- @deprecated -- tsserver renamed to ts_ls but not yet released, so keep this for now
                --- the proper approach is to check the nvim-lspconfig release version when it's released to determine the server name dynamically
                tsserver = {
                    enabled = false,
                },
                ts_ls = {
                    enabled = false,
                },
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {
                                gc_details = false,
                                generate = true,
                                regenerate_cgo = true,
                                run_govulncheck = true,
                                test = true,
                                tidy = true,
                                upgrade_dependency = true,
                                vendor = true,
                            },
                            hints = {
                                assignVariableTypes = true,
                                compositeLiteralFields = true,
                                compositeLiteralTypes = true,
                                constantValues = true,
                                functionTypeParameters = true,
                                parameterNames = true,
                                rangeVariableTypes = true,
                            },
                            analyses = {
                                nilness = true,
                                unusedparams = true,
                                unusedwrite = true,
                                useany = true,
                            },
                            usePlaceholders = true,
                            completeUnimported = true,
                            staticcheck = true,
                            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
                            semanticTokens = true,
                        },
                    },
                },
                vtsls = {
                    -- explicitly add default filetypes, so that we can extend
                    -- them in related extras
                    filetypes = {
                        "javascript",
                        "javascriptreact",
                        "javascript.jsx",
                        "typescript",
                        "typescriptreact",
                        "typescript.tsx",
                    },
                    settings = {
                        complete_function_calls = true,
                        vtsls = {
                            enableMoveToFileCodeAction = true,
                            autoUseWorkspaceTsdk = true,
                            experimental = {
                                maxInlayHintLength = 30,
                                completion = {
                                    enableServerSideFuzzyMatch = true,
                                },
                            },
                        },
                        typescript = {
                            updateImportsOnFileMove = { enabled = "always" },
                            suggest = {
                                completeFunctionCalls = true,
                            },
                            inlayHints = {
                                enumMemberValues = { enabled = true },
                                functionLikeReturnTypes = { enabled = true },
                                parameterNames = { enabled = "literals" },
                                parameterTypes = { enabled = true },
                                propertyDeclarationTypes = { enabled = true },
                                variableTypes = { enabled = false },
                            },
                        },
                    },
                    keys = {
                        {
                            "gD",
                            function()
                                local win = vim.api.nvim_get_current_win()
                                local params = vim.lsp.util.make_position_params(win, "utf-16")
                                LazyVim.lsp.execute({
                                    command = "typescript.goToSourceDefinition",
                                    arguments = { params.textDocument.uri, params.position },
                                    open = true,
                                })
                            end,
                            desc = "Goto Source Definition",
                        },
                        {
                            "gR",
                            function()
                                LazyVim.lsp.execute({
                                    command = "typescript.findAllFileReferences",
                                    arguments = { vim.uri_from_bufnr(0) },
                                    open = true,
                                })
                            end,
                            desc = "File References",
                        },
                        {
                            "<leader>co",
                            LazyVim.lsp.action["source.organizeImports"],
                            desc = "Organize Imports",
                        },
                        {
                            "<leader>cM",
                            LazyVim.lsp.action["source.addMissingImports.ts"],
                            desc = "Add missing imports",
                        },
                        {
                            "<leader>cu",
                            LazyVim.lsp.action["source.removeUnused.ts"],
                            desc = "Remove unused imports",
                        },
                        {
                            "<leader>cD",
                            LazyVim.lsp.action["source.fixAll.ts"],
                            desc = "Fix all diagnostics",
                        },
                        {
                            "<leader>cV",
                            function()
                                LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
                            end,
                            desc = "Select TS workspace version",
                        },
                    },
                },
            },
            setup = {
                --- @deprecated -- tsserver renamed to ts_ls but not yet released, so keep this for now
                --- the proper approach is to check the nvim-lspconfig release version when it's released to determine the server name dynamically
                tsserver = function()
                    -- disable tsserver
                    return true
                end,
                ts_ls = function()
                    -- disable tsserver
                    return true
                end,

                gopls = function(_, opts)
                    -- workaround for gopls not supporting semanticTokensProvider
                    -- https://github.com/golang/go/issues/54531#issuecomment-1464982242
                    Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
                        if not client.server_capabilities.semanticTokensProvider then
                            local semantic = client.config.capabilities.textDocument.semanticTokens
                            client.server_capabilities.semanticTokensProvider = {
                                full = true,
                                legend = {
                                    tokenTypes = semantic.tokenTypes,
                                    tokenModifiers = semantic.tokenModifiers,
                                },
                                range = true,
                            }
                        end
                    end)
                    -- end workaround
                end,
                vtsls = function(_, opts)
                    if vim.lsp.config.denols and vim.lsp.config.vtsls then
                        ---@param server string
                        local resolve = function(server)
                            local markers, root_dir =
                                vim.lsp.config[server].root_markers, vim.lsp.config[server].root_dir
                            vim.lsp.config(server, {
                                root_dir = function(bufnr, on_dir)
                                    local is_deno = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) ~= nil
                                    if is_deno == (server == "denols") then
                                        if root_dir then
                                            return root_dir(bufnr, on_dir)
                                        elseif type(markers) == "table" then
                                            local root = vim.fs.root(bufnr, markers)
                                            return root and on_dir(root)
                                        end
                                    end
                                end,
                            })
                        end
                        resolve("denols")
                        resolve("vtsls")
                    end

                    Snacks.util.lsp.on({ name = "vtsls" }, function(buffer, client)
                        client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
                            ---@type string, string, lsp.Range
                            local action, uri, range = unpack(command.arguments)

                            local function move(newf)
                                client:request("workspace/executeCommand", {
                                    command = command.command,
                                    arguments = { action, uri, range, newf },
                                })
                            end

                            local fname = vim.uri_to_fname(uri)
                            client:request("workspace/executeCommand", {
                                command = "typescript.tsserverRequest",
                                arguments = {
                                    "getMoveToRefactoringFileSuggestions",
                                    {
                                        file = fname,
                                        startLine = range.start.line + 1,
                                        startOffset = range.start.character + 1,
                                        endLine = range["end"].line + 1,
                                        endOffset = range["end"].character + 1,
                                    },
                                },
                            }, function(_, result)
                                ---@type string[]
                                local files = result.body.files
                                table.insert(files, 1, "Enter new path...")
                                vim.ui.select(files, {
                                    prompt = "Select move destination:",
                                    format_item = function(f)
                                        return vim.fn.fnamemodify(f, ":~:.")
                                    end,
                                }, function(f)
                                    if f and f:find("^Enter new path") then
                                        vim.ui.input({
                                            prompt = "Enter move destination:",
                                            default = vim.fn.fnamemodify(fname, ":h") .. "/",
                                            completion = "file",
                                        }, function(newf)
                                            return newf and move(newf)
                                        end)
                                    elseif f then
                                        move(f)
                                    end
                                end)
                            end)
                        end
                    end)
                    -- copy typescript settings to javascript
                    opts.settings.javascript =
                        vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
                end,
            },
        },
    },
}
