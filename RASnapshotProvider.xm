#import "headers.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"
#import "RAResourceImageProvider.h"

@implementation RASnapshotProvider
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(RASnapshotProvider, sharedInstance->imageCache = [NSCache new]);
}

- (UIImage*)snapshotForIdentifier:(NSString*)identifier orientation:(UIInterfaceOrientation)orientation {
	/*if (![NSThread isMainThread])
	{
		__block id result = nil;
		NSOperationQueue* targetQueue = [NSOperationQueue mainQueue];
		[targetQueue addOperationWithBlock:^{
		    result = [self snapshotForIdentifier:identifier orientation:orientation];
		}];
		[targetQueue waitUntilAllOperationsAreFinished];
		return result;
	}*/
	@autoreleasepool {
		if ([imageCache objectForKey:identifier]) {
			return [imageCache objectForKey:identifier];
		}

		UIImage *image = nil;

		SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:identifier];
		__block SBAppSwitcherSnapshotView *view = nil;

		ON_MAIN_THREAD(^{
			if ([%c(SBUIController) respondsToSelector:@selector(switcherController)]) {
				view = [[[%c(SBUIController) sharedInstance] switcherController] performSelector:@selector(_snapshotViewForDisplayItem:) withObject:item];
				[view setOrientation:orientation orientationBehavior:0];
			} else {
				SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];
				view = [[%c(SBAppSwitcherSnapshotView) alloc] initWithDisplayItem:item application:app orientation:orientation preferringDownscaledSnapshot:NO async:NO withQueue:nil];
			}
		});

		if (view) {
			if ([view respondsToSelector:@selector(_loadSnapshotSync)]) {
				[view performSelectorOnMainThread:@selector(_loadSnapshotSync) withObject:nil waitUntilDone:YES];
				image = MSHookIvar<UIImageView*>(view, "_snapshotImageView").image;
			} else {
				_SBAppSwitcherSnapshotContext *snapshotContext = MSHookIvar<_SBAppSwitcherSnapshotContext*>(view, "_snapshotContext");
				SBSwitcherSnapshotImageView *snapshotImageView = snapshotContext.snapshotImageView;
				image = snapshotImageView.image;
			}
		}

		if (!image) {
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:identifier];

			if (app && app.mainSceneID) {
				@try {
					CGRect frame = CGRectMake(0, 0, 0, 0);
					UIView *view = [%c(SBUIController) _zoomViewWithSplashboardLaunchImageForApplication:app sceneID:app.mainSceneID screen:UIScreen.mainScreen interfaceOrientation:0 includeStatusBar:YES snapshotFrame:&frame];

					if (view) {
						UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);

						ON_MAIN_THREAD(^{
							[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
						});

						image = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
					}
				}
				@catch (NSException *ex) {
					LogError(@"[ReachApp] error generating snapshot: %@", ex);
				}
			}

			if (!image) { // we can only hope it does not reach this point of desperation
				image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Default.png", app.path]];
			}
		}

		if (image) {
			[imageCache setObject:image forKey:identifier];
		}

		return image;
	}
}

- (UIImage*)snapshotForIdentifier:(NSString*)identifier {
	return [self snapshotForIdentifier:identifier orientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (void)forceReloadOfSnapshotForIdentifier:(NSString*)identifier {
	[imageCache removeObjectForKey:identifier];
}

- (UIImage*)storedSnapshotOfMissionControl {
	return [imageCache objectForKey:@"missioncontrol"];
}

- (void)storeSnapshotOfMissionControl:(UIWindow*)window {
	UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 0);

	[window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	if (image) {
		[imageCache setObject:image forKey:@"missioncontrol"];
	}
}

- (NSString*)createKeyForDesktop:(RADesktopWindow*)desktop {
	return [NSString stringWithFormat:@"desktop-%lu", (unsigned long)desktop.hash];
}

- (UIImage*)snapshotForDesktop:(RADesktopWindow*)desktop {
	NSString *key = [self createKeyForDesktop:desktop];
	if ([imageCache objectForKey:key]) {
		return [imageCache objectForKey:key];
	}

	UIImage *img = [self renderPreviewForDesktop:desktop];
	if (img) {
		[imageCache setObject:img forKey:key];
	}
	return img;
}

- (void)forceReloadSnapshotOfDesktop:(RADesktopWindow*)desktop {
	[imageCache removeObjectForKey:[self createKeyForDesktop:desktop]];
}

- (UIImage*)rotateImageToMatchOrientation:(UIImage*)oldImage {
	CGFloat degrees = 0;
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
		degrees = 270;
	} else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
		degrees = 90;
	} else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		degrees = 180;
	}

	// https://stackoverflow.com/questions/20764623/rotate-newly-created-ios-image-90-degrees-prior-to-saving-as-png

	__block CGSize rotatedSize;

	ON_MAIN_THREAD(^{
		//Calculate the size of the rotated view's containing box for our drawing space
		static UIView *rotatedViewBox = [[UIView alloc] init];
		rotatedViewBox.frame = CGRectMake(0,0,oldImage.size.width, oldImage.size.height);
		CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
		rotatedViewBox.transform = t;
		rotatedSize = rotatedViewBox.frame.size;
	});

	//CGSize rotatedSize = rotatedViewBox.frame.size;
	//CGSize rotatedSize = CGSizeApplyAffineTransform(oldImage.size, CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees)));

	//Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();

	//Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

	//Rotate the image context
	CGContextRotateCTM(bitmap, (degrees * M_PI / 180));

	//Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

- (UIImage*)renderPreviewForDesktop:(RADesktopWindow*)desktop {
	@autoreleasepool {
		UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, 0);
		CGContextRef context = UIGraphicsGetCurrentContext();

		[[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];

		ON_MAIN_THREAD(^{
			[[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];
		//});

			UIImage *image = [self wallpaperImage:NO];
			CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
			//since drawInRect doesnt work
			CGContextTranslateCTM(context, 0, image.size.height);
			CGContextScaleCTM(context, 1.0, -1.0);

			CGContextDrawImage(context, imageRect, image.CGImage); // Wallpaper

			CGContextScaleCTM(context, 1.0, -1.0);
			CGContextTranslateCTM(context, 0, -imageRect.size.height);
		//[[[[%c(SBUIController) sharedInstance] window] layer] performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Icons
		//ON_MAIN_THREAD(^{
			//[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow") drawViewHierarchyInRect:UIScreen.mainScreen.bounds afterScreenUpdates:YES];
			if (IS_IOS_OR_NEWER(iOS_9_0)) { //not sure why broken
				UIView *view = [[%c(SBIconController) sharedInstance] view];
				[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
			} else {
				[[[%c(SBUIController) sharedInstance] window] drawViewHierarchyInRect:[UIScreen mainScreen].bounds afterScreenUpdates:NO];
			}

			[desktop drawViewHierarchyInRect:desktop.bounds afterScreenUpdates:NO];
		});
		//[desktop.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Desktop windows

		for (UIView *view in desktop.subviews) { // Application views
			if (![view isKindOfClass:[RAWindowBar class]]) {
				continue;
			}
			RAHostedAppView *hostedView = [((RAWindowBar*)view) attachedView];

			UIImage *image = [self snapshotForIdentifier:hostedView.bundleIdentifier orientation:hostedView.orientation];
			CIImage *coreImage = image.CIImage;
			if (!coreImage) {
				coreImage = [CIImage imageWithCGImage:image.CGImage];
			}
			//coreImage = [coreImage imageByApplyingTransform:view.transform];
			CGFloat rotation = atan2(hostedView.transform.b, hostedView.transform.a);

			CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
			coreImage = [coreImage imageByApplyingTransform:transform];
			image = [UIImage imageWithCIImage:coreImage];
			[image drawInRect:view.frame]; // by using frame, we take care of scale.
		}
		//if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
		//	CGContextRotateCTM(c, DEGREES_TO_RADIANS(90));
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		image = [self rotateImageToMatchOrientation:image];
		[[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
		return image;
	}
}

- (UIImage*)wallpaperImage {
	return [self wallpaperImage:YES];
}

- (UIImage*)wallpaperImage:(BOOL)blurred {
	NSString *key = blurred ? @"wallpaperImageBlurred" : @"wallpaperImage";
	if ([imageCache objectForKey:key]) {
		return [imageCache objectForKey:key];
	}
	//its really that easy elijah (ok maybe i need to resize the image);
	UIImage *oldImage = [[%c(SBWallpaperController) sharedInstance] sharedWallpaperView].displayedImage;
	UIImage *image = [RAResourceImageProvider imageWithImage:oldImage scaledToSize:[UIScreen mainScreen].bounds.size];

	if (blurred) {
		CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[gaussianBlurFilter setDefaults];
		CIImage *inputImage = [CIImage imageWithCGImage:[image CGImage]];
		[gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
		[gaussianBlurFilter setValue:@25 forKey:kCIInputRadiusKey];

		CIImage *outputImage = [gaussianBlurFilter outputImage];
		outputImage = [outputImage imageByCroppingToRect:CGRectMake(0, 0, image.size.width * UIScreen.mainScreen.scale, image.size.height * UIScreen.mainScreen.scale)];
		CIContext *context = [CIContext contextWithOptions:nil];
		CGImageRef cgimg = [context createCGImage:outputImage fromRect:[inputImage extent]];  // note, use input image extent if you want it the same size, the output image extent is larger
		image = [UIImage imageWithCGImage:cgimg];
		CGImageRelease(cgimg);
	}

	[imageCache setObject:image forKey:key];

	return image;
}

- (void)forceReloadEverything {
	[imageCache removeAllObjects];
}
@end
