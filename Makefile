export ARCHS = arm64
export TARGET = iphone:clang:11.2:12.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ForceLSShortcuts

ForceLSShortcuts_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += forcelsshortcuts
include $(THEOS_MAKE_PATH)/aggregate.mk
