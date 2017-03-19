#import "headers.h"
#import "RABackgrounder.h"
#import "RARunningAppsProvider.h"

NSMutableDictionary *processAssertions = [NSMutableDictionary dictionary];
BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
- (void)host:(__unsafe_unretained FBScene*)arg1 didUpdateSettings:(__unsafe_unretained FBSSceneSettings*)arg2 withDiff:(unsafe_id)arg3 transitionContext:(unsafe_id)arg4 completion:(unsafe_id)arg5 {
  if ([RABackgrounder.sharedInstance hasUnlimitedBackgroundTime:arg1.identifier] && arg2.backgrounded && ![processAssertions objectForKey:arg1.identifier]) {
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:arg1.identifier];

    keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithPID:[app pid] flags:(BKSProcessAssertionFlagPreventSuspend | BKSProcessAssertionFlagAllowIdleSleep | BKSProcessAssertionFlagPreventThrottleDownCPU | BKSProcessAssertionFlagWantsForegroundResourcePriority) reason:BKSProcessAssertionReasonBackgroundUI name:@"reachapp" withHandler:^{
      LogInfo(@"ReachApp: %d kept alive: %@", [app pid], [keepAlive$temp valid] ? @"TRUE" : @"FALSE");
      if (keepAlive$temp.valid) {
        processAssertions[arg1.identifier] = keepAlive$temp;
      }
    }];
  }
  %orig(arg1, arg2, arg3, arg4, arg5);
}
%end

@interface RAUnlimitedBackgroundingAppWatcher : NSObject <RARunningAppsProviderDelegate>
+ (void)load;
@end

RAUnlimitedBackgroundingAppWatcher *sharedInstance$RAUnlimitedBackgroundingAppWatcher;

@implementation RAUnlimitedBackgroundingAppWatcher
+ (void)load {
  IF_NOT_SPRINGBOARD {
    return;
  }
  sharedInstance$RAUnlimitedBackgroundingAppWatcher = [[RAUnlimitedBackgroundingAppWatcher alloc] init];
  [[%c(RARunningAppsProvider) sharedInstance] addTarget:sharedInstance$RAUnlimitedBackgroundingAppWatcher];
}

- (void)appDidDie:(__unsafe_unretained SBApplication*)app {
  if (![processAssertions objectForKey:app.bundleIdentifier]) {
    return;
  }
  [processAssertions[app.bundleIdentifier] invalidate];
  [processAssertions removeObjectForKey:app.bundleIdentifier];
}
@end
