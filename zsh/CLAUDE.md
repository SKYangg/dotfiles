# zsh 模块

> 面包屑：[dotfiles](../CLAUDE.md) > zsh

## 职责

Zsh 主配置，包含 Oh My Zsh 框架、Powerlevel10k 主题、别名、环境变量分拆管理。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.zshrc` | `~/.zshrc` | 主入口：加载 OMZ、p10k、plugins、source 子文件、按需初始化 NVM/Conda、Kaku 集成与 vi 重绑 |
| `.zprofile` | `~/.zprofile` | 登录 shell 环境：可选 Homebrew/OrbStack、Julia depot |
| `.zshenv` | `~/.zshenv` | 所有 shell 通用（最早加载）：PATH 去重/定向清理、`path_prepend`、cargo/goup |
| `.zshrc.aliases` | `~/.zshrc.aliases` | 别名定义，由 `.zshrc` source |
| `.zshrc.env` | `~/.zshrc.env` | 工具环境变量（由 `.zshrc` source） |
| `.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k 主题配置（`p10k configure` 生成） |

## 主要配置项

- **插件管理器**：Oh My Zsh（`~/.oh-my-zsh`，不在仓库中）
- **主题**：Powerlevel10k（`ZSH_THEME="powerlevel10k/powerlevel10k"`）
- **加载顺序**：`.zshenv` → `.zprofile`（登录）→ `.zshrc`（交互）→ env/aliases → OMZ/p10k → Conda/NVM 按需加载器 → zoxide → Kaku → vi 重绑

## 不变量（改动前必读）

- **PATH 一律用 `path_prepend`**（定义在 `.zshenv`）。它自带目录存在性检查，配合 `typeset -U path` 去重；已确认属于 dotfiles 的旧条目由 `path_remove` 定向清理。
  直接写 `export PATH="...:$PATH"` 会导致 PATH 随 shell 嵌套无限增长。
- **dotfiles 管理的 PATH 条目只允许有一个来源**。`.claude/bin` 由 `.zshenv` 负责；Kaku bin 由 `.zshrc` 的集成段负责。外部 Kaku 脚本可能再次去重前置同一路径。
- **`kaku.zsh` 必须在 `.zshrc` 的 p10k 与 zoxide 之后加载，vi 重绑必须在它之后**。它通过检测 `__zoxide_z` / `_zsh_autosuggest_start` /
  `_main_complete` 来自我禁用 zsh-z、autosuggestions、compinit。提前 source 会导致这些守卫失效，
  从而重复加载插件、compinit 跑两次，并让 zsh-z 的 `z` 覆盖 zoxide。
- **`SAVEHIST` 必须写在 `source $ZSH/oh-my-zsh.sh` 之后**，否则被 OMZ 的默认值 10000 覆盖。
- **自定义补全的 `fpath` 必须写在 `oh-my-zsh.sh` 之前**，否则 compinit 已跑完，补全不生效。
- **目录跳转由 zoxide 提供**：`cd`（frecency）与 `cdi`（交互）。不要再加 `z`/`zi` 别名 ——
  `zoxide query` 只打印路径不跳转。
- **NVM/Conda 默认按需初始化**：不要把 `nvm.sh` 或 `conda shell.zsh hook` 恢复到启动路径；首次 `node`、`npm`、`npx`、`nvm` 或 `conda activate` 必须仍能完成初始化。

## 依赖

- 工具：`zsh`、`oh-my-zsh`、`powerlevel10k`
- 外部：`conda`（`.zshrc` 内按需 init）、可选 `homebrew`、`kaku`（`~/.config/kaku`）

## 平台适配

- `DOTFILES_PLATFORM` 自动识别为 `macos` 或 `linux`，也可由主机 profile 覆盖。
- Homebrew、Conda、Java、pnpm、浏览器和剪贴板命令均优先使用环境变量或当前主机可发现的可执行文件。
- macOS 专属的 iCloud、WindowServer 和 `networksetup` 入口只在相应命令或目录存在时定义。

## 修改指南

- 添加别名 → 编辑 `.zshrc.aliases`
- 添加环境变量 → 编辑 `.zshrc.env`
- 修改 PATH / 登录逻辑 → 编辑 `.zprofile`
- 不要直接编辑 `~/.zshrc`（是 symlink）
