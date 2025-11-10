return { --colorizer
  'norcalli/nvim-colorizer.lua',
  config = function()
    require('colorizer').setup({
      '*', -- Enable for all filetypes
    }, {
      RGB = true,
      RRGGBB = true,
      RRGGBBAA = true,
      rgb_fn = true,
      hsl_fn = true,
      css = true,
      names = false,
    })
  end,
}
