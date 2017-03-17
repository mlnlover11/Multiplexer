#import "headers.h"
#import "RARunningAppsProvider.h"

@interface RASpringBoardKeyboardActivation : NSObject<RARunningAppsProviderDelegate>
+ (instancetype)sharedInstance;

@property (nonatomic, readonly, copy) NSString *currentIdentifier;

- (void)showKeyboardForAppWithIdentifier:(NSString*)identifier;
- (void)hideKeyboard;

- (UIWindow*)keyboardWindow;
@end
