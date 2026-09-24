return {
    'akinsho/toggleterm.nvim',
    version = '*',
    -- VeryLazy rather than `keys`/`cmd`: toggleterm's own `open_mapping` and the
    -- TermOpen autocmd below only exist once setup() has run, so deferring until
    -- first keypress makes the very first <C-\> unreliable. The plugin is tiny.
    event = 'VeryLazy',

    opts = {
        open_mapping = [[<c-\>]],
        direction = 'horizontal',

        -- One number applies to every direction, so use a function instead:
        -- rows for horizontal, columns for vertical.
        size = function(term)
            if term.direction == 'horizontal' then
                return 15
            elseif term.direction == 'vertical' then
                return math.floor(vim.o.columns * 0.4)
            end
        end,

        start_in_insert = true,
        insert_mappings = true,   -- <C-\> also works from insert mode
        terminal_mappings = true, -- ...and from inside the terminal
        persist_size = true,
        persist_mode = true,
        close_on_exit = true,
        hide_numbers = true,
        -- Terminal windows use the editor background unchanged. Flip to true
        -- (toggleterm's default) for a subtly darker terminal background.
        shade_terminals = false,

        -- toggleterm sets its float border explicitly, which overrides the
        -- global vim.o.winborder from plugins/lsp.lua. Match it.
        float_opts = {
            border = 'rounded',
            winblend = 0,
        },
    },

    config = function(_, opts)
        require('toggleterm').setup(opts)

        -- Applies to every terminal buffer, including plain `:terminal`.
        vim.api.nvim_create_autocmd('TermOpen', {
            pattern = '*',
            group = vim.api.nvim_create_augroup('my.toggleterm', { clear = true }),
            callback = function(args)
                local o = { buffer = args.buf }
                -- <Esc><Esc>, not a bare <Esc>: a bare mapping would swallow
                -- Escape inside anything running in the terminal (vim, TUIs).
                vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], o)
                -- Window navigation straight out of terminal mode.
                vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], o)
                vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], o)
                vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], o)
                vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], o)
                vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], o)
            end,
        })

        local map = function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { desc = desc })
        end

        map('<leader>tf', '<cmd>ToggleTerm direction=float<cr>', 'Terminal: float')
        map('<leader>th', '<cmd>ToggleTerm direction=horizontal<cr>', 'Terminal: horizontal')
        map('<leader>tv', '<cmd>ToggleTerm direction=vertical<cr>', 'Terminal: vertical')
        map('<leader>ta', '<cmd>ToggleTermToggleAll<cr>', 'Terminal: toggle all')

        -- Send the current file to the terminal, e.g. :lua run node on it.
        map('<leader>tr', function()
            vim.cmd('TermExec cmd="' .. vim.fn.expand('%:p') .. '"')
        end, 'Terminal: run current file')
    end,
}
