return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    opts_extend = { 'ensure_installed' },
    opts = {
        ensure_installed = {
            'asm',
            'bash',
            'c',
            'cpp',
            'css',
            'git_config',
            'git_rebase',
            'gitattributes',
            'gitcommit',
            'gitignore',
            'go',
            'gomod',
            'gosum',
            'gotmpl',
            'html',
            'javascript',
            'jsdoc',
            'json',
            'json5',
            'kotlin',
            'lua',
            'luadoc',
            'luap',
            'markdown',
            'markdown_inline',
            'printf',
            'python',
            'query',
            'regex',
            'rust',
            'sql',
            'swift',
            'toml',
            'tsx',
            'typescript',
            'vim',
            'vimdoc',
            'yaml',
            'zig',
            'ziggy',
            'ziggy_schema',
        },
    },
    config = function(_, opts)
        local TS = require('nvim-treesitter')
        TS.setup()

        -- Install whatever isn't on disk yet. Async: does not block startup.
        local installed = {}
        for _, lang in ipairs(TS.get_installed('parsers')) do
            installed[lang] = true
        end
        local missing = vim.tbl_filter(function(lang)
            return not installed[lang]
        end, opts.ensure_installed or {})

        if #missing > 0 then
            TS.install(missing, { summary = true }):await(function()
                -- Buffers opened before the install finished got no highlighting.
                vim.schedule(function()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) then
                            vim.api.nvim_exec_autocmds('FileType', { buffer = buf })
                        end
                    end
                end)
            end)
        end

        -- `main` enables nothing on its own: wire it up per buffer.
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup('treesitter_enable', { clear = true }),
            callback = function(ev)
                local lang = vim.treesitter.language.get_lang(ev.match)
                if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
                    return -- no parser installed for this filetype
                end
                if vim.treesitter.query.get(lang, 'indents') then
                    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
