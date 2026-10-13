-- LSP 与诊断信息

-- 默认关闭诊断信息
vim.diagnostic.enable(false)

-- 打开诊断后的显示方式：Neovim 0.11 起默认不显示行尾诊断文字，
-- 只有波浪线和标志列。这里改为只在光标所在行下方展开诊断内容，
-- 不会满屏都是；其他行仍只显示波浪线和标志列。
vim.diagnostic.config({
  virtual_lines = { current_line = true },
})

-- <leader>ul 切换诊断信息
vim.keymap.set("n", "<leader>ul", function()
  local enabled = vim.diagnostic.is_enabled()

  vim.diagnostic.enable(not enabled)

  vim.notify(
    "LSP diagnostics " .. (not enabled and "enabled" or "disabled"),
    vim.log.levels.INFO
  )
end, {
  desc = "Toggle LSP diagnostics",
})

-- 悬浮窗显示当前行诊断信息
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { noremap = true, silent = true, desc = "Line diagnostics" })

-- LSP 附加到缓冲区后设置代码导航快捷键。
-- 这些按键只在当前缓冲区有 LSP 时生效，避免覆盖普通文本缓冲区的行为。
--
-- Neovim 内置（无需配置）：
--   K    悬浮文档          grn  重命名          gra  代码操作（含 ruff 整理 import）
--   grr  查找引用          gri  跳到实现        grt  跳到类型定义
--   gO   文档符号          <C-s>（插入模式）函数签名
-- 不要再单独映射 gr：它会和上面的 gr* 冲突，按 gr 要等 timeoutlen 才生效。
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Set LSP navigation keymaps",
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition,
      vim.tbl_extend("force", opts, { desc = "LSP: Go to definition" }))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
      vim.tbl_extend("force", opts, { desc = "LSP: Go to declaration" }))
  end,
})

-- 启用语言服务器（配置来自 nvim-lspconfig）。
-- 如果项目有 .venv，告诉 Pyright 使用其中的解释器；这样第三方库（例如
-- torch）的源码和类型信息才能被 LSP 找到。没有 .venv 时保留 Pyright 默认行为。
vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        -- 关闭"未 import 名字的自动导入补全"。开启时 Pyright 每次改动后都要扫描
        -- 环境里所有已装的包，大环境（transformers 等 200+ 包）下每个新单词的
        -- 补全要等约 1 秒；关闭后降到 0.2–0.6 秒。
        autoImportCompletions = false,
      },
    },
  },
  before_init = function(_, config)
    local root = config.root_dir
    if not root then
      return
    end

    local python = root .. "/.venv/bin/python"
    if vim.fn.executable(python) == 1 then
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = python
    end
  end,
})

-- Ruff 语言服务器：Python 格式化（<leader>cf）、lint、整理 import。
-- 与 Pyright 分工：类型检查 / 跳转 / 补全交给 Pyright，ruff 只管风格。
vim.lsp.config("ruff", {
  init_options = {
    settings = {
      -- 项目里的 pyproject.toml / ruff.toml 优先；没有配置时才用下面的默认值
      configurationPreference = "filesystemFirst",
      -- 行宽上限：ruff 默认 88 会频繁强制折行，放宽到 120
      lineLength = 120,
    },
  },
  -- 与 Pyright 使用同一种位置编码（Pyright 只支持 UTF-16），
  -- 否则含中文的行里，只按一种编码换算位置的插件可能错位几个字符
  capabilities = {
    general = {
      positionEncodings = { "utf-16" },
    },
  },
  on_attach = function(client)
    -- 悬浮文档交给 Pyright，避免 K 弹出两份
    client.server_capabilities.hoverProvider = false
  end,
})

vim.lsp.enable("clangd")
vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
