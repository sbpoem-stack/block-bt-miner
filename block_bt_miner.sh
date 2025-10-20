#!/bin/bash
# ============================================
# 一键阻止 BT/Torrent 与加密货币矿池流量，并保存规则
# （适用于 Linux VPS，Windows 仅用于 GitHub 管理）
# ============================================

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行该脚本"
  exit 1
fi

# 依赖检测
if ! command -v iptables >/dev/null 2>&1; then
  echo "未检测到 iptables，请先安装"
  exit 1
fi

# 清理旧的 string OUTPUT 规则
iptables -S OUTPUT | grep -E 'string' | while read rule; do
  iptables -D OUTPUT ${rule#-A OUTPUT }
done

# 定义阻断关键词
keywords=(
  "torrent" ".torrent" "peer_id=" "announce" "info_hash" "get_peers" "find_node"
  "BitTorrent" "announce_peer" "BitTorrent protocol" "announce.php?passkey="
  "magnet:" "xunlei" "sandai" "Thunder" "XLLiveUD"
  "ethermine.com" "antpool.one" "antpool.com" "pool.bar" "seed_hash"
)

# 去重
unique_keywords=($(printf "%s\n" "${keywords[@]}" | sort -u))

# 添加 iptables 规则
for s in "${unique_keywords[@]}"; do
  iptables -A OUTPUT -m string --string "$s" --algo bm -j DROP
done

# 显示当前 OUTPUT 链规则
iptables -L OUTPUT -v --line-numbers

# 保存规则（Debian/Ubuntu）
if command -v iptables-save >/dev/null 2>&1; then
  iptables-save > /etc/iptables.rules
  # 自动在开机加载（Debian/Ubuntu）
  grep -q "iptables-restore < /etc/iptables.rules" /etc/rc.local 2>/dev/null || \
    (echo -e "#!/bin/sh -e\niptables-restore < /etc/iptables.rules\nexit 0" > /etc/rc.local && chmod +x /etc/rc.local)
fi

# CentOS/RHEL 系统可用 service iptables save
if command -v service >/dev/null 2>&1 && [ -f /etc/init.d/iptables ]; then
  service iptables save
fi

echo "阻断规则已应用并保存，重启后依然生效！"
