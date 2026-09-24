return {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },

    opts = {
        -- conform resolves `prettier` via util.from_node_modules, which searches
        -- upward from the current file for node_modules/.bin/prettier. Each project
        -- therefore gets its own pinned prettier and its own .prettierrc.
        formatters_by_ft = {
            javascript      = { 'prettier' },
            javascriptreact = { 'prettier' },
            typescript      = { 'prettier' },
            typescriptreact = { 'prettier' },
            vue             = { 'prettier' },
            svelte          = { 'prettier' },
            json            = { 'prettier' },
            jsonc           = { 'prettier' },
            css             = { 'prettier' },
            scss            = { 'prettier' },
            less            = { 'prettier' },
            html            = { 'prettier' },
            yaml            = { 'prettier' },
            markdown        = { 'prettier' },
        },

        format_on_save = function(bufnr)
            -- eslint --fix first, then prettier, in one BufWritePre so the order is
            -- deterministic. LspEslintFixAll uses client:request_sync, so its edits
            -- have landed by the time this returns and prettier formats fixed text.
            if vim.lsp.get_clients({ bufnr = bufnr, name = 'eslint' })[1] then
                pcall(vim.api.nvim_buf_call, bufnr, function()
                    vim.cmd('LspEslintFixAll')
                end)
            end

            -- No formatter listed above -> fall back to the language server, so
            -- lua_ls, rust_analyzer, gopls etc. still format on save.
            return { lsp_format = 'fallback', timeout_ms = 1000 }
        end,
    },
}
