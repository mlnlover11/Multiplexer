#import "RARunningAppsProvider.h"

@implementation RARunningAppsProvider
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RARunningAppsProvider,
		sharedInstance->apps = [NSMutableArray array];
		sharedInstance->targets = [NSMutableArray array];
	);
}

- (instancetype)init {
	self = [super init];
	if (self) {
		pthread_mutex_init(&mutex, NULL);
	}
	return self;
}

-(void) addRunningApp:(__unsafe_unretained SBApplication*)app
{
	pthread_mutex_lock(&mutex);

	[apps addObject:app];
	for (NSObject<RARunningAppsProviderDelegate>* target in targets)
		if ([target respondsToSelector:@selector(appDidStart:)])
    	dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidStart:app];
			});

	pthread_mutex_unlock(&mutex);
}

-(void) removeRunningApp:(__unsafe_unretained SBApplication*)app
{
	pthread_mutex_lock(&mutex);

	[apps removeObject:app];

	for (NSObject<RARunningAppsProviderDelegate>* target in targets)
		if ([target respondsToSelector:@selector(appDidDie:)])
 	   	dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidDie:app];
			});

	pthread_mutex_unlock(&mutex);
}

-(void) addTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	pthread_mutex_lock(&mutex);

	if (![targets containsObject:target])
		[targets addObject:target];

	pthread_mutex_unlock(&mutex);
}

-(void) removeTarget:(__weak NSObject<RARunningAppsProviderDelegate>*)target
{
	pthread_mutex_lock(&mutex);

	[targets removeObject:target];

	pthread_mutex_unlock(&mutex);
}

- (void)dealloc {
	pthread_mutex_destroy(&mutex);
}

-(NSArray*) runningApplications { return apps; }
-(NSMutableArray*) mutableRunningApplications { return apps; }
@end

%hook SBApplication
- (void)updateProcessState:(unsafe_id)arg1
{
	%orig;

	if (self.isRunning && ![RARunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self])
		[RARunningAppsProvider.sharedInstance addRunningApp:self];
	else if (!self.isRunning && [RARunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self])
		[RARunningAppsProvider.sharedInstance removeRunningApp:self];
}
%end
