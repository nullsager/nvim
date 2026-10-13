-- Treesitter：语法高亮、折叠、智能缩进、语法对象

-- ---------------------------------------------------------
-- Parser 安装：启动时异步安装缺少的，已安装的不会重复安装。
-- 新增语言只需在这里加一项，高亮和折叠会自动启用。
-- ---------------------------------------------------------
require("nvim-treesitter").install({
  "lua", "luadoc", "vim", "vimdoc", "query", -- Neovim 配置
  "c", "cpp", "python", "bash", -- 编程语言
  "markdown", "markdown_inline", -- 笔记
  "json", "yaml", "toml", -- 配置文件
  "diff", "gitcommit", "gitignore", -- Git
  "html", "css", "javascript", "typescript", "tsx", "regex", -- Web 与其他
})

-- CodeCompanion buffer 本质上是 Markdown
vim.treesitter.language.register("markdown", { "codecompanion" })

-- ---------------------------------------------------------
-- 按 filetype 启用：有 parser 就开启高亮与折叠，没有就跳过
-- （第一次启动时 parser 可能仍在异步安装，装好后重新打开文件即可）。
-- 打开文件时默认全部展开：见 options.lua 的 foldlevelstart。
-- ---------------------------------------------------------

-- Treesitter 缩进仍是实验功能，只对下列 filetype 启用；
-- 某种语言缩进异常时从这里删掉即可回退到 Vim 自带的缩进规则。
local ts_indent = {}
for _, ft in ipairs({
  "c", "cpp", "python", "lua", "sh", "bash", "json", "yaml", "toml",
  "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact",
}) do
  ts_indent[ft] = true
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end
    -- [0][0]：只作用于当前窗口里的这个 buffer，切到别的 buffer 不会带过去
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    if ts_indent[args.match] then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- ---------------------------------------------------------
-- 语法对象（textobjects）
-- ---------------------------------------------------------

require("nvim-treesitter-textobjects").setup({
  select = {
    -- 当前光标不在目标内部时，自动向后寻找目标
    lookahead = true,

    selection_modes = {
      ["@parameter.outer"] = "v",
      ["@function.outer"] = "V",
      ["@class.outer"] = "V",
    },

    include_surrounding_whitespace = false,
  },

  move = {
    -- 跳转时记录到 jumplist，可以使用 <C-o> 返回
    set_jumps = true,
  },
})

local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")
local ts_swap = require("nvim-treesitter-textobjects.swap")

-- ---------------------------------------------------------
-- 选择语法对象
-- x：可视模式
-- o：操作符等待模式，因此可以配合 d、c、y 使用
--
-- 快捷键 → { 语法对象, 描述 }
-- ---------------------------------------------------------
local select_textobjects = {
  af = { "@function.outer", "Around function" },
  ["if"] = { "@function.inner", "Inside function" },
  ac = { "@class.outer", "Around class" },
  ic = { "@class.inner", "Inside class" },
  aa = { "@parameter.outer", "Around parameter" },
  ia = { "@parameter.inner", "Inside parameter" },
  al = { "@loop.outer", "Around loop" },
  il = { "@loop.inner", "Inside loop" },
  ai = { "@conditional.outer", "Around conditional" },
  ii = { "@conditional.inner", "Inside conditional" },
}

for lhs, spec in pairs(select_textobjects) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    ts_select.select_textobject(spec[1], "textobjects")
  end, { desc = spec[2] })
end

-- ---------------------------------------------------------
-- 函数和类之间跳转
--
-- 快捷键 → { 跳转方法, 语法对象, 描述 }
-- ---------------------------------------------------------
local move_textobjects = {
  ["]f"] = { "goto_next_start", "@function.outer", "Next function start" },
  ["[f"] = { "goto_previous_start", "@function.outer", "Previous function start" },
  ["]F"] = { "goto_next_end", "@function.outer", "Next function end" },
  ["[F"] = { "goto_previous_end", "@function.outer", "Previous function end" },
  ["]c"] = { "goto_next_start", "@class.outer", "Next class start" },
  ["[c"] = { "goto_previous_start", "@class.outer", "Previous class start" },
}

for lhs, spec in pairs(move_textobjects) do
  vim.keymap.set({ "n", "x", "o" }, lhs, function()
    ts_move[spec[1]](spec[2], "textobjects")
  end, { desc = spec[3] })
end

-- ---------------------------------------------------------
-- 交换函数参数
-- ---------------------------------------------------------

vim.keymap.set("n", "<leader>sn", function()
  ts_swap.swap_next("@parameter.inner")
end, {
  desc = "Swap with next parameter",
})

vim.keymap.set("n", "<leader>sp", function()
  ts_swap.swap_previous("@parameter.inner")
end, {
  desc = "Swap with previous parameter",
})
