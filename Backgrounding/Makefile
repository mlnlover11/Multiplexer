ARCHS = armv7 armv7s arm64

CFLAGS = -I../ -I../Theming/ -Wno-deprecated-declarations -O2
CFLAGS += -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachAppBackgrounding
ReachAppBackgrounding_FILES = $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) ../Tweak.xm
ReachAppBackgrounding_FRAMEWORKS = UIKit CoreGraphics
ReachAppBackgrounding_LIBRARIES = applist

IconIndicator.xm_CFLAGS = -fno-objc-arc
SpringBoard_UIAppCustomBackgroundModes.xm_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
