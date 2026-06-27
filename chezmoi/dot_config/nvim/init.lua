vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/rose-pine/neovim",
  "https://github.com/sainnhe/everforest",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/nvim-mini/mini.comment",
  "https://github.com/nvim-mini/mini.completion",
  "https://github.com/nvim-mini/mini.hipatterns",
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/nvim-mini/mini.keymap",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/nvim-mini/mini.statusline",
  "https://github.com/tpope/vim-sleuth",
})

vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.completeopt = { "menuone", "noselect", "fuzzy", "popup" }
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

require("tokyonight").setup({
  style = "night",
  styles = { comments = { italic = true }, keywords = { italic = false } },
})

require("catppuccin").setup({
  flavour = "mocha",
  styles = { comments = { "italic" }, conditionals = {}, keywords = {} },
})

require("kanagawa").setup({
  commentStyle = { italic = true },
  keywordStyle = { italic = false },
})

require("rose-pine").setup({
  styles = { italic = true },
})

vim.g.everforest_enable_italic = true

-- Try: tokyonight, kanagawa, rose-pine, catppuccin, everforest
vim.cmd.colorscheme("tokyonight")

require("mini.icons").setup()
MiniIcons.tweak_lsp_kind()

require("mini.comment").setup()

require("mini.completion").setup()

require("mini.keymap").setup()
local map_multistep = require("mini.keymap").map_multistep

map_multistep("i", "<Tab>", { "pmenu_next" })
map_multistep("i", "<S-Tab>", { "pmenu_prev" })
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
map_multistep("i", "<BS>", { "minipairs_bs" })

require("mini.pairs").setup()

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = {
    -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
    todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
    note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

    -- Highlight hex color strings (`#rrggbb`) using that color
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

require("mini.indentscope").setup()

require("mini.statusline").setup()

vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim", "MiniCompletion", "MiniIcons" } },
      telemetry = { enable = false },
      workspace = { checkThirdParty = false },
    },
  },
})

local function goto_first_definition()
  vim.lsp.buf.definition({
    reuse_win = true,
    on_list = function(options)
      local items = {}
      local seen = {}

      for _, item in ipairs(options.items) do
        local key = table.concat({ item.filename, item.lnum, item.col }, ":")
        if not seen[key] then
          seen[key] = true
          table.insert(items, item)
        end
      end

      if #items == 0 then
        vim.notify("No definition found", vim.log.levels.INFO)
        return
      end

      vim.fn.setqflist({}, " ", { title = options.title, items = items })
      vim.cmd("silent! cfirst")
      vim.cmd("cclose")
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
    end

    map("K", vim.lsp.buf.hover, "LSP hover")
    map("gd", goto_first_definition, "LSP definition")
    map("gD", vim.lsp.buf.declaration, "LSP declaration")
    map("gi", vim.lsp.buf.implementation, "LSP implementation")
    map("gr", vim.lsp.buf.references, "LSP references")
    map("<C-k>", vim.lsp.buf.signature_help, "LSP signature help")
    map("<leader>rn", vim.lsp.buf.rename, "LSP rename")
    map("<leader>ca", vim.lsp.buf.code_action, "LSP code action")
    map("[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, "Previous diagnostic")
    map("]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")
    map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
  end,
})

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "bashls",
    "gopls",
    "jsonls",
    "lua_ls",
    "pyright",
    "ts_ls",
    "yamlls",
  },
  automatic_enable = { exclude = { "basedpyright" } },
})
