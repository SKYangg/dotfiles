# terminal 模块

> 面包屑：[dotfiles](../CLAUDE.md) > terminal

## 职责

Ghostty 终端模拟器、Starship 跨 shell 提示符配置。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.config/ghostty/config` | `~/.config/ghostty/config` | Ghostty 终端配置（字体、颜色、快捷键） |
| `starship.toml` | `~/.config/starship.toml` | Starship 提示符主题配置 |

## 依赖

- 工具：可选 `ghostty`（终端）、`starship`（提示符；使用主机包管理器安装）

## 修改指南

- 修改终端外观/字体 → 编辑 `.config/ghostty/config`
- 修改命令行提示符样式 → 编辑 `starship.toml`
- Starship 需在 shell rc 中启用：`eval "$(starship init zsh)"`（已在 .zshrc 中）
