-- Treesitter parsers

-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "go",
      "gomod",
      "gosum",
      "gowork",
      "python",
      "rust",
      "yaml",
      "bash",
      "toml",
      -- add more arguments for adding more treesitter parsers
    },
  },
}
