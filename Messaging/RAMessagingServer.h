#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import "RAMessaging.h"

@interface RAMessagingServer : NSObject {
	CPDistributedMessagingCenter *messagingCenter;
	NSMutableDictionary *dataForApps;
	NSMutableDictionary *contextIds;
	NSMutableDictionary *waitingCompletions;
}
+ (instancetype)sharedInstance;

- (void)loadServer;

- (RAMessageAppData)getDataForIdentifier:(NSString*)identifier;
- (void)setData:(RAMessageAppData)data forIdentifier:(NSString*)identifier;
- (void)sendStoredDataToApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;

- (void)resizeApp:(NSString*)identifier toSize:(CGSize)size completion:(RAMessageCompletionCallback)callback;
- (void)moveApp:(NSString*)identifier toOrigin:(CGPoint)origin completion:(RAMessageCompletionCallback)callback;
- (void)endResizingApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;

- (void)rotateApp:(NSString*)identifier toOrientation:(UIInterfaceOrientation)orientation completion:(RAMessageCompletionCallback)callback;
- (void)unRotateApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;

- (void)forceStatusBarVisibility:(BOOL)visibility forApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;
- (void)unforceStatusBarVisibilityForApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;

- (void)setHosted:(BOOL)value forIdentifier:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;

- (void)forcePhoneMode:(BOOL)value forIdentifier:(NSString*)identifier andRelaunchApp:(BOOL)relaunch;

- (unsigned int)getStoredKeyboardContextIdForApp:(NSString*)identifier;

- (void)receiveShowKeyboardForAppWithIdentifier:(NSString*)identifier;
- (void)receiveHideKeyboard;
- (void)setShouldUseExternalKeyboard:(BOOL)value forApp:(NSString*)identifier completion:(RAMessageCompletionCallback)callback;
@end
