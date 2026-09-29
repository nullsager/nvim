-- 模糊搜索：fzf-lua

require("fzf-lua").setup({})

-- ---------------------------------------------------------
-- 文件与内容搜索
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>", { desc = "Grep in project" })
vim.keymap.set("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Grep word under cursor" })
vim.keymap.set("v", "<leader>fw", "<cmd>FzfLua grep_visual<cr>", { desc = "Grep selection" })
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Find buffer" })
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Recent files" })
vim.keymap.set("n", "<leader>fR", "<cmd>FzfLua resume<cr>", { desc = "Resume last picker" })

-- ---------------------------------------------------------
-- Neovim 内置资源
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", { desc = "Help tags" }) vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Search keymaps" }) vim.keymap.set("n", "<leader>fc", "<cmd>FzfLua commands<cr>", { desc = "Search commands" })

-- ---------------------------------------------------------
-- LSP 与诊断（诊断显示默认关闭，用 <leader>ul 切换）
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Document symbols" })

-- ---------------------------------------------------------
-- Git（直接调用系统 git 命令，无需额外插件）
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>gf", "<cmd>FzfLua git_files<cr>", { desc = "Git files" })
vim.keymap.set("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "Git status" })
vim.keymap.set("n", "<leader>gc", "<cmd>FzfLua git_commits<cr>", { desc = "Git commits" })
vim.keymap.set("n", "<leader>gb", "<cmd>FzfLua git_branches<cr>", { desc = "Git branches" })
