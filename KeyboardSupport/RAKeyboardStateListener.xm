#import "RAKeyboardStateListener.h"
#import "headers.h"
#import <execinfo.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "RAMessaging.h"
#import "RAMessagingClient.h"
#import "RAKeyboardWindow.h"
#import "RARemoteKeyboardView.h"
#import "RADesktopManager.h"

extern BOOL overrideDisableForStatusBar;
BOOL isShowing = NO;

@implementation RAKeyboardStateListener
+ (instancetype)sharedInstance {
  SHARED_INSTANCE(RAKeyboardStateListener);
}

- (void)didShow:(NSNotification*)notif {
  LogDebug(@"[ReachApp] keyboard didShow");
  _visible = YES;
  _size = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

  IF_NOT_SPRINGBOARD {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, NULL, true);
    [RAMessagingClient.sharedInstance notifyServerOfKeyboardSizeUpdate:_size];

    if ([RAMessagingClient.sharedInstance shouldUseExternalKeyboard]) {
      [RAMessagingClient.sharedInstance notifyServerToShowKeyboard];
      isShowing = YES;
    }
  }
}

- (void)didHide {
  LogDebug(@"[ReachApp] keyboard didHide");
  _visible = NO;

  IF_NOT_SPRINGBOARD {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, NULL, true);
    if ([RAMessagingClient.sharedInstance shouldUseExternalKeyboard] || isShowing) {
      isShowing = NO;
      [RAMessagingClient.sharedInstance notifyServerToHideKeyboard];
    }
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didShow:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(didHide) name:UIApplicationWillResignActiveNotification object:nil];
  }
  return self;
}

- (void)_setVisible:(BOOL)val {
  _visible = val;
}

- (void)_setSize:(CGSize)size {
  _size = size;
}
@end

void externalKeyboardDidShow(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [RAKeyboardStateListener.sharedInstance _setVisible:YES];
}

void externalKeyboardDidHide(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  //LogDebug(@"[ReachApp] externalKeyboardDidHide");
  [RAKeyboardStateListener.sharedInstance _setVisible:NO];
}

%hook UIKeyboard
- (void)activate {
  %orig;

  void (^block)() = ^{
    IF_NOT_SPRINGBOARD {
        unsigned int contextID = 0;
        if (%c(UIRemoteKeyboardWindow) && [UIKeyboard activeKeyboard] && [[UIKeyboard activeKeyboard] window]) {
          contextID = [[[UIKeyboard activeKeyboard] window] _contextId]; // ((UITextEffectsWindow*)[%c(UIRemoteKeyboardWindow) remoteKeyboardWindowForScreen:UIScreen.mainScreen create:NO])._contextId;
        } else {
          contextID = UITextEffectsWindow.sharedTextEffectsWindow._contextId;
        }
        [RAMessagingClient.sharedInstance notifyServerWithKeyboardContextId:contextID];

  #if DEBUG && NO
        assert([[[UIKeyboard activeKeyboard] window] _contextId]);
        assert(contextID != 0);
        assert(contextID == [[[UIKeyboard activeKeyboard] window] _contextId]);
  #endif

        LogDebug(@"[ReachApp] c id %d", contextID);
    }
  };

  if (IS_IOS_OR_NEWER(iOS_9_0)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), block);
  } else {
    block();
  }
}

+ (void)initImplementationNow {
  %orig;
  LogDebug(@"initImplementationNow");
}
%end

%ctor {
  // Any process
  [RAKeyboardStateListener sharedInstance];

  // Just SpringBoard
  IF_SPRINGBOARD {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, externalKeyboardDidShow, CFSTR("com.efrederickson.reachapp.keyboard.didShow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, externalKeyboardDidHide, CFSTR("com.efrederickson.reachapp.keyboard.didHide"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  }
}
