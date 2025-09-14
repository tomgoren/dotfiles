-- Mason configuration and auto-install of tools

-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        "gopls",
        "pyright",
        "rust-analyzer",
        "yaml-language-server",
        "bash-language-server",

        -- install formatters
        "stylua",
        "gofumpt",
        "golines",
        "goimports",
        "black",
        "isort",
        "ruff",
        "yamlfmt",
        "shfmt",

        -- install debuggers
        "debugpy",
        "delve",
        "codelldb",

        -- install any other package
        "tree-sitter-cli",
        "staticcheck",
        "shellcheck",
        "taplo",
      },
    },
  },
}
