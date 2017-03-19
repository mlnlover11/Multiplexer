#import "RALocalizer.h"
#import "headers.h"

@implementation RALocalizer
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RALocalizer, [sharedInstance loadTranslation]);
}

- (BOOL)attemptLoadForLanguageCode:(NSString*)code {
	NSString *expandedPath = [NSString stringWithFormat:@"%@/Localizations/%@.strings",RA_BASE_PATH,code];
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:expandedPath];
	if (plist) {
		translation = plist;
		return YES;
	}
	return NO;
}

- (void)loadTranslation {
	NSArray *langs = [NSLocale preferredLanguages];

	for (NSString *lang in langs) {
		NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:lang];
		NSString *languageDesignator = components[NSLocaleLanguageCode];

		if ([self attemptLoadForLanguageCode:languageDesignator]) {
			break;
		}
	}
	if (!translation) {
		[self attemptLoadForLanguageCode:@"en"];
	}
}

- (NSString*)localizedStringForKey:(NSString*)key {
	return ![translation objectForKey:key] ? key : translation[key];
}
@end
