#import "RAAppSelectorView.h"

@implementation RAAppSelectorView
-(instancetype) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
  		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
			self.scrollEnabled = YES;
	}
	return self;
}

-(void) relayoutApps
{
	[self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

  static CGSize fullSize = [%c(SBIconView) defaultIconSize];
  fullSize.height = fullSize.width;
  CGFloat padding = 20;

  NSInteger numIconsPerLine = 0;
  CGFloat tmpWidth = 10;
  while (tmpWidth + fullSize.width <= self.frame.size.width)
  {
      numIconsPerLine++;
      tmpWidth += fullSize.width + 20;
  }
  padding = (self.frame.size.width - (numIconsPerLine * fullSize.width)) / (numIconsPerLine + 1);

	CGSize contentSize = CGSizeMake(padding, 10);
	int horizontal = 0;

	static NSMutableArray *allApps = nil;
	if (!allApps)
	{
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			allApps = [[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] mutableCopy];
		} else {
			allApps = [[[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] visibleIconIdentifiers] mutableCopy];
		}
	    [allApps sortUsingComparator: ^(NSString* a, NSString* b) {
	    	NSString *a_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:a].displayName;
	    	NSString *b_ = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:b].displayName;
	        return [a_ caseInsensitiveCompare:b_];
		}];
		//[allApps removeObject:currentBundleIdentifier];
	}
	for (NSString *str in allApps)
	{
		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
		SBApplicationIcon *icon = nil;
		SBIconView *iconView = nil;
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
			iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
		} else {
			icon = [[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
			iconView = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] _iconViewForIcon:icon];
		}
        if (!iconView || ![icon isKindOfClass:[%c(SBApplicationIcon) class]])
        	continue;

        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);
        contentSize.width += iconView.frame.size.width + padding;

        horizontal++;
        if (horizontal >= numIconsPerLine)
        {
        	horizontal = 0;
        	contentSize.width = padding;
        	contentSize.height += iconView.frame.size.height + 10;
        }

        iconView.restorationIdentifier = app.bundleIdentifier;
        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];
        [self addSubview:iconView];
	}
	contentSize.width = self.frame.size.width;
	contentSize.height += fullSize.height * 1.5;
	self.contentSize = contentSize;
}

-(void) appViewItemTap:(UITapGestureRecognizer*)recognizer
{
	if (self.target)
		if ([self.target respondsToSelector:@selector(appSelector:appWasSelected:)])
			[self.target appSelector:self appWasSelected:recognizer.view.restorationIdentifier];
}
@end
