include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ForceLSShortcuts

ForceLSShortcuts_FILES = FLSSRootListController.m
ForceLSShortcuts_INSTALL_PATH = /Library/PreferenceBundles
ForceLSShortcuts_FRAMEWORKS = UIKit MessageUI
ForceLSShortcuts_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ForceLSShortcuts.plist$(ECHO_END)
