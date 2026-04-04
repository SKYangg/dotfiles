# cli 模块

> 面包屑：[dotfiles](../CLAUDE.md) > cli

## 职责

命令行工具集合配置：文件管理器（yazi）、shell 历史（atuin）、系统监控（btop）、包管理（Homebrew Brewfile）、Python 环境（uv、conda）等。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.config/yazi/yazi.toml` | `~/.config/yazi/yazi.toml` | yazi 文件管理器主配置 |
| `.config/yazi/keymap.toml` | `~/.config/yazi/keymap.toml` | yazi 键位绑定 |
| `.config/yazi/theme.toml` | `~/.config/yazi/theme.toml` | yazi 主题 |
| `.config/yazi/init.lua` | `~/.config/yazi/init.lua` | yazi Lua 插件初始化 |
| `.config/yazi/package.toml` | `~/.config/yazi/package.toml` | yazi 插件清单 |
| `.config/atuin/config.toml` | `~/.config/atuin/config.toml` | atuin 历史搜索配置 |
| `.config/btop/btop.conf` | `~/.config/btop/btop.conf` | btop 系统监控配置 |
| `.config/brewfile/Brewfile` | `~/.config/brewfile/Brewfile` | Homebrew 包清单 |
| `.config/uv/uv.toml` | `~/.config/uv/uv.toml` | uv Python 包管理器配置 |
| `.condarc` | `~/.condarc` | conda 配置（channels、环境路径） |
| `.npmrc` | `~/.npmrc` | npm 全局配置 |
| `.config/neofetch/config.conf` | `~/.config/neofetch/config.conf` | neofetch 系统信息展示配置 |
| `.config/kaku/assistant.toml.example` | 不链接（模板） | Kaku AI 助手配置模板 |
| `.config/mihomo/config.yaml` | `~/.config/mihomo/config.yaml` | Mihomo（Clash.Meta）代理配置 |
| `.config/cronboard/config.toml` | `~/.config/cronboard/config.toml` | Cronboard 配置 |
| `.config/zotero-mcp/config.json` | `~/.config/zotero-mcp/config.json` | Zotero MCP 集成配置 |

## 依赖

- 工具：`yazi`、`atuin`、`btop`、`brew`、`uv`、`conda`、`npm`、`neofetch`
- yazi 插件：通过 `ya pack` 管理（见 `package.toml`）

## 修改指南

- 添加 Homebrew 包 → 编辑 `Brewfile`，`brew bundle` 安装
- 修改 yazi 配置 → 编辑对应 `.toml` 文件（已链接）
- yazi plugins/flavors 目录内容不纳管（在 `.gitignore` 中），通过 `ya pack -i` 恢复
- `kaku/assistant.toml` 含 API key，使用 `.example` 模板手动实例化
