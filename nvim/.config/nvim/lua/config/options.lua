vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

local options = {
    number = true,
    relativenumber = true,
    mouse = 'a',
    showmode = false,
    breakindent = true,
    undofile = true,
    ignorecase = true,
    smartcase = true,
    signcolumn = 'yes',
    updatetime = 250,
    timeoutlen = 300,
    splitright = true,
    splitbelow = true,
    list = true,
    inccommand = 'split',
    cursorline = true,
    scrolloff = 10,
    confirm = true,
    tabstop = 4,
    shiftwidth = 4,
    softtabstop = 4,
    expandtab = true,
    cindent = true,
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

-- Set tab to two spaces so literal tabs are invisible and don't cause E1511
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }
vim.opt.cinoptions = 'g0'
