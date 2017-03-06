#import "RALocalizer.h"
#import "headers.h"

@implementation RALocalizer
+(id) sharedInstance
{
	SHARED_INSTANCE2(RALocalizer, [sharedInstance loadTranslation]);
}

-(BOOL) attemptLoadForLanguageCode:(NSString*)code
{
	NSString *expandedPath = [NSString stringWithFormat:@"%@/Localizations/%@.strings",RA_BASE_PATH,code];
	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:expandedPath];
	if (plist)
	{
		translation = plist;
		return YES;
	}
	return NO;
}

-(void) loadTranslation
{
	NSArray *langs = [NSLocale preferredLanguages];

	for (NSString *lang in langs)
	{
		//NSDictionary *components = [NSLocale componentsFromLocaleIdentifier:lang];
		//NSString *languageDesignator = components[NSLocaleLanguageCode];
		if ([self attemptLoadForLanguageCode:lang])
			break;
	}
	if (!translation)
		LogWarn(@"Failed Translation loading English");
		[self attemptLoadForLanguageCode:@"en"];
}

-(NSString*) localizedStringForKey:(NSString*)key
{
	return [translation objectForKey:key] ? translation[key] : key;
}
@end
