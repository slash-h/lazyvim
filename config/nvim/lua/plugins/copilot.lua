-- currently we don't want Co-pilot since Windsurf is being used, so don't actually load anything here and return an empty spec
-- stylua: ignore
if true then return {} end

return {
  "zbirenbaum/copilot.lua",
  opts = {
    suggestion = {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      hide_during_completion = vim.g.ai_cmp,
      keymap = {
        accept = false, -- handled by nvim-cmp / blink.cmp
        next = "<M-]>",
        prev = "<M-[>",
      },
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}
