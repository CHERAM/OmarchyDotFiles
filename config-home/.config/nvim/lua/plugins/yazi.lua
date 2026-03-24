return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>fy", "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
    { "<leader>fY", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
  },
  opts = {
    open_for_directories = true,
  },
}
