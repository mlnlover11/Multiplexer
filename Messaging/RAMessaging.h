#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RAMessageType) {
	RAMessageTypeUpdateAppData = 0,

	RAMessageTypeShowKeyboard,
	RAMessageTypeHideKeyboard,
	RAMessageTypeUpdateKeyboardContextId,
	RAMessageTypeRetrieveKeyboardContextId,
};

typedef struct {
	BOOL shouldForceSize;
	// Can't use CGSize because it uses CGFloats which aren't able to be transferred between 32/64bit processes (because its float in one and something else (double? i can't remember) in the other).
	// Also why we can't use CGFloat here
	float wantedClientOriginX;
	float wantedClientOriginY;
	float wantedClientWidth;
	float wantedClientHeight;

	BOOL statusBarVisibility;
	BOOL shouldForceStatusBar;
	BOOL canHideStatusBarIfWanted;

	UIInterfaceOrientation forcedOrientation;
	BOOL shouldForceOrientation;

	BOOL shouldUseExternalKeyboard;
	BOOL isBeingHosted;
	// Only applies after the app has been restarted.
	BOOL forcePhoneMode;
} RAMessageAppData;

static NSString *RAMessagingUpdateAppInfoMessageName = @"updateAppInfo";
static NSString *RAMessagingShowKeyboardMessageName = @"showKeyboard";
static NSString *RAMessagingHideKeyboardMessageName = @"hideKeyboard";
static NSString *RAMessagingUpdateKeyboardContextIdMessageName = @"updateKBContextId";
static NSString *RAMessagingRetrieveKeyboardContextIdMessageName = @"getKBContextId";
static NSString *RAMessagingUpdateKeyboardSizeMessageName = @"updateKBSize";
static NSString *RAMessagingOpenURLKMessageName = @"openURL";
static NSString *RAMessagingSnapFrontMostWindowLeftMessageName = @"snapLeft";
static NSString *RAMessagingSnapFrontMostWindowRightMessageName = @"snapRight";
static NSString *RAMessagingGoToDesktopOnTheLeftMessageName = @"switchToDesktopLeft";
static NSString *RAMessagingGoToDesktopOnTheRightMessageName = @"switchToDesktopRight";
static NSString *RAMessagingAddNewDesktopMessageName = @"addNewDesktop";
static NSString *RAMessagingMaximizeAppMessageName = @"maximizeApp";
static NSString *RAMessagingCloseAppMessageName = @"closeApp";
static NSString *RAMessagingGetFrontMostAppInfoMessageName = @"frontMostApp";
static NSString *RAMessagingChangeFrontMostAppMessageName = @"yes_another_message";
static NSString *RAMessagingDetachCurrentAppMessageName = @"the_messages_never_end";

typedef void (^RAMessageCompletionCallback)(BOOL success);
