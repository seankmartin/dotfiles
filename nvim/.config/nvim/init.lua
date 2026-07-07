-- Enable Vim-style behavior is already Neovim default.

-- Basics
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Save and quit
vim.keymap.set("n", "<leader>w", ":write<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", ":quit<CR>", { desc = "Quit window" })

-- Search
vim.keymap.set("n", "<leader>/", ":nohlsearch<CR>", { desc = "Clear search" })

-- jk leaves insert mode
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Motion helpers
vim.keymap.set("n", "J", "5j", { desc = "Move down 5 lines" })
vim.keymap.set("n", "K", "5k", { desc = "Move up 5 lines" })
vim.keymap.set("n", "<Space>j", "J", { desc = "Join line" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Use Space as leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Leader mappings
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format document" })
vim.keymap.set("n", "<leader>d", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>.", vim.lsp.buf.code_action, { desc = "Code action" })

vim.keymap.set("n", "<leader>e", "$", { desc = "Line end" })
vim.keymap.set("n", "<leader>s", "^", { desc = "First non-blank char" })
vim.keymap.set("n", "<leader>r", "<C-r>", { desc = "Redo" })

-- Buffers
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bb", ":FzfLua buffers<CR>", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>be", ":enew<CR>", { desc = "New empty buffer" })

-- Search clear
vim.keymap.set("n", "<leader>/", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Marks as rough bookmark equivalent
vim.keymap.set("n", "<leader>m", "mM", { desc = "Set mark M" })
vim.keymap.set("n", "<leader>l", "'M", { desc = "Go to mark M" })
vim.keymap.set("n", "<leader>n", "'M", { desc = "Go to mark M" })

-- Select all
vim.keymap.set({ "n", "v" }, "<C-a>", "ggVG", { desc = "Select all" })

-- Visual mode indent/outdent and keep selection
vim.keymap.set("v", ">", ">gv", { desc = "Indent selection" })
vim.keymap.set("v", "<", "<gv", { desc = "Outdent selection" })

-- Paste and reselect
vim.keymap.set("v", "p", "pgvy", { desc = "Paste and reselect" })

-- Text object helper: make d( behave like di(
vim.keymap.set("o", "(", "i(", { desc = "Inside parentheses" })

-- Copy/paste alternatives
vim.keymap.set({ "n", "v" }, "<C-k><C-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<C-k><C-v>", '"+p', { desc = "Paste from system clipboard" })

-- Disable Ctrl-c / Ctrl-v in editor modes if you want Vim behavior
vim.keymap.set({ "n", "i", "v" }, "<C-c>", "<Nop>")
vim.keymap.set({ "n", "i", "v" }, "<C-v>", "<Nop>")

-- Plugins --

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  {
    url = "https://codeberg.org/andyg/leap.nvim",
    dependencies = {
      "tpope/vim-repeat",
    },
    keys = {
      { "s",  "<Plug>(leap-forward)",     mode = { "n", "x", "o" } },
      { "S",  "<Plug>(leap-backward)",    mode = { "n", "x", "o" } },
      { "gs", "<Plug>(leap-from-window)", mode = { "n", "x", "o" } },
    },
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader><leader>",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
    },
  },

  {
    "nvim-mini/mini.surround",
    version = false, -- always use latest
    opts = {},
  },

  {
    "ibhagwan/fzf-lua",
    opts = {},
    keys = {
      {
        "<leader>ff",
        function() require("fzf-lua").files() end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function() require("fzf-lua").live_grep() end,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function() require("fzf-lua").buffers() end,
        desc = "Buffers",
      },
      {
        "<leader>fh",
        function() require("fzf-lua").help_tags() end,
        desc = "Help tags",
      },
    },
  },

})

