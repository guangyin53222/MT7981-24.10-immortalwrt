#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# ===================== 修改默认 IP 地址 =====================
# ImmortalWrt 24.10 默认是 192.168.1.1，改为 192.168.100.1
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# ===================== 修改默认主机名（可选，取消注释启用） =====================
sed -i "s/hostname='ImmortalWrt'/hostname='MyRouter'/g" package/base-files/files/bin/config_generate

# ===================== 修改固件版本显示名称（可选） =====================
# sed -i "s/DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='ImmortalWrt By DIY $(date +"%Y%m%d")'/g" package/base-files/files/etc/openwrt_release

# ========== 4. Argon 主题 ==========
echo ">>> 设置 Argon 为默认主题..."
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
