#import <libactivator/libactivator.h>
#import "RABackgrounder.h"
#import "RADesktopManager.h"
#import "RADesktopWindow.h"
#import "RAHostedAppView.h"
#import "RAWindowBar.h"
#import "RAWindowSorter.h"
#import "Multiplexer.h"

@interface RAActivatorCreateWindowListener : NSObject <LAListener>
@end

static RAActivatorCreateWindowListener *sharedInstance$RAActivatorCreateWindowListener;

@implementation RAActivatorCreateWindowListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)levent {
  SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];
  RAIconIndicatorViewInfo indicatorInfo = [[%c(RABackgrounder) sharedInstance] allAggregatedIndicatorInfoForIdentifier:topApp.bundleIdentifier];

  // Close app
  [[%c(RABackgrounder) sharedInstance] temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:topApp andCloseForegroundApp:NO];
  FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
    SBDeactivationSettings *deactiveSets = [[%c(SBDeactivationSettings) alloc] init];
    [deactiveSets setFlag:YES forDeactivationSetting:20];
    [deactiveSets setFlag:NO forDeactivationSetting:2];
    [topApp _setDeactivationSettings:deactiveSets];

    SBAppToAppWorkspaceTransaction *transaction = [Multiplexer createSBAppToAppWorkspaceTransactionForExitingApp:topApp];
    [transaction begin];

    // Open in window
    RAWindowBar *windowBar = [RADesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];
    if (!RADesktopManager.sharedInstance.lastUsedWindow) {
      RADesktopManager.sharedInstance.lastUsedWindow = windowBar;
    }
  }];
  [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];

  // Pop forced foreground backgrounding
  [[%c(RABackgrounder) sharedInstance] queueRemoveTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
  [[%c(RABackgrounder) sharedInstance] removeTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
  [[%c(RABackgrounder) sharedInstance] updateIconIndicatorForIdentifier:topApp.bundleIdentifier withInfo:indicatorInfo];
}
@end

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }
  sharedInstance$RAActivatorCreateWindowListener = [[RAActivatorCreateWindowListener alloc] init];
  [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$RAActivatorCreateWindowListener forName:@"com.efrederickson.reachapp.windowedmultitasking.createWindow"];
}
