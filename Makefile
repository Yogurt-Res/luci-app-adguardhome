# Copyright (C) 2018-2019 Lienol
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-adguardhome
# 2026.11.15: 版本号必须碾压官方 luci feed 同名包（26.317.52279~1c75ea4），
# apk 同名槽位高版本胜出，否则固件里会静默装成官方插件（数字式日期，恒大于 26.x）
PKG_VERSION:=2026.11.15
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
