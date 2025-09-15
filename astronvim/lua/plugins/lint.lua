-- Configure nvim-lint to use shellcheck and exclude noisy rules for shell files

---@type LazySpec
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
    },
  },
  config = function(_, opts)
    local lint = require "lint"
    lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, opts.linters_by_ft or {})

    -- Pass exclusions via environment to avoid overriding default args
    local existing = vim.env.SHELLCHECK_OPTS or ""
    -- Append exclusions (duplication is harmless for shellcheck)
    vim.env.SHELLCHECK_OPTS = (existing .. " -e SC1090,SC1091"):gsub("%s+", " ")

    -- Ensure markdownlint ignores the line-length rule (MD013)
    -- Point markdownlint to a shared config in this dotfiles repo
    local md_cfg = vim.fn.expand("$HOME/dev/dotfiles/.markdownlint.json")
    if (vim.env.MARKDOWNLINT_CONFIG or "") == "" and md_cfg and md_cfg ~= "" then
      vim.env.MARKDOWNLINT_CONFIG = md_cfg
    end
  end,
}
