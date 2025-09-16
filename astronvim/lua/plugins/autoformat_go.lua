-- Enable format-on-save only for Go files

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    formatting = {
      format_on_save = {
        enabled = true,
        -- Only autoformat Go files on save
        allow_filetypes = { "go" },
      },
    },
  },
}

