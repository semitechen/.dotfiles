return {
  {
    "augustunderground/vim-skill",
    ft = { "skill" },
    build = function()
      -- Fix buggy indent script that causes E749 on empty buffers due to unescaped ||
      local indent_file = vim.fn.stdpath("data") .. "/lazy/vim-skill/indent/skill.vim"
      if vim.fn.filereadable(indent_file) == 1 then
        local lines = vim.fn.readfile(indent_file)
        local changed = false
        for i, line in ipairs(lines) do
          local new_line = line:gsub("&&,||", "&&,\\\\|\\\\|")
          if new_line ~= line then
            lines[i] = new_line
            changed = true
          end
        end
        if changed then
          vim.fn.writefile(lines, indent_file)
        end
      end
    end,
    init = function()
      vim.filetype.add({
        extension = {
          il = "skill",
          ils = "skill",
          cdf = "skill",
          ocn = "skill",
        },
      })
    end,
  },
}
