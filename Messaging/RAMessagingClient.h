#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import "RAMessaging.h"

@interface RAMessagingClient : NSObject {
	CPDistributedMessagingCenter *serverCenter;
}
+ (instancetype)sharedInstance;

@property (nonatomic, readonly) RAMessageAppData currentData;
@property (nonatomic) BOOL hasRecievedData;
@property (nonatomic, copy) NSString *knownFrontmostApp;

- (void)requestUpdateFromServer;

- (void)notifyServerWithKeyboardContextId:(unsigned int)cid;
- (void)notifyServerOfKeyboardSizeUpdate:(CGSize)size;
- (void)notifyServerToShowKeyboard;
- (void)notifyServerToHideKeyboard;
- (BOOL)notifyServerToOpenURL:(NSURL*)url openInWindow:(BOOL)openWindow;
- (void)notifySpringBoardOfFrontAppChangeToSelf;

// Methods to ease the currentData usage
- (BOOL)shouldResize;
- (CGSize)resizeSize;
- (BOOL)shouldHideStatusBar;
- (BOOL)shouldShowStatusBar;
- (UIInterfaceOrientation)forcedOrientation;
- (BOOL)shouldForceOrientation;
- (BOOL)shouldUseExternalKeyboard;
- (BOOL)isBeingHosted;
@end
