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
vim.opt.termguicolors = true     -- 真彩色, 配合终端透明背景
vim.opt.background = "light"     -- 你是浅色
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- 让 y/p/d 等默认走系统剪贴板（等价于 set clipboard=unnamedplus）
vim.opt.clipboard = "unnamedplus"

-- 显示字符数：普通模式显示全文件 chars；可视模式显示选中区域 visual_chars
vim.o.statusline = (vim.o.statusline ~= "" and vim.o.statusline or "%f%m%r%h%w%=%-14.(%l,%c%V%) %P")
  .. "  %{mode()=~#'^[vV\\]' ? wordcount().visual_chars.' sel' : wordcount().chars.'c'}"


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

require("lazy").setup({
  { "tpope/vim-surround" },

  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000, opts = { style = "day" } },

  -- fzf-lua：模糊查找工具
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        -- 全局配置
        winopts = {
          height = 0.85,
          width = 0.80,
          preview = {
            layout = "vertical",
            vertical = "down:50%",
          },
        },
        -- 文件查找配置
        files = {
          -- 使用 fd（更快，支持软链接）
          -- --no-ignore-vcs: 忽略 .gitignore 规则，这样软链接目录即使在 .gitignore 中也能被搜索
          cmd = "fd --type f --follow --hidden --no-ignore-vcs --exclude .git --exclude node_modules --exclude .next --exclude dist --exclude build --exclude .cache --exclude vendor --exclude .venv --exclude __pycache__",
          -- 备选方案（如果没有 fd）
          -- cmd = "rg --files --follow --hidden --glob '!.git'",
          -- cmd = "find -L . -type f 2>/dev/null | sed 's#^./##'",
        },
        -- 文本搜索配置
        grep = {
          -- 跟随软链接，并排除常见目录
          -- --no-ignore-vcs: 忽略 .gitignore 规则，这样软链接目录即使在 .gitignore 中也能被搜索
          rg_opts = "--follow --hidden --no-ignore-vcs --column --line-number --no-heading --color=always --smart-case " ..
                    "--glob=!.git/ --glob=!node_modules/ --glob=!.next/ --glob=!dist/ --glob=!build/ " ..
                    "--glob=!.cache/ --glob=!vendor/ --glob=!.venv/ --glob=!__pycache__/ " ..
                    "--glob=!*.min.js --glob=!*.min.css",
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      -- 使用新的 vim.lsp.config API（Neovim 0.11+）
      vim.lsp.config('gopls', {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = {
          gopls = {
            staticcheck = true,
          },
        },
      })

      -- 为 Go 文件设置 LSP 快捷键
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          -- 只为 gopls 设置快捷键
          if client and client.name == 'gopls' then
            local opts = { buffer = bufnr }
            -- 跳转定义
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            -- 跳转到类型定义（Go 中更有用）
            vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)
            -- 查看引用
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            -- 悬浮文档
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            -- 重命名
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          end
        end,
      })

      -- 启用 gopls（会在打开 Go 文件时自动启动）
      vim.lsp.enable('gopls')
    end,
  },
})

-- 启用主题
-- vim.cmd.colorscheme("tokyonight-day")
vim.cmd.colorscheme("gruvbox")

-- 你的段落包裹：需要 remap 才能触发 surround 的 ys
map("n", "<leader>p", "ysip<p>", { silent = true, remap = true })

-- fzf-lua 快捷键
map("n", "<leader>ff", "<cmd>lua require('fzf-lua').files()<CR>", { desc = "查找文件" })
map("n", "<leader>fg", "<cmd>lua require('fzf-lua').live_grep()<CR>", { desc = "全局搜索" })
map("n", "<leader>fb", "<cmd>lua require('fzf-lua').buffers()<CR>", { desc = "查找 Buffer" })
map("n", "<leader>fh", "<cmd>lua require('fzf-lua').help_tags()<CR>", { desc = "查找帮助" })
map("n", "<leader>fo", "<cmd>lua require('fzf-lua').oldfiles()<CR>", { desc = "最近文件" })

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

--------------- file autoupdate ----------------

-- 10s 触发 CursorHold / CursorHoldI（单位：毫秒）
vim.opt.updatetime = 10000

-- 外部修改时：buffer 干净(未修改)就自动 reload
vim.opt.autoread = true

-- 这些时机去检查“磁盘上的文件是否变了”
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    -- checktime 会触发文件时间戳检查；
    -- 配合 autoread：未修改的 buffer 会自动重载
    vim.cmd("checktime")
  end,
})

-- 可选：reload 发生后给个提示（不想提示就删掉这一段）
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("File changed on disk, reloaded.", vim.log.levels.INFO)
  end,
})

-- 可选：如果你的 buffer 有未保存修改，磁盘文件又变了，给更明显提示
vim.api.nvim_create_autocmd("FileChangedShell", {
  callback = function()
    if vim.bo.modified then
      vim.notify("File changed on disk, but you have unsaved changes (not reloaded).", vim.log.levels.WARN)
    end
  end,
})

------------------------------------------------
