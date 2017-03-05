#import "Multiplexer.h"
#import "RACompatibilitySystem.h"
#import "headers.h"

@implementation MultiplexerExtension
@end

@implementation Multiplexer
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(Multiplexer, sharedInstance->activeExtensions = [NSMutableArray array]);
}

-(NSString*) currentVersion { return @"1.0"; }
-(BOOL) isOnSupportedOS { return IS_IOS_BETWEEN(iOS_8_0, iOS_10_2); }

-(void) registerExtension:(NSString*)name forMultiplexerVersion:(NSString*)version
{
	if ([self.currentVersion compare:version options:NSNumericSearch] == NSOrderedDescending)
	{
		[RACompatibilitySystem showWarning:[NSString stringWithFormat:@"Extension %@ was built for Multiplexer version %@, which is above the current version. Compliancy issues may occur.", name, version]];
	}

	MultiplexerExtension *ext = [[MultiplexerExtension alloc] init];
	ext.name = name;
	ext.multiplexerVersion = version;
	[activeExtensions addObject:ext];
}

+ (SBAppToAppWorkspaceTransaction*)createSBAppToAppWorkspaceTransactionForExitingApp:(SBApplication*)app
{
	if ([%c(SBAppToAppWorkspaceTransaction) respondsToSelector:@selector(initWithAlertManager:exitedApp:)])
	{
		return [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:app];
	}
	else
	{
	// ** below code from Mirmir (https://github.com/EthanArbuckle/Mirmir/blob/lamo_no_ms/Lamo/CDTLamo.mm#L114-L138)
    SBWorkspaceApplicationTransitionContext *transitionContext = [[%c(SBWorkspaceApplicationTransitionContext) alloc] init];

    //set layout role to 'side' (deactivating)
    SBWorkspaceDeactivatingEntity *deactivatingEntity = [%c(SBWorkspaceDeactivatingEntity) entity];
    [deactivatingEntity setLayoutRole:3];
    [transitionContext setEntity:deactivatingEntity forLayoutRole:3];

    //set layout role for 'primary' (activating)
    SBWorkspaceHomeScreenEntity *homescreenEntity = [[%c(SBWorkspaceHomeScreenEntity) alloc] init];
    [transitionContext setEntity:homescreenEntity forLayoutRole:2];

    [transitionContext setAnimationDisabled:YES];

    //create transititon request
    SBMainWorkspaceTransitionRequest *transitionRequest = [[%c(SBMainWorkspaceTransitionRequest) alloc] initWithDisplay:[UIScreen.mainScreen valueForKey:@"_fbsDisplay"]];
    [transitionRequest setApplicationContext:transitionContext];

    return [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithTransitionRequest:transitionRequest];
  }
}

+(BOOL) shouldShowControlCenterGrabberOnFirstSwipe
{
	if ([%c(SBUIController) respondsToSelector:@selector(shouldShowControlCenterTabControlOnFirstSwipe)])
		[[%c(SBUIController) sharedInstance] shouldShowControlCenterTabControlOnFirstSwipe];
	return [[%c(SBControlCenterController) sharedInstance] _shouldShowGrabberOnFirstSwipe];
}
@end
