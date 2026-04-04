# ai 模块

> 面包屑：[dotfiles](../CLAUDE.md) > ai

## 职责

Claude Code（CCG）与 Codex 的配置文件、上下文规则模板，以及 AI 工具的共享设置。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code 全局规则（CCG 增强配置） |
| `.claude/settings.json.example` | 不链接（模板） | Claude Code settings 模板，含敏感字段占位符 |
| `.claude/.ccg/config.toml.example` | 不链接（模板） | CCG 多模型协作配置模板 |
| `.codex/AGENTS.md` | `~/.codex/AGENTS.md` | Codex 全局 agent 说明 |
| `.codex/config.toml.example` | 不链接（模板） | Codex 配置模板 |

## 主要配置项

- `CLAUDE.md` 定义 Claude Code 的核心行为：调研优先、多模型协作、Git 规范、安全检查
- CCG 工作流：Codex（后端任务）、Gemini（前端任务）、Claude（代码实现）
- `settings.json` 含 API key / MCP server 配置，**不纳管**，需手动实例化

## 依赖

- 工具：`claude`（Claude Code CLI）、`codex`（OpenAI Codex CLI）
- 运行时：真实 `~/.claude/settings.json`、`~/.codex/config.toml`（本地，不在仓库）

## 修改指南

- 修改 Claude Code 全局行为 → 编辑 `.claude/CLAUDE.md`（已链接，直接生效）
- 添加新 MCP server → 编辑本地 `~/.claude/settings.json`（不提交）
- 更新配置模板 → 编辑对应 `.example` 文件
- **不要**在模板中写入真实 API key
