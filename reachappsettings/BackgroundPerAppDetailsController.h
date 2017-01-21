#import "headers.h"
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSpecifier.h>

@interface RABGPerAppDetailsController : SKTintedListController<SKListControllerProtocol>
{
	NSString* _appName;
	NSString* _identifier;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier;
@end
