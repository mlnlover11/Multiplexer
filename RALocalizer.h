@interface RALocalizer : NSObject {
	NSDictionary *translation;
}
+(instancetype) sharedInstance;

-(NSString*) localizedStringForKey:(NSString*)key;
@end
