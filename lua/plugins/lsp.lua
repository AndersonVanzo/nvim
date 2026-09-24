return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = { 'Mason', 'MasonInstall', 'MasonUpdate', 'MasonLog' },

    dependencies = {
        -- Server installation
        'mason-org/mason.nvim',
        'mason-org/mason-lspconfig.nvim',

        -- Autocompletion
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'saadparwaiz1/cmp_luasnip',

        -- Snippets
        { 'L3MON4D3/LuaSnip', build = 'make install_jsregexp' },
        'rafamadriz/friendly-snippets',
    },

    -- Filetype mappings must exist before the first file is read, and `config`
    -- is deferred to the events above. `init` always runs at startup.
    init = function()
        vim.filetype.add({
            extension = {
                -- h = 'c',  -- forces EVERY .h to C; breaks C++ headers under clangd
                c3 = 'c3',
                d = 'd',
                templ = 'templ',
            },
        })
    end,

    config = function()
        -- ── UI ───────────────────────────────────────────────────────────────
        -- Native in 0.11+; replaces the old `vim.lsp.with(handlers.hover, …)`
        -- monkey-patching, and covers signature help and diagnostic floats too.
        vim.o.winborder = 'rounded'

        vim.diagnostic.config({
            virtual_text  = true,
            severity_sort = true,
            float         = {
                style  = 'minimal',
                border = 'rounded',
                source = 'if_many',
                header = '',
                prefix = '',
            },
            signs         = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '✘',
                    [vim.diagnostic.severity.WARN]  = '▲',
                    [vim.diagnostic.severity.HINT]  = '⚑',
                    [vim.diagnostic.severity.INFO]  = '»',
                },
            },
        })

        -- Cap runaway hover/signature windows. Borders come from `winborder`.
        local orig = vim.lsp.util.open_floating_preview
        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
            opts            = opts or {}
            opts.max_width  = opts.max_width or 80
            opts.max_height = opts.max_height or 24
            opts.wrap       = opts.wrap ~= false
            return orig(contents, syntax, opts, ...)
        end

        -- ── Mason ────────────────────────────────────────────────────────────
        -- Must run before vim.lsp.enable: setup() prepends Mason's bin dir to
        -- PATH, which is how `cmd` lookups below resolve Mason-installed servers.
        require('mason').setup({})
        require('mason-lspconfig').setup({
            ensure_installed = { 'lua_ls', 'intelephense', 'ts_ls', 'eslint' },
            -- We enable explicitly below so Mason-installed and system-installed
            -- servers (your cargo rust-analyzer, /usr/bin/clangd) take one path.
            automatic_enable = false,
        })

        -- ── shared defaults ──────────────────────────────────────────────────
        -- Lowest precedence: lspconfig's lsp/*.lua and the per-server overrides
        -- below both win over anything set here.
        vim.lsp.config('*', {
            root_markers = { '.git' },
            capabilities = require('cmp_nvim_lsp').default_capabilities(),
        })

        -- ── per-server overrides ─────────────────────────────────────────────
        -- Keys MUST match nvim-lspconfig's lsp/<name>.lua. cmd, filetypes and
        -- root_markers come from there; only list what you actually change.
        local servers = {
            lua_ls        = {
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                            checkThirdParty = false,
                            library = vim.api.nvim_get_runtime_file('', true),
                        },
                        telemetry = { enable = false },
                    },
                },
            },

            cssls         = {
                settings = {
                    css  = { validate = true },
                    scss = { validate = true },
                    less = { validate = true },
                },
            },

            intelephense  = {
                settings = {
                    intelephense = {
                        files = { maxSize = 5000000 },
                    },
                },
            },

            ts_ls         = {
                settings = {
                    completions = { completeFunctionCalls = true },
                },
            },

            zls           = {
                settings = {
                    zls = {
                        enable_build_on_save = true,
                        build_on_save_step   = 'install',
                        warn_style           = false,
                        enable_snippets      = true,
                    },
                },
            },

            nil_ls        = {
                settings = {
                    ['nil'] = {
                        formatting = { command = { 'alejandra' } },
                    },
                },
            },

            rust_analyzer = {
                settings = {
                    ['rust-analyzer'] = {
                        cargo = { allFeatures = true },
                        formatting = { command = { 'rustfmt' } },
                    },
                },
            },

            hls           = {
                settings = {
                    haskell = {
                        formattingProvider = 'fourmolu',
                        plugin = { semanticTokens = { globalOn = false } },
                    },
                },
            },

            gopls         = {
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = false,
                            ST1003 = false,
                            ST1000 = false,
                        },
                        staticcheck = true,
                    },
                },
            },

            -- No overrides needed; lspconfig's defaults are used verbatim.
            clangd        = {},
            c3_lsp        = {},
            serve_d       = {},
            jsonls        = {},
            templ         = {},
            eslint        = {},
        }

        for name, cfg in pairs(servers) do
            vim.lsp.config[name] = cfg
        end
        -- Servers whose binary isn't installed are skipped silently by
        -- vim.lsp's own validate_cmd; no guards needed here.
        vim.lsp.enable(vim.tbl_keys(servers))

        -- ── on attach ────────────────────────────────────────────────────────
        -- Format-on-save lives in plugins/conform.lua, which sequences
        -- eslint --fix then prettier, and falls back to the LSP for filetypes
        -- with no formatter configured.
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('my.lsp', { clear = true }),
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then return end
                local buf = args.buf
                local map = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, { buffer = buf }) end

                map('n', 'K', vim.lsp.buf.hover)
                map('n', 'gd', vim.lsp.buf.definition)
                map('n', 'gD', vim.lsp.buf.declaration)
                map('n', 'gi', vim.lsp.buf.implementation)
                map('n', 'go', vim.lsp.buf.type_definition)
                map('n', 'gr', vim.lsp.buf.references)
                map('n', 'gs', vim.lsp.buf.signature_help)
                map('n', 'gl', vim.diagnostic.open_float)
                map('n', '<F2>', vim.lsp.buf.rename)
                -- Via conform, so ts_ls and eslint never both format the buffer:
                -- vim.lsp.buf.format() applies EVERY capable client in sequence.
                map({ 'n', 'x' }, '<F3>', function()
                    require('conform').format({ async = true, lsp_format = 'fallback' })
                end)
                map('n', '<F4>', vim.lsp.buf.code_action)

                if client:supports_method('textDocument/documentHighlight') then
                    local hl_group = vim.api.nvim_create_augroup('my.lsp.highlight', { clear = false })
                    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                        buffer = buf,
                        group = hl_group,
                        callback = vim.lsp.buf.document_highlight,
                    })
                    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                        buffer = buf,
                        group = hl_group,
                        callback = vim.lsp.buf.clear_references,
                    })
                end
            end,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('my.lsp.detach', { clear = true }),
            callback = function(args)
                pcall(vim.api.nvim_clear_autocmds, { group = 'my.lsp.highlight', buffer = args.buf })
            end,
        })

        -- ── completion ───────────────────────────────────────────────────────
        local cmp = require('cmp')
        require('luasnip.loaders.from_vscode').lazy_load()

        -- Match cmp's own completeopt below; 'noselect' and 'noinsert' conflict.
        vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }

        cmp.setup({
            preselect = 'item',
            completion = {
                completeopt = 'menu,menuone,noinsert',
            },
            window = {
                documentation = cmp.config.window.bordered(),
            },
            sources = {
                { name = 'path' },
                { name = 'nvim_lsp' },
                { name = 'buffer',  keyword_length = 3 },
                { name = 'luasnip', keyword_length = 2 },
            },
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            formatting = {
                fields = { 'abbr', 'menu', 'kind' },
                format = function(entry, item)
                    local n = entry.source.name
                    if n == 'nvim_lsp' then
                        item.menu = '[LSP]'
                    else
                        item.menu = string.format('[%s]', n)
                    end
                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                -- confirm completion item
                ['<CR>'] = cmp.mapping.confirm({ select = false }),

                -- scroll documentation window
                ['<C-f>'] = cmp.mapping.scroll_docs(5),
                ['<C-u>'] = cmp.mapping.scroll_docs(-5),

                -- toggle completion menu
                ['<C-e>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.abort()
                    else
                        cmp.complete()
                    end
                end),

                -- tab complete
                ['<Tab>'] = cmp.mapping(function(fallback)
                    local col = vim.fn.col('.') - 1

                    if cmp.visible() then
                        cmp.select_next_item({ behavior = 'select' })
                    elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                        fallback()
                    else
                        cmp.complete()
                    end
                end, { 'i', 's' }),

                -- go to previous item
                ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),

                -- navigate to next snippet placeholder
                ['<C-d>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if luasnip.jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),

                -- navigate to the previous snippet placeholder
                ['<C-b>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
        })
    end,
}
