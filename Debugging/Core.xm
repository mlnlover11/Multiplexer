#import <substrate.h>
#import <objc/runtime.h>
#import "RACompatibilitySystem.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#import "headers.h"

%hook NSObject
- (void)doesNotRecognizeSelector:(SEL)selector
{
	LogDebug(@"[ReachApp] doesNotRecognizeSelector: selector '%@' on class '%s' (image: %s)", NSStringFromSelector(selector), class_getName(self.class), class_getImageName(self.class));

	NSArray *symbols = [NSThread callStackSymbols];
	LogDebug(@"[ReachApp] Obtained %zd stack frames:\n", symbols.count);
	for (NSString *symbol in symbols)
	{
		LogDebug(@"[ReachApp] %@\n", symbol);
	}

	%orig;
}
%end

/*Class (*orig$objc_getClass)(const char *name);
Class hook$objc_getClass(const char *name)
{
	Class cls = orig$objc_getClass(name);
	if (!cls)
	{
		LogDebug(@"[ReachApp] something attempted to access nil class '%s'", name);
	}
	return cls;
}*/

%ctor
{
	IF_SPRINGBOARD {

		// Causes cycript to not function
		//MSHookFunction((void*)objc_getClass, (void*)hook$objc_getClass, (void**)&orig$objc_getClass);

		%init;
	}
	//LogDebug(@"[ReachApp] %s", class_getImageName(orig$objc_getClass("RAMissionControlManager")));
}
