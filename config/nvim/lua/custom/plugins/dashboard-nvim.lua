return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    -- Disable indent lines for dashboard
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'dashboard',
      callback = function()
        vim.opt_local.colorcolumn = ''
        vim.opt_local.foldcolumn = '0'
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
        -- Disable indent-blankline for dashboard
        if vim.g.loaded_indent_blankline then
          vim.cmd 'IndentBlanklineDisable'
        end
        -- Disable ibl (newer version of indent-blankline)
        local ok, ibl = pcall(require, 'ibl')
        if ok then
          ibl.setup_buffer(0, { enabled = false })
        end
      end,
    })

    require('dashboard').setup {
      theme = 'doom',
      disable_move = true,
      config = {
        header = {

          '                                                                       ',
          '                                                                       ',
          '                                                                       ',
          '                                                                       ',
          '                                                                     ',
          '       ███████████           █████      ██                     ',
          '      ███████████             █████                             ',
          '      ████████████████ ███████████ ███   ███████     ',
          '     ████████████████ ████████████ █████ ██████████████   ',
          '    ██████████████    █████████████ █████ █████ ████ █████   ',
          '  ██████████████████████████████████ █████ █████ ████ █████  ',
          ' ██████  ███ █████████████████ ████ █████ █████ ████ ██████ ',
          '                                                                       ',
          '                                                                       ',
          '                                                                       ',
          '                                                                       ',
          '                                                                       ',
          -- '',
          -- '',
          -- '██╗  ██╗██╗ ██████╗██╗  ██╗███████╗████████╗ █████╗ ██████╗ ████████╗',
          -- '██║ ██╔╝██║██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝',
          -- '█████╔╝ ██║██║     █████╔╝ ███████╗   ██║   ███████║██████╔╝   ██║   ',
          -- '██╔═██╗ ██║██║     ██╔═██╗ ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ',
          -- '██║  ██╗██║╚██████╗██║  ██╗███████║   ██║   ██║  ██║██║  ██║   ██║   ',
          -- '╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ',
          -- '',
          -- '███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
          -- '████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
          -- '██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║',
          -- '██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
          -- '██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
          -- '╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
          -- '',
          -- '',
          -- '                                                                                 ',
          -- '                                                                                 ',
          -- '  =================     ===============     ===============   ========  ========',
          -- '  \\\\ . . . . . . .\\\\   //. . . . . . .\\\\   //. . . . . . .\\\\  \\\\. . .\\\\// . . //',
          -- '  ||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\\/ . . .||',
          -- '  || . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||',
          -- '  ||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||',
          -- '  || . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\\ . . . . ||',
          -- "  ||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\\_ . .|. .||",
          -- '  || . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\\ `-_/| . ||',
          -- "  ||_-' ||  .|/    || ||    \\|.  || `-_|| ||_-' ||  .|/    || ||   | \\  / |-_.||",
          -- "  ||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \\  / |  `||",
          -- "  ||    `'         || ||         `'    || ||    `'         || ||   | \\  / |   ||",
          -- "  ||            .===' `===.         .==='.`===.         .===' /==. |  \\/  |   ||",
          -- "  ||         .=='   \\_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \\/  |   ||",
          -- "  ||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \\/  |   ||",
          -- "  ||   .=='    _-'          '-__\\._-'         '-_./__-'         `' |. /|  |   ||",
          -- "  ||.=='    _-'                                                     `' |  /==.||",
          -- "  =='    _-'                        N E O V I M                         \\/   `==",
          -- "  \\   _-'                                                                `-_   /",
          -- "  `''                                                                      ``'   ",
          -- '                                                                                 ',
          -- '                                                                                 ',
        },

        center = {
          {
            icon = '󰈞  ',
            icon_hl = 'Title',
            desc = 'Find File           ',
            desc_hl = 'String',
            key = 'f',
            keymap = 'Space sf',
            key_hl = 'Number',
            action = 'lua require("telescope.builtin").find_files()',
          },
          {
            icon = '󰈚  ',
            icon_hl = 'Title',
            desc = 'Recent Files        ',
            desc_hl = 'String',
            key = 'r',
            keymap = 'Space sr',
            key_hl = 'Number',
            action = 'lua require("telescope.builtin").oldfiles()',
          },
          {
            icon = '  ',
            icon_hl = 'Title',
            desc = 'Neovim Configuration       ',
            desc_hl = 'String',
            key = 'c',
            keymap = 'Space sc',
            key_hl = 'Number',
            action = 'lua require("telescope.builtin").find_files({cwd = vim.fn.stdpath("config")})',
          },
          {
            icon = '  ',
            icon_hl = 'Title',
            desc = 'Colorscheme         ',
            desc_hl = 'String',
            key = 't',
            keymap = 'Space st',
            key_hl = 'Number',
            action = 'lua require("telescope.builtin").colorscheme()',
          },
          {
            icon = '  ',
            icon_hl = 'Title',
            desc = 'Keymaps             ',
            desc_hl = 'String',
            key = 'k',
            keymap = 'Space sk',
            key_hl = 'Number',
            action = 'lua require("telescope.builtin").keymaps()',
          },
          {
            icon = '󰈆  ',
            icon_hl = 'Title',
            desc = 'Quit Neovim         ',
            desc_hl = 'String',
            key = 'q',
            keymap = 'Space q',
            key_hl = 'Number',
            action = 'qa',
          },
        },

        footer = {
          -- '',
          -- '',
          -- '════════════════════════════════════════════════════════════════════════════════════════════',
          -- '',
          -- 'Sharp tools make faster work ',
          -- '',
          -- '════════════════════════════════════════════════════════════════════════════════════════════',
          -- '',
          -- '  Welcome to your development environment - Press any key to continue  ',
          -- '',
        },
        vertical_center = true,
      },
      hide = {
        statusline = true,
        tabline = true,
        winbar = true,
      },
      preview = {
        command = '',
        file_path = '',
        file_height = 12,
        file_width = 80,
      },
    }
  end,
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}
