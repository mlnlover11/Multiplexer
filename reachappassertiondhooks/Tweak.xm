#import <dlfcn.h>
#import <Foundation/Foundation.h>

@interface BSAuditToken : NSObject
- (int)pid;
 @end

%hookf(int, "_BSAuditTokenTaskHasEntitlement", BSAuditToken *token, NSString *entitlement) {
	if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
		return 1;
	}
	return %orig;
}

%hookf(int, "_BSXPCConnectionHasEntitlement", id connection, NSString *entitlement) {
	if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
		return 1;
	}
	return %orig;
}
