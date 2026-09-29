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

-- 启用语言服务器（配置来自 nvim-lspconfig）
vim.lsp.enable("clangd")
vim.lsp.enable("pyright")
