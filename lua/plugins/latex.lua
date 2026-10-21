-- LaTeX 写作：VimTeX + tectonic 编译 + zathura 预览
--
-- 流程：Neovim 写 .tex → tectonic 编译出 PDF → zathura 显示，SyncTeX 双向跳转。
-- tectonic 基于 XeTeX，中文用 ctex 宏包即可；缺的宏包首次编译时自动下载，
-- 所以第一次编译会慢一些（约 10 秒），之后每次 1~2 秒。
--
-- 常用按键（<localleader> 是 \，只在 tex 文件里生效，完整列表见 :h vimtex-default-mappings）：
--   \ll  编译（保存时也会自动编译）     \lv  正向跳转：PDF 定位到光标处
--   \le  错误和警告列表（quickfix）    \lo  编译输出
--   \lt  目录                         \lc  清理中间文件
--   zathura 里 Ctrl + 左键：反向跳转回 Neovim 对应的行

local M = {}

vim.g.vimtex_compiler_method = "tectonic"

-- 主变体靠 xdotool 找 zathura 窗口，Wayland 下没有，用 simple 变体
vim.g.vimtex_view_method = "zathura_simple"

-- 保存即编译，不再每次提示"开始 / 完成编译"；出错时 quickfix 会自动弹出
vim.g.vimtex_compiler_silent = 1

-- \cite{ 补全要解析 .bib；默认靠 bibtex 程序（没装 TeX Live 就没有），
-- 改用 VimTeX 自带的 Lua 解析器，速度差不多
vim.g.vimtex_parser_bib_backend = "lua"

-- quickfix 只在出错时自动弹出。ctex 的五号字每次都会产生无害的
-- "Font shape ... substituted" 警告，否则每次保存都会弹一下；警告仍可用 \le 查看
vim.g.vimtex_quickfix_open_on_warning = 0

local group = vim.api.nvim_create_augroup("UserVimtex", { clear = true })

-- tectonic 不支持持续编译，改为保存时编译一次；
-- 上一次还没编完就先停掉，保证 PDF 对应最新内容
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.tex",
  desc = "VimTeX: compile on save",
  command = [[if exists('b:vimtex') | if b:vimtex.compiler.is_running() | call vimtex#compiler#stop() | endif | call vimtex#compiler#start() | endif]],
})

-- treesitter.lua 全局占用了 ic / ac（类），VimTeX 发现已有映射就不再设置；
-- LaTeX 里没有"类"，在 tex 里换回 VimTeX 的命令文本对象（如 dac 删除整个 \textbf{...}）
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "tex",
  desc = "VimTeX: command text objects",
  callback = function(args)
    vim.keymap.set({ "x", "o" }, "ic", "<Plug>(vimtex-ic)", { buffer = args.buf, desc = "Inside LaTeX command" })
    vim.keymap.set({ "x", "o" }, "ac", "<Plug>(vimtex-ac)", { buffer = args.buf, desc = "Around LaTeX command" })
  end,
})

-- ---------------------------------------------------------
-- 让 VimTeX 认出 tectonic 的编译错误
-- ---------------------------------------------------------
-- VimTeX 按 -file-line-error 格式（"main.tex:13: 错误"）解析日志，并且靠
-- "日志里有没有错误"判断编译成败。tectonic 的日志是传统格式
-- （"! Undefined control sequence."），"未定义命令""缺少 $" 这类 TeX 错误
-- 解析不出来：编译失败会被当成成功，quickfix 里也看不到错误。
-- tectonic 自己的输出里有 "error: 文件:行号: 信息"，这里把它补进 VimTeX 的
-- 解析结果，编译成败判断、自动弹出 quickfix 和 \le 就都能用了。

-- 从最近一次编译的输出里取错误，放到当前 quickfix 列表最前面
function M.add_tectonic_errors()
  local lines = vim.fn.readfile(vim.fn.eval("b:vimtex.compiler.output"))
  local root = vim.fn.eval("b:vimtex.root")

  -- 输出文件会累积历次编译，只看最后一次（每次以 "note: Running TeX" 开头）
  local start = 1
  for i, line in ipairs(lines) do
    if line:find("^note: Running TeX") then
      start = i
    end
  end

  local errors = {}
  for i = start, #lines do
    local file, lnum, text = lines[i]:match("^error: (.-):(%d+): (.*)$")
    if file then
      local path = file:sub(1, 1) == "/" and file or vim.fs.joinpath(root, file)
      -- \input{chap} 报出来的文件名不带 .tex
      if vim.fn.filereadable(path) == 0 and vim.fn.filereadable(path .. ".tex") == 1 then
        path = path .. ".tex"
      end
      table.insert(errors, { filename = path, lnum = tonumber(lnum), text = text, type = "E" })
    end
  end
  if #errors == 0 then
    return
  end

  -- "! LaTeX Error" 这类 VimTeX 自己也能解析出的错误（通常缺行号）会重复，
  -- 保留 tectonic 这条带文件和行号的
  local qflist = vim.tbl_filter(function(item)
    if item.type ~= "E" then
      return true
    end
    local text = item.text:match("^[^\n]*")
    for _, err in ipairs(errors) do
      if err.text:find(text, 1, true) then
        return false
      end
    end
    return true
  end, vim.fn.getqflist())
  vim.fn.setqflist(vim.list_extend(errors, qflist), "r")
end

-- 包装 VimTeX 解析器的 addqflist：先照常解析日志，再补上 tectonic 的错误。
-- 解析器对象属于整个项目（b:vimtex.qf），每个项目只包装一次。
vim.cmd([[
  function! UserVimtexAddqflist(tex, log) abort dict
    call self.addqflist_vimtex(a:tex, a:log)
    call v:lua.require'plugins.latex'.add_tectonic_errors()
  endfunction
]])

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VimtexEventInitPost",
  desc = "VimTeX: parse tectonic errors",
  command = [[if !has_key(b:vimtex.qf, 'addqflist_vimtex') | let b:vimtex.qf.addqflist_vimtex = b:vimtex.qf.addqflist | let b:vimtex.qf.addqflist = function('UserVimtexAddqflist') | endif]],
})

return M
