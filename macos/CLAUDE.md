# macos

> 面包屑：[dotfiles](../CLAUDE.md) > macos

## 职责

macOS 系统级集成：LaunchAgents 与配套的看护脚本。仅参与 macOS 平台还原，Linux 主机由 `bootstrap.sh` 跳过。

> 本模块的由来、完整诊断过程与机制说明见 [INCIDENT-2026-09-10-clash-dns-desync.md](./INCIDENT-2026-09-10-clash-dns-desync.md)。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.local/bin/clash-dns-guard.sh` | `~/.local/bin/clash-dns-guard.sh` | 断言 Clash Party TUN 生效期间默认网络服务的 DNS 为 `223.5.5.5` |
| `Library/LaunchAgents/com.skyang.clash-dns-guard.plist` | `~/Library/LaunchAgents/com.skyang.clash-dns-guard.plist` | 上者的触发器（RunAtLoad + StartInterval 120s + WatchPaths） |
| `INCIDENT-2026-09-10-clash-dns-desync.md` | 不链接（顶层 `*.md` 被 `should_skip_source` 跳过） | 引发本模块诞生的故障完整复盘 |

## 为什么需要 clash-dns-guard

Clash Party 的「DNS 覆写」只在 core 启动时跑一次，且用一个单槽备份 `originDNS` 当开关：

```js
async function setPublicDNS() {
  const { originDNS } = await getAppConfig();
  if (!originDNS) {                 // "Empty" 也是真值 → 条件不成立
    await getOriginDNS();
    await setDNS("223.5.5.5");      // ← 此后再也不执行
  }
}
```

任何一次非正常退出都会让该槽与现实脱节，覆写变成**永久空操作**，DNS 静默回落到路由器/ISP，代理对「按域名匹配」的规则整体失效且不自愈。

已知触发源（2026-09-10 的事故已定位为第 1 条）：

- 退出时 `recoverDNS()` 用 750ms 超时，而 helper 在后台照常完成操作 → DNS 被清空但 `originDNS` 残留（helper `/off` 实测首次耗时 15.75s）
- 崩溃、断电、`kill -9`
- 手动在系统设置里改 DNS
- 系统更新等场景下 `configd` 重建网络配置（未见实际发生，保留为可能性）

看护脚本**不读写 Clash Party 的任何配置**（避免与其内存态 `patchAppConfig` 竞争），只断言一个不变量：

```
mihomo TUN 存在  ⇒  默认网络服务的 DNS == 223.5.5.5
```

App 退出时 TUN 消失，脚本静默退出，因此不影响 `recoverDNS()` 的还原语义。

## 行为

- 前置条件任一不满足即静默 `exit 0`：非 macOS、`mihomo` 未运行、无 `198.18.0.0/16` 的 TUN 接口、helper socket 缺失、无默认路由
- 幂等：状态已正确时不写入、不记日志
- 只作用于**当前默认路由对应的网络服务**，因此换网络后会重新断言
- 通过 Clash Party 自带的特权 helper 改写 DNS（root），不需要 `sudo`
- 日志：`~/Library/Logs/clash-dns-guard.log`（自截断至 2000 行），仅记录修复与失败

## 常用命令

```bash
# 查看判定结果
~/.local/bin/clash-dns-guard.sh --status

# 预览将要执行的动作（不改动）
~/.local/bin/clash-dns-guard.sh --dry-run

# 看护日志
tail -20 ~/Library/Logs/clash-dns-guard.log

# 重载 LaunchAgent
launchctl bootout   gui/$(id -u)/com.skyang.clash-dns-guard 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.skyang.clash-dns-guard.plist
launchctl print gui/$(id -u)/com.skyang.clash-dns-guard | grep -E 'state|last exit'
```

## 修改指南

- 目标 DNS 或日志路径 → 改 `clash-dns-guard.sh` 顶部的 `readonly` 常量
- plist 里 `ProgramArguments` 使用绝对路径（与既有 `battery.plist` 一致）；换用户名需同步修改
- 若 Clash Party 更换了 TUN 网段，需同步更新 `TUN_CIDR_REGEX`

## 已知未处理

- `fake-ip-filter: ["*"]` 位于 Clash Party 的 `mihomo.yaml`，当前被订阅自带的 `dns:` 段覆盖而失效。若订阅去掉 `dns:` 段，该条会生效并**彻底废掉 fake-ip**。需从订阅源修复，未纳入本模块。
- Tailscale 的 `utun6` 上有一个 `Scoped` resolver（指向 `192.168.31.1`）。**已查证为 `configd` 的设计行为，不是残留**：Tailscale 服务的持久配置是 `DNS={'__INACTIVE__': True}`（对应 `tailscale dns status` 的 `Use Tailscale DNS: disabled`），而 `configd` 会为「已连接且自身未提供 DNS 的 VPN 接口」把当前 DHCP 下发的系统 DNS 镜像到接口作用域；对照组 Shadowrocket（同为 VPN、同为 `__INACTIVE__`，但 `Disconnected`）没有该条目。DNS 覆写只写 `Setup:`/`Global:` 层，不改变 DHCP 层，因此不会影响它。标记为 `Scoped`，仅对显式绑定该接口的查询生效，常态无影响，无需处理。
