-- currently we don't want GO, so don't actually load anything here and return an empty spec
-- stylua: ignore
if true then return {} end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      if not opts.servers then
        opts.servers = {}
      end
      opts.servers.gopls = {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            usePlaceholders = true,
            completeUnimported = true, -- This enables auto-import
            gofumpt = true,
          },
        },
      }
      return opts
    end,
  },
}
