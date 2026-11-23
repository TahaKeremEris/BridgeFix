TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = Bridge

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BridgeFix

BridgeFix_FILES = Tweak.xm
BridgeFix_CFLAGS = -fobjc-arc -fobjc-arc-exceptions

include $(THEOS_MAKE_PATH)/tweak.mk
