-- Leader（要放最前）
vim.g.mapleader = ","
vim.g.maplocalleader = ","

local map = vim.keymap.set

-- 基础编辑体验
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.hlsearch = true
vim.opt.termguicolors = true     -- 直接拥抱真彩色，省心
vim.opt.background = "light"     -- 你是浅色
-- 让 y/p/d 等默认走系统剪贴板（等价于 set clipboard=unnamedplus）
vim.opt.clipboard = "unnamedplus"

-- 输入法：离开插入模式切回 ABC（有 im-select 才启用）
if vim.fn.executable("im-select") == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      pcall(vim.fn.system, { "im-select", "com.apple.keylayout.ABC" })
    end,
  })
end

-- 安装 lazy.nvim（如果没有就自动装）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 插件：就三个，够用且稳定
require("lazy").setup({
  { "tpope/vim-surround" },

  -- 选一个“浅色也舒服”的主题（推荐这个，观感清晰，Visual 也明显）
  -- { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = { style = "day" } },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000, opts = { style = "day" } },
})

-- 启用主题
-- vim.cmd.colorscheme("tokyonight-day")
vim.cmd.colorscheme("gruvbox")

-- 你的段落包裹：需要 remap 才能触发 surround 的 ys
map("n", "<leader>p", "ysip<p>", { silent = true, remap = true })

-- 延时退出插入模式的 timer
local exit_insert_timer = nil

vim.api.nvim_create_augroup("focus_lost_actions", { clear = true })

vim.api.nvim_create_autocmd("FocusLost", {
  group = "focus_lost_actions",
  callback = function()
    -- 只在插入/替换模式时启动延时
    local m = vim.fn.mode()
    if m == "i" or m == "R" or m == "Rv" then
      -- 如果已经有等待中的 timer，先取消
      if exit_insert_timer then
        vim.fn.timer_stop(exit_insert_timer)
      end

      -- 设置 1 分钟后执行：退出插入模式 + 保存 + 切换输入法
      exit_insert_timer = vim.fn.timer_start(6000, function()
        -- 1) 退出插入模式
        vim.cmd("stopinsert")

        -- 2) 保存文件
        vim.cmd("silent! update")

        -- 3) 切换输入法到英文
        if vim.fn.executable("im-select") == 1 then
          pcall(vim.fn.system, { "im-select", "com.apple.keylayout.ABC" })
        end

        exit_insert_timer = nil
      end)
    else
      -- 如果不在插入模式，立即保存（但不切换输入法）
      vim.cmd("silent! update")
    end
  end,
})

-- 获得焦点时，智能处理
vim.api.nvim_create_autocmd("FocusGained", {
  group = "focus_lost_actions",
  callback = function()
    -- 如果有等待中的 timer，取消它
    if exit_insert_timer then
      vim.fn.timer_stop(exit_insert_timer)
      exit_insert_timer = nil
    end

    -- 检查当前模式
    local m = vim.fn.mode()

    -- 如果在 normal mode 或 visual mode，切换到英文输入法
    if m == "n" or m == "no" or m == "v" or m == "V" then
      if vim.fn.executable("im-select") == 1 then
        pcall(vim.fn.system, { "im-select", "com.apple.keylayout.ABC" })
      end
    end
    -- 如果在插入模式，不做任何操作（保持当前输入法）
  end,
})

-- 🔧 确保焦点事件不被忽略
vim.opt.eventignore:remove("FocusGained")
vim.opt.eventignore:remove("FocusLost")

-- 只在启动 Neovim 时切回英文输入法
if vim.fn.executable("im-select") == 1 then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      pcall(vim.fn.system, { "im-select", "com.apple.keylayout.ABC" })
    end,
  })
end




-- 让 nvim 背景透明（配合终端透明）
vim.opt.termguicolors = true

local function transparent()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "FoldColumn",
    "EndOfBuffer",
    "MsgArea",
  }
  for _, g in ipairs(groups) do
    vim.api.nvim_set_hl(0, g, { bg = "NONE" })
  end
end

-- 如果你是启动时就设定 colorscheme：
-- vim.cmd.colorscheme("gruvbox")
transparent()

-- 如果你会切换 colorscheme，建议再加个自动重应用：
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = transparent,
})

