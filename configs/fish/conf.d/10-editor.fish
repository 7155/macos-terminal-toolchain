# Fish 使用 set -gx 导出环境变量，不能依赖 ~/.zshrc 中的 export。
set -gx EDITOR nvim
set -gx VISUAL nvim

# uv tool 安装的 BasedPyright 通常位于 ~/.local/bin。
fish_add_path --prepend $HOME/.local/bin

# 可选：只有虚拟环境不在当前目录的 .venv 时才在本机取消注释。
# 不要把真实机器绝对路径提交到公共仓库。
# set -gx NVIM_PYTHON_PATH /absolute/path/to/.venv/bin/python
