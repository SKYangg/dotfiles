# 事件复盘：Clash Party DNS 覆写失效导致代理下 Google 不可用

> **日期**：2026-09-10
> **状态**：已修复（App 层状态复位 + 新增自愈看护）
> **影响范围**：Clash Party TUN 模式下全部「按域名匹配」的规则失效；`google.com` / `youtube.com` 等域名不可达
> **相关模块**：[macos/CLAUDE.md](./CLAUDE.md)

---

## 1. 现象

用户报告：「代理访问 `google.com` 不通」。

与直觉相反的是，**代理本身完全正常**：

```console
$ curl -x http://127.0.0.1:7890 https://www.google.com     # 显式走代理
200  (2.19s)

$ curl https://www.google.com                              # 走系统 DNS
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL
```

同一个代理，显式指定时 200，走系统解析就失败 —— 说明问题不在代理链路，而在**解析结果**。

---

## 2. 环境

| 项目 | 值 |
|---|---|
| 系统 | macOS 27.0 (26A428)，本次重启于 14:51:55 |
| 代理 | Clash Party，mihomo `v1.19.29`，特权 helper `v1.1.0` |
| TUN | `utun1500`，`198.18.0.1/30`，`auto-route: true`，`dns-hijack: any:53` |
| DNS | `enhanced-mode: fake-ip`，`fake-ip-range: 198.18.0.1/16` |
| 上游 | 路由器 `192.168.31.1`（小米），IPv6 `fd00:6868:6868::1` |
| 订阅 | `cyber-nomad.yaml`（远程，自带 `dns:` 段） |
| 监听 | mixed `7890`、socks `7891`、http `7892`；helper socket `/tmp/mihomo-party-helper.sock` |

---

## 3. 诊断过程

诊断按「从外到内」四层推进，每层都有可复现的证据。

### 3.1 第一层：代理链路正常

```
curl -x http://127.0.0.1:7890 https://www.google.com   → 200
curl --resolve www.google.com:443:142.251.45.142 ...   → 200   # 真实 Google IP，走 TUN
curl --resolve www.google.com:443:198.18.0.23  ...     → 200   # Clash fake-ip
```

节点存活、规则匹配、fake-ip 反查全部正常。

### 3.2 第二层：系统解析出来的 IP 是错的

```
$ dig +short www.google.com
157.240.7.20                     # ← 这是 Facebook 的 IP，不是 Google 的
$ dig +short AAAA www.google.com
2001::1                          # ← Teredo 占位地址，垃圾数据

$ curl --resolve www.google.com:443:157.240.7.20 https://www.google.com
curl: (35) SSL_ERROR_SYSCALL     # 连到错误 IP，TLS 必然失败
```

### 3.3 第三层：Clash 的 DNS 是好的，只是没被问到

```
$ dig @192.168.31.1 www.google.com   → 157.240.7.20     # 路由器：污染
$ dig @223.5.5.5    www.google.com   → 198.18.0.23      # 被劫持 → Clash 正确返回 fake-ip
$ dig @198.18.0.1   www.google.com   → 198.18.0.23      # Clash TUN 自身
```

关键差异：`192.168.31.1` 与 en0 **同网段**，路由表标记为 **on-link**：

```
$ route -n get 192.168.31.1
interface: en0                   # 无 gateway，直连
```

同网段流量**永远不进入 utun1500**，因此 Clash 的 `dns-hijack: any:53` 拦不到它。而 `223.5.5.5` 是远端地址，命中 mihomo 的 auto-route 分割路由（`1/8, 2/7, 4/6, 8/5, 16/4, 32/3, 64/2, 128/1` → `198.18.0.1` @ `utun1500`），进入 TUN 后即被劫持。

**结论：系统的 DNS 出口指向了局域网路由器，绕过了 Clash。**

### 3.4 第四层：为什么 App 的「DNS 覆写」没生效

Clash Party 有 `autoSetDNS` 机制，本应把默认网络服务的 DNS 改成远端地址。但：

- helper 日志中**完全没有 `/dns` 请求**，说明覆写从未执行
- App 配置里却残留着 `originDNS: Empty`（备份槽被占用）

两者矛盾 —— 备份槽存在意味着「App 认为覆写正在进行中」，但实际没有。

---

## 4. 根因

### 4.1 直接原因：`originDNS` 单槽状态机

`app.asar` 中的实际实现：

```js
async function setPublicDNS() {
  if (process.platform !== "darwin") return;
  if (net.isOnline()) {
    const { originDNS } = await getAppConfig();
    if (!originDNS) {                       // ← "Empty" 是 JS 真值，条件不成立
      await getOriginDNS();                 //   备份原值 → originDNS
      await setDNS("223.5.5.5");            //   写入覆写值 ← 再也不会执行
    }
  } else { /* 5s 后重试 */ }
}
```

`originDNS` 的存在被当作「覆写已生效」的标志（它同时是备份槽和开关）。一旦这个槽与现实脱节，`setPublicDNS()` 就变成**永久空操作**，且没有任何自愈路径。

### 4.2 触发路径：`recoverDNS` 的 750ms 超时

退出路径：

```js
async function stopCoreForExit() {
  coreOperationPhase = "shutting-down";
  cancelAutomaticRestart();
  stopCoreProcessAndStreams();                         // ① 先杀 mihomo
  await Promise.allSettled([
    recoverDNS({ force: true, timeout: 750 }),         // ② 再还原 DNS
    cleanupStoppedCoreResources()
  ]);                                                  // ③ 异常被 allSettled 吞掉
}

async function recoverDNS(options = {}) {
  if (originDNS) {
    await setDNS(originDNS, options.timeout);          // ← 超时即抛
    await patchAppConfig({ originDNS: void 0 });       // ← 永远到不了
  }
}

async function setDNS(dns, timeout) {
  try {
    await axios.post("http://localhost/dns", { service, dns }, { socketPath, timeout });
  } catch (error) {
    if (timeout !== void 0) throw error;               // ← 带 timeout 时不回退 osascript
    /* osascript 弹窗回退 */
  }
}
```

**核心矛盾**：helper 是 root 常驻进程，客户端的 750ms 超时**不会中断它** —— 它照旧把 DNS 清空并返回 `200`；但客户端此时已经抛异常，`patchAppConfig({ originDNS: void 0 })` 不再执行。

> 实测佐证：helper 的 `/off` 首次调用耗时 **15.75s**（遍历全部网络服务），第二次 1.69s；单独的 `/dns` 只要 42ms。说明 750ms 在某些状态下确实不够。

于是产生精确的失同步签名：

```
DNS         = 空（已还原成 DHCP）
originDNS   = "Empty"（备份槽未清）
```

### 4.3 完整成因链

```
① 关机/重启（本次由系统更新触发）
      ↓
② stopCoreForExit() → recoverDNS({force, timeout:750})
      ↓
③ helper 后台成功清空 DNS，客户端 750ms 超时抛异常
      ↓
④ originDNS: "Empty" 残留，patchAppConfig 未执行
      ↓
⑤ 重启后 setPublicDNS() 因 !originDNS 为假而空转
      ↓
⑥ 系统 DNS 落到路由器 192.168.31.1（on-link，绕过 TUN）
      ↓
⑦ 返回污染 IP 157.240.7.20 → TLS 失败
```

### 4.4 被推翻的假设（诊断过程中的两次修正）

**假设 A（错误）："更新重写了网络配置，把 DNS 重置回 DHCP"**

一度认为系统更新是元凶，依据是 `/Library/Preferences/SystemConfiguration/` 下同时出现的三个 14:53 时间戳文件。深入比对后推翻：

```
更新前 (preferences-pre-upgrade-source)
    CurrentSet = /Sets/A57B12E9-...     Wi-Fi 7867BF07 DNS = {}   ← 更新前就是空的

更新提议 (preferences-pre-upgrade-new-target)
    CurrentSet = /Sets/0F5DDBD3-...     新 Wi-Fi UUID B342A63F DNS = {}

当前
    CurrentSet = /Sets/A57B12E9-...     ← 与更新前完全一致
    0F5DDBD3 是否在当前配置中: False
    B342A63F 是否在当前服务中: False
```

更新**准备**了替代配置，但**从未被采纳**。`NetworkInterfaces.plist` 唯一变化是 `en6` 的 `Active: True → None`，与 DNS 无关。

→ 更新只是**恰好同时发生**（重启是更新的前置动作）。真正原因是确定性 bug，**每次关机都可能复现**。这个修正很重要：它把问题从「外部不可控事件」收敛为可测试、可防护的软件缺陷。

**假设 B（错误）："utun6 上的 resolver 是更新残留"**

见 §6.4，实为 `configd` 的设计行为。

**其他可产生同一签名的路径**：`getOriginDNS()` 成功而 `setDNS()` 失败（例如 helper 不可用）。当前看护脚本对两类路径都有效。

---

## 5. 修复

### 5.1 一次性复位（App 层）

| 操作 | 结果 |
|---|---|
| 删除残留的 `originDNS: Empty` | 解开空操作锁 |
| 补上显式 `autoSetDNS: true` | 该键原本缺失，代码默认 `true` 但 GUI 复选框读 `isSelected: autoSetDNS` → `undefined` → 界面显示「未勾选」，与实际行为不符 |
| 退出 App 触发 `recoverDNS` | helper `POST /dns` 42ms 清空 Wi-Fi DNS、清空备份槽（验证退出路径本身是健康的） |
| 重启 App 触发 `setPublicDNS` | Wi-Fi DNS = `223.5.5.5`，`originDNS: Empty` 重新落盘 |

### 5.2 长期修复：自愈看护（`macos/` 模块）

因为 `originDNS` 这个单点状态本质上脆弱，加了常驻看护。详情见 [macos/CLAUDE.md](./CLAUDE.md)。

| 文件 | 作用 |
|---|---|
| `.local/bin/clash-dns-guard.sh` | 断言不变量 |
| `Library/LaunchAgents/com.skyang.clash-dns-guard.plist` | RunAtLoad + StartInterval 120s + WatchPaths |

**不变量**：

```
mihomo TUN 存在  ⇒  默认网络服务的 DNS == 223.5.5.5
```

**关键设计决定：脚本不读也不写 Clash Party 的任何配置。** 原计划是去清除 `originDNS` 脏标记，但那会与 App 内存态的 `patchAppConfig` 抢写 config.yaml。改为只断言 DNS 本身后：

- 即使 App 的状态机彻底卡死，DNS 也始终正确
- App 退出时 TUN 先消失，脚本静默退出，`recoverDNS()` 的还原语义完全不受影响（`stopCoreProcessAndStreams()` 在 `recoverDNS` 之前执行，天然无竞态）

覆盖面：

| 隐患 | 如何覆盖 |
|---|---|
| `originDNS` 失同步 | 不再依赖 App 自愈 |
| 只处理启动时那一个服务 | 每次重新解析当前默认路由对应的服务，换网络后自动重新断言 |
| 开机自启竞态 | `RunAtLoad` + 120s 周期兜底 |
| helper 调用 | 走 App 自带的 root helper，不需要 `sudo` |

### 5.3 验证

**端到端故障复现测试**（用与 bug 完全相同的方式制造失同步）：

```
15:52:26  helper 收到 dns=Empty            ← 制造的故障
          dig www.google.com → 157.240.7.20（与最初问题同一个污染 IP）
15:52:32  helper 收到 dns=223.5.5.5        ← LaunchAgent 自动修复，无人工干预
15:52:33  REPAIRED service='Wi-Fi' device='en0' before='<none>'
          dig www.google.com → 198.18.0.23
```

`launchctl print` 确认 `runs = 2`、`last exit code = 0`。

**最终状态**：

```
networksetup -getdnsservers Wi-Fi  → 223.5.5.5
grep originDNS config.yaml         → originDNS: Empty
dig www.google.com                 → 198.18.0.23
https://www.google.com             → 200 (2.13s)
https://www.youtube.com            → 200 (2.82s)
https://www.baidu.com              → 200 (0.08s)    ← 直连未受影响
```

---

## 6. 机制参考

### 6.1 「DNS 覆写」的实现

`app.asar` 中的实际动作，本质是**用特权 helper 调用 `networksetup -setdnsservers`**：

```js
async function getDefaultService() {              // 默认路由网卡 → 网络服务名
  const device = await getDefaultDevice();
  const { stdout: order } = await execPromise(`networksetup -listnetworkserviceorder`);
  const block = order.split("\n\n").find((s) => s.includes(`Device: ${device}`));
  for (const line of block.split("\n"))
    if (line.match(/^\(\d+\).*/)) return line.trim().split(" ").slice(1).join(" ");
}

async function getOriginDNS() {                   // 备份原值
  const { stdout: dns } = await execPromise(`networksetup -getdnsservers "${service}"`);
  if (dns.startsWith("There aren't any DNS Servers set on"))
    await patchAppConfig({ originDNS: "Empty" }); // 哨兵值
  else
    await patchAppConfig({ originDNS: dns.trim().replace(/\n/g, " ") });
}

async function setDNS(dns, timeout) {             // 覆写
  try { await axios.post("http://localhost/dns", { service, dns }, { socketPath, timeout }); }
  catch (error) { /* 见 §4.2 */ }
}
```

helper（`/Library/PrivilegedHelperTools/party.mihomo.helper`，launchd daemon，Go + Gin）暴露：

| 路由 | 作用 |
|---|---|
| `POST /pac` | 设置 PAC 代理（全部服务） |
| `POST /global` | 设置全局代理 |
| `POST /dns` | **设置 DNS**（按请求中的 `service`） |
| `GET /off` | 关闭全部代理设置 |

注意两点：

- `autoSetDNS` 在 config.yaml 中**并不存在**，代码用解构默认值 `= true` → 行为上默认开启。但 GUI 复选框绑 `isSelected: autoSetDNS` → 界面会显示为未勾选。
- 覆写只作用于**默认路由对应的那一个网络服务**，其他服务不动。

### 6.2 为什么把 DNS 改成远端地址就能通

关键**不是「换了个更好的 DNS」，而是路由归属变了**：

| | `192.168.31.1` | `223.5.5.5` |
|---|---|---|
| 与 en0 关系 | 同网段 `192.168.31.0/24` | 远端 |
| 路由 | **on-link**，`interface: en0`，无 gateway | 命中 auto-route → `198.18.0.1` @ `utun1500` |
| 进入 TUN | ❌ | ✅ |
| `dns-hijack: any:53` | 拦不到 | 拦到 |

完整闭环：

1. DNS 包发往 `223.5.5.5:53` → 进 `utun1500`
2. mihomo 见目标端口 53，命中 `dns-hijack: any:53`，**不当普通连接转发**，交给内置 DNS
3. 按 `nameserver` 解析，因 `enhanced-mode: fake-ip` 返回假 IP（`198.18.0.23`）
4. 应用连 `198.18.0.23` → 又进 TUN → 依据 `profile.store-fake-ip: true` 的映射**反查回真实域名** → 按域名跑规则（`DomainSuffix: google.com → 🔎 Google Scholar`）→ 走代理

**真正的收益**：域名信息不会在本地被污染或丢失，规则始终按域名匹配，而不是按一个可能错的 IP。

### 6.3 macOS DNS 的三层模型

理解本次问题必须区分这三层（`scutil` 可分别查看）：

```
Setup:  /Network/Service/<svc>/DNS    手工/程序设定的 DNS
                                       ← networksetup -setdnsservers 写这里
State:  /Network/Service/<svc>/DNS    该服务从网络（DHCP/PPP）拿到的 DNS
Global: /Network/Global/DNS           实际生效的解析器
                                       __CONFIGURATION_ID__ 指向胜出的服务
```

本次的实际取值：

```
Setup:  /Network/Service/7867BF07/DNS = 223.5.5.5       ← 覆写写在这里
State:  /Network/Service/7867BF07/DNS = 192.168.31.1    ← DHCP 原值，未被改动
Global: /Network/Global/DNS           = 223.5.5.5       ← 生效值
State:  /Network/Service/41B1EDF0/DNS = 192.168.31.1    ← 镜像到 utun6 的作用域
```

两点推论：

- `scutil --proxy` 看不到 DNS（那是代理设置），要用 `networksetup -getdnsservers` 或 `scutil --dns`
- 覆写只改 `Setup:`/`Global:`，**不触碰 `State:`**，因此所有从 DHCP 层派生的东西都不受影响（见下节）

### 6.4 `utun6` 上的 scoped resolver 从哪来（**设计行为，非故障**）

一度被误判为「更新残留」。查证结论：这是 `configd` 的既定行为。

**证据 1 —— 不是 Tailscale 写的**

```
持久配置:  [Tailscale] id=41B1EDF0  DNS={'__INACTIVE__': True}
tailscale dns status → Use Tailscale DNS: disabled / MagicDNS: disabled tailnet-wide
                       Resolvers: (no resolvers configured)
```

**证据 2 —— 是 `configd` 补的**

```
State:/Network/Service/41B1EDF0-.../DNS {
  InterfaceName : utun6                                    ← 生成「接口作用域 resolver」才填
  ServerAddresses : [192.168.31.1, fd00:6868:6868::1]
}
```

`InterfaceName` 是结构性字段；地址与 Wi-Fi 的 `State:` 值逐字相同，即 DHCP 下发的系统 DNS。

**证据 3 —— 对照组排除随机残留**

| VPN 服务 | 连接状态 | 自身 DNS | 有 State DNS 条目？ |
|---|---|---|---|
| Tailscale `41B1EDF0` | **Connected** | `__INACTIVE__` | **有**（镜像 DHCP 值） |
| Shadowrocket `825993BD` | Disconnected | `__INACTIVE__` | **无** |

→「已连接、自身未提供 DNS 的 VPN 接口，`configd` 会把当前系统 DNS 镜像到它的接口作用域」是条件性行为。

**影响面**：`flags: Scoped`，仅对显式绑定该接口（`IP_BOUND_IF`）的查询生效；普通应用走 Global。且 Tailscale 装的是 **ifscope** default 路由（`UCSIg` 的 `I`），不会抢主路由。

**结论：常态无影响，无需处理。** 想清掉只能让 `configd` 重新评估该接口的作用域配置（断开重连 Tailscale，会短暂断 VPN）—— 不值得。

---

## 7. 未决事项

| 项 | 状态 |
|---|---|
| `mihomo.yaml` 的 `fake-ip-filter: ["*"]` | **待从订阅源修复**。当前被订阅自带的 `dns:` 段覆盖而失效；一旦订阅去掉 `dns:` 段，该条生效会**彻底废掉 fake-ip**（所有域名返回真实 IP，域名规则退化为依赖 sniffer 嗅探）。`- "*"` 看起来是误配 |
| helper socket 无鉴权 | **建议向上游提 issue**，见 §8.2 |
| `utun6` scoped resolver | 已查证为设计行为，不处理 |

---

## 8. 顺带发现

### 8.1 仓库漂移（已修复）

`bootstrap.sh --dry-run` 显示 7 项待链接，其中 5 项是**非预期**的：包内文档与测试目录会被散落到 `$HOME` 根目录。

```
vim/maintenance.md      -> ~/maintenance.md
vim/practical-guide.md  -> ~/practical-guide.md
vim/tests/*             -> ~/tests/*
git/template_ignore     -> ~/template_ignore       （已实际产生，已清理）
```

已修正（详见 `scripts/bootstrap.sh` 的 `should_skip_source`）：

| 规则 | 覆盖 |
|---|---|
| 泛化包顶层文档 `*/*.md`（原为仅 `*/CLAUDE.md`） | `vim/maintenance.md`、`vim/practical-guide.md` |
| 新增 `*/tests/*` | `vim/tests/*` |
| `SKIP_SOURCES` 新增 `git/template_ignore` | 155 行参考模板；真正生效的是 1 行的 `git/.config/git/ignore` |

验证方式：用临时 `--home` 跑全量 dry-run 做前后对比，**只**移除 5 个非预期条目（81 → 76），无其他增删。嵌套文档（如 `cli/.config/yazi/plugins/<name>/README.md`）仍正常链接。

### 8.2 安全发现：特权 helper socket 无鉴权且 world-writable

```console
$ ls -la /tmp/mihomo-party-helper.sock /tmp/mihomo-party-501-*.sock
srw-rw-rw-  1 root  wheel  /tmp/mihomo-party-helper.sock
srw-rw-rw-  1 root  wheel  /tmp/mihomo-party-501-<pid>.sock
```

- helper 以 **root** 运行，暴露 `POST /pac`、`POST /global`、`POST /dns`、`GET /off`，**没有调用方校验**
- 任意本地用户/进程都能借此以 root 身份改写系统 DNS 与系统代理设置
- mihomo 的 API socket 同样 `0666`，任意本地用户可改代理配置、读连接列表（含访问的目标域名）

这是本地权限边界穿越（非远程可利用，但多用户机器或任何被攻陷的用户态进程都能用）。本次排查过程中正是借此在无 `sudo` 的情况下完成 DNS 操作。

**无法从配置侧修复**：socket 属主是 root，`chmod 600` 会让 App 自己（普通用户身份）也连不上。真正修法需要上游用 `getpeereid` 校验调用方 uid。

---

## 9. 教训

1. **单一状态位同时承担「备份」和「开关」两种语义**是这类 bug 的温床。`originDNS` 既是备份槽又是「覆写进行中」的标志，一旦两者脱节就永久失效，且没有任何自愈路径。设计上应当用独立的、可从现实反推的状态。

2. **客户端超时不等于服务端中止。** 750ms 的 axios 超时只中止了客户端等待，root helper 照常完成操作 —— 这使「DNS 被改」与「备份槽被清」变成两个不会同时发生的事件。

3. **`Promise.allSettled` 会静默吞掉失败。** 退出路径的异常没有任何用户可见反馈，问题只在下次启动时以完全不同的面貌（Google 不通）暴露出来。

4. **「on-link 会绕过 TUN」是排查此类问题的第一个检查点。** DNS 指向同网段地址时，`dns-hijack` 永远不会生效。

5. **不要被时间戳巧合带偏。** `NetworkInterfaces-pre-upgrade-*.plist` 的存在让我一度错误归因于系统更新。区分「更新**写了**候选配置」和「更新**采用了**该配置」需要比对 `CurrentSet` —— 这次差一点把一个确定性 bug 归因成不可控的外部事件。

6. **诊断结论要标注置信度。** 本次有两次公开修正（§4.4），都是因为把「相关性」当成了「因果性」。事后补齐对照组（Shadowrocket vs Tailscale）和前后快照（`preferences-pre-upgrade-*`）才得到确定结论。
