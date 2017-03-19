#import "headers.h"
#import "RAHostedAppView.h"

@class RADesktopWindow;

@interface RAWindowBar : UIView <UIGestureRecognizerDelegate> {
	RAHostedAppView *attachedView;
}

@property (nonatomic, weak) RADesktopWindow *desktop;

- (void)close;
- (void)maximize;
- (void)minimize;
- (void)sizingLockButtonTap:(id)arg1;
- (BOOL)isLocked;

- (void)showOverlay;
- (void)hideOverlay;
- (BOOL)isOverlayShowing;

- (RAHostedAppView*)attachedView;
- (void)attachView:(RAHostedAppView*)view;

- (void)updateClientRotation;
- (void)updateClientRotation:(UIInterfaceOrientation)orientation;

- (void)scaleTo:(CGFloat)scale animated:(BOOL)animate;
- (void)scaleTo:(CGFloat)scale animated:(BOOL)animate derotate:(BOOL)derotate;

- (void)saveWindowInfo;

- (void)disableLongPress;
- (void)enableLongPress;

- (void)resignForemostApp;
- (void)becomeForemostApp;
@end
