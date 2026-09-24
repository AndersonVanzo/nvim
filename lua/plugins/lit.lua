return {
  -- 1. Ensure Tree-sitter handles html/css syntax parsing inside template literals
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "html", "css", "typescript", "javascript" })
      end
    end,
  },

  -- 2. Inject the typescript-lit-html-plugin into LazyVim's default TypeScript server (vtsls)
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Safeguard to ensure servers table exists
      opts.servers = opts.servers or {}
      
      -- Configure vtsls (LazyVim's default)
      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                {
                  name = "typescript-lit-html-plugin",
                  -- Safely resolves the path where the plugin lives in your local project node_modules
                  location = vim.fn.getcwd() .. "/node_modules/typescript-lit-html-plugin",
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
            },
          },
        },
      })
    end,
  },
}

