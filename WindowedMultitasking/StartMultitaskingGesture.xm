#import "headers.h"
#import "RADesktopManager.h"
#import "RAGestureManager.h"
#import "RASettings.h"
#import "RAHostManager.h"
#import "RABackgrounder.h"
#import "RASwipeOverManager.h"
#import "RAWindowStatePreservationSystemManager.h"
#import "RAControlCenterInhibitor.h"
#import "Multiplexer.h"

BOOL locationIsInValidArea(CGFloat x) {
  if (x == 0) { // more than likely, UIGestureRecognizerStateEnded
    return YES;
  }

  switch ([RASettings.sharedInstance windowedMultitaskingGrabArea]) {
    case RAGrabAreaBottomLeftThird:
      LogDebug(@"[ReachApp] StartMultitaskingGesture: %f %f", x, UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width);
      return x <= UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width / 3.0;
    case RAGrabAreaBottomMiddleThird:
      return x >= UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width / 3.0 && x <= (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width / 3.0) * 2;
    case RAGrabAreaBottomRightThird:
      return x >= (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width / 3.0) * 2;
    default:
      return NO;
  }
}

%ctor {
  IF_NOT_SPRINGBOARD {
    return;
  }
  __weak __block UIView *appView = nil;
  __block CGFloat lastY = 0;
  __block CGPoint originalCenter;
  [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
    SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];

    // Dismiss potential CC
    //[[%c(SBUIController) sharedInstance] _showControlCenterGestureEndedWithLocation:CGPointMake(0, UIScreen.mainScreen.bounds.size.height - 1) velocity:CGPointZero];

    if (state == UIGestureRecognizerStateBegan) {
      [RAControlCenterInhibitor setInhibited:YES];

      // Show HS/Wallpaper
      [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
      [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

      // Assign view
      appView = [RAHostManager systemHostViewForApplication:topApp].superview;
      if (IS_IOS_OR_NEWER(iOS_9_0)) {
        appView = appView.superview;
      }
      originalCenter = appView.center;
    } else if (state == UIGestureRecognizerStateChanged) {
      lastY = location.y;
      CGFloat scale = location.y / UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height;

      if ([RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier]) {
        scale = MIN(MAX(scale, 0.01), 1);
        CGFloat actualScale = scale;
        scale = 1 - scale;
        RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];

        // Interpolates between A and B with percentage T (T% between state A and state B)
        CGFloat (^interpolate)(CGFloat, CGFloat, CGFloat) = ^CGFloat(CGFloat a, CGFloat b, CGFloat t){
          return a + (b - a) * t;
        };

        CGPoint center = CGPointMake(
          interpolate(info.center.x, originalCenter.x, actualScale),
          interpolate(info.center.y, originalCenter.y, actualScale)
        );

        CGFloat currentRotation = (atan2(info.transform.b, info.transform.a) * scale);
        //CGFloat currentScale = 1 - (sqrt(info.transform.a * info.transform.a + info.transform.c * info.transform.c) * scale);
        CGFloat currentScale = interpolate(1, sqrt(info.transform.a * info.transform.a + info.transform.c * info.transform.c), scale);
        CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeScale(currentScale, currentScale), currentRotation);

        appView.center = center;
        appView.transform = transform;
      } else {
        scale = MIN(MAX(scale, 0.3), 1);
        appView.transform = CGAffineTransformMakeScale(scale, scale);
      }
    } else if (state == UIGestureRecognizerStateEnded) {
      [RAControlCenterInhibitor setInhibited:NO];

      if (lastY <= (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / 4) * 3 && lastY != 0) { // 75% down, 0 == gesture ended in most situations
        [UIView animateWithDuration:.3 animations:^{
          if ([RAWindowStatePreservationSystemManager.sharedInstance hasWindowInformationForIdentifier:topApp.bundleIdentifier]) {
            RAPreservedWindowInformation info = [RAWindowStatePreservationSystemManager.sharedInstance windowInformationForAppIdentifier:topApp.bundleIdentifier];
            appView.center = info.center;
            appView.transform = info.transform;
          } else {
            appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
            appView.center = originalCenter;
          }
        } completion:^(BOOL _) {
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
          [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];

          // Pop forced foreground backgrounding
          [[%c(RABackgrounder) sharedInstance] queueRemoveTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
          [[%c(RABackgrounder) sharedInstance] removeTemporaryOverrideForIdentifier:topApp.bundleIdentifier];
          [[%c(RABackgrounder) sharedInstance] updateIconIndicatorForIdentifier:topApp.bundleIdentifier withInfo:indicatorInfo];
        }];
      } else {
        appView.center = originalCenter;
        [UIView animateWithDuration:0.2 animations:^{ appView.transform = CGAffineTransformIdentity; } completion:^(BOOL _) {
          [[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
        }];
      }
      appView = nil;
    }

    return RAGestureCallbackResultSuccess;
  } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
    return [RASettings.sharedInstance windowedMultitaskingEnabled] && (locationIsInValidArea(location.x) || appView) && ![[%c(RASwipeOverManager) sharedInstance] isUsingSwipeOver] && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && [UIApplication.sharedApplication _accessibilityFrontMostApplication] && ![[%c(SBNotificationCenterController) sharedInstance] isVisible];
  } forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.windowedmultitasking.systemgesture" priority:RAGesturePriorityDefault];
}
