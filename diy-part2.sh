#!/bin/bash
# diy-part2.sh - ImmortalWrt 24.10 / MT7981 / Linux 6.6
# 执行时机: feeds update & install 之后，make 之前
# 作用: 修改默认设置 + 自动修复 .config 格式问题 + 追加必要包
set -e

echo "=========================================="
echo ">>> [diy-part2] 开始自定义配置..."
echo "=========================================="

# ============================================================
# 步骤 0: 自动修复 .config 中的格式错误（最关键！）
# ============================================================
echo ">>> [0/6] 修复 .config 格式问题..."

# 修复 "#CONFIG_xxx=y" → "CONFIG_xxx=y"（# 后缺空格导致配置失效）
sed -i 's/^#CONFIG_/CONFIG_/g' .config

# 修复 "# CONFIG_xxx is not set" 中多余的空格变体
sed -i 's/^# CONFIG_/CONFIG_/g' .config

# 删除不存在的包（会导致 make 报错）
sed -i '/CONFIG_PACKAGE_kmod-owf/d' .config
sed -i '/CONFIG_PACKAGE_kmod-udptunnel/d' .config

# 删除重复的 cmcc_xr30-nand 配置
sed -i '/CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_cmcc_xr30-nand/d' .config

echo "    .config 格式修复完成"

# ============================================================
# 步骤 1: 修改默认 LAN IP
# ============================================================
echo ">>> [1/6] 修改默认 IP..."
sed -i 's/192.168.1.1/192.168.61.1/g' package/base-files/files/bin/config_generate

# ============================================================
# 步骤 2: 修改主机名
# ============================================================
echo ">>> [2/6] 修改主机名..."
sed -i 's/ImmortalWrt/MT7981-Router/g' package/base-files/files/bin/config_generate

# ============================================================
# 步骤 3: 修改时区为 CST-8 / Asia/Shanghai
# ============================================================
echo ">>> [3/6] 修改时区..."
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
sed -i "/set system.@system\[-1\].zonename='UTC'/d" package/base-files/files/bin/config_generate
sed -i "/commit system/a\set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# ============================================================
# 步骤 4: 修改闭源 MTK WiFi SSID（mtwifi-cfg 的 .dat 文件）
# ============================================================
echo ">>> [4/6] 修改 WiFi SSID（闭源驱动）..."

# 查找 mtwifi-cfg 的 dat 文件（适配不同路径）
MTWIFI_DAT=""
for f in $(find package -name "mt7615*.dat" -o -name "mt7981*.dat" -o -name "mtwifi*.dat" 2>/dev/null); do
    if [ -f "$f" ]; then
        MTWIFI_DAT="$f"
        break
    fi
done

if [ -n "$MTWIFI_DAT" ]; then
    echo "    找到 WiFi 配置文件: $MTWIFI_DAT"
    sed -i 's/OpenWrt_2G/MT7981_2.4G/g' "$MTWIFI_DAT"
    sed -i 's/OpenWrt_5G/MT7981_5G/g' "$MTWIFI_DAT"
    # 设置默认开启 WiFi + WPA2
    sed -i 's/Disable=1/Disable=0/g' "$MTWIFI_DAT" 2>/dev/null || true
    sed -i 's/AuthMode=OPEN/AuthMode=WPA2PSK/g' "$MTWIFI_DAT" 2>/dev/null || true
    sed -i 's/EncrypType=NONE/EncrypType=AES/g' "$MTWIFI_DAT" 2>/dev/null || true
    # 设置默认密码
    sed -i 's/WPAPSK1=.*/WPAPSK1=12345678/g' "$MTWIFI_DAT" 2>/dev/null || true
    echo "    WiFi SSID 修改完成"
else
    echo "    ⚠️ 未找到 mtwifi dat 文件，尝试修改 uci 默认值..."
    # 备用方案：修改 package/mtk 下的默认 uci 配置
    UCI_WIFI=$(find package -name "wireless*" -path "*/mtk/*" 2>/dev/null | head -n1)
    if [ -n "$UCI_WIFI" ]; then
        sed -i 's/OpenWrt_2G/MT7981_2.4G/g' "$UCI_WIFI" 2>/dev/null || true
        sed -i 's/OpenWrt_5G/MT7981_5G/g' "$UCI_WIFI" 2>/dev/null || true
        echo "    通过 uci 配置修改完成"
    fi
fi

# ============================================================
# 步骤 5: 追加 .config 配置（启用关键包）
# ============================================================
echo ">>> [5/6] 追加 .config 配置..."

cat >> .config << 'EOF'

# ---------- 基础 LuCI（完整版，非精简 light） ----------
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lib-base=y
CONFIG_PACKAGE_luci-lib-ip=y
CONFIG_PACKAGE_luci-lib-jsonc=y
CONFIG_PACKAGE_luci-lib-nixio=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-wireguard=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-opkg=y
CONFIG_PACKAGE_luci-app-ttyd=y

# ---------- Argon 主题 ----------
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y

# ---------- 闭源 MTK WiFi 配置工具 ----------
CONFIG_PACKAGE_mtwifi-cfg=y
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y

# ---------- HWNAT 硬件加速 ----------
CONFIG_PACKAGE_kmod-mediatek-hnat=y
CONFIG_PACKAGE_turboacc-mtk=y
CONFIG_PACKAGE_luci-app-turboacc=y

# ---------- 中文语言包 ----------
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-network-zh-cn=y
CONFIG_PACKAGE_luci-i18n-system-zh-cn=y
CONFIG_PACKAGE_luci-i18n-status-zh-cn=y

# ---------- 实用工具 ----------
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_screen=y
CONFIG_PACKAGE_tmux=y
CONFIG_PACKAGE_openssh-sftp-server=y

# ---------- NTP 服务器 ----------
CONFIG_PACKAGE_ntpd=y
CONFIG_PACKAGE_ntpdate=y

EOF

echo "    .config 追加完成"

# ============================================================
# 步骤 6: 修改默认 NTP 服务器 & 版本信息
# ============================================================
echo ">>> [6/6] 修改 NTP 和版本信息..."

# 修改 NTP 服务器为国内可用地址
if [ -f package/base-files/files/etc/config/system ]; then
    sed -i 's/0.openwrt.pool.ntp.org/ntp.aliyun.com/g' package/base-files/files/etc/config/system 2>/dev/null || true
    sed -i 's/1.openwrt.pool.ntp.org/ntp.tencent.com/g' package/base-files/files/etc/config/system 2>/dev/null || true
fi

# 修改版本信息
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='ImmortalWrt 24.10 by guangyin53222'/" package/base-files/files/etc/openwrt_release
fi

# 修改 banner
if [ -f package/base-files/files/etc/banner ]; then
    cat > package/base-files/files/etc/banner << 'BANNER'

  ___ ___       _   _  ___   _  _     ___  
 |_ _/ _ \     /_\ | \| \ \ / | |   / __| 
  | | (_) |   / _ \| .` |\ V /| |__| (_ | 
 |___\___/   /_/ \_\_|\_| \_/ |____|\___| 
                                             
  ImmortalWrt 24.10 / MT7981 / Linux 6.6
  Built by guangyin53222

BANNER
fi

# ============================================================
# 最终处理
# ============================================================
echo ""
echo "=========================================="
echo ">>> [diy-part2] 所有自定义完成"
echo ">>> 正在运行 make defconfig 生成最终配置..."
echo "=========================================="

make defconfig

echo ""
echo "=========================================="
echo ">>> ✅ diy-part2.sh 执行完毕"
echo "=========================================="
