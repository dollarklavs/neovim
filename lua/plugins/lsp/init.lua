return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                {"ray-x/lsp_signature.nvim"}, {"glepnir/lspsaga.nvim", branch = "main"}, {"hrsh7th/cmp-nvim-lsp"},
                {"SmiteshP/nvim-navic", opts = {highlight = true}}, {"williamboman/mason.nvim"},
                {"williamboman/mason-lspconfig.nvim"}
            }
        },
        event = "BufReadPre",
        config = function()
            local lspconfig = require("lspconfig")

            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            local nok, navic = pcall(require, "nvim-navic")
            if not nok then
                vim.notify("Unable to require nvim-navic", vim.lsp.log_levels.ERROR, {title = "Plugin error"})
                return
            end

            local saga_status, saga = pcall(require, "lspsaga")
            if not saga_status then
                vim.notify("Unable to require lspsaga", vim.lsp.log_levels.ERROR, {title = "Plugin error"})
                return
            end

            saga.init_lsp_saga({
                -- keybinds for navigation in lspsaga window
                move_in_saga = {prev = "<C-k>", next = "<C-j>"},
                -- use enter to open file with finder
                finder_action_keys = {open = "<CR>"},
                -- use enter to open file with definition preview
                definition_action_keys = {edit = "<CR>"},
                -- disable virtual text
                code_action_lightbulb = {virtual_text = false}
            })

            local on_attach = function(client, bufnr)
                require("plugins.lsp.format").on_attach(client, bufnr)

                if client.name == "tsserver" then
                    client.server_capabilities.document_formatting = false
                elseif client.name == "sumneko_lua" then
                    client.server_capabilities.document_formatting = false
                elseif client.name == "gopls" then
                    client.server_capabilities.document_formatting = false
                    client.server_capabilities.document_range_formatting = false
                end

                -- Avoid attaching multiple times
                if client.name ~= "pylsp" and client.name ~= "null-ls" and client.name ~= "efm" then
                    navic.attach(client, bufnr)
                end

                require("plugins.lsp.keymaps").on_attach(client, bufnr)
            end

            local capabilities = cmp_nvim_lsp.default_capabilities()

            local signs = {Error = " ", Warn = " ", Hint = "ﴞ ", Info = " "}
            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = ""})
            end

            local config = {
                -- disable virtual text
                virtual_text = false,
                -- show signs
                signs = {active = signs},
                update_in_insert = true,
                underline = true,
                severity_sort = true,
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = ""
                }
            }

            vim.diagnostic.config(config)

            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {border = "rounded"})

            vim.lsp.handlers["textDocument/signatureHelp"] =
                vim.lsp.with(vim.lsp.handlers.signature_help, {border = "rounded"})

            -- Go
            lspconfig["gopls"].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {gopls = {analyses = {unusedparams = true}, staticcheck = true, gofumpt = true}},
                root_dir = lspconfig.util.root_pattern(".git", "go.mod", "."),
                init_options = {usePlaceholders = true, completeUnimported = true, gofumpt = true}
            })

            -- Lua
            lspconfig["sumneko_lua"].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = { -- custom settings for lua
                    Lua = {
                        -- make the language server recognize "vim" global
                        diagnostics = {globals = {"vim", "require"}},
                        workspace = {
                            -- make language server aware of runtime files
                            library = {
                                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                                [vim.fn.stdpath("config") .. "/lua"] = true
                            }
                        }
                    }
                }
            })

            -- Python
            lspconfig["pylsp"].setup({capabilities = capabilities, on_attach = on_attach})

            lspconfig["pyright"].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                    python = {
                        analysis = {
                            autoSearchPaths = true,
                            diagnosticMode = "openFilesOnly",
                            useLibraryCodeForTypes = true
                        }
                    }
                }
            })

            -- Bash
            lspconfig["bashls"].setup({capabilities = capabilities, on_attach = on_attach, filetypes = {"sh", "zsh"}})

            -- Docker
            lspconfig["bashls"].setup({capabilities = capabilities, on_attach = on_attach, root_dir = vim.loop.cwd})

            -- C
            local utf16cap = capabilities
            utf16cap.offsetEncoding = {"utf-16"}
            lspconfig["clangd"].setup({
                cmd = {"clangd", "--background-index"},
                capabilities = utf16cap,
                on_attach = on_attach
            })

            lspconfig["efm"].setup({capabilities = capabilities, on_attach = on_attach})

            lspconfig["jsonls"].setup({capabilities = capabilities, on_attach = on_attach})

            lspconfig["perlnavigator"].setup({capabilities = capabilities, on_attach = on_attach})

            lspconfig["yamlls"].setup({capabilities = capabilities, on_attach = on_attach})

            lspconfig["solargraph"].setup({
                capabilities = capabilities,
                on_attach = on_attach,
                filetypes = {"ruby", "rb", "erb", "rakefile"}
            })

            lspconfig["rust_analyzer"].setup({capabilities = capabilities, on_attach = on_attach})
        end
    }, {
        "jose-elias-alvarez/null-ls.nvim",
        build = {
            "go install github.com/daixiang0/gci@latest",
            "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest",
            "go install golang.org/x/tools/cmd/goimports@latest"
        },
        dependencies = {"jayp0521/mason-null-ls.nvim"},
        event = "BufReadPre",
        config = function()
            -- import mason-null-ls plugin safely
            local mason_null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
            if not mason_null_ls_status then
                vim.notify("Unable to require mason-null-ls", vim.lsp.log_levels.ERROR, {title = "Plugin error"})
                return
            end

            mason_null_ls.setup({
                -- list of formatters & linters for mason to install
                ensure_installed = {"stylua", "black", "gofmt", "goimports", "golangci_lint"},
                -- auto-install configured servers (with lspconfig)
                automatic_installation = true
            })

            local null_ls = require("null-ls")
            local h = require("null-ls.helpers")

            -- for conciseness
            local formatting = null_ls.builtins.formatting -- to setup formatters
            local diagnostics = null_ls.builtins.diagnostics -- to setup linters

            local gci_format = {
                method = null_ls.methods.FORMATTING,
                filetypes = {"go"},
                generator = h.formatter_factory({command = "gci", args = {"-w", "$FILENAME"}, to_temp_file = true})
            }

            -- configure null_ls
            null_ls.setup({
                -- setup formatters & linters
                sources = {
                    formatting.stylua, formatting.lua_format, formatting.black, formatting.rustfmt, formatting.gofmt,
                    formatting.gofumpt, formatting.clang_format, formatting.goimports, diagnostics.golangci_lint.with({
                        args = {
                            "run", "--enable-all", "--disable", "lll", "--disable", "godot", "--out-format=json",
                            "$DIRNAME", "--path-prefix", "$ROOT"
                        }
                    }), gci_format, null_ls.builtins.formatting.rubocop.with({
                        args = {
                            "--auto-correct", "-f", "-c", HOME_PATH .. "/.work-rubocop.yml", "quiet", "--stderr",
                            "--stdin", "$FILENAME"
                        }
                    }), null_ls.builtins.diagnostics.rubocop.with({
                        args = {"-c", HOME_PATH .. "/.work-rubocop.yml", "-f", "json", "--stdin", "$FILENAME"}
                    })
                }
            })
        end
    }, {"williamboman/mason.nvim", cmd = "Mason", opts = {}}, -- Mason LSP
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {
                "gopls", "sumneko_lua", "bashls", "yamlls", "pyright", "pylsp", "efm", "solargraph", "dockerls",
                "clangd", "jsonls", "perlnavigator", "rust_analyzer"
            },
            automatic_installation = true
        }
    }
}
