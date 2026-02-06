-- Configure nvim-lint to use shellcheck and exclude noisy rules for shell files

---@type LazySpec
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      markdown = { "markdownlint-cli2" },
    },
  },
  config = function(_, opts)
    local lint = require "lint"
    lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, opts.linters_by_ft or {})

    -- Pass exclusions via environment to avoid overriding default args
    local existing = vim.env.SHELLCHECK_OPTS or ""
    -- Append exclusions (duplication is harmless for shellcheck)
    vim.env.SHELLCHECK_OPTS = (existing .. " -e SC1090,SC1091"):gsub("%s+", " ")

    -- Force markdownlint-cli2 to use user's home config (disables MD013 globally)
    local md = lint.linters["markdownlint-cli2"]
    if md then
      local cfg = vim.fs.normalize(vim.fn.expand "~/.markdownlint-cli2.jsonc")
      local args = md.args or {}
      local has_config = false
      for i = 1, #args do
        if args[i] == "--config" then
          has_config = true
          break
        end
      end
      if not has_config then md.args = vim.list_extend({ "--config", cfg }, args) end
    end
  end,
}
