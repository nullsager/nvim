-- LSP 与诊断信息

-- 默认关闭诊断信息
vim.diagnostic.enable(false)

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
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Set LSP navigation keymaps",
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition,
      vim.tbl_extend("force", opts, { desc = "LSP: Go to definition" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover,
      vim.tbl_extend("force", opts, { desc = "LSP: Show documentation" }))
    vim.keymap.set("n", "gr", vim.lsp.buf.references,
      vim.tbl_extend("force", opts, { desc = "LSP: Find references" }))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
      vim.tbl_extend("force", opts, { desc = "LSP: Go to declaration" }))
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation,
      vim.tbl_extend("force", opts, { desc = "LSP: Go to implementation" }))
  end,
})

-- 启用语言服务器（配置来自 nvim-lspconfig）。
-- 如果项目有 .venv，告诉 Pyright 使用其中的解释器；这样第三方库（例如
-- torch）的源码和类型信息才能被 LSP 找到。没有 .venv 时保留 Pyright 默认行为。
vim.lsp.config("pyright", {
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

vim.lsp.enable("clangd")
vim.lsp.enable("pyright")
