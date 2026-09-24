return {
    {
        -- ssh tunneling and copying to clipboard
        'ojroques/vim-oscyank',
    },
    {
        -- git plugin
        'tpope/vim-fugitive',
    },
    {
        -- show CSS colors
        'brenoprata10/nvim-highlight-colors',
        config = function()
            require('nvim-highlight-colors').setup({})
        end,
    },
    {
        -- auto-close brackets and quotes: ( [ { " ' `
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        opts = {},
    },
}
