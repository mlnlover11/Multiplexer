#import <dlfcn.h>
#import <Foundation/Foundation.h>

@interface BSAuditToken : NSObject
- (int)pid;
 @end

%hookf(BOOL, "_BSAuditTokenTaskHasEntitlement", BSAuditToken *token, NSString *entitlement) {
	if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
		return YES;
	}
	return %orig;
}
