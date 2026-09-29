-- Treesitter：语法高亮、折叠、智能缩进、语法对象

local treesitter = require("nvim-treesitter")

treesitter.setup({
  -- 默认安装目录已经足够，一般不需要修改
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- ---------------------------------------------------------
-- Parser 安装
-- ---------------------------------------------------------

-- 常用语言 parser
local treesitter_parsers = {
  -- Neovim 配置
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query",

  -- C/C++
  "c",
  "cpp",

  -- Python
  "python",

  -- Shell
  "bash",

  -- Markdown
  "markdown",
  "markdown_inline",

  -- 配置文件
  "json",
  "yaml",
  "toml",

  -- Git
  "diff",
  "gitcommit",
  "gitignore",

  -- Web
  "html",
  "css",
  "javascript",
  "typescript",
  "tsx",

  -- 其他常用 parser
  "regex",
}

-- 异步安装缺少的 parser。
-- 已经安装的 parser 不会重复安装。
treesitter.install(treesitter_parsers)

-- CodeCompanion buffer 本质上是 Markdown
vim.treesitter.language.register("markdown", { "codecompanion" })

-- ---------------------------------------------------------
-- 按 filetype 启用 Treesitter 功能
-- ---------------------------------------------------------

-- 需要启用 Treesitter 功能的实际 filetype
local treesitter_filetypes = {
  "lua",
  "vim",
  "vimdoc",

  "c",
  "cpp",
  "python",

  "sh",
  "bash",

  "markdown",
  "codecompanion",

  "json",
  "yaml",
  "toml",
  "diff",
  "gitcommit",

  "html",
  "css",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

-- 适合启用 Treesitter 缩进的 filetype
-- Treesitter 缩进仍然属于实验功能，如果某种语言缩进异常，
-- 可以直接从这里删除。
local treesitter_indent_filetypes = {
  c = true,
  cpp = true,
  python = true,
  lua = true,
  sh = true,
  bash = true,
  json = true,
  yaml = true,
  toml = true,
  html = true,
  css = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local treesitter_group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = treesitter_group,
  pattern = treesitter_filetypes,
  callback = function(args)
    -- 启用 Treesitter 高亮和语言注入
    local ok = pcall(vim.treesitter.start, args.buf)

    -- 第一次启动时 parser 可能仍在异步安装。
    -- 此时不继续设置，安装完成后重新打开文件即可。
    if not ok then
      return
    end

    -- Treesitter 折叠
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

    -- 打开文件时默认不要折叠所有代码
    vim.wo.foldlevel = 99

    -- Treesitter 智能缩进
    if treesitter_indent_filetypes[vim.bo[args.buf].filetype] then
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
