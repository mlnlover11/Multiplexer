#import "RACompatibilitySystem.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "headers.h"
#import "UIAlertController+Window.h"

@implementation RACompatibilitySystem
+(NSString*) aggregateSystemInfo
{
	NSMutableString *ret = [[NSMutableString alloc] init];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    [ret appendString:[NSString stringWithFormat:@"%@, %@ %@\n", sysInfo, UIDevice.currentDevice.systemName, UIDevice.currentDevice.systemVersion]];

    return ret;
}

+(void) showWarning:(NSString*)info
{
	NSString *message = [NSString stringWithFormat:@"System info: %@\n\nWARNING: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Multiplexer Compatibility" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [alert show];
}

+(void) showError:(NSString*)info
{
	NSString *message = [NSString stringWithFormat:@"System info: %@\n\n***ERROR***: POTENTIAL INCOMPATIBILITY DETECTED\n%@", [self aggregateSystemInfo], info];

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Multiplexer Compatibility" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [alert show];
}
@end
