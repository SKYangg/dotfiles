# aerospace 模块

> 面包屑：[dotfiles](../CLAUDE.md) > aerospace

## 职责

macOS 平铺窗口管理器 AeroSpace 的配置。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.aerospace.toml` | `~/.aerospace.toml` | AeroSpace 全局配置（布局、快捷键、工作区） |

## 依赖

- 工具：`aerospace`（`brew install --cask aerospace`）

## 修改指南

- 修改窗口布局或快捷键 → 编辑 `.aerospace.toml`
- 修改后 AeroSpace 自动重载，或执行 `aerospace reload-config`
