ARCHS = armv7 armv7s arm64
CFLAGS = -I./ -Iwidgets/ -Iwidgets/Core/ -Iwidgets/Reachability/ -ISwipeOver/ -IReachability/ -IGestureSupport/ -IKeyboardSupport/ -IMissionControl/ -IWindowedMultitasking/ -INotificationCenterApp/ -IBackgrounding/ -IIntroTutorial/ -IMessaging/ -ITheming/ -Wno-deprecated-declarations
CFLAGS += -fobjc-arc -O2
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReachApp
ReachApp_FILES = Tweak.xm $(wildcard *.xm) $(wildcard *.mm) $(wildcard *.m) \
	$(wildcard Reachability/*.xm) $(wildcard Reachability/*.mm) $(wildcard Reachability/*.m) \
	$(wildcard widgets/*.xm) $(wildcard widgets/*.mm) $(wildcard widgets/*.m) \
	$(wildcard widgets/Core/*.xm) $(wildcard widgets/Core/*.mm) $(wildcard widgets/Core/*.m) \
	$(wildcard widgets/Reachability/*.xm) $(wildcard widgets/Reachability/*.mm) $(wildcard widgets/Reachability/*.m) \
	$(wildcard KeyboardSupport/*.xm) $(wildcard KeyboardSupport/*.mm) $(wildcard KeyboardSupport/*.m) \
	$(wildcard GestureSupport/*.xm) $(wildcard GestureSupport/*.mm) $(wildcard GestureSupport/*.m) \
	$(wildcard WindowedMultitasking/*.xm) $(wildcard WindowedMultitasking/*.mm) $(wildcard WindowedMultitasking/*.m) \
	$(wildcard NotificationCenterApp/*.xm) $(wildcard NotificationCenterApp/*.mm) $(wildcard NotificationCenterApp/*.m) \
	$(wildcard IntroTutorial/*.xm) $(wildcard IntroTutorial/*.mm) $(wildcard IntroTutorial/*.m) \
	$(wildcard Messaging/*.xm) $(wildcard Messaging/*.mm) $(wildcard Messaging/*.m) \
	$(wildcard DRM/*.xm) $(wildcard DRM/*.mm) $(wildcard DRM/*.m) \
	$(wildcard Theming/*.xm) $(wildcard Theming/*.mm) $(wildcard Theming/*.m) \
	$(wildcard Debugging/*.xm) $(wildcard Debugging/*.mm) $(wildcard Debugging/*.m)

ReachApp_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreImage
ReachApp_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices AppSupport IOKit
ReachApp_LIBRARIES = applist rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += Backgrounding
SUBPROJECTS += MissionControl
SUBPROJECTS += SwipeOver

SUBPROJECTS += reachappfakephonemode

SUBPROJECTS += reachappassertiondhooks
SUBPROJECTS += reachappbackboarddhooks

SUBPROJECTS += reachappsettings
SUBPROJECTS += reachappflipswitch
SUBPROJECTS += reachappfsdaemon


include $(THEOS_MAKE_PATH)/aggregate.mk
