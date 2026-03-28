# Dotfiles Migration Checklist

这个清单基于当前机器 `/Users/skyang` 的实际文件布局整理，目标是把适合纳管的配置逐步迁移到当前目录 `/Users/skyang/dotfiles`。

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
    .vscode/extensions/extensions.json
    .cursor/argv.json
    .config/zed/settings.json
  ai/
    .claude/CLAUDE.md
    .codex/AGENTS.md
    .codex/config.toml
```

## Phase 1: 先迁“安全且稳定”的配置

- [ ] 迁移 shell 配置：`.zshrc`、`.zprofile`、`.zshenv`、`.zshrc.aliases`、`.p10k.zsh`。
- [ ] 迁移兼容 shell 配置：`.bashrc`、`.bash_profile`、`.profile`、`.shinit`。
- [ ] 迁移终端与 TUI 配置：`.tmux.conf`、`.vimrc`、`.aerospace.toml`、`.warprc`、`.config/ghostty/config`。
- [ ] 迁移 CLI 工具配置：`.config/starship.toml`、`.config/atuin/config.toml`、`.config/btop/btop.conf`、`.config/neofetch/config.conf`、`.config/uv/uv.toml`。
- [ ] 迁移文件管理器配置：`.config/yazi/init.lua`、`.config/yazi/keymap.toml`、`.config/yazi/package.toml`、`.config/yazi/theme.toml`、`.config/yazi/yazi.toml`。
- [ ] 迁移 fish 配置：`.config/fish/config.fish`。
- [ ] 迁移 Git 忽略规则和包清单：`.config/git/ignore`、`.config/brewfile/Brewfile`。
- [ ] 迁移编辑器基础配置：`.vscode/argv.json`、`.vscode/extensions/extensions.json`、`.cursor/argv.json`、`.config/zed/settings.json`。
- [ ] 迁移 agent 规则类文件：`.claude/CLAUDE.md`、`.codex/AGENTS.md`。

## Phase 2: 脱敏后再迁

- [ ] 检查 `.gitconfig` 是否包含只适用于当前机器的用户名、邮箱、签名程序路径。
- [ ] 检查 `.npmrc` 是否包含 registry token；如果有，改成模板或用环境变量注入。
- [ ] 检查 `.condarc` 是否包含私有 channel、token 或内网地址。
- [ ] 检查 `.ssh/config`；保留 host alias 和端口等规则，不要纳管任何私钥。
- [ ] 检查 `.docker/config.json`；如果含登录态，改成模板。`.docker/daemon.json` 通常可直接纳管。
- [ ] 检查 `.claude/settings.json`、`.claude.json`、`.claude/.ccg/config.toml` 是否包含账号、本机路径或敏感参数。
- [ ] 检查 `.codex/config.toml` 是否包含只适用于本机的路径或本地实验配置。
- [ ] 检查 `.config/mihomo/config.yaml` 是否包含机场订阅、节点信息或密钥。
- [ ] 检查 `.config/cronboard/config.toml`、`.config/zotero-mcp/config.json`、`.config/kaku/assistant.toml` 是否包含 secret。
- [ ] 评估 `.config/fish/fish_variables` 是否值得纳管；它更像“偏好 + 状态”的混合文件。

## Phase 3: 明确排除

- [ ] 不纳管任何 history 文件：`.zsh_history`、`.bash_history`、`.python_history`、`.node_repl_history`、`.viminfo`。
- [ ] 不纳管 shell 生成物：`.zcompdump*`、`.z`。
- [ ] 不纳管备份和旧版本：`*.backup`、`*.old`、`*.kaku-backup-*`、`pre-oh-my-zsh`。
- [ ] 不纳管日志、数据库、session、telemetry、cache：`.codex/history.jsonl`、`.claude/history.jsonl`、`*.sqlite`、`*.log`、`telemetry/`、`sessions/`、`debug/`。
- [ ] 不纳管编辑器和工具的运行态目录，只保留配置文件本身，不要整目录复制。
- [ ] 不纳管私钥和主机历史：`.ssh/id_*`、`.ssh/known_hosts*`。
- [ ] 不纳管带 secret 的文件：`.codex/auth.json`、`.config/cronboard/secret.key` 等。

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

- [ ] 先按上面的目录布局创建包目录。
- [ ] 从 `zsh`、`tmux`、`vim`、`aerospace`、`yazi` 这几组开始迁移。
- [ ] 迁完后用 `stow` 或符号链接方式接管家目录。
- [ ] 最后再把 `dotfiles` 初始化成 Git 仓库。
