#!/bin/bash
# diy-part1.sh - ImmortalWrt 24.10 / MT7981 / Linux 6.6
# 执行时机: feeds update 之前
# 作用: 克隆第三方 LuCI 插件到 package/
set -e

echo "=========================================="
echo ">>> [diy-part1] 开始克隆第三方插件..."
echo "=========================================="

# ---------- 1. iStore (应用商店) ----------
if [ ! -d "package/luci-app-store" ]; then
 echo ">>> 克隆 iStore..."
 git clone --depth=1 https://github.com/linkease/istore.git package/luci-app-store
fi

# ---------- 2. OpenAppFilter (应用过滤) ----------
if [ ! -d "package/OpenAppFilter" ]; then
 echo ">>> 克隆 OpenAppFilter v6.1.8..."
 git clone --depth=1 --branch v6.1.8 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
fi

# ---------- 3. Harbor File (文件管理) ----------
if [ ! -d "package/luci-app-harbor-file" ]; then
 echo ">>> 克隆 luci-app-harbor-file..."
 git clone --depth=1 https://github.com/destan19/luci-app-harbor-file package/luci-app-harbor-file
fi

# ---------- 4. Geckos AC (集客 AC 控制器) ----------
if [ ! -d "package/luci-app-gecoosac" ]; then
 echo ">>> 克隆 luci-app-gecoosac..."
 git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac || \
 echo "⚠️ luci-app-gecoosac 克隆失败，跳过（可能不兼容 24.10）"
fi

# ---------- 5. PassWall (科学上网) ----------
if [ ! -d "package/luci-app-passwall" ]; then
 echo ">>> 克隆 PassWall..."
 git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall 2>/dev/null || \
 echo "⚠️ PassWall 克隆失败，跳过"
fi

# ---------- 说明 ----------
# ❌ 以下包在 24.10 + ucode LuCI 下会出问题，已移除：
# - luci-app-tcpdump (老 Lua 版，会导致 LuCI 500 错误)
# - luci-app-mtk (旧版无线配置工具，与 mtwifi-cfg 冲突)
#
# ✅ 如需 tcpdump 功能，只需在 .config 里开 CONFIG_PACKAGE_tcpdump=y
# （命令行版，不开 LuCI 前端）

echo "=========================================="
echo ">>> [diy-part1] 第三方插件克隆完成"
echo "=========================================="
echo ">>> feeds update/install 将由 workflow 后续步骤执行"
