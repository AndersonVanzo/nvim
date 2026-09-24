return {
    {
        "catppuccin/nvim",
        -- Required: the repo is catppuccin/nvim, so without an explicit name
        -- lazy installs it as "nvim", which breaks require("catppuccin").
        name = "catppuccin",
        priority = 1000, -- colourscheme first, so later plugins see its highlights
        opts = {
            flavour = "mocha",
            -- auto_integrations defaults to true, so telescope, treesitter,
            -- cmp, mason and harpoon get themed without being listed here.
            -- Only integrations needing sub-options belong in `integrations`.

            -- term_colors = true,  -- also recolour :terminal/toggleterm ANSI
            --                         colours; off by default so your kitty
            --                         palette and shell prompt stay as-is.
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme "catppuccin-mocha"
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            -- lualine reads the theme from options.theme. A top-level `theme`
            -- key is silently ignored, which is why the previous
            -- `theme = "tokyonight"` never actually applied -- lualine's
            -- default of 'auto' was detecting the colourscheme instead.
            options = {
                theme = "catppuccin-mocha",
            },
        },
    },
}
