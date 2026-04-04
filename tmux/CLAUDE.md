# tmux 模块

> 面包屑：[dotfiles](../CLAUDE.md) > tmux

## 职责

tmux 终端复用器配置。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.tmux.conf` | `~/.tmux.conf` | tmux 主配置（前缀键、分屏快捷键、状态栏） |

## 依赖

- 工具：`tmux`

## 修改指南

- 编辑 `.tmux.conf` 后，`tmux source ~/.tmux.conf` 热重载
