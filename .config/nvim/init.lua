-- Leader（要放最前）
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- move visual line
vim.keymap.set("n", "J", "gj", { noremap = true, silent = true })
vim.keymap.set("n", "K", "gk", { noremap = true, silent = true })
-- vic, vac 选中 Markdown 代码块
map('x', 'ic', '<Esc>?^```<CR>jV/^```<CR>k', { desc = "Select inner markdown code block", silent = true })
map('x', 'ac', '<Esc>?^```<CR>V/^```<CR>', { desc = "Select around markdown code block", silent = true })

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
-- 禁用 unnamedplus, 不让 y/p/d 等默认走系统剪贴板, 避免污染 nvim 自己的寄存器体系，手动通过 OSC52 同步到本地系统剪贴板，remote 环境友好
-- vim.opt.clipboard = "unnamedplus"

-- 显示字符数：普通模式显示全文件 chars；可视模式显示选中区域 visual_chars
vim.o.statusline = (vim.o.statusline ~= "" and vim.o.statusline or "%f%m%r%h%w%=%-14.(%l,%c%V%) %P")
  .. "  %{mode()=~#'^[vV\\]' ? wordcount().visual_chars.' sel' : wordcount().chars.'c'}"


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
  {
    "kylechui/nvim-surround",
    version = "*",
    config = function()
      require("nvim-surround").setup({
        indent_lines = false,  -- 禁用自动缩进
      })

      -- visual mode: 用 <p> 标签包裹选中内容
      -- S (surround) -> t (tag) -> p (标签名) -> CR (确认)
      vim.keymap.set("v", "<leader>t", "St<p><CR>", { silent = false, remap = true, desc = "Wrap with <p> tag" })
    end,
  },

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

      -- TypeScript/JavaScript Language Server
      vim.lsp.config('ts_ls', {
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
        root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
      })

      -- 为所有 LSP 设置快捷键
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client then
            local opts = { buffer = bufnr }
            -- 跳转定义
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            -- 跳转到类型定义
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

      -- 启用 LSP
      vim.lsp.enable('gopls')
      vim.lsp.enable('ts_ls')
    end,
  },

  -- 用于剪贴板传递，兼容本地/远程环境
  {
    "ojroques/nvim-osc52",
    config = function()
      local osc52 = require("osc52")

      osc52.setup({
        max_length = 0,      -- 0 = 不限（但终端可能有限制）
        silent = false,
        trim = false,
      })

      -- visual mode: <leader>y 把选区复制到「本地」剪贴板
      vim.keymap.set("v", "<leader>y", function()
        osc52.copy_visual()
      end, { desc = "OSC52 yank (visual)" })

      -- normal mode: <leader>yy 复制当前行到「本地」剪贴板
      vim.keymap.set("n", "<leader>yy", function()
        vim.cmd("normal! yy")                 -- 保持 nvim 内部寄存器正常（p 仍可用）
        require("osc52").copy_register('"')   -- 把匿名寄存器内容同步到本地剪贴板
      end, { desc = "Yank line + OSC52 sync" })

      -- visual mode: <leader>d 删除选区并复制到系统剪贴板
      vim.keymap.set("v", "<leader>d", function()
        vim.cmd('normal! d')  -- 删除选区（进入匿名寄存器）
        require("osc52").copy_register('"')  -- 同步到系统剪贴板
      end, { desc = "Delete and OSC52 copy (visual)" })

      -- normal mode: <leader>dd 删除当前行并复制到系统剪贴板
      vim.keymap.set("n", "<leader>dd", function()
        vim.cmd("normal! dd")                 -- 删除当前行（进入匿名寄存器）
        require("osc52").copy_register('"')   -- 同步到系统剪贴板
      end, { desc = "Delete line + OSC52 sync" })

    end,
  },

  -- Advanced motion, 基于关键词的跳转
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- 支持中文（拼音加加双拼）跳转
  {
    "kanlac/flash-zh.nvim",
    dependencies = { "folke/flash.nvim" },
    opts = { scheme = "pyjj" },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash-zh").jump({ chinese_only = false }) end, desc = "Flash between Chinese" },
      { "r", mode = "o", function() require("flash-zh").remote({ chinese_only = false }) end, desc = "Remote Flash between Chinese" },
    },
  },

})

-- 启用主题
-- vim.cmd.colorscheme("tokyonight-day")
vim.cmd.colorscheme("gruvbox")

-- fzf-lua 快捷键
map("n", "<leader>ff", "<cmd>lua require('fzf-lua').files()<CR>", { desc = "查找文件" })
map("n", "<leader>fg", "<cmd>lua require('fzf-lua').live_grep()<CR>", { desc = "全局搜索" })
map("n", "<leader>fb", "<cmd>lua require('fzf-lua').buffers()<CR>", { desc = "查找 Buffer" })
map("n", "<leader>fh", "<cmd>lua require('fzf-lua').help_tags()<CR>", { desc = "查找帮助" })
map("n", "<leader>fo", "<cmd>lua require('fzf-lua').oldfiles()<CR>", { desc = "最近文件" })

-- yank path 目录拷贝快捷键
vim.keymap.set("n", "<leader>yp", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()            -- 注意：会返回“当前窗口的 cwd”，所以跟 lcd 对齐
  local rel = vim.fs.relpath(cwd, file)  -- 相对 cwd 的路径

  if not rel then
    rel = file -- 不在 cwd 下就退回绝对路径
  end

  vim.fn.setreg("+", rel)
  vim.notify("Yanked path: " .. rel)
end, { desc = "Yank path relative to (l)cd" })

vim.keymap.set("n", "<leader>tt", function()
  -- 在下一行新开一行（等价于按 o），光标移动到新行并进入 insert
  vim.cmd("normal! o")
  -- 在新行插入时间（此时光标已在新行）
  vim.api.nvim_put({ os.date("%H:%M") .. " " }, "c", true, true)
  vim.cmd("startinsert!")
end, { desc = "Insert time and enter insert mode" })

-- 延时自动保存的 timer（FocusLost 和 InsertLeave 共用）
local autosave_timer = nil

-- 启动延时保存（1m 后保存）
-- exit_insert: 是否在保存前先退出插入模式
local function start_autosave_timer(exit_insert)
  if autosave_timer then
    vim.fn.timer_stop(autosave_timer)
  end
  autosave_timer = vim.fn.timer_start(60000, function()
    if exit_insert then
      local m = vim.fn.mode()
      if m == "i" or m == "R" or m == "Rv" then
        vim.cmd("stopinsert")
      end
    end
    vim.cmd("silent! update")
    autosave_timer = nil
  end)
end

-- 取消延时保存
local function cancel_autosave_timer()
  if autosave_timer then
    vim.fn.timer_stop(autosave_timer)
    autosave_timer = nil
  end
end

vim.api.nvim_create_augroup("focus_lost_actions", { clear = true })

vim.api.nvim_create_autocmd("FocusLost", {
  group = "focus_lost_actions",
  callback = function()
    start_autosave_timer(true)  -- 延时退出插入 + 保存
  end,
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = "focus_lost_actions",
  callback = function()
    cancel_autosave_timer()
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = "focus_lost_actions",
  callback = function()
    -- 启动延时保存（不退出插入，因为已经退出了）
    start_autosave_timer(false)
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = "focus_lost_actions",
  callback = function()
    cancel_autosave_timer()
  end,
})

-- 🔧 确保焦点事件不被忽略
vim.opt.eventignore:remove("FocusGained")
vim.opt.eventignore:remove("FocusLost")

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

-- 替换/搜索执行后自动取消高亮（不影响你下一次 / 搜索时继续高亮）
vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = ":",
  callback = function()
    -- 防抖：避免在某些情况下闪烁
    vim.schedule(function()
      vim.cmd("nohlsearch")
    end)
  end,
})
