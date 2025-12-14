-- dotfiles/nvim options — keep LazyVim aligned with legacy .vimrc defaults

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true

opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

opt.clipboard = "unnamedplus"
opt.list = true
opt.listchars = { tab = "▸ ", trail = "·", extends = "»", precedes = "«", nbsp = "%" }

opt.backspace = { "indent", "eol", "start" }
opt.termguicolors = true
