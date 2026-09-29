-- Markdown 浏览器实时预览：iamcco/markdown-preview.nvim
-- 与 render-markdown 的区别：render-markdown 在 buffer 内做视觉渲染，
-- 本插件在浏览器中生成实时页面（编辑自动刷新、同步滚动），
-- 适合检查最终排版、演示与分享。
--
-- 前端依赖（插件 app/ 目录下的 Node 服务）由 lua/plugins/init.lua 中的
-- PackChanged 钩子在插件安装 / 更新后自动执行 npm install。
-- 如需手动重装依赖：:call mkdp#util#install()

-- 以下 g:mkdp_* 全局变量在打开 Markdown 文件时读取，需在启动阶段设置。

vim.g.mkdp_auto_start = 0         -- 打开 Markdown 文件时不自动弹出预览
vim.g.mkdp_auto_close = 1         -- 切换到其他 buffer 时自动关闭对应预览页
vim.g.mkdp_refresh_slow = 0       -- 实时刷新（关闭省资源模式）
vim.g.mkdp_command_for_global = 0 -- 只在 Markdown buffer 中提供命令
vim.g.mkdp_open_to_the_world = 0  -- 预览服务仅监听本机回环地址
vim.g.mkdp_browser = ""           -- 使用系统默认浏览器
vim.g.mkdp_echo_preview_url = 1   -- 打开预览后在命令行显示 URL，方便复制
vim.g.mkdp_theme = "dark"         -- 预览页面主题：dark / light

-- 退出 Neovim 时保留浏览器中的预览页。
-- 插件在打开预览时注册了 VimLeave → mkdp#rpc#stop_server()（组名 MKDP_REFRESH_INIT<bufnr>），
-- 它会让服务器通知页面执行 window.close()，再杀掉预览服务器进程。
-- 这里在 VimLeavePre 抢先清除这些 VimLeave 自动命令：页面收不到关闭指令，
-- 会停留在最后渲染的内容（此后服务器随 Neovim 退出，页面变为静态快照，刷新将失效）。
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("MkdpKeepPreviewOnExit", { clear = true }),
  callback = function()
    for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeave" })) do
      if au.group_name and au.group_name:match("^MKDP_REFRESH_INIT") then
        vim.api.nvim_clear_autocmds({ group = au.group, event = "VimLeave" })
      end
    end
  end,
  desc = "退出 Neovim 时保留 markdown-preview 浏览器页面",
})

-- 快捷键：<leader>mp 开关预览。
-- 插件命令（:MarkdownPreviewToggle 等）由 ftplugin 提供，仅 Markdown buffer 存在。
vim.keymap.set("n", "<leader>mp", function()
  if vim.bo.filetype ~= "markdown" then
    vim.notify("Markdown 预览仅可用于 Markdown 文件", vim.log.levels.WARN)
    return
  end
  vim.cmd("MarkdownPreviewToggle")
end, { noremap = true, silent = true, desc = "Toggle Markdown preview" })
