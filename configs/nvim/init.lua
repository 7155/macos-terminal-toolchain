-- ============================================================
-- 最小 Python / LangGraph 学习配置
-- Neovim 0.12 + BasedPyright + blink.cmp + Treesitter
-- ============================================================

vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.termguicolors = true
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- Treesitter parser 尚未安装时，仍保留 Vim 自带的基础语法高亮。
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- Neovim 0.12 内置 vim.pack，不再额外安装包管理器。
vim.pack.add({
    {
        src = "https://github.com/neovim/nvim-lspconfig",
    },
    {
        src = "https://github.com/Saghen/blink.cmp",
        version = "v1.10.2",
    },
    {
        src = "https://github.com/rafamadriz/friendly-snippets",
    },
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
    },
    {
        src = "https://github.com/Mofiqul/vscode.nvim",
    },
})

-- Treesitter 判断代码结构，主题把不同结构画成不同颜色。
require("vscode").setup({
    style = "dark",
    italic_comments = true,
})
vim.cmd.colorscheme("vscode")

-- 已安装时是 no-op；第一次应按 README 使用 headless 命令等待完成。
require("nvim-treesitter").install({ "python" })
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python" },
    callback = function()
        vim.treesitter.start()
    end,
})

-- LSP 生成语义候选，blink.cmp 负责候选菜单和按键交互。
local blink = require("blink.cmp")

blink.setup({
    keymap = {
        preset = "super-tab",
        ["<CR>"] = { "accept", "fallback" },
    },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = {
        trigger = {
            show_on_keyword = true,
        },
        list = {
            selection = {
                preselect = true,
                auto_insert = false,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = {
                border = "rounded",
            },
        },
        ghost_text = {
            enabled = true,
        },
        menu = {
            border = "rounded",
            draw = {
                columns = {
                    { "kind_icon" },
                    { "label", "label_description", gap = 1 },
                    { "source_name" },
                },
            },
        },
    },
    signature = {
        enabled = true,
        window = {
            border = "rounded",
        },
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
        implementation = "prefer_rust_with_warning",
    },
})

local basedpyright_settings = {
    basedpyright = {
        analysis = {
            autoImportCompletions = true,
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
        },
    },
}

-- 本机可通过 Fish 的 NVIM_PYTHON_PATH 选择项目虚拟环境。
-- 公共配置不保存用户名、卷名或其他机器专属绝对路径。
if vim.env.NVIM_PYTHON_PATH and vim.env.NVIM_PYTHON_PATH ~= "" then
    basedpyright_settings.python = {
        pythonPath = vim.env.NVIM_PYTHON_PATH,
    }
end

vim.lsp.config("basedpyright", {
    cmd = { "basedpyright-langserver", "--stdio" },
    capabilities = blink.get_lsp_capabilities(),
    settings = basedpyright_settings,
})
vim.lsp.enable("basedpyright")

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "跳转到定义" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "查看类型和文档" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "重命名符号" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作" })

vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    signs = true,
})
