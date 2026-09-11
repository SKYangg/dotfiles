#!/usr/bin/env bash
#
# clash-dns-guard.sh — 保证 Clash Party 的 TUN 生效期间，当前默认网络服务的 DNS
#                      被覆写为 223.5.5.5。
#
# 为什么需要它
# ------------
# Clash Party 的「DNS 覆写」只在 core 启动时执行一次 (setPublicDNS())，并且用一个
# 单槽备份 originDNS 当开关：
#
#     async function setPublicDNS() {
#       const { originDNS } = await getAppConfig();
#       if (!originDNS) {                  // "Empty" 也是真值 → 条件不成立
#         await getOriginDNS();
#         await setDNS("223.5.5.5");       // ← 再也不会执行
#       }
#     }
#
# 任何一次非正常退出都会让这个槽与现实脱节，之后覆写变成永久空操作，DNS 悄悄回落到
# 路由器/ISP，代理对「按域名匹配」的规则整体失效，而且不会自愈。已知触发源：
#
#   * 退出时 recoverDNS() 用 750ms 超时，helper 却在后台照常完成操作 →
#     DNS 被清空但 originDNS 残留（helper /off 实测首次耗时 15.75s）
#   * macOS 系统更新重写 /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
#     （2026-09-10 的 macOS 27.0 更新就是这样把本次环境打坏的）
#   * 崩溃、断电、kill -9
#   * 手动在系统设置里改 DNS
#
# 本脚本的立场
# ------------
# 不读取、不修改 Clash Party 的任何配置（避免与其内存态 patchAppConfig 竞争），
# 只断言一个不变量：
#
#     mihomo TUN 存在  ⇒  默认网络服务的 DNS == 223.5.5.5
#
# 于是即使 App 自己的 originDNS 状态机卡死，DNS 也始终正确。App 退出时的
# recoverDNS() 语义不受影响，因为此时 TUN 已消失，脚本会直接静默退出。
#
# 说明
# ----
#   * 通过 Clash Party 自带的特权 helper（以 root 运行）改写 DNS，因此无需 sudo
#   * 幂等：状态已正确时不产生任何写入，也不写日志
#   * 只作用于「当前默认路由对应的网络服务」，因此换网络（Wi-Fi/热点/USB 网卡）
#     后也会重新断言，覆盖了 App 只处理启动时那一个服务的缺口
#
# 用法: clash-dns-guard.sh [--dry-run] [--status]

set -uo pipefail

readonly TARGET_DNS="223.5.5.5"
readonly HELPER_SOCK="/tmp/mihomo-party-helper.sock"
readonly LOG_FILE="${HOME}/Library/Logs/clash-dns-guard.log"
readonly LOG_MAX_LINES=2000

# mihomo 的 fake-ip-range 默认是 198.18.0.0/16，TUN 接口会持有该网段的一个地址。
# 用「进程 + TUN 网段」双重判断，避免在 TUN 关闭（仅系统代理模式）时误改 DNS。
readonly TUN_CIDR_REGEX='inet 198\.18\.'

DRY_RUN=0
STATUS_ONLY=0

usage() {
  cat <<'EOF'
Usage: clash-dns-guard.sh [options]

Assert that the default network service's DNS is 223.5.5.5 while the
Clash Party TUN is active.

Options:
  --dry-run   Report what would change without modifying anything
  --status    Print the current verdict to stdout and exit
  -h, --help  Show this help
EOF
}

log() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$$" "$*" >>"${LOG_FILE}" 2>/dev/null
}

# 非关键条件一律安静退出（exit 0），避免 launchd 把常态误判成失败。
skip() { [[ "${STATUS_ONLY}" -eq 1 ]] && printf 'skip: %s\n' "$*"; exit 0; }

rotate_log() {
  [[ -f "${LOG_FILE}" ]] || return 0
  local n
  n=$(wc -l <"${LOG_FILE}" 2>/dev/null) || return 0
  (( n > LOG_MAX_LINES )) || return 0
  tail -n $((LOG_MAX_LINES / 2)) "${LOG_FILE}" >"${LOG_FILE}.tmp" 2>/dev/null &&
    mv "${LOG_FILE}.tmp" "${LOG_FILE}" 2>/dev/null
}

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --status) STATUS_ONLY=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v networksetup >/dev/null 2>&1 || skip "not macOS"
mkdir -p "$(dirname -- "${LOG_FILE}")" 2>/dev/null
rotate_log

# --- 前置条件：Clash Party 的 TUN 是否真的生效 --------------------------------

pgrep -x mihomo >/dev/null 2>&1 || skip "mihomo not running"
ifconfig 2>/dev/null | grep -qE "${TUN_CIDR_REGEX}" || skip "mihomo TUN interface not found"
[[ -S "${HELPER_SOCK}" ]] || skip "privileged helper socket missing: ${HELPER_SOCK}"

# --- 解析「默认路由 → 网络服务名」 --------------------------------------------

dev="$(route -n get default 2>/dev/null | awk '/^[[:space:]]*interface:/{print $2; exit}')"
[[ -n "${dev}" ]] || skip "no default route"

service="$(networksetup -listnetworkserviceorder 2>/dev/null | awk -v d="${dev}" '
  /^\([0-9]+\) / { svc = $0; sub(/^\([0-9]+\) /, "", svc); next }
  /Device: /     { if (index($0, "Device: " d ")") > 0) { print svc; exit } }
')"
[[ -n "${service}" ]] || skip "no network service bound to device ${dev}"

# --- 读当前 DNS ---------------------------------------------------------------

read_dns() {
  local out
  out="$(networksetup -getdnsservers "$1" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  case "${out}" in
    *"There aren't any DNS Servers set on"*) printf '' ;;
    *) printf '%s' "${out}" ;;
  esac
}

current="$(read_dns "${service}")"

if [[ "${current}" == "${TARGET_DNS}" ]]; then
  [[ "${STATUS_ONLY}" -eq 1 ]] && printf 'ok: service=%s device=%s dns=%s\n' "${service}" "${dev}" "${TARGET_DNS}"
  exit 0
fi

# --- 修复 ---------------------------------------------------------------------

if [[ "${STATUS_ONLY}" -eq 1 ]]; then
  printf 'desync: service=%s device=%s dns=%s expected=%s\n' \
    "${service}" "${dev}" "${current:-<none>}" "${TARGET_DNS}"
  exit 1
fi

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "DRY-RUN would repair service='${service}' device='${dev}' before='${current:-<none>}'"
  printf 'dry-run: would set %s -> %s\n' "${service}" "${TARGET_DNS}"
  exit 0
fi

payload="{\"service\":\"$(json_escape "${service}")\",\"dns\":\"${TARGET_DNS}\"}"
response="$(curl -sS --max-time 15 --unix-socket "${HELPER_SOCK}" \
  -X POST "http://localhost/dns" \
  -H 'Content-Type: application/json' \
  -d "${payload}" 2>&1)"

after="$(read_dns "${service}")"

if [[ "${after}" == "${TARGET_DNS}" ]]; then
  log "REPAIRED service='${service}' device='${dev}' before='${current:-<none>}' helper='${response}'"
else
  log "REPAIR-FAILED service='${service}' device='${dev}' before='${current:-<none>}' after='${after:-<none>}' helper='${response}'"
  exit 1
fi
