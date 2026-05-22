-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Move lines
vim.keymap.set('n', 'J', ':m .+1<CR>==', { desc = 'Move line down', silent = true })
vim.keymap.set('n', 'K', ':m .-2<CR>==', { desc = 'Move line up', silent = true })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move block down', silent = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move block up', silent = true })

-- Indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Shift left' })
vim.keymap.set('v', '>', '>gv', { desc = 'Shift right' })

-- Clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })
vim.keymap.set({ 'n', 'v' }, '<D-v>', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('i', '<D-v>', '<C-r>+', { desc = 'Paste from system clipboard' })
vim.keymap.set('c', '<D-v>', '<C-r>+', { desc = 'Paste from system clipboard' })

-- Paste over selection without yanking
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste over selection without yanking' })

-- Black hole register for minor deletions
vim.keymap.set({ 'n', 'v' }, 'x', '"_x', { desc = 'Delete character without yanking' })
vim.keymap.set({ 'n', 'v' }, 'c', '"_c', { desc = 'Change without yanking' })
vim.keymap.set({ 'n', 'v' }, 'C', '"_C', { desc = 'Change to end of line without yanking' })
vim.keymap.set({ 'n', 'v' }, 's', '"_s', { desc = 'Substitute without yanking' })

-- Tmux fix for S-CR
vim.keymap.set({ 'n', 'i' }, '<Esc>[13;2u', '<S-CR>', { remap = true })

-- Command aliases
vim.api.nvim_create_user_command('W', 'w', { desc = 'Save current file' })
vim.api.nvim_create_user_command('Q', 'q', { desc = 'Quit Neovim' })
vim.api.nvim_create_user_command('Wq', 'wq', { desc = 'Save and Quit' })
vim.api.nvim_create_user_command('WQ', 'wq', { desc = 'Save and Quit' })
