#
# Copyright (C) 2023 muink
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
#go env

PKG_NAME:=alwaysonline
PKG_VERSION=1.2.0
PKG_RELEASE:=20230520

PKG_MAINTAINER:=muink <hukk1996@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Jamesits/alwaysonline.git
PKG_SOURCE_VERSION:=4119d5f03219f71c0d1a19e535524a63d0f5a857
#PKG_SOURCE_VERSION:=v$(PKG_VERSION)

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/jamesits/alwaysonline/v2

AWOL_COMMIT_HASH:=$(shell echo $(PKG_SOURCE_VERSION)|cut -c -8)
AWOL_BUILD_TIME:=$(shell date -d @$(SOURCE_DATE_EPOCH) -u +%FT%TZ%z)
GO_PKG_LDFLAGS_X:=\
	main.versionGitCommitHash=$(AWOL_COMMIT_HASH) \
	main.versionCompileTime=$(AWOL_BUILD_TIME) \
	main.versionCompileHost=OpenWrt \
	main.versionGitStatus=clean

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Hijack/bypass Windows NCSI and iOS portal detection on a network level.
  URL:=https://github.com/Jamesits/alwaysonline
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/$(PKG_NAME)/description
  AlwaysOnline is a HTTP and DNS server which mocks a lot network/internet/portal detection servers.
endef

define Package/$(PKG_NAME)/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=alwaysonline uci metapackage ($(1))
  DEPENDS:=+alwaysonline
  USERID:=alwaysonline:alwaysonline
  PROVIDES:=uci-$(PKG_NAME)
  VARIANT:=$(1)
endef

define Package/$(PKG_NAME)-firewall
  $(call Package/$(PKG_NAME)/Default,firewall)
  # ref: https://github.com/openwrt/packages/blob/4a7822604ad3cadb0461c5969bbf07b18a046834/admin/zabbix/Makefile#L67
  DEFAULT_VARIANT:=1
  # ref: https://github.com/openwrt/packages/blob/10986d56c9fcdd093be0495d6e7a02e7f5f3141e/mail/exim/Makefile#L57
  CONFLICTS:=$(PKG_NAME)-nginx
endef

define Package/$(PKG_NAME)-nginx
  $(call Package/$(PKG_NAME)/Default,nginx)
  DEPENDS+= nginx
endef

define Package/$(PKG_NAME)/description/Default
  This variant of the alwaysonline package is based on the $(1).
endef

Package/$(PKG_NAME)-firewall/description = $(Package/$(PKG_NAME)/description/Default,'iptables/nftables')
Package/$(PKG_NAME)-nginx/description = $(Package/$(PKG_NAME)/description/Default,nginx)

define Package/$(PKG_NAME)/conffiles/Default
/etc/config/alwaysonline
endef

Package/$(PKG_NAME)-firewall/conffiles = $(Package/$(PKG_NAME)/conffiles/Default)
Package/$(PKG_NAME)-nginx/conffiles = $(Package/$(PKG_NAME)/conffiles/Default)

define Package/$(PKG_NAME)-firewall/prerm
#!/bin/sh
uci delete firewall.$(PKG_NAME)
uci commit firewall
endef

define Package/$(PKG_NAME)/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME) $(1)/usr/sbin/
endef

define Package/$(PKG_NAME)/install/Default
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/$(PKG_NAME).config $(1)/etc/config/alwaysonline

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/$(PKG_NAME).$(2).init $(1)/etc/init.d/alwaysonline
endef

define Package/$(PKG_NAME)-firewall/install
	$(call Package/$(PKG_NAME)/install/Default, $(1),firewall)

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci-defaults $(1)/etc/uci-defaults/99_$(PKG_NAME)

	$(INSTALL_DIR) $(1)/usr/share/$(PKG_NAME)
	$(INSTALL_DATA) ./files/fw3.include $(1)/usr/share/$(PKG_NAME)/fw3.include
	$(INSTALL_DATA) ./files/fw4.include $(1)/usr/share/$(PKG_NAME)/fw4.include

	$(INSTALL_DIR) $(1)/usr/share/nftables.d
	$(CP) ./files/nftables.d/* $(1)/usr/share/nftables.d/
endef

define Package/$(PKG_NAME)-nginx/install
	$(call Package/$(PKG_NAME)/install/Default, $(1),nginx)

	$(INSTALL_DIR) $(1)/etc/nginx/conf.d/alwaysonline
	$(INSTALL_DATA) ./files/$(PKG_NAME).locations $(1)/etc/nginx/conf.d/alwaysonline/alwaysonline.locations
	$(LN) /var/etc/nginx/conf.d/alwaysonline.conf $(1)/etc/nginx/conf.d/alwaysonline.conf
endef

$(eval $(call GoBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-firewall))
$(eval $(call BuildPackage,$(PKG_NAME)-nginx))
