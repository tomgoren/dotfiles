---@type LazySpec
return {
  {
    "nickjvandyke/opencode.nvim",
    dependencies = {
      {
        "folke/snacks.nvim",
        opts = { input = {}, picker = {}, terminal = {} },
      },
    },
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>oa", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Opencode ask" })

      vim.keymap.set({ "n", "x" }, "<leader>oo", function()
        require("opencode").select()
      end, { desc = "Opencode select" })

      vim.keymap.set({ "n", "t" }, "<leader>ot", function()
        require("opencode").toggle()
      end, { desc = "Opencode toggle" })

    end,
  },
}
