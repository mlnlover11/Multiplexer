@class SBApplication;

@interface MultiplexerExtension : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *multiplexerVersion;
@end

@interface Multiplexer : NSObject {
	NSMutableArray *activeExtensions;
}
+ (instancetype)sharedInstance;

- (NSString*)currentVersion;
- (BOOL)isOnSupportedOS;

- (void)registerExtension:(NSString*)name forMultiplexerVersion:(NSString*)version;

+ (id)createSBAppToAppWorkspaceTransactionForExitingApp:(SBApplication*)app;
+ (BOOL)shouldShowControlCenterGrabberOnFirstSwipe;
@end
