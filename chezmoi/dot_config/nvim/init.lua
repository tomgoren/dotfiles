vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/rose-pine/neovim",
  "https://github.com/sainnhe/everforest",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/nvim-mini/mini.comment",
  "https://github.com/nvim-mini/mini.completion",
  "https://github.com/nvim-mini/mini.hipatterns",
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/nvim-mini/mini.keymap",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/nvim-mini/mini.statusline",
  "https://github.com/nvim-mini/mini.surround",
  "https://github.com/tpope/vim-sleuth",
})

vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.completeopt = { "menuone", "noselect", "fuzzy", "popup" }
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.splitright = true
vim.opt.splitbelow = true

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

local pick = require("mini.pick")
pick.setup()
vim.keymap.set("n", "<leader>b", pick.builtin.buffers, { desc = "Select buffer" })
vim.keymap.set("n", "<leader>T", function()
  vim.cmd("vsplit")
  vim.cmd("terminal")
end, { desc = "Open terminal" })
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("botright 15split")
  vim.cmd("terminal")
end, { desc = "Open terminal" })
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })

require("mini.comment").setup()

require("mini.completion").setup()

require("mini.keymap").setup()
local map_multistep = require("mini.keymap").map_multistep

map_multistep("i", "<Tab>", { "pmenu_next" })
map_multistep("i", "<S-Tab>", { "pmenu_prev" })
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
map_multistep("i", "<BS>", { "minipairs_bs" })

require("mini.pairs").setup({
  mappings = {
    ["("] = { neigh_pattern = "^[^\\][^%w_]" },
  },
})

require("mini.surround").setup()

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

local treesitter_parsers = { "hcl", "terraform" }

require("nvim-treesitter").setup()

-- `.tfvars` files get their own filetype but share the terraform grammar
vim.treesitter.language.register("terraform", "terraform-vars")

if #vim.api.nvim_list_uis() > 0 then
  -- No-op for parsers that are already installed
  require("nvim-treesitter").install(treesitter_parsers)
end

-- No language server validates plain `.hcl`: terraform-ls only checks files in a
-- terraform module and terragrunt-ls reports no diagnostics at all. Shell out to
-- terragrunt when it is available, and fall back to tree-sitter parse errors.
local hcl_diagnostics_ns = vim.api.nvim_create_namespace("hcl_diagnostics")

local function publish_syntax_diagnostics(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or parser == nil then
    return
  end

  local query = vim.treesitter.query.parse(parser:lang(), "(ERROR) @error")
  local diagnostics = {}

  for _, tree in ipairs(parser:parse() or {}) do
    for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
      local lnum, col, end_lnum, end_col = node:range()
      table.insert(diagnostics, {
        lnum = lnum,
        col = col,
        end_lnum = end_lnum,
        end_col = end_col,
        severity = vim.diagnostic.severity.ERROR,
        source = "treesitter",
        message = "Syntax error",
      })
    end
  end

  vim.diagnostic.set(hcl_diagnostics_ns, buf, diagnostics)
end

-- `terragrunt hcl validate` reads from disk and follows the include chain, so it
-- also reports problems in parent configs that this buffer cannot display
local function publish_terragrunt_diagnostics(buf, entries)
  local file = vim.api.nvim_buf_get_name(buf)
  local diagnostics = {}
  local elsewhere = {}

  for _, entry in ipairs(entries) do
    local range = entry.range
    if type(range) == "table" and range.start ~= nil and range["end"] ~= nil then
      local message = entry.summary or "Validation error"
      if entry.detail ~= nil then
        message = message .. ": " .. entry.detail
      end

      if range.filename == file then
        table.insert(diagnostics, {
          lnum = range.start.line - 1,
          col = range.start.column - 1,
          end_lnum = range["end"].line - 1,
          end_col = range["end"].column - 1,
          severity = entry.severity == "warning" and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
          source = "terragrunt",
          message = message,
        })
      else
        table.insert(elsewhere, vim.fs.basename(range.filename or "?") .. ":" .. range.start.line .. " " .. message)
      end
    end
  end

  vim.diagnostic.set(hcl_diagnostics_ns, buf, diagnostics)

  if #elsewhere > 0 then
    vim.notify("terragrunt: " .. table.concat(elsewhere, "\n"), vim.log.levels.WARN)
  end
end

local function validate_hcl(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.fn.executable("terragrunt") == 0 then
    publish_syntax_diagnostics(buf)
    return
  end

  local command = {
    "terragrunt",
    "hcl",
    "validate",
    "--json",
    "--no-color",
    "--log-level",
    "error",
    "--working-dir",
    vim.fs.dirname(file),
  }

  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local stdout = vim.trim(result.stdout or "")
      if stdout == "" then
        -- Nothing to report: terragrunt only prints JSON when it finds problems
        vim.diagnostic.reset(hcl_diagnostics_ns, buf)
        return
      end

      local ok, entries = pcall(vim.json.decode, stdout)
      if not ok or type(entries) ~= "table" then
        vim.notify("terragrunt: could not parse validation output", vim.log.levels.WARN)
        return
      end

      publish_terragrunt_diagnostics(buf, entries)
    end)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "hcl", "terraform", "terraform-vars" },
  callback = function(event)
    local ok, err = pcall(vim.treesitter.start, event.buf)
    if not ok then
      vim.notify("Tree-sitter highlighting unavailable: " .. err, vim.log.levels.WARN)
      return
    end

    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Only plain `.hcl`: terraform-ls and tflint already cover terraform filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = "hcl",
  callback = function(event)
    validate_hcl(event.buf)
    vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = event.buf,
      callback = function()
        validate_hcl(event.buf)
      end,
    })
  end,
})

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

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
    },
  },
})

vim.lsp.config("terraformls", {
  settings = {
    terraform = {
      validation = { enableEnhancedValidation = true },
    },
  },
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(event)
    vim.lsp.buf.format({
      bufnr = event.buf,
      filter = function(client)
        return client.name == "gopls"
      end,
    })
  end,
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
    map("<leader>tf", function()
      vim.lsp.buf.format({
        bufnr = event.buf,
        filter = function(client)
          return client.name == "terraformls"
        end,
      })
    end, "Terraform: format buffer")
  end,
})

local mason_packages = {
  "bashls",
  "gopls",
  "jsonls",
  "lua_ls",
  "pyright",
  "terraformls",
  "terragrunt_ls",
  "tflint",
  "ts_ls",
  "yamlls",
}

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = mason_packages,
  automatic_enable = { exclude = { "basedpyright" } },
})
require("mason-tool-installer").setup({
  ensure_installed = mason_packages,
  auto_update = true,
  run_on_start = #vim.api.nvim_list_uis() > 0,
  debounce_hours = 24,
})
