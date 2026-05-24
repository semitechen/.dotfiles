return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			"nvim-telescope/telescope-ui-select.nvim",
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = { require("telescope.themes").get_dropdown() },
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find(require("telescope").themes.get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		keys = {
			{
				"\\",
				function()
					local yazi = require("yazi")
					local yazi_win = nil
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						if vim.api.nvim_win_is_valid(win) then
							local buf = vim.api.nvim_win_get_buf(win)
							if vim.bo[buf].filetype == "yazi" then
								yazi_win = win
								break
							end
						end
					end

					if yazi_win then
						vim.api.nvim_win_close(yazi_win, true)
					else
						yazi.toggle()
					end
				end,
				desc = "Toggle yazi explorer",
			},
			{
				"<leader>cw",
				function()
					require("yazi").yazi(vim.fn.getcwd())
				end,
				desc = "Open yazi in nvim's working directory",
			},
		},
		---@type YaziConfig
		opts = {
			open_for_directories = true,
			floating_window_scaling_factor = 1,
			yazi_floating_window_border = "none",
			keymaps = {
				show_help = "<f1>",
				open_file_in_vertical_split = "<C-v>",
				open_file_in_horizontal_split = "<C-x>",
				open_file_in_tab = "<C-t>",
				open_file_in_background = "<S-CR>",
				send_to_quickfix_list = "<C-q>",
			},
			hooks = {
				before_opening_window = function(opts)
					opts.row = 1
					opts.height = opts.height - 1
				end,
				yazi_opened = function(_, yazi_buffer_id, _)
					vim.keymap.set("t", "\\", function()
						vim.api.nvim_win_close(0, true)
					end, { buffer = yazi_buffer_id, desc = "Close yazi" })

					vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = yazi_buffer_id })

					vim.keymap.set("n", "<leader>d", function()
						vim.notify("ripdrag is intended for Linux; current platform is MacOS", vim.log.levels.WARN)
					end, { buffer = yazi_buffer_id, desc = "Drag file" })
				end,
				yazi_closed_successfully = function(chosen_file, _, _)
					if chosen_file then
						local buffers = vim.api.nvim_list_bufs()
						for _, buf in ipairs(buffers) do
							local name = vim.api.nvim_buf_get_name(buf)
							if name ~= "" and vim.fn.isdirectory(name) == 1 then
								vim.api.nvim_buf_delete(buf, { force = true })
							end
						end
					end
				end,
			},
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gitsigns = require("gitsigns")
				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, { desc = "Jump to next git [c]hange" })

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, { desc = "Jump to previous git [c]hange" })

				-- Actions
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git [s]tage hunk" })
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git [r]eset hunk" })
				map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
				map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
				map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
				map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
				map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
				map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "git preview hunk [i]nline" })
				map("n", "<leader>hb", function()
					gitsigns.blame_line({ full = true })
				end, { desc = "git [b]lame line" })
				map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
				map("n", "<leader>hD", function()
					gitsigns.diffthis("@")
				end, { desc = "git [D]iff against last commit" })
				map("n", "<leader>hQ", function()
					gitsigns.setqflist("all")
				end, { desc = "git hunk [Q]uickfix list (all files in repo)" })
				map(
					"n",
					"<leader>hq",
					gitsigns.setqflist,
					{ desc = "git hunk [q]uickfix list (all changes in this file)" }
				)
				map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
				map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "[T]oggle git intra-line [w]ord diff" })
				map({ "o", "x" }, "ih", gitsigns.select_hunk)
			end,
		},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPre", "BufNewFile" },
		main = "ibl",
		opts = {},
	},
}
