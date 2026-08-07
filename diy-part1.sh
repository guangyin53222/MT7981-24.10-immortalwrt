#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# ===================== 第三方插件统一拉取（先删旧残留） =====================

# OpenAppFilter（家长控制/应用过滤）
# 注意：ImmortalWrt 24.10 上包名是 luci-app-oaf，与 Turbo ACC 冲突需关闭 ACC
rm -rf package/OpenAppFilter
git clone --depth 1 -b v6.1.8 https://github.com/destan19/OpenAppFilter package/OpenAppFilter

# iStore 软件中心
rm -rf package/luci-app-store
git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store

# 集客 AC 控制（gecoosac）
rm -rf package/luci-app-gecoosac
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac

# WAN MAC 修改插件
rm -rf package/luci-app-wan-mac
git clone --depth=1 https://github.com/linkease/openwrt-app-actions tmp/openwrt-app-actions
mv tmp/openwrt-app-actions/applications/luci-app-wan-mac package/luci-app-wan-mac
rm -rf tmp/openwrt-app-actions

# TCPDUMP 抓包插件
rm -rf package/luci-app-tcpdump
git clone --depth=1 https://github.com/KFERMercer/luci-app-tcpdump.git package/luci-app-tcpdump

# Harbor File 文件管理
rm -rf package/luci-app-harbor-file
git clone --depth=1 https://github.com/destan19/luci-app-harbor-file package/luci-app-harbor-file

# ===================== 重要：不要在 part1 里跑 feeds update/install =====================
# 让 yml 工作流统一执行 ./scripts/feeds update -a && ./scripts/feeds install -a
# 否则会和 yml 里的 Update/Install feeds 步骤重复，且可能漏装依赖
