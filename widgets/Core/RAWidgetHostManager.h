#import "headers.h"
#import "RAWidgetBase.h"

@interface RAWidgetHostManager : NSObject {
	NSMutableArray *widgets;
}
+(instancetype) sharedInstance;

-(void) addWidget:(RAWidgetBase*)widget;
-(void) removeWidget:(RAWidgetBase*)widget;
-(void) removeWidgetWithIdentifier:(NSString*)identifier;
-(RAWidgetBase*) widgetForIdentifier:(NSString*)identifier;
@end
