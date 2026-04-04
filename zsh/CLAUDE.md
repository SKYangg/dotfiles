# zsh 模块

> 面包屑：[dotfiles](../CLAUDE.md) > zsh

## 职责

Zsh 主配置，包含 Oh My Zsh 框架、Powerlevel10k 主题、别名、环境变量分拆管理。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.zshrc` | `~/.zshrc` | 主入口：加载 OMZ、plugins、source 子文件 |
| `.zprofile` | `~/.zprofile` | 登录 shell 环境：Homebrew PATH、conda init |
| `.zshenv` | `~/.zshenv` | 所有 shell 通用变量（最早加载） |
| `.zshrc.aliases` | `~/.zshrc.aliases` | 别名定义，由 `.zshrc` source |
| `.zshrc.env` | `~/.zshrc.env` | 工具环境变量（由 `.zshrc` source） |
| `.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k 主题配置（`p10k configure` 生成） |

## 主要配置项

- **插件管理器**：Oh My Zsh（`~/.oh-my-zsh`，不在仓库中）
- **主题**：Powerlevel10k（`ZSH_THEME="powerlevel10k/powerlevel10k"`）
- **加载顺序**：`.zshenv` → `.zprofile`（登录）→ `.zshrc`（交互）→ source `.zshrc.env`、`.zshrc.aliases`

## 依赖

- 工具：`zsh`、`oh-my-zsh`、`powerlevel10k`
- 外部：`conda`（zprofile init）、`homebrew`（/opt/homebrew/bin）

## 修改指南

- 添加别名 → 编辑 `.zshrc.aliases`
- 添加环境变量 → 编辑 `.zshrc.env`
- 修改 PATH / 登录逻辑 → 编辑 `.zprofile`
- 不要直接编辑 `~/.zshrc`（是 symlink）
