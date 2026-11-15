TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GitHubKey
GitHubKey_FILES = Tweak.xm
GitHubKey_CFLAGS = -fobjc-arc
GitHubKey_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk

# Rootless build:
# make package THEOS_PACKAGE_SCHEME=rootless
#
# Rootful build:
# make package
