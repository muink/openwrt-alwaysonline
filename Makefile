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
PKG_RELEASE:=20231217

PKG_MAINTAINER:=muink <hukk1996@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Jamesits/alwaysonline.git
PKG_SOURCE_VERSION:=26ad6c3f053b01a52571eeb11e08bbdbffabbf49
#PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_MIRROR_HASH:=d896c286911fac5feb309e81661a99792d477bd005f0109382add554dcc85acc
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

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

define Package/$(PKG_NAME)/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Hijack/bypass Windows NCSI and iOS portal detection on a network level.
  URL:=https://github.com/Jamesits/alwaysonline
  DEPENDS:=$(GO_ARCH_DEPENDS)
  USERID:=alwaysonline:alwaysonline
  PROVIDES:=$(PKG_NAME)
  VARIANT:=$(1)
  DEFAULT_VARIANT:=1
endef

define Package/$(PKG_NAME)
  $(call Package/$(PKG_NAME)/Default,nodns)
endef

define Package/$(PKG_NAME)/description/Default
  AlwaysOnline is a HTTP and DNS server which mocks a lot network/internet/portal detection servers.
endef

Package/$(PKG_NAME)/description = $(Package/$(PKG_NAME)/description/Default)

define Package/$(PKG_NAME)/install/Default
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME) $(1)/usr/sbin/
endef

Package/$(PKG_NAME)/install = $(Package/$(PKG_NAME)/install/Default)

define Package/uci-$(PKG_NAME)/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=alwaysonline uci metapackage ($(1))
  DEPENDS:=+alwaysonline +luci-app-alwaysonline
  USERID:=alwaysonline:alwaysonline
  PROVIDES:=uci-$(PKG_NAME)
  VARIANT:=$(1)
endef

define Package/uci-$(PKG_NAME)
  $(call Package/uci-$(PKG_NAME)/Default,firewall)
  # ref: https://github.com/openwrt/packages/blob/4a7822604ad3cadb0461c5969bbf07b18a046834/admin/zabbix/Makefile#L67
  DEFAULT_VARIANT:=1
  # ref: https://github.com/openwrt/packages/blob/10986d56c9fcdd093be0495d6e7a02e7f5f3141e/mail/exim/Makefile#L57
  CONFLICTS:=uci-$(PKG_NAME)-nginx
endef

define Package/uci-$(PKG_NAME)-nginx
  $(call Package/uci-$(PKG_NAME)/Default,nginx)
  DEPENDS+= nginx
endef

define Package/uci-$(PKG_NAME)/description/Default
  This variant of the alwaysonline package is based on the $(1).
endef

define Package/uci-$(PKG_NAME)/description
  $(call Package/uci-$(PKG_NAME)/description/Default,iptables/nftables)
endef

define Package/uci-$(PKG_NAME)-nginx/description
  $(call Package/uci-$(PKG_NAME)/description/Default,nginx)
endef

define Package/uci-$(PKG_NAME)/conffiles/Default
/etc/config/alwaysonline
endef

Package/uci-$(PKG_NAME)/conffiles = $(Package/uci-$(PKG_NAME)/conffiles/Default)
Package/uci-$(PKG_NAME)-nginx/conffiles = $(Package/uci-$(PKG_NAME)/conffiles/Default)

define Package/uci-$(PKG_NAME)/prerm
#!/bin/sh
uci -q delete firewall.$(PKG_NAME)
uci commit firewall
endef

define Package/uci-$(PKG_NAME)/install/Default
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/$(PKG_NAME).config $(1)/etc/config/alwaysonline

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/$(PKG_NAME).$(2).init $(1)/etc/init.d/alwaysonline
endef

define Package/uci-$(PKG_NAME)/install
	$(call Package/uci-$(PKG_NAME)/install/Default,$(1),firewall)
endef

define Package/uci-$(PKG_NAME)-nginx/install
	$(call Package/uci-$(PKG_NAME)/install/Default,$(1),nginx)

	$(INSTALL_DIR) $(1)/etc/nginx/conf.d/alwaysonline
	$(INSTALL_DATA) ./files/$(PKG_NAME).locations $(1)/etc/nginx/conf.d/alwaysonline/alwaysonline.locations
	$(LN) /var/etc/nginx/conf.d/alwaysonline.conf $(1)/etc/nginx/conf.d/alwaysonline.conf
endef

$(eval $(call GoBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,uci-$(PKG_NAME)))
$(eval $(call BuildPackage,uci-$(PKG_NAME)-nginx))
