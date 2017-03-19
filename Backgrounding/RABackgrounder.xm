#import "RABackgrounder.h"
#import "RASettings.h"
#import "Multiplexer.h"

NSString *FriendlyNameForBackgroundMode(RABackgroundMode mode) {
	switch (mode) {
		case RABackgroundModeNative:
			return LOCALIZE(@"NATIVE");
		case RABackgroundModeForcedForeground:
			return LOCALIZE(@"FORCE_FOREGROUND");
		case RABackgroundModeForceNone:
			return LOCALIZE(@"DISABLE");
		case RABackgroundModeSuspendImmediately:
			return LOCALIZE(@"SUSPEND_IMMEDIATELY");
		case RABackgroundModeUnlimitedBackgroundingTime:
			return LOCALIZE(@"UNLIMITED_BACKGROUNDING_TIME");
		default:
			return @"Unknown";
	}
}

NSMutableDictionary *temporaryOverrides = [NSMutableDictionary dictionary];
NSMutableDictionary *temporaryShouldPop = [NSMutableDictionary dictionary];

@implementation RABackgrounder
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(RABackgrounder);
}

- (BOOL)shouldAutoLaunchApplication:(NSString*)identifier {
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) {
		return NO;
	}

	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && (![dict objectForKey:@"autoLaunch"] ? NO : [dict[@"autoLaunch"] boolValue]);
}

- (BOOL)shouldAutoRelaunchApplication:(NSString*)identifier {
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) {
		return NO;
	}

	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return ![self killProcessOnExit:identifier] && [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && (![dict objectForKey:@"autoRelaunch"] ? NO : [dict[@"autoRelaunch"] boolValue]);
}

- (NSInteger)popTemporaryOverrideForApplication:(NSString*)identifier {
	if (!identifier || ![temporaryOverrides objectForKey:identifier]) {
		return -1;
	}

	RABackgroundMode override = (RABackgroundMode)[temporaryOverrides[identifier] intValue];
	return override;
}

- (void)queueRemoveTemporaryOverrideForIdentifier:(NSString*)identifier {
	if (!identifier) {
		return;
	}
	temporaryShouldPop[identifier] = @YES;
}

- (void)removeTemporaryOverrideForIdentifier:(NSString*)identifier {
	if (!identifier) {
		return;
	}

	if ([temporaryShouldPop objectForKey:identifier] && [[temporaryShouldPop objectForKey:identifier] boolValue]) {
		[temporaryShouldPop removeObjectForKey:identifier];
		[temporaryOverrides removeObjectForKey:identifier];
	}
}

- (NSInteger)popTemporaryOverrideForApplication:(NSString*)identifier is:(RABackgroundMode)mode {
	NSInteger popped = [self popTemporaryOverrideForApplication:identifier];
	return popped == -1 ? -1 : (popped == mode ? 1 : 0);
}

- (RABackgroundMode)globalBackgroundMode {
	return (RABackgroundMode)[(RASettings*)[%c(RASettings) sharedInstance] globalBackgroundMode];
}

- (BOOL)shouldKeepInForeground:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground;
}

- (BOOL)shouldSuspendImmediately:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeSuspendImmediately;
}

- (BOOL)preventKillingOfIdentifier:(NSString*)identifier {
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) {
		return NO;
	}

	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && (![dict objectForKey:@"preventDeath"] ? NO : [dict[@"preventDeath"] boolValue]);
}

- (BOOL)shouldRemoveFromSwitcherWhenKilledOnExit:(NSString*)identifier {
	if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) {
		return NO;
	}

	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"removeFromSwitcher"] ? [dict[@"removeFromSwitcher"] boolValue] : NO;
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled && (![dict objectForKey:@"removeFromSwitcher"] ? NO : [dict[@"removeFromSwitcher"] boolValue]);
}

- (NSInteger)backgroundModeForIdentifier:(NSString*)identifier {
	@autoreleasepool {
		if (!identifier || ![[%c(RASettings) sharedInstance] backgrounderEnabled]) {
			return RABackgroundModeNative;
		}

		NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier];
		if (temporaryOverride != -1) {
			return temporaryOverride;
		}

#if __has_feature(objc_arc)
		__weak // dictionary is cached by RASettings anyway
#endif
		NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
		BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
		if (!enabled) {
			return [self globalBackgroundMode];
		}
		return [dict[@"backgroundMode"] intValue];
	}
}

- (BOOL)hasUnlimitedBackgroundTime:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeUnlimitedBackgroundingTime;
}

- (BOOL)killProcessOnExit:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == RABackgroundModeForceNone;
}

- (void)temporarilyApplyBackgroundingMode:(RABackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close {
	temporaryOverrides[app.bundleIdentifier] = @(mode);
	[temporaryShouldPop removeObjectForKey:app.bundleIdentifier];

	if (close) {
		FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
			SBAppToAppWorkspaceTransaction *transaction = [%c(Multiplexer) createSBAppToAppWorkspaceTransactionForExitingApp:app];
			[transaction begin];
		}];
		[(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
	}
}

- (NSInteger)application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode {
	NSDictionary *dict = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return [[%c(RASettings) sharedInstance] backgrounderEnabled] && enabled ? (val ? [val boolValue] : -1) : -1;
}

- (RAIconIndicatorViewInfo)allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier {
	int info = RAIconIndicatorViewInfoNone;

	if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeNative) {
		info |= RAIconIndicatorViewInfoNative;
	} else if ([self backgroundModeForIdentifier:identifier] == RABackgroundModeForcedForeground) {
		info |= RAIconIndicatorViewInfoForced;
	} else if ([self shouldSuspendImmediately:identifier]) {
		info |= RAIconIndicatorViewInfoSuspendImmediately;
	} else if ([self hasUnlimitedBackgroundTime:identifier]) {
		info |= RAIconIndicatorViewInfoUnlimitedBackgroundTime;
	}

	if ([self killProcessOnExit:identifier]) {
		info |= RAIconIndicatorViewInfoForceDeath;
	}

	if ([self preventKillingOfIdentifier:identifier]) {
		info |= RAIconIndicatorViewInfoUnkillable;
	}

	return (RAIconIndicatorViewInfo)info;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(RAIconIndicatorViewInfo)info {
	@autoreleasepool {
		SBIconView *ret = nil;
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			if ([[[%c(SBIconViewMap) homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)]) {
				// iOS 8.0+
				SBApplicationIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:identifier];
				ret = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
			} else {
				// iOS 7.X could support once all features are seperate tweaks?
				SBApplicationIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:identifier];
				ret = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
			}
		} else {
			SBApplicationIcon *icon = [[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] applicationIconForBundleIdentifier:identifier];
			ret = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] mappedIconViewForIcon:icon];
		}

		[ret RA_updateIndicatorView:info];
	}
}
#pragma GCC diagnostic pop


- (BOOL)shouldShowIndicatorForIdentifier:(NSString*)identifier {
	NSDictionary *dct = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(RASettings) sharedInstance] shouldShowIconIndicatorsGlobally];
	return globalSetting ? (![dct objectForKey:@"showIndicatorOnIcon"] ? YES : [dct[@"showIndicatorOnIcon"] boolValue]) : NO;
}

- (BOOL)shouldShowStatusBarIconForIdentifier:(NSString*)identifier {
	NSDictionary *dct = [[%c(RASettings) sharedInstance] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(RASettings) sharedInstance] shouldShowStatusBarIcons];
	return globalSetting ? (![dct objectForKey:@"showStatusBarIcon"] ? YES : [dct[@"showStatusBarIcon"] boolValue]) : NO;
}
@end
