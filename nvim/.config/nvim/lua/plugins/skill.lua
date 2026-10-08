return {
  {
    "augustunderground/vim-skill",
    ft = { "skill" },
    build = function()
      -- Fix buggy indent script that causes E749 on empty buffers due to unescaped ||
      local indent_file = vim.fn.stdpath("data") .. "/lazy/vim-skill/indent/skill.vim"
      if vim.fn.filereadable(indent_file) == 1 then
        os.execute("sed -i '' 's/setlocal lispwords+=\\(.*\\)&&,||/setlocal lispwords+=\\1\\&\\&,\\\\|\\\\|/' " .. indent_file)
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
