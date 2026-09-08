# editor 模块

> 面包屑：[dotfiles](../CLAUDE.md) > editor

## 职责

VS Code、Cursor、Zed 编辑器配置及可移植扩展清单管理。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.config/zed/settings.json` | `~/.config/zed/settings.json` | Zed 编辑器配置 |
| `.vscode/argv.json` | `~/.vscode/argv.json` | VS Code 启动参数 |
| `.cursor/argv.json` | `~/.cursor/argv.json` | Cursor 启动参数 |
| `.vscode/extensions/extensions.list` | `~/.vscode/extensions/extensions.list` | 可移植扩展 ID 清单（新机器安装用） |
| `.vscode/extensions/extensions.json` | 不提交、不链接 | 本机 runtime 扩展快照（非规范来源） |

## 主要配置项

- `extensions.list` 是 **规范来源**，每行一个扩展 ID，由 `install-vscode-extensions.sh` 读取安装
- `extensions.json` 是本机 runtime 快照，不提交到公开仓库；新机器不使用

## 依赖

- 工具：`code`（VS Code CLI）、`cursor`（Cursor CLI）
- 脚本：`scripts/install-vscode-extensions.sh`

## 修改指南

- 新增扩展 → 将扩展 ID 追加到 `extensions.list`
- 在新机器安装扩展：
  ```bash
  ./scripts/install-vscode-extensions.sh           # VS Code
  ./scripts/install-vscode-extensions.sh --code-bin cursor  # Cursor
  ```
- 修改 Zed 配置 → 编辑 `.config/zed/settings.json`
- **不要**以 `extensions.json` 作为迁移依据
