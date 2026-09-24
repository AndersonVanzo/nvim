local conf = require('telescope.config').values
local themes = require('telescope.themes')

local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end
    local opts = themes.get_ivy({
        promt_title = "Working List"
    })
    require("telescope.pickers").new(opts, {
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer(opts),
        sorter = conf.generic_sorter(opts),
    }):find()
end

return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = function()
        local harpoon = require("harpoon")
        local keys = {
            {
                "<leader>a",
                function()
                    harpoon:list():add()
                end,
                desc = "Harpoon File",
            },
            {
                "<leader>fl",
                function()
                    toggle_telescope(harpoon:list())
                end,
                desc = "Open Harpoon Window",
            },
            {
                "<C-e>",
                function()
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
                desc = "Harpoon Quick Menu",
            },
            {
                "<C-p>",
                function()
                    harpoon:list():prev()
                end,
                desc = "Harpoon Previous"
            },
            {
                "<C-n>",
                function()
                    harpoon:list():next()
                end,
                desc = "Harpoon Next",
            }
        }
        return keys
    end
}
