#import "headers.h"

typedef NS_ENUM(NSInteger, RABackgroundMode) {
  RABackgroundModeNative = 1,
  RABackgroundModeForceNativeForOldApps = 2,
  RABackgroundModeForcedForeground = 3,
  RABackgroundModeForceNone = 4,
  RABackgroundModeSuspendImmediately = 5,
  RABackgroundModeUnlimitedBackgroundingTime = 6,
};

typedef NS_ENUM(NSInteger, RAIconIndicatorViewInfo) {
  RAIconIndicatorViewInfoNone = 0,
  RAIconIndicatorViewInfoNative = 1,
  RAIconIndicatorViewInfoForced = 2,
  RAIconIndicatorViewInfoSuspendImmediately = 4,

  RAIconIndicatorViewInfoUnkillable = 8,
  RAIconIndicatorViewInfoForceDeath = 16,

  RAIconIndicatorViewInfoUnlimitedBackgroundTime = 32,


  RAIconIndicatorViewInfoTemporarilyInhibit = 1024,
  RAIconIndicatorViewInfoInhibit = 2048,
  RAIconIndicatorViewInfoUninhibit = 4096,
};

NSString *FriendlyNameForBackgroundMode(RABackgroundMode mode);

@interface RABackgrounder : NSObject
+ (instancetype) sharedInstance;

- (BOOL)shouldAutoLaunchApplication:(NSString*)identifier;
- (BOOL)shouldAutoRelaunchApplication:(NSString*)identifier;

- (BOOL)shouldKeepInForeground:(NSString*)identifier;
- (BOOL)shouldSuspendImmediately:(NSString*)identifier;

- (BOOL)killProcessOnExit:(NSString*)identifier;
- (BOOL)shouldRemoveFromSwitcherWhenKilledOnExit:(NSString*)identifier;
- (BOOL)preventKillingOfIdentifier:(NSString*)identifier;
- (NSInteger)backgroundModeForIdentifier:(NSString*)identifier;
- (BOOL)hasUnlimitedBackgroundTime:(NSString*)identifier;

- (void)temporarilyApplyBackgroundingMode:(RABackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close;
- (void)queueRemoveTemporaryOverrideForIdentifier:(NSString*)identifier;
- (void)removeTemporaryOverrideForIdentifier:(NSString*)identifier;

- (NSInteger)application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode;

- (RAIconIndicatorViewInfo)allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier;
- (void)updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(RAIconIndicatorViewInfo)info;
- (BOOL)shouldShowIndicatorForIdentifier:(NSString*)identifier;
- (BOOL)shouldShowStatusBarIconForIdentifier:(NSString*)identifier;
@end
