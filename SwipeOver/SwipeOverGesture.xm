#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAKeyboardStateListener.h"
#import "RAMissionControlManager.h"
#import "PDFImage.h"
#import "PDFImageOptions.h"
#import "RASettings.h"
#import "RAHostManager.h"
#import "RAResourceImageProvider.h"
#import "Multiplexer.h"

UIView *grabberView;
BOOL isShowingGrabber = NO;
BOOL isPastGrabber = NO;
NSDate *lastTouch;
CGPoint startingPoint;
BOOL firstSwipe = NO;

CGRect adjustFrameForRotation() {
  CGFloat portraitWidth = 30;
  CGFloat portraitHeight = 50;

  CGFloat width = UIScreen.mainScreen.RA_interfaceOrientedBounds.size.width;
  CGFloat height = UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height;

  switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation]) {
    case UIInterfaceOrientationPortrait: {
      LogDebug(@"[ReachApp] portrait");
      return (CGRect){ { width - portraitWidth + 5, (height - portraitHeight) / 2 }, { portraitWidth, portraitHeight } };
    }
    case UIInterfaceOrientationPortraitUpsideDown: {
      LogDebug(@"[ReachApp] portrait upside down");
      return (CGRect){ { 0, 0}, { 50, 50 } };
    }
    case UIInterfaceOrientationLandscapeLeft: {
      LogDebug(@"[ReachApp] landscape left");
      return (CGRect){ { ((width - portraitWidth) / 2), -(portraitWidth / 2) }, { portraitWidth, portraitHeight } };
    }
    case UIInterfaceOrientationLandscapeRight: {
      LogDebug(@"[ReachApp] landscape right");
      return (CGRect){ { (height - portraitHeight) / 2, width - portraitWidth - 5 }, { portraitWidth, portraitHeight } };
    }
  }
  return CGRectZero;
}

CGPoint adjustCenterForOffscreenSlide(CGPoint center) {
  CGFloat portraitWidth = 30;
  //CGFloat portraitHeight = 50;

  switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation]) {
    case UIInterfaceOrientationPortrait:
      return (CGPoint) { center.x + portraitWidth, center.y };
    case UIInterfaceOrientationPortraitUpsideDown:
      return (CGPoint) { center.x - portraitWidth, center.y };
    case UIInterfaceOrientationLandscapeLeft:
      return (CGPoint) { center.x, center.y - portraitWidth };
    case UIInterfaceOrientationLandscapeRight:
      return (CGPoint) { center.x, center.y + portraitWidth };
  }
  return CGPointZero;
}

CGAffineTransform adjustTransformRotation() {
  switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation]) {
    case UIInterfaceOrientationPortrait:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    case UIInterfaceOrientationLandscapeLeft:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
    case UIInterfaceOrientationLandscapeRight:
      return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
  }
  return CGAffineTransformIdentity;
}

BOOL swipeOverLocationIsInValidArea(CGFloat y) {
  if (y == 0) {
    return YES; // more than likely, UIGestureRecognizerStateEnded
  }

  switch ([[%c(RASettings) sharedInstance] swipeOverGrabArea]) {
    case RAGrabAreaSideAnywhere:
      return YES;
    case RAGrabAreaSideTopThird:
      return y <= UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / 3.0;
    case RAGrabAreaSideMiddleThird:
      return y >= UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / 3.0 && y <= (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / 3.0) * 2;
    case RAGrabAreaSideBottomThird:
      return y >= (UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height / 3.0) * 2;
    default:
      return NO;
  }
}

%ctor {
  [[%c(RAGestureManager) sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
    lastTouch = [NSDate date];

    if ([%c(Multiplexer) shouldShowControlCenterGrabberOnFirstSwipe] || [[%c(RASettings) sharedInstance] alwaysShowSOGrabber]) {
      if (!isShowingGrabber && !isPastGrabber) {
        firstSwipe = YES;
        isShowingGrabber = YES;

        grabberView = [[UIView alloc] init];

        _UIBackdropView *bgView = [[%c(_UIBackdropView) alloc] initWithStyle:1];
        bgView.frame = CGRectMake(0, 0, grabberView.frame.size.width, grabberView.frame.size.height);
        [grabberView addSubview:bgView];

        //grabberView.backgroundColor = UIColor.redColor;
        grabberView.frame = adjustFrameForRotation();

        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, grabberView.frame.size.width - 20, grabberView.frame.size.height - 20)];
        imgView.image = [%c(RAResourceImageProvider) imageForFilename:@"Grabber" constrainedToSize:CGSizeMake(grabberView.frame.size.width - 20, grabberView.frame.size.height - 20)];
        [grabberView addSubview:imgView];
        grabberView.layer.cornerRadius = 5;
        grabberView.clipsToBounds = YES;

        grabberView.transform = adjustTransformRotation();
        //[UIWindow.keyWindow addSubview:grabberView]; // The desktop view most likely
        [[[%c(RAHostManager) systemHostViewForApplication:UIApplication.sharedApplication._accessibilityFrontMostApplication] superview] addSubview:grabberView];

        static void (^dismisser)() = ^{ // top kek, needs "static" so it's not a local, self-retaining block
          if ([[NSDate date] timeIntervalSinceDate:lastTouch] > 2) {
            [UIView animateWithDuration:0.2 animations:^{
              //grabberView.frame = CGRectOffset(grabberView.frame, 40, 0);
              grabberView.center = adjustCenterForOffscreenSlide(grabberView.center);
            } completion:^(BOOL _) {
              [grabberView removeFromSuperview];
              grabberView = nil;
              isShowingGrabber = NO;
              isPastGrabber = NO;
            }];
          } else if (grabberView) { // left there
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
              dismisser();
            });
          }
        };
        dismisser();

        return RAGestureCallbackResultSuccess;
      } else if (CGRectContainsPoint(grabberView.frame, location) || (isShowingGrabber && !firstSwipe && [[%c(RASettings) sharedInstance] swipeOverGrabArea] != RAGrabAreaSideAnywhere && [[%c(RASettings) sharedInstance] swipeOverGrabArea] != RAGrabAreaSideMiddleThird)) {
        [grabberView removeFromSuperview];
        grabberView = nil;
        isShowingGrabber = NO;
        isPastGrabber = YES;
      } else if (!isPastGrabber) {
        if (state == UIGestureRecognizerStateEnded) {
          firstSwipe = NO;
        }
        startingPoint = CGPointZero;
        isPastGrabber = NO;
        return RAGestureCallbackResultSuccess;
      }
    }

    CGPoint translation;
    switch (state) {
      case UIGestureRecognizerStateBegan: {
        startingPoint = location;
        break;
      }
      case UIGestureRecognizerStateChanged: {
        translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
        break;
      }
      case UIGestureRecognizerStateEnded: {
        startingPoint = CGPointZero;
        isPastGrabber = NO;
        break;
      }
    }

    if (![RASwipeOverManager.sharedInstance isUsingSwipeOver]) {
      [RASwipeOverManager.sharedInstance startUsingSwipeOver];
    }

    //if (state == UIGestureRecognizerStateChanged)
    [RASwipeOverManager.sharedInstance sizeViewForTranslation:translation state:state];

    return RAGestureCallbackResultSuccess;
  } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
    if ([[%c(RAKeyboardStateListener) sharedInstance] visible] && ![RASwipeOverManager.sharedInstance isUsingSwipeOver]) {
      CGRect realKBFrame = CGRectMake(0, UIScreen.mainScreen.RA_interfaceOrientedBounds.size.height, [[%c(RAKeyboardStateListener) sharedInstance] size].width, [[%c(RAKeyboardStateListener) sharedInstance] size].height);
      realKBFrame = CGRectOffset(realKBFrame, 0, -realKBFrame.size.height);

      if (CGRectContainsPoint(realKBFrame, location) || realKBFrame.size.height > 50) {
        return NO;
      }
    }

    return [[%c(RASettings) sharedInstance] swipeOverEnabled] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBNotificationCenterController) sharedInstance] isVisible] && ![[%c(RAMissionControlManager) sharedInstance] isShowingMissionControl] && (swipeOverLocationIsInValidArea(location.y) || isShowingGrabber);
  } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}
