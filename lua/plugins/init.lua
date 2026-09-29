-- 插件清单与加载入口
-- 使用 Neovim 内置的 vim.pack 管理插件，版本锁定见 nvim-pack-lock.json。

-- markdown-preview.nvim 的构建钩子：
-- 该插件安装 / 更新后需要在其 app/ 目录执行 npm install（下载前端服务依赖）。
-- PackChanged 自动命令必须注册在 vim.pack.add() 之前，首次安装时才会触发。
vim.api.nvim_create_autocmd("PackChanged", {
  desc = "markdown-preview.nvim 安装/更新后自动安装前端依赖",
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name ~= "markdown-preview.nvim" or (kind ~= "install" and kind ~= "update") then
      return
    end
    if vim.fn.executable("npm") == 0 then
      vim.schedule(function()
        vim.notify("markdown-preview: 未找到 npm，请安装 Node.js 后重启", vim.log.levels.ERROR)
      end)
      return
    end
    vim.notify("markdown-preview: 正在安装前端依赖（npm install）…")
    vim.system({ "npm", "install" }, { cwd = ev.data.path .. "/app" }, function(res)
      vim.schedule(function()
        if res.code == 0 then
          vim.notify("markdown-preview: 前端依赖安装完成")
        else
          vim.notify(
            "markdown-preview: npm install 失败，可手动执行 :call mkdp#util#install()",
            vim.log.levels.ERROR
          )
        end
      end)
    end)
  end,
})

vim.pack.add({
  -- 快捷键提示
  "https://github.com/folke/which-key.nvim",

  -- 编辑增强
  "https://www.github.com/echasnovski/mini.nvim",
  "https://github.com/echasnovski/mini.icons",

  -- 补全
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  "https://github.com/erooke/blink-cmp-latex",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/milanglacier/minuet-ai.nvim",

  -- LSP 与模糊搜索
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/nvim-tree/nvim-web-devicons",

  -- 笔记
  "https://github.com/obsidian-nvim/obsidian.nvim",

  -- Org mode
  "https://github.com/nvim-orgmode/orgmode",

  -- Markdown 渲染与预览
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/iamcco/markdown-preview.nvim",

  -- 通用依赖库
  "https://www.github.com/nvim-lua/plenary.nvim",

  -- Treesitter
  "https://github.com/neovim-treesitter/treesitter-parser-registry",
  "https://github.com/neovim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",

  -- AI 助手
  { src = "https://www.github.com/olimorris/codecompanion.nvim", version = vim.version.range("^19.0.0") },
})

-- 各插件的详细配置
require("plugins.which-key")
require("plugins.mini")
require("plugins.minuet")
require("plugins.completion")
require("plugins.lsp")
require("plugins.fzf")
require("plugins.treesitter")
require("plugins.obsidian")
require("plugins.orgmode")
require("plugins.codecompanion")
require("plugins.markdown")
require("plugins.markdown-preview")
