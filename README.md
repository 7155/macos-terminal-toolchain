# Ghostty + Fish + Yazi + Neovim 学习环境

这份记录保存一条可复现的 macOS 命令行工作流：

```text
Ghostty
  -> 启动 Fish
  -> Fish 导出 EDITOR/VISUAL=nvim
  -> Yazi 用 Neovim 打开文本文件
  -> Neovim 用 Treesitter 着色、BasedPyright 理解 Python、blink.cmp 显示补全
```

这里最重要的边界是：

- Ghostty 只负责终端窗口和启动 Shell。
- Fish 负责环境变量、PATH、自动建议和命令补全。
- Yazi 负责文件浏览；它通过 opener 启动编辑器。
- Neovim 负责编辑；LSP 提供“代码含义”，补全插件负责“候选窗口”，Treesitter 负责“语法结构”，主题负责“颜色”。

## 1. 本机验收版本

这套配置在 2026-08-10 验证过以下版本：

```text
Ghostty       1.3.1
Fish          4.8.0
Yazi          26.5.6
Neovim        0.12.4
tree-sitter   0.26.12
BasedPyright  1.39.9
```

版本升级后如果插件 API 变化，应重新执行本文最后的验收脚本。

## 2. 安装命令

```bash
brew install --cask ghostty
brew install fish yazi neovim tree-sitter-cli uv
uv tool install basedpyright
```

当前主题使用 `MesloLGS NF`。如果系统中还没有这款字体，可以安装 Nerd Font：

```bash
brew install --cask font-meslo-lg-nerd-font
```

确认命令都能找到：

```bash
command -v fish
command -v yazi
command -v nvim
command -v tree-sitter
command -v basedpyright-langserver
```

## 3. Ghostty 启动 Fish

配置文件使用 [configs/ghostty/config.ghostty](configs/ghostty/config.ghostty)。在 macOS 上可以把内容合并到：

```text
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty
```

关键配置只有一行：

```ini
command = /opt/homebrew/bin/fish
```

它表示每个新的 Ghostty 终端直接启动 Fish，不需要先进入 Zsh 再手动执行 `fish`。

验证配置语法和最终值：

```bash
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config | rg '^(command|theme|font-family|font-size) ='
```

修改 `command` 后应新建 Ghostty 窗口；已有 Shell 进程不会变成 Fish。

## 4. Fish 把 Neovim 暴露给子进程

把 [configs/fish/conf.d/10-editor.fish](configs/fish/conf.d/10-editor.fish) 放到：

```text
~/.config/fish/conf.d/10-editor.fish
```

核心语句是：

```fish
set -gx EDITOR nvim
set -gx VISUAL nvim
```

`-g` 表示 Fish 全局变量，`-x` 表示导出给 Yazi 等子进程。只在 `.zshrc` 中写 `export EDITOR=nvim` 对 Fish 不生效，因为 Fish 不读取 `.zshrc`。

检查 Fish 配置和实际值：

```bash
fish -n ~/.config/fish/conf.d/10-editor.fish
fish -lc 'echo EDITOR=$EDITOR; echo VISUAL=$VISUAL; command -v nvim'
```

如果项目虚拟环境没有位于当前目录的 `.venv`，可以在本机 Fish 配置中额外指定：

```fish
set -gx NVIM_PYTHON_PATH /absolute/path/to/.venv/bin/python
```

不要把真实绝对路径直接提交到公共配置。Fish 环境需要激活时，应使用 Fish 版本的脚本：

```fish
source .venv/bin/activate.fish
```

## 5. Yazi 用 Neovim 打开文件

把 [configs/yazi/yazi.toml](configs/yazi/yazi.toml) 放到：

```text
~/.config/yazi/yazi.toml
```

配置中的数据流是：

```text
选中文本文件
  -> Yazi 匹配默认 edit opener
  -> 执行 nvim %s
  -> block=true 暂时隐藏 Yazi
  -> 退出 Neovim
  -> 回到原来的 Yazi 界面
```

常用按键：

| 所在程序 | 按键 | 作用 |
| --- | --- | --- |
| Yazi | `Enter` | 使用默认 opener 打开文件或进入目录 |
| Yazi | `O` | 显示 “Open with” 列表，应看到 `Neovim` |
| Yazi | `q` | 退出 Yazi |
| Neovim | `i` | 进入插入模式 |
| Neovim | `Esc`、`:wq`、`Enter` | 保存并返回 Yazi |
| Neovim | `Esc`、`:q!`、`Enter` | 放弃修改并返回 Yazi |

最直接的诊断命令：

```bash
fish -lc 'yazi --debug 2>/dev/null' | sed -n '/^Variables$/,/^Multiplexers$/p'
```

正确输出应同时包含：

```text
EDITOR             : Some("nvim")
VISUAL             : Some("nvim")
run: NonEmptyString("nvim %s")
desc: "Neovim"
```

如果 `EDITOR` 仍为 `None`，问题属于 Fish 环境变量；如果编辑器已有值但 opener 不是 `nvim %s`，问题属于 Yazi 配置路径或 TOML 内容。

## 6. Neovim 的补全与高亮

把 [configs/nvim/init.lua](configs/nvim/init.lua) 放到：

```text
~/.config/nvim/init.lua
```

这份配置包含：

- `nvim-lspconfig`：启动 BasedPyright。
- `blink.cmp`：显示接近 VS Code 的候选菜单、文档、签名和灰色行内建议。
- `nvim-treesitter`：解析 Python 语法结构。
- `vscode.nvim`：为关键字、字符串、模块、函数等结构提供不同颜色。

首次安装 Python parser：

```bash
nvim --headless "+lua require('nvim-treesitter').install({'python'}):wait(300000)" +qa
```

然后新开 Neovim 窗口。旧窗口不会自动重新执行完整的 `init.lua`。

Python/LangGraph 示例：

```python
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph
```

不要写 `import longchain`：这是拼写错误。输入 `import langg` 时应该出现 `langgraph`；输入 `import langchain_` 时应出现 `langchain_core` 和 `langchain_openai`。

补全按键：

| 按键 | 作用 |
| --- | --- |
| `Ctrl+Space` | 手动触发候选菜单 |
| `Tab` | 下一个候选项 |
| `Shift+Tab` | 上一个候选项 |
| `Enter` | 接受候选项 |
| `gd` | 跳转定义 |
| `K` | 查看类型与文档 |
| `空格 r n` | 重命名符号 |

## 7. 一键验收

完成本机配置后运行：

```bash
./verify.sh
```

预期最后输出：

```text
TERMINAL_TOOLCHAIN_OK
```

脚本只读取配置和启动 headless 检查，不修改文件。

## 8. 安全边界

- 不要把 API Key、OAuth Token、Cookie、`auth.json` 或真实 `.env` 上传到 GitHub。
- 本地测试密钥应放在被 Git 忽略且权限为 `600` 的 `.env` 中。
- 公共配置使用 `NVIM_PYTHON_PATH` 这类环境变量，避免提交用户名、磁盘卷名和绝对虚拟环境路径。

## 官方资料

- [Ghostty configuration](https://ghostty.org/docs/config)
- [Ghostty shell integration](https://ghostty.org/docs/features/shell-integration)
- [Fish tutorial](https://fishshell.com/docs/current/tutorial)
- [Yazi yazi.toml](https://yazi-rs.github.io/docs/configuration/yazi/)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [BasedPyright language server settings](https://docs.basedpyright.com/latest/configuration/language-server-settings/)
