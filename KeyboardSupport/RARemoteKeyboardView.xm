#import "RARemoteKeyboardView.h"
#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Foundation/Foundation.h>
#import "RAMessagingServer.h"

@interface RARemoteKeyboardView () {
    BOOL cancelFetchingContextId;
}
@end

@implementation RARemoteKeyboardView
@synthesize layerHost = _layerHost;

- (void)connectToKeyboardWindowForApp:(NSString*)identifier {
  if (!identifier) {
    self.layerHost.contextId = 0;
    cancelFetchingContextId = YES;
    return;
  }
  _identifier = identifier;

  unsigned int value = [RAMessagingServer.sharedInstance getStoredKeyboardContextIdForApp:identifier];
  self.layerHost.contextId = value;

  LogDebug(@"[ReachApp] loaded keyboard view with %d", value);
  if (value == 0 && !cancelFetchingContextId) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [self connectToKeyboardWindowForApp:identifier];
    });
  }
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.userInteractionEnabled = YES;
    self.layerHost = [[CALayerHost alloc] init];
    self.layerHost.anchorPoint = CGPointMake(0, 0);
    if (IS_IOS_OR_OLDER(iOS_8_4)) {
      self.layerHost.transform = CATransform3DMakeScale(1/[UIScreen mainScreen].scale, 1/[UIScreen mainScreen].scale, 1);
    }
    self.layerHost.bounds = self.bounds;
    [self.layer addSublayer:self.layerHost];
    update = NO;
  }

  return self;
}

- (void)dealloc {
  self.layerHost = nil;
}
@end
