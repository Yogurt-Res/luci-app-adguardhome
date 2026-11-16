# Copyright (C) 2018-2019 Lienol
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-adguardhome
# 版本格式：真实日期.当日构建序号（.1 .2 .3…）。同日多次构建只递增尾号，
# 不再改日期本身。apk 逐段数字比较：2026.11.16.2 > 2026.11.16 > 2026.11.15，
# 恒高于官方 luci feed 同名包（26.317.52279~1c75ea4，2026 > 26 首段即胜），
# 否则固件里会静默装成官方插件。
# 注意：CI 从本行原样 grep 版本值（actions/build-luci-app），必须是静态字面量，
# 不能用 $(shell date …) 动态生成（会原样进 artifact 名且多次 parse 不一致）。
# 2026.11.16.3: 手动设置/更新/密码页按钮同样通栏，统一 inline-block 修复
# 2026.11.16.2: 修 .1 的注释语法导致日志页 500
# 2026.11.16.1: 日志页布局修复（勾选框错位、按钮通栏、轮询换行粘连）
PKG_VERSION:=2026.11.16.3
PKG_MAINTAINER:=admin

LUCI_TITLE:=LuCI app for AdGuard Home
LUCI_DEPENDS:=+!wget&&!curl:curl
LUCI_PKGARCH:=all
LUCI_DESCRIPTION:=A powerful LuCI interface for managing AdGuard Home - a DNS-based ad and tracker blocker that protects all devices on your network

define Package/$(PKG_NAME)/conffiles
/etc/config/AdGuardHome
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
	uci -q batch <<-EOF >/dev/null 2>&1
		delete ucitrack.@AdGuardHome[-1]
		add ucitrack AdGuardHome
		set ucitrack.@AdGuardHome[-1].init=AdGuardHome
		commit ucitrack
	EOF
	rm -f /tmp/luci-indexcache
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	/etc/init.d/AdGuardHome enable >/dev/null 2>&1
	enable=$(uci get AdGuardHome.AdGuardHome.enabled 2>/dev/null)
	if [ "$enable" == "1" ]; then
		/etc/init.d/AdGuardHome reload >/dev/null 2>&1
	fi
	rm -f /tmp/luci-indexcache
	rm -f /tmp/luci-modulecache/*
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
uci -q batch <<-EOF >/dev/null 2>&1
	delete ucitrack.@AdGuardHome[-1]
	commit ucitrack
EOF
fi
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
