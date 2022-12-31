local M = {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = {
        {"<c-t>", ":ToggleTerm", desc = "Toggle term"}, {
            "<c-g>",
            function()
                local lazygit = require("toggleterm.terminal").Terminal:new({cmd = "lazygit", hidden = true})

                vim.keymap.set("n", "<C-g>", function() lazygit:toggle() end)
            end,
            desc = ""
        }
    }
}

function M.config()
    require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-t>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        -- direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {border = "curved", winblend = 0, highlights = {border = "Normal", background = "Normal"}}
    })

    function _G.set_terminal_keymaps()
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], {noremap = true, buffer = 0, desc = "Esc in terminal"})
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], {noremap = true, buffer = 0, desc = "Esc in terminal"})
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-W>h]],
                       {noremap = true, buffer = 0, desc = "Navigate to left window"})
        vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-W>j]],
                       {noremap = true, buffer = 0, desc = "Navigate to window below"})
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-W>k]],
                       {noremap = true, buffer = 0, desc = "Navigate to window above"})
        vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-W>l]],
                       {noremap = true, buffer = 0, desc = "Navigate to right window"})
    end

    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end

return M
