#import "RABackgrounder.h"
#import "RASettings.h"

@interface SBIconAccessoryImage : UIImage
-(id)initWithImage:(id)arg1 ;
@end

@interface SBDarkeningImageView : UIImageView
- (void)setImage:(id)arg1 brightness:(double)arg2;
- (void)setImage:(id)arg1;
@end

@interface SBIconBadgeView : UIView
{
    NSString *_text;
    _Bool _animating;
    id/*block*/ _queuedAnimation;
    _Bool _displayingAccessory;
    SBIconAccessoryImage *_backgroundImage;
    SBDarkeningImageView *_backgroundView;
    SBDarkeningImageView *_textView;
}

+ (id)_createImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutBackgroundImage;
+ (id)checkoutAccessoryImagesForIcon:(id)arg1 location:(int)arg2;
+ (struct CGPoint)_overhang;
+ (double)_textPadding;
+ (struct CGPoint)_textOffset;
+ (double)_maxTextWidth;
+ (id)_textFont;
- (void)_resizeForTextImage:(id)arg1;
- (void)_clearText;
- (void)_zoomOutWithPreparation:(id/*block*/)arg1 animation:(id/*block*/)arg2 completion:(id/*block*/)arg3;
- (void)_zoomInWithTextImage:(id)arg1 preparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_crossfadeToTextImage:(id)arg1 withPreparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_configureAnimatedForText:(id)arg1 highlighted:(_Bool)arg2 withPreparation:(id/*block*/)arg3 animation:(id/*block*/)arg4 completion:(id/*block*/)arg5;
- (void)setAccessoryBrightness:(double)arg1;
- (struct CGPoint)accessoryOriginForIconBounds:(struct CGRect)arg1;
- (void)prepareForReuse;
- (_Bool)displayingAccessory;
- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3;
- (void)configureAnimatedForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3 withPreparation:(id/*block*/)arg4 animation:(id/*block*/)arg5 completion:(id/*block*/)arg6;
- (void)layoutSubviews;
- (void)dealloc;
- (id)init;
@end

@interface SBIconParallaxBadgeView : SBIconBadgeView
- (void)_applyParallaxSettings;
- (void)settings:(id)arg1 changedValueForKey:(id)arg2;
@end

NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info)
{
	NSMutableString *ret = [[NSMutableString alloc] init];

	if (info & RAIconIndicatorViewInfoNone)
		return nil;

	if (info & RAIconIndicatorViewInfoNative)
		[ret appendString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		[ret appendString:@"F"];

	if (info & RAIconIndicatorViewInfoForceDeath)
		[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately)
		[ret appendString:@"S"];
		
	if (info & RAIconIndicatorViewInfoUnkillable)
		[ret appendString:@"U"];

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime)
		[ret appendString:@"B"];

	return ret;
}

%hook SBIconView
%new -(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info
{
	[[self viewWithTag:9962] removeFromSuperview];

	NSString *text = stringFromIndicatorInfo(info);
	if ((text == nil || text.length == 0) || (self.icon == nil || self.icon.application == nil || ![RABackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) || [RASettings.sharedInstance backgrounderEnabled] == NO)
	{
		return;
	}

	SBIconBadgeView *badge = [[%c(SBIconBadgeView) alloc] init];
	badge.tag = 9962;
	

	UIImage *img = [%c(SBIconBadgeView) _checkoutImageForText:text highlighted:NO];
	//[badge _configureAnimatedForText:text highlighted:YES withPreparation:nil animation:nil completion:nil];
	[badge _crossfadeToTextImage:img withPreparation:nil animation:nil completion:nil];
	[badge _resizeForTextImage:img];

	SBDarkeningImageView *imgView = MSHookIvar<SBDarkeningImageView*>(badge, "_backgroundView");
	SBIconAccessoryImage *image = [[%c(SBIconAccessoryImage) alloc] initWithImage:[[%c(SBIconBadgeView) _checkoutBackgroundImage] _flatImageWithColor:[UIColor colorWithRed:60/255.0f green:108/255.0f blue:255/255.0f alpha:1.0f]]];
	[imgView setImage:image brightness:1];

	[badge setAccessoryBrightness:1];

	if (!badge.superview)
		[self addSubview:badge];

	CGPoint overhang = [%c(SBIconBadgeView) _overhang];
	badge.frame = CGRectMake(-overhang.x, -overhang.y, badge.frame.size.width, badge.frame.size.height);
}
%end


%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    if (self.isRunning == NO)
    	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
}
%end

%hook SBIconController
-(void)iconWasTapped:(SBApplicationIcon*)arg1 
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.application.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
	%orig;
}
%end