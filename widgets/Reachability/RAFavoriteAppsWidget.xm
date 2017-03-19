#import "headers.h"
#import "RAFavoriteAppsWidget.h"
#import "RAReachabilityManager.h"
#import "RAWidgetSectionManager.h"
#import "RASettings.h"

@interface RAFavoriteAppsWidget () {
	CGFloat savedX;
}
@end

@implementation RAFavoriteAppsWidget
- (BOOL)enabled {
	return [RASettings.sharedInstance showFavorites];
}

- (NSInteger)sortOrder {
	return 2;
}

- (NSString*)displayName {
	return LOCALIZE(@"FAVORITES");
}

- (NSString*)identifier {
	return @"com.efrederickson.reachapp.widgets.sections.favoriteapps";
}

- (CGFloat)titleOffset {
	return savedX;
}

- (UIView*)viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size_ iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing {
	CGSize size = [%c(SBIconView) defaultIconSize];
	spacing = (frame.size.width - (iconsPerLine * size.width)) / iconsPerLine;
	NSString *currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
	if (!currentBundleIdentifier) {
		return nil;
	}
	CGSize contentSize = CGSizeMake((spacing / 2.0), 10);
	CGFloat interval = (size.width + spacing) * iconsPerLine;
	NSInteger intervalCount = 1;
	BOOL isTop = YES;
	BOOL hasSecondRow = NO;
	SBApplication *app = nil;
	CGFloat width = interval;
	savedX = spacing / 2.0;

	NSMutableArray *favorites = [RASettings.sharedInstance favoriteApps];
	[favorites removeObject:currentBundleIdentifier];
	if (favorites.count == 0) {
		return nil;
	}

	UIScrollView *favoritesView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 200)];
	favoritesView.backgroundColor = [UIColor clearColor];
	favoritesView.pagingEnabled = [RASettings.sharedInstance pagingEnabled];
	for (NSString *str in favorites) {
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
		SBApplicationIcon *icon = nil;
		SBIconView *iconView = nil;
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
			iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
		} else {
			icon = [[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] applicationIconForBundleIdentifier:app.bundleIdentifier];
			iconView = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] _iconViewForIcon:icon];
		}
		if (!iconView) {
			continue;
		}

		if (interval != 0 && contentSize.width + iconView.frame.size.width > interval * intervalCount) {
			if (isTop) {
				contentSize.height += size.height + 10;
				contentSize.width -= interval;
			} else {
				intervalCount++;
				contentSize.height -= (size.height + 10);
				width += interval;
			}
			hasSecondRow = YES;
			isTop = !isTop;
		}

		iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);

		iconView.tag = app.pid;
		iconView.restorationIdentifier = app.bundleIdentifier;
		UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
		[iconView addGestureRecognizer:iconViewTapGestureRecognizer];

		[favoritesView addSubview:iconView];

		contentSize.width += iconView.frame.size.width + spacing;
	}
	contentSize.width = width;
	contentSize.height = 10 + ((size.height + 10) * (hasSecondRow ? 2 : 1));
	frame = favoritesView.frame;
	frame.size.height = contentSize.height;
	favoritesView.frame = frame;
	[favoritesView setContentSize:contentSize];
	return favoritesView;
}

- (void)appViewItemTap:(UIGestureRecognizer*)gesture {
	[GET_SBWORKSPACE appViewItemTap:gesture];
	//[[RAReachabilityManager sharedInstance] launchTopAppWithIdentifier:gesture.view.restorationIdentifier];
}
@end

%ctor {
	static id _widget = [[RAFavoriteAppsWidget alloc] init];
	[RAWidgetSectionManager.sharedInstance registerSection:_widget];
}
