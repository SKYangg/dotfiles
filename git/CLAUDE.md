# git 模块

> 面包屑：[dotfiles](../CLAUDE.md) > git

## 职责

Git 全局配置模板（sanitized，不含真实用户信息）与全局 .gitignore 规则。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.gitconfig` | 不链接（模板） | 全局 Git 配置模板，需手动实例化 |
| `.config/git/ignore` | `~/.config/git/ignore` | 全局 .gitignore（OS 文件、编辑器临时文件等） |

## 主要配置项

- `.gitconfig` 是 **sanitized 模板**，真实的 `~/.gitconfig` 含用户名/邮箱/token，不纳管
- 全局 ignore 覆盖：`.DS_Store`、`*.swp`、`.idea/`、`.vscode/` 等
- 启用 `delta` 作为 pager（需 brew install git-delta）

## 依赖

- 工具：`git`、`git-delta`（可选，用于 diff 高亮）

## 修改指南

- 修改全局 ignore → 编辑 `.config/git/ignore`（已链接）
- 修改 git 配置模板 → 编辑 `.gitconfig`，同步到本地 `~/.gitconfig`
- **不要**在模板中写入真实邮箱、token、内网域名
