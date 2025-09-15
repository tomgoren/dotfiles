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
  end,
}

