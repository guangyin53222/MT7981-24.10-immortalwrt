#!/bin/bash
# diy-part2.sh - ImmortalWrt 24.10 / MT7981 / Linux 6.6
# 执行时机: feeds update & install 之后
# 作用: 修改默认 IP / 主机名 / 时区 / WiFi SSID / 版本信息
set -e

echo "=========================================="
echo ">>> [diy-part2] 开始自定义配置..."
echo "=========================================="

# ==============================================
# 0. 自动修复 .config 中的已知问题
# ==============================================
echo ">>> [步骤0] 自动修复 .config..."
CONFIG_FILE=".config"
if [ -f "$CONFIG_FILE" ]; then
    # 修复注释格式错误（#CONFIG_ 应改为 # CONFIG_）
    sed -i 's/^#CONFIG_/# CONFIG_/g' "$CONFIG_FILE"

    # 删除重复的 xr30-nand 行
    sed -i '/CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_cmcc_xr30-nand/d' "$CONFIG_FILE"

    # 修正 udptunnel 注释格式
    sed -i 's/^#CONFIG_PACKAGE_kmod-udptunnel4/CONFIG_PACKAGE_kmod-udptunnel4/' "$CONFIG_FILE"
    sed -i 's/^#CONFIG_PACKAGE_kmod-udptunnel6/CONFIG_PACKAGE_kmod-udptunnel6/' "$CONFIG_FILE"

    # 删除冲突包
    sed -i '/CONFIG_PACKAGE_luci-app-tcpdump/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_luci-app-mtk[^w]/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_kmod-owf/d' "$CONFIG_FILE"

    # 补充关键包（如果不存在）
    if ! grep -q "CONFIG_PACKAGE_luci=y" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# === 补充：完整 LuCI ===" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-ssl=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-theme-argon=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-proto-ipv6=y" >> "$CONFIG_FILE"
    fi

    if ! grep -q "CONFIG_PACKAGE_mtwifi-cfg" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# === 补充：MTK 无线配置 ===" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_mtwifi-cfg=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-app-mtwifi-cfg=y" >> "$CONFIG_FILE"
    fi

    if ! grep -q "CONFIG_PACKAGE_kmod-mediatek-hnat" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# === 补充：HWNAT 加速 ===" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_kmod-mediatek-hnat=y" >> "$CONFIG_FILE"
        echo "CONFIG_PACKAGE_luci-app-turboacc-mtk=y" >> "$CONFIG_FILE"
    fi

    # 修正默认 IP
    sed -i 's/CONFIG_TARGET_PREINIT_IP="192.168.1.1"/CONFIG_TARGET_PREINIT_IP="192.168.61.1"/' "$CONFIG_FILE"
    sed -i 's/CONFIG_TARGET_PREINIT_BROADCAST="192.168.1.255"/CONFIG_TARGET_PREINIT_BROADCAST="192.168.61.255"/' "$CONFIG_FILE"

    echo ">>> .config 修复完成"
else
    echo "⚠️ 未找到 .config 文件，跳过修复"
fi

# ---------- 可自定义参数 ----------
LAN_IP="192.168.61.1"
HOSTNAME="ImmortalWrt-MT7981"
SSID_2G="MT7981_2.4G"
SSID_5G="MT7981_5G"
WIFI_PASSWORD="12345678"

# ==============================================
# 1. 修改默认 LAN IP
# ==============================================
echo ">>> 设置默认 LAN IP: $LAN_IP"
sed -i "s/192.168.1.1/$LAN_IP/g" package/base-files/files/bin/config_generate

# ==============================================
# 2. 修改主机名
# ==============================================
echo ">>> 设置主机名: $HOSTNAME"
sed -i "s/ImmortalWrt/$HOSTNAME/g" package/base-files/files/bin/config_generate

# ==============================================
# 3. 修改时区为 CST-8 (中国)
# ==============================================
echo ">>> 设置时区: Asia/Shanghai (CST-8)"
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate
# 删除旧的 zonename 行（如果有）
sed -i "/set system.@system\[-1\].zonename='UTC'/d" package/base-files/files/bin/config_generate
# 在 commit system 后面插入 zonename
sed -i "/commit system/a\set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# ==============================================
# 4. 修改闭源 WiFi 驱动 SSID (关键！)
# ==============================================
# ⚠️ 重要说明：
# 闭源 MTK 驱动的 WiFi SSID 存在 .dat 文件里，不在 mac80211.sh！
# 路径可能是：
#   package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b0.dat  (2.4G)
#   package/mtk/drivers/wifi-profile/files/mt7981/mt7981.dbdc.b1.dat  (5G)
# 或（新版）：
#   package/mtk/drivers/mt_wifi/files/ 下

echo ">>> 修改闭源 WiFi SSID..."

# 方法1: 搜索 wifi-profile 目录下的 dat 文件
WIFI_PROFILE_DIR=""
for d in \
    package/mtk/drivers/wifi-profile/files/mt7981 \
    package/mtk/drivers/mt_wifi/files \
    package/mtk/applications/mtwifi-cfg/files; do
    if [ -d "$d" ]; then
        WIFI_PROFILE_DIR="$d"
        echo ">>> 找到 WiFi 配置目录: $d"
        break
    fi
done

# 如果没找到，扩大搜索范围
if [ -z "$WIFI_PROFILE_DIR" ]; then
    WIFI_DAT=$(find package/ -name "mt7981.dbdc.b0.dat" 2>/dev/null | head -1)
    if [ -n "$WIFI_DAT" ]; then
        WIFI_PROFILE_DIR=$(dirname "$WIFI_DAT")
        echo ">>> 通过搜索找到 WiFi 配置目录: $WIFI_PROFILE_DIR"
    fi
fi

if [ -n "$WIFI_PROFILE_DIR" ]; then
    # 修改 2.4G SSID
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/MT7981_AX3000_2\.4G/$SSID_2G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/ImmortalWrt-2\.4G/$SSID_2G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/OpenWrt_2G/$SSID_2G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/MT7981_2\.4G/$SSID_2G/g" {} \; 2>/dev/null || true

    # 修改 5G SSID
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/MT7981_AX3000_5G/$SSID_5G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/ImmortalWrt-5G/$SSID_5G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/OpenWrt_5G/$SSID_5G/g" {} \; 2>/dev/null || true
    find "$WIFI_PROFILE_DIR" -name "*.dat" -exec sed -i "s/MT7981_5G/$SSID_5G/g" {} \; 2>/dev/null || true

    echo ">>> WiFi SSID 修改完成: $SSID_2G / $SSID_5G"
else
    echo "⚠️ 未找到 WiFi profile 目录，跳过 SSID 修改"
    echo "   (可能是 mtwifi-cfg 模式，SSID 可在刷机后通过 LuCI 设置)"
fi

# ==============================================
# 5. 修改 mtwifi.sh 中的默认 SSID (如果使用了 mtwifi-cfg)
# ==============================================
MTWIFI_SH="package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
if [ -f "$MTWIFI_SH" ]; then
    echo ">>> 修改 mtwifi.sh 中的默认 SSID..."
    sed -i "s/ImmortalWrt-2\.4G/$SSID_2G/g" "$MTWIFI_SH" 2>/dev/null || true
    sed -i "s/ImmortalWrt-5G/$SSID_5G/g" "$MTWIFI_SH" 2>/dev/null || true
    sed -i "s/MT7981_AX3000_2\.4G/$SSID_2G/g" "$MTWIFI_SH" 2>/dev/null || true
    sed -i "s/MT7981_AX3000_5G/$SSID_5G/g" "$MTWIFI_SH" 2>/dev/null || true
fi

# ==============================================
# 6. 修改默认 root 密码为空（直接回车登录）
# ==============================================
echo ">>> 设置默认无密码登录..."
# shadow 文件中 root 行改为空密码
sed -i 's/^root:.*$/root::0:0:99999:7:::/' package/base-files/files/etc/shadow 2>/dev/null || true

# ==============================================
# 7. 修改版本信息
# ==============================================
echo ">>> 设置版本信息..."
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='ImmortalWrt 24.10 by guangyin53222'/" \
        package/base-files/files/etc/openwrt_release
fi

# ==============================================
# 8. 预置 WiFi 加密和默认开启
# ==============================================
# 在 /etc/config/wireless 不存在时，通过 uci-defaults 脚本设置
echo ">>> 创建 WiFi 默认配置脚本..."
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-set-wifi << 'EOF'
#!/bin/sh
# 设置 WiFi 默认 SSID 和密码（兼容 mtwifi-cfg）
# 2.4G
uci set wireless.@wifi-iface[0].ssid="MT7981_2.4G" 2>/dev/null
uci set wireless.@wifi-iface[0].encryption="psk2+ccmp" 2>/dev/null
uci set wireless.@wifi-iface[0].key="12345678" 2>/dev/null
uci set wireless.@wifi-iface[0].disabled="0" 2>/dev/null
# 5G
uci set wireless.@wifi-iface[1].ssid="MT7981_5G" 2>/dev/null
uci set wireless.@wifi-iface[1].encryption="psk2+ccmp" 2>/dev/null
uci set wireless.@wifi-iface[1].key="12345678" 2>/dev/null
uci set wireless.@wifi-iface[1].disabled="0" 2>/dev/null
uci commit wireless 2>/dev/null
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-wifi

# ==============================================
# 9. 设置默认 NTP 服务器（中国时区推荐）
# ==============================================
echo ">>> 设置默认 NTP 服务器..."
mkdir -p package/base-files/files/etc/config
cat > package/base-files/files/etc/config/system << 'EOF'
config system
    option hostname 'ImmortalWrt-MT7981'
    option timezone 'CST-8'
    option zonename 'Asia/Shanghai'

config timeserver 'ntp'
    option enabled '1'
    option enable_server '0'
    list server 'ntp.aliyun.com'
    list server 'time1.cloud.tencent.com'
    list server 'pool.ntp.org'
EOF

echo "=========================================="
echo ">>> [diy-part2] 所有自定义配置完成！"
echo "=========================================="
echo "  默认 IP:    $LAN_IP"
echo "  主机名:      $HOSTNAME"
echo "  WiFi 2.4G:  $SSID_2G / $WIFI_PASSWORD"
echo "  WiFi 5G:    $SSID_5G / $WIFI_PASSWORD"
echo "  时区:        Asia/Shanghai (CST-8)"
echo "=========================================="
