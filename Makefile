ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WiCellSwitcher
WiCellSwitcher_FILES = Tweak.xm
WiCellSwitcher_CFLAGS = -fobjc-arc
WiCellSwitcher_FRAMEWORKS = UIKit CoreTelephony SystemConfiguration Foundation
WiCellSwitcher_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += wicellswitcherprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload"
