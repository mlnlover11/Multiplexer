#import "headers.h"
#import "RABackgrounder.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

@interface FBApplicationInfo : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
- (BOOL)isExitsOnSuspend;
@end

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(__unsafe_unretained NSString *)mode {
	int override = [RABackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
	if (override == -1) {
		return %orig;
	}
	return override;
}
%end

%hook BKSProcessAssertion
- (instancetype)initWithPID:(NSInteger)arg1 flags:(NSUInteger)arg2 reason:(NSUInteger)arg3 name:(NSString *)arg4 withHandler:(unsafe_id)arg5 {
	if (arg3 != BKSProcessAssertionReasonViewServices && // whitelist this to allow share menu to work
	    ![arg4 isEqualToString:@"Called by iOS6_iCleaner, from unknown method"] && // whitelist iCleaner to prevent crash on open
	    ![arg4 isEqualToString:@"Called by Filza_main, from -[AppDelegate applicationDidEnterBackground:]"]) // Whitelist filza to prevent iOS hang (?!) Not sure if the springboard hack is still required
	{
		NSString *identifier = [NSBundle mainBundle].bundleIdentifier;

		if (!identifier)
		  goto ORIGINAL;

		//LogDebug(@"BKSProcessAssertion initWithPID:'%zd' flags:'%tu' reason:'%tu' name:'%@' withHandler:'%@' process identifier:'%@'", arg1, arg2, arg3, arg4, arg5, identifier);

		if ([RABackgrounder.sharedInstance shouldSuspendImmediately:identifier]) {
		  if ((arg3 >= BKSProcessAssertionReasonAudio && arg3 <= BKSProcessAssertionReasonVOiP)) // In most cases arg3 == 4 (finish task)
			{
		    //NSLog(@"[ReachApp] blocking BKSProcessAssertion");

		    //if (arg5)
		    //{
		        //void (^arg5fix)() = arg5;
		        //arg5fix();
		        // ^^ causes crashes with share menu
		    //}
		    return nil;
		  }
		  //else if (arg3 == kProcessAssertionReasonActivation)
		  //{
		  //    arg2 = ProcessAssertionFlagAllowIdleSleep;
		  //}
		}
	}
ORIGINAL:
	return %orig(arg1, arg2, arg3, arg4, arg5);
}
%end
