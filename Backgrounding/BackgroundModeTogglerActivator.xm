#import <libactivator/libactivator.h>
#import "RABackgrounder.h"
#import "RASettings.h"

@interface RAActivatorBackgrounderToggleModeListener : NSObject <LAListener, UIAlertViewDelegate>
@end

static RAActivatorBackgrounderToggleModeListener *sharedInstance$RAActivatorBackgrounderToggleModeListener;

@implementation RAActivatorBackgrounderToggleModeListener
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    SBApplication *app = [UIApplication sharedApplication]._accessibilityFrontMostApplication;

    if (!app)
        return;

    NSString *friendlyCurrentBackgroundMode = FriendlyNameForBackgroundMode((RABackgroundMode)[RABackgrounder.sharedInstance backgroundModeForIdentifier:app.bundleIdentifier]);

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"MULTIPLEXER") message:[NSString stringWithFormat:LOCALIZE(@"BACKGROUNDER_POPUP_SWITCHER_TEXT"),app.displayName,friendlyCurrentBackgroundMode] delegate:self cancelButtonTitle:LOCALIZE(@"CANCEL") otherButtonTitles:LOCALIZE(@"FORCE_FOREGROUND"), LOCALIZE(@"NATIVE"), LOCALIZE(@"SUSPEND_IMMEDIATELY"), LOCALIZE(@"DISABLE"), nil];

    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    SBApplication *app = UIApplication.sharedApplication._accessibilityFrontMostApplication;
    if (!app)
        return;

    BOOL dismissApp = [[%c(RASettings) sharedInstance] exitAppAfterUsingActivatorAction];

    if (buttonIndex == [alertView cancelButtonIndex])
    {
        return;
    }
    if (buttonIndex == 1)
    {
        // Force foreground
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForcedForeground forApplication:app andCloseForegroundApp:dismissApp];
    }
    else if (buttonIndex == 2)
    {
        // Native
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeNative forApplication:app andCloseForegroundApp:dismissApp];
    }
    else if (buttonIndex == 3)
    {
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeSuspendImmediately forApplication:app andCloseForegroundApp:dismissApp];
    }
    else// if (buttonIndex == 3)
    {
        [RABackgrounder.sharedInstance temporarilyApplyBackgroundingMode:RABackgroundModeForceNone forApplication:app andCloseForegroundApp:dismissApp];
    }
}
@end

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
    {
        sharedInstance$RAActivatorBackgrounderToggleModeListener = [[RAActivatorBackgrounderToggleModeListener alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance$RAActivatorBackgrounderToggleModeListener forName:@"com.efrederickson.reachapp.backgrounder.togglemode"];
    }
}