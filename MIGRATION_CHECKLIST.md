# Dotfiles Migration Checklist

这个清单基于当前机器 `$HOME` 的实际文件布局整理，目标是把适合纳管的配置逐步迁移到 `$HOME/dotfiles`，并保留跨平台适配边界。

## 当前状态

- [x] 目录已按包结构完成迁移。
- [x] 已建立软链接回原路径，并保留迁移前备份。
- [x] 已补充 `README.md`、`PHASE2_AUDIT.md` 和 `scripts/bootstrap.sh`。
- [x] 新机器恢复流程已明确：链接托管配置、手动实例化模板、单独安装依赖。
- [x] VS Code 扩展已改为通过可移植清单恢复，不再依赖新机器上的运行态 `extensions.json`。

## 推荐目录布局

建议按 `stow` 友好的结构组织：

```text
dotfiles/
  zsh/
    .zshrc
    .zprofile
    .zshenv
    .zshrc.aliases
    .p10k.zsh
  bash/
    .bashrc
    .bash_profile
    .profile
    .shinit
  tmux/
    .tmux.conf
  vim/
    .vimrc
  git/
    .gitconfig
    .config/git/ignore
  aerospace/
    .aerospace.toml
  terminal/
    .warprc
    .config/ghostty/config
    .config/starship.toml
  cli/
    .config/atuin/config.toml
    .config/btop/btop.conf
    .config/neofetch/config.conf
    .config/uv/uv.toml
    .config/yazi/init.lua
    .config/yazi/keymap.toml
    .config/yazi/package.toml
    .config/yazi/theme.toml
    .config/yazi/yazi.toml
  fish/
    .config/fish/config.fish
  editor/
    .vscode/argv.json
    .vscode/extensions/extensions.list
    .cursor/argv.json
    .config/zed/settings.json
  ai/
    .claude/CLAUDE.md
    .codex/AGENTS.md
    .codex/config.toml
```

## Phase 1: 先迁“安全且稳定”的配置

- [x] 迁移 shell 配置：`.zshrc`、`.zprofile`、`.zshenv`、`.zshrc.aliases`、`.p10k.zsh`。
- [x] 迁移兼容 shell 配置：`.bashrc`、`.bash_profile`、`.profile`、`.shinit`。
- [x] 迁移终端与 TUI 配置：`.tmux.conf`、`.vimrc`、`.aerospace.toml`、`.warprc`、`.config/ghostty/config`。
- [x] 迁移 CLI 工具配置：`.config/starship.toml`、`.config/atuin/config.toml`、`.config/btop/btop.conf`、`.config/neofetch/config.conf`、`.config/uv/uv.toml`。
- [x] 迁移文件管理器配置：`.config/yazi/init.lua`、`.config/yazi/keymap.toml`、`.config/yazi/package.toml`、`.config/yazi/theme.toml`、`.config/yazi/yazi.toml`。
- [x] 迁移 fish 配置：`.config/fish/config.fish`。
- [x] 迁移 Git 忽略规则和包清单：`.config/git/ignore`、`.config/brewfile/Brewfile`。
- [x] 迁移编辑器基础配置：`.vscode/argv.json`、`.cursor/argv.json`、`.config/zed/settings.json`，并把 VS Code 扩展改为可移植清单 `editor/.vscode/extensions/extensions.list`。
- [x] 迁移 agent 规则类文件：`.claude/CLAUDE.md`、`.codex/AGENTS.md`。

## Phase 2: 脱敏后再迁

- [x] 检查 `.gitconfig` 是否包含只适用于当前机器的用户名、邮箱、签名程序路径。
- [x] 检查 `.npmrc` 是否包含 registry token；如果有，改成模板或用环境变量注入。
- [x] 检查 `.condarc` 是否包含私有 channel、token 或内网地址。
- [x] 检查 `.ssh/config`；保留 host alias 和端口等规则，不要纳管任何私钥。
- [x] 检查 `.docker/config.json`；如果含登录态，改成模板。`.docker/daemon.json` 通常可直接纳管。
- [x] 检查 `.claude/settings.json`、`.claude.json`、`.claude/.ccg/config.toml` 是否包含账号、本机路径或敏感参数。
- [x] 检查 `.codex/config.toml` 是否包含只适用于本机的路径或本地实验配置。
- [x] 检查 `.config/mihomo/config.yaml` 是否包含机场订阅、节点信息或密钥。
- [x] 检查 `.config/cronboard/config.toml`、`.config/zotero-mcp/config.json`、`.config/kaku/assistant.toml` 是否包含 secret。
- [x] 评估 `.config/fish/fish_variables` 是否值得纳管；它更像“偏好 + 状态”的混合文件。

## Phase 3: 明确排除

- [x] 不纳管任何 history 文件：`.zsh_history`、`.bash_history`、`.python_history`、`.node_repl_history`、`.viminfo`。
- [x] 不纳管 shell 生成物：`.zcompdump*`、`.z`。
- [x] 不纳管备份和旧版本：`*.backup`、`*.old`、`*.kaku-backup-*`、`pre-oh-my-zsh`。
- [x] 不纳管日志、数据库、session、telemetry、cache：`.codex/history.jsonl`、`.claude/history.jsonl`、`*.sqlite`、`*.log`、`telemetry/`、`sessions/`、`debug/`。
- [x] 不纳管编辑器和工具的运行态目录，只保留配置文件本身，不要整目录复制。
- [x] 不纳管私钥和主机历史：`.ssh/id_*`、`.ssh/known_hosts*`。
- [x] 不纳管带 secret 的文件：`.codex/auth.json`、`.config/cronboard/secret.key` 等。

## 推荐迁移顺序

1. 先把 Phase 1 的文件复制到 `dotfiles/` 对应包目录。
2. 逐个 diff 当前家目录和新目录，确认没有把状态文件混进去。
3. 对 Phase 2 文件做模板化或拆分，例如把 token 改成环境变量。
4. 最后再初始化 Git 仓库，并补一份 `.gitignore`。

## 建议补的 `.gitignore`

```gitignore
.DS_Store
*.log
*.sqlite
*.sqlite-shm
*.sqlite-wal
*.backup
*.old
*kaku-backup*
**/.DS_Store
**/telemetry/
**/debug/
**/sessions/
**/history.jsonl
**/known_hosts
**/known_hosts.old
**/id_*
**/*.pem
**/*.key
```

## 下一个动作

- [x] 先按上面的目录布局创建包目录。
- [x] 从 `zsh`、`tmux`、`vim`、`aerospace`、`yazi` 这几组开始迁移。
- [x] 迁完后用 `stow` 或符号链接方式接管家目录。
- [x] 最后再把 `dotfiles` 初始化成 Git 仓库。
