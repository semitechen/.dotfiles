return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope').themes.get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  {
    'stevearc/oil.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'refractalize/oil-git-status.nvim',
    },
    lazy = false,
    keys = {
      {
        '\\',
        function()
          local oil = require 'oil'
          if vim.bo.filetype == 'oil' then
            vim.g.last_oil_dir = oil.get_current_dir()
            oil.close()
          else
            if vim.g.last_oil_dir then
              oil.open(vim.g.last_oil_dir)
            else
              oil.open()
            end
          end
        end,
        desc = 'Toggle Full Screen Explorer',
      },
    },
    config = function()
      require('oil').setup {
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        constrain_cursor = 'name',
        delete_to_trash = true,
        win_options = {
          signcolumn = 'yes:2',
          scrolloff = 0,
        },
        columns = { 'icon' },
        keymaps = {
          ['<2-LeftMouse>'] = {
            callback = function()
              local mousepos = vim.fn.getmousepos()
              if mousepos and mousepos.line > 0 then pcall(vim.api.nvim_win_set_cursor, 0, { mousepos.line, 0 }) end
              local oil = require 'oil'
              local entry = oil.get_cursor_entry()
              if not entry then return end
              local target = oil.get_current_dir() .. entry.name
              if entry.type == 'directory' then
                oil.open(target)
              else
                vim.ui.open(target)
              end
            end,
          },
          ['<S-CR>'] = {
            callback = function()
              local oil = require 'oil'
              local entry = oil.get_cursor_entry()
              if not entry then return end
              local target = oil.get_current_dir() .. entry.name
              if entry.type == 'directory' then
                oil.open(target)
              else
                vim.cmd('badd ' .. vim.fn.fnameescape(target))
                vim.cmd 'redrawtabline'
                vim.notify('Opened in background: ' .. entry.name)
              end
            end,
          },
          ['<CR>'] = 'actions.select',
          ['<C-l>'] = 'actions.select',
          ['q'] = 'actions.close',
          ['<leader>d'] = {
            callback = function()
              local oil = require 'oil'
              local entry = oil.get_cursor_entry()
              if not entry or entry.type == 'directory' then return end
              local target = oil.get_current_dir() .. entry.name
              vim.fn.jobstart({ 'ripdrag', target }, { detach = true })
              vim.notify('Dragging: ' .. entry.name)
            end,
          },
        },
      }
      require('oil-git-status').setup {
        show_ignored = false,
        symbols = {
          index = {
            ['!'] = '◌',
            ['?'] = '●',
            [' A'] = '',
            ['A'] = '',
            ['C'] = 'C',
            ['D'] = '',
            ['M'] = '',
            ['R'] = 'R',
            ['T'] = 'T',
            ['U'] = 'U',
            [' '] = ' ',
          },
          working_tree = {
            ['!'] = '◌',
            ['?'] = '●',
            [' A'] = '',
            ['A'] = '',
            ['C'] = 'C',
            ['D'] = '',
            ['M'] = '',
            ['R'] = 'R',
            ['T'] = 'T',
            ['U'] = 'U',
            [' '] = ' ',
          },
        },
      }
    end,
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions
        map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
        map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
        map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
        map('n', '<leader>hQ', function() gitsigns.setqflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)' })
        map('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix list (all changes in this file)' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
        map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff' })
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
      end,
    },
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    main = 'ibl',
    opts = {},
  },
}
