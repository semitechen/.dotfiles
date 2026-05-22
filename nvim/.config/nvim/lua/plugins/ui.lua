return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      require('tokyonight').setup {
        transparent = true,
        styles = {
          comments = { italic = false },
        },
        on_highlights = function(hl, _)
          local transparent = { bg = 'none', fg = 'none' }
          hl.BufferLineFill = transparent
          hl.BufferLineBackground = transparent
          hl.BufferLineSeparator = transparent
          hl.BufferLineSeparatorVisible = transparent
          hl.BufferLineSeparatorSelected = transparent
          hl.BufferLineTabSeparator = transparent
          hl.BufferLineTabSeparatorSelected = transparent
          hl.BufferLineIndicatorSelected = transparent
          hl.BufferLineIndicatorVisible = transparent
        end,
      }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    lazy = false,
    keys = {
      { '<A-,>', '<Cmd>BufferLineCyclePrev<CR>', desc = 'Previous tab' },
      { '<A-.>', '<Cmd>BufferLineCycleNext<CR>', desc = 'Next tab' },
    },
    opts = {
      options = {
        always_show_bufferline = true,
        separator_style = { '', '' },
        indicator = {
          style = 'none',
        },
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
