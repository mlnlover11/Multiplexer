#import "headers.h"
#import "RASettings.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"

BOOL launchNextOpenIntoWindow = NO;
BOOL override = NO;
BOOL allowOpenApp = NO;

%hook SBIconController
- (void)iconWasTapped:(__unsafe_unretained SBApplicationIcon*)arg1 {
	if ([RASettings.sharedInstance windowedMultitaskingEnabled] && [RASettings.sharedInstance launchIntoWindows] && arg1.application) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1.application animated:YES];
		override = YES;
	}
	%orig;
}

- (void)_launchIcon:(unsafe_id)icon {
	if (!override) {
		%orig;
	} else {
		override = NO;
	}
}
%end

%hook SBUIController
- (void)activateApplicationAnimated:(__unsafe_unretained SBApplication*)arg1 {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([RASettings.sharedInstance windowedMultitaskingEnabled] &&[RASettings.sharedInstance launchIntoWindows] && !allowOpenApp) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1 animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[RADesktopManager.sharedInstance removeAppWithIdentifier:arg1.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}

- (void)activateApplication:(__unsafe_unretained SBApplication*)arg1 {
	// Broken
	//if (launchNextOpenIntoWindow)

	if ([RASettings.sharedInstance windowedMultitaskingEnabled] &&[RASettings.sharedInstance launchIntoWindows] && !allowOpenApp) {
		[RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:arg1 animated:YES];
		//launchNextOpenIntoWindow = NO;
		return;
	} else {
		[RADesktopManager.sharedInstance removeAppWithIdentifier:arg1.bundleIdentifier animated:NO forceImmediateUnload:YES];
	}
	%orig;
}
%end
