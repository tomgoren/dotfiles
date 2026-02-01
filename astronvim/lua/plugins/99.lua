return {
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require "99"
      _99.setup({
        completion = {
          source = "cmp",
        },
        md_files = {
          "AGENT.md",
          "AGENTS.md",
        },
      })

      vim.keymap.set("n", "<leader>9f", function()
        _99.fill_in_function()
      end, { desc = "99 fill function" })

      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "99 visual" })

      vim.keymap.set("v", "<leader>9s", function()
        _99.stop_all_requests()
      end, { desc = "99 stop requests" })
    end,
  },
}
