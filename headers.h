#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <SpringBoard/SBIconLabel.h>
#import <SpringBoard/SBApplication.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import <IOKit/hid/IOHIDEvent.h>
#import <AssertionServices/BKSProcessAssertion.h>
#import <GraphicsServices/GraphicsServices.h>
#import <SpringBoardServices/SBSRestartRenderServerAction.h>
#import <FrontBoard/FBProcess.h>
#import <FrontBoard/FBProcessManager.h>
#import <FrontBoard/FBScene.h>
#import <FrontBoard/FBSceneManager.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <version.h>

#define RA_BASE_PATH @"/Library/Multiplexer"

#import "RALocalizer.h"
#define LOCALIZE(x) [[objc_getClass("RALocalizer") sharedInstance] localizedStringForKey:x]

#import "RAThemeManager.h"
// Note that "x" expands into the passed variable
#define THEMED(x) [[objc_getClass("RAThemeManager") sharedInstance] currentTheme].x

#import "RASBWorkspaceFetcher.h"
#define GET_SBWORKSPACE [RASBWorkspaceFetcher getCurrentSBWorkspaceImplementationInstanceForThisOS]

#define GET_STATUSBAR_ORIENTATION (![UIApplication sharedApplication]._accessibilityFrontMostApplication ? UIApplication.sharedApplication.statusBarOrientation : UIApplication.sharedApplication._accessibilityFrontMostApplication.statusBarOrientation)

#if DEBUG
#define LogDebug HBLogDebug
#define LogInfo HBLogInfo
#define LogWarn HBLogWarn
#define LogError HBLogError
#else
#define LogDebug(...)
#define LogInfo(...)
#define LogWarn(...)
#define LogError(...)
#endif

#if MULTIPLEXER_CORE
extern BOOL $__IS_SPRINGBOARD;
#define IS_SPRINGBOARD $__IS_SPRINGBOARD
#else
#define IS_SPRINGBOARD IN_SPRINGBOARD
#endif

#define ON_MAIN_THREAD(block) \
    { \
      dispatch_block_t _blk = block; \
      if (NSThread.isMainThread) { \
        _blk(); \
      } else { \
        dispatch_sync(dispatch_get_main_queue(), _blk); \
      } \
    }

#define IF_SPRINGBOARD if (IS_SPRINGBOARD)
#define IF_NOT_SPRINGBOARD if (!IS_SPRINGBOARD)
#define IF_THIS_PROCESS(x) if ([[x objectForKey:@"bundleIdentifier"] isEqual:NSBundle.mainBundle.bundleIdentifier])

// ugh, i got so tired of typing this in by hand, plus it expands method declarations by a LOT.
#define unsafe_id __unsafe_unretained id

#ifdef __cplusplus
extern "C" {
#endif

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
void BKSHIDServicesCancelTouchesOnMainDisplay();

#ifdef __cplusplus
}
#endif

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(radians) ((radians) * (M_PI / 180))

void SET_BACKGROUNDED(id settings, BOOL val);

#define SHARED_INSTANCE2(cls, extracode) \
static cls *sharedInstance = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
    sharedInstance = [[cls alloc] init]; \
    extracode; \
}); \
return sharedInstance;

#define SHARED_INSTANCE(cls) SHARED_INSTANCE2(cls, );

////////////////////////////////////////////////////////////////////////////////////////////////

@interface UIRemoteKeyboardWindow : UIWindow //UITextEffectsWindow
+(instancetype)remoteKeyboardWindowForScreen:(id)arg1 create:(BOOL)arg2;
@end

@interface SBMainSwitcherGestureCoordinator : NSObject
+ (id)sharedInstance;
- (void)_releaseOrientationLock;
- (void)_lockOrientation;
@end

@interface SBIconImageView : UIView {
    UIImageView *_overlayView;
    //SBIconProgressView *_progressView;
    _Bool _isPaused;
    UIImage *_cachedSquareContentsImage;
    _Bool _showsSquareCorners;
    SBIcon *_icon;
    double _brightness;
    double _overlayAlpha;
}

+ (id)dequeueRecycledIconImageViewOfClass:(Class)arg1;
+ (void)recycleIconImageView:(id)arg1;
+ (double)cornerRadius;
@property(nonatomic) _Bool showsSquareCorners; // @synthesize showsSquareCorners=_showsSquareCorners;
@property(nonatomic) double overlayAlpha; // @synthesize overlayAlpha=_overlayAlpha;
@property(nonatomic) double brightness; // @synthesize brightness=_brightness;
@property(retain, nonatomic) SBIcon *icon; // @synthesize icon=_icon;
- (_Bool)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)iconImageDidUpdate:(id)arg1;
- (struct CGRect)visibleBounds;
- (struct CGSize)sizeThatFits:(struct CGSize)arg1;
- (id)squareDarkeningOverlayImage;
- (id)darkeningOverlayImage;
- (id)squareContentsImage;
- (UIImage*)contentsImage;
- (void)_clearCachedImages;
- (id)_generateSquareContentsImage;
- (void)_updateProgressMask;
- (void)_updateOverlayImage;
- (id)_currentOverlayImage;
- (void)updateImageAnimated:(_Bool)arg1;
- (id)snapshot;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (void)setPaused:(_Bool)arg1;
- (void)setProgressAlpha:(double)arg1;
- (void)_clearProgressView;
- (void)progressViewCanBeRemoved:(id)arg1;
- (void)setProgressState:(long long)arg1 paused:(_Bool)arg2 percent:(double)arg3 animated:(_Bool)arg4;
- (void)_updateOverlayAlpha;
- (void)setIcon:(id)arg1 animated:(_Bool)arg2;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
@end

@interface SBOrientationLockManager : NSObject
{
    NSMutableSet *_lockOverrideReasons;
    long long _userLockedOrientation;
}

+ (id)sharedInstance;
- (_Bool)_effectivelyLocked;
- (void)_updateLockStateWithOrientation:(long long)arg1 forceUpdateHID:(_Bool)arg2 changes:(id/*block*/)arg3;
- (void)_updateLockStateWithChanges:(id/*block*/)arg1;
- (void)updateLockOverrideForCurrentDeviceOrientation;
- (_Bool)lockOverrideEnabled;
- (void)enableLockOverrideForReason:(id)arg1 forceOrientation:(long long)arg2;
- (void)enableLockOverrideForReason:(id)arg1 suggestOrientation:(long long)arg2;
- (void)setLockOverrideEnabled:(_Bool)arg1 forReason:(id)arg2;
- (long long)userLockOrientation;
- (_Bool)isLocked;
- (void)unlock;
- (void)lock:(long long)arg1;
- (void)lock;
- (void)dealloc;
- (id)init;
- (void)restoreStateFromPrefs;

@end

@interface SBMedusaSettings : NSObject
{
    _Bool _enableSideApps;
    _Bool _enableBreadcrumbs;
    _Bool _enablePinningSideApps;
    _Bool _debugSceneColors;
    _Bool _debugRotationCenter;
    _Bool _debugColorRotationRegions;
    _Bool _clipRotationRegions;
    _Bool _fencesRotation;
    NSString *_desiredBundleIdentifier;
    double _zoomOutRotationFactor;
    double _rotationSlowdownFactor;
    double _spaceAroundSideGrabberToAllowPullIn;
    unsigned long long _millisecondsBetweenResizeSteps;
    double _slideOffResizeThreshold;
    double _gapSwipeBuffer;
}

+ (id)settingsControllerModule;
@property(nonatomic) double gapSwipeBuffer; // @synthesize gapSwipeBuffer=_gapSwipeBuffer;
@property(nonatomic) double slideOffResizeThreshold; // @synthesize slideOffResizeThreshold=_slideOffResizeThreshold;
@property(nonatomic) unsigned long long millisecondsBetweenResizeSteps; // @synthesize millisecondsBetweenResizeSteps=_millisecondsBetweenResizeSteps;
@property(nonatomic) _Bool fencesRotation; // @synthesize fencesRotation=_fencesRotation;
@property(nonatomic) double spaceAroundSideGrabberToAllowPullIn; // @synthesize spaceAroundSideGrabberToAllowPullIn=_spaceAroundSideGrabberToAllowPullIn;
@property(nonatomic) double rotationSlowdownFactor; // @synthesize rotationSlowdownFactor=_rotationSlowdownFactor;
@property(nonatomic) double zoomOutRotationFactor; // @synthesize zoomOutRotationFactor=_zoomOutRotationFactor;
@property(nonatomic) _Bool clipRotationRegions; // @synthesize clipRotationRegions=_clipRotationRegions;
@property(nonatomic) _Bool debugColorRotationRegions; // @synthesize debugColorRotationRegions=_debugColorRotationRegions;
@property(nonatomic) _Bool debugRotationCenter; // @synthesize debugRotationCenter=_debugRotationCenter;
@property(nonatomic) _Bool debugSceneColors; // @synthesize debugSceneColors=_debugSceneColors;
@property(copy, nonatomic) NSString *desiredBundleIdentifier; // @synthesize desiredBundleIdentifier=_desiredBundleIdentifier;
@property(nonatomic) _Bool enablePinningSideApps; // @synthesize enablePinningSideApps=_enablePinningSideApps;
@property(nonatomic) _Bool enableBreadcrumbs; // @synthesize enableBreadcrumbs=_enableBreadcrumbs;
@property(nonatomic) _Bool enableSideApps; // @synthesize enableSideApps=_enableSideApps;
- (_Bool)anyRotationDebuggingEnabled;
- (void)setDefaultValues;

@end

@interface SBToAppsWorkspaceTransaction : NSObject
-(NSArray*) toApplications;
@end

@interface SBFWallpaperView : UIView
@property (nonatomic,readonly) UIImage *wallpaperImage;
- (void)setGeneratesBlurredImages:(BOOL)arg1;
- (void)_startGeneratingBlurredImages;
- (void)prepareToAppear;
@end

@interface SBFStaticWallpaperView : SBFWallpaperView
@property (setter=_setDisplayedImage:,getter=_displayedImage,nonatomic,retain) UIImage *displayedImage;
@end

@interface SBControlCenterController : UIViewController
+ (id)sharedInstance;
@property(nonatomic, getter=isPresented) _Bool presented; // @synthesize presented=_presented;
@property(nonatomic, getter=isUILocked) _Bool UILocked; // @synthesize UILocked=_uiLocked;
- (void)dismissAnimated:(_Bool)arg1;
- (void)presentAnimated:(_Bool)arg1;
- (void)presentAnimated:(_Bool)arg1 completion:(id)arg2;
- (void)hideGrabberAnimated:(_Bool)arg1 completion:(id)arg2;
- (void)hideGrabberAnimated:(_Bool)arg1;
- (void)showGrabberAnimated:(_Bool)arg1;
- (void)preventDismissalOnLock:(_Bool)arg1 forReason:(id)arg2;
- (void)_dismissOnLock;
- (void)_uiRelockedNotification:(id)arg1;
- (void)_lockStateChangedNotification:(id)arg1;
- (_Bool)isGrabberVisible;
- (_Bool)isPresentingControllerTransitioning;
- (_Bool)isVisible;
- (void)loadView;
- (_Bool)handleMenuButtonTap;
- (void)removeObserver:(id)arg1;
- (void)addObserver:(id)arg1;
- (_Bool)isAvailableWhileLocked;

// iOS 9
- (_Bool)_shouldShowGrabberOnFirstSwipe;
@end

@interface BKSProcess : NSObject { //BSBaseXPCClient  {
    int _pid;
    NSString *_bundlePath;
    bool _workspaceLocked;
    bool _connectedToExternalAccessories;
    bool _nowPlayingWithAudio;
    bool _recordingAudio;
    bool _supportsTaskSuspension;
    int _visibility;
    int _taskState;
    NSObject *_delegate;
    long long _terminationReason;
    long long _exitStatus;
}

@property (nonatomic, weak) NSObject * delegate;
@property int visibility;
@property long long terminationReason;
@property long long exitStatus;
@property bool workspaceLocked;
@property bool connectedToExternalAccessories;
@property bool nowPlayingWithAudio;
@property bool recordingAudio;
@property bool supportsTaskSuspension;
@property int taskState;
@property(readonly) double backgroundTimeRemaining;

+ (id)busyExtensionInstances:(id)arg1;
+ (void)setTheSystemApp:(int)arg1 identifier:(id)arg2;
+ (double)backgroundTimeRemaining;

- (void)setVisibility:(int)arg1;
- (int)visibility;
- (void)_sendMessageType:(int)arg1 withMessage:(id)arg2 withReplyHandler:(id)arg3 waitForReply:(bool)arg4;
- (long long)exitStatus;
- (id)initWithPID:(int)arg1 bundlePath:(id)arg2 visibility:(int)arg3 workspaceLocked:(bool)arg4 queue:(id)arg5;
- (bool)supportsTaskSuspension;
- (void)setTerminationReason:(long long)arg1;
- (void)setConnectedToExternalAccessories:(bool)arg1;
- (void)setNowPlayingWithAudio:(bool)arg1;
- (void)setRecordingAudio:(bool)arg1;
- (void)setWorkspaceLocked:(bool)arg1;
- (void)setTaskState:(int)arg1;
- (void)queue_connectionWasCreated;
- (void)queue_connectionWasInterrupted;
- (void)queue_handleMessage:(id)arg1;
- (bool)recordingAudio;
- (bool)nowPlayingWithAudio;
- (bool)connectedToExternalAccessories;
- (bool)workspaceLocked;
- (void)setExitStatus:(long long)arg1;
- (void)_handleDebuggingStateChanged:(id)arg1;
- (void)_handleExpirationWarning:(id)arg1;
- (void)_handleSuspendedStateChanged:(id)arg1;
- (void)_sendMessageType:(int)arg1 withMessage:(id)arg2;
- (int)taskState;
- (double)backgroundTimeRemaining;
- (void)setSupportsTaskSuspension:(bool)arg1;
- (id)delegate;
- (id)init;
- (void)setDelegate:(NSObject*)arg1;
- (void)dealloc;
- (long long)terminationReason;
@end

@interface SBAppSwitcherSnapshotView : UIView
- (void)setOrientation:(long long)arg1 orientationBehavior:(int)arg2;
- (void)_loadSnapshotAsync;
- (void)_loadZoomUpSnapshotSync;
- (void)_loadSnapshotSync;
- (id)initWithDisplayItem:(id)arg1 application:(id)arg2 orientation:(long long)arg3 preferringDownscaledSnapshot:(_Bool)arg4 async:(_Bool)arg5 withQueue:(id)arg6;
@end

@interface _SBFVibrantSettings : NSObject
{
    int _style;
    UIColor *_referenceColor;
    id _legibilitySettings; // _UILegibilitySettings *_legibilitySettings;
    float _referenceContrast;
    UIColor *_tintColor;
    UIColor *_shimmerColor;
    UIColor *_chevronShimmerColor;
    UIColor *_highlightColor;
    UIColor *_highlightLimitingColor;
}

+ (id)vibrantSettingsWithReferenceColor:(id)arg1 referenceContrast:(float)arg2 legibilitySettings:(id)arg3;
@property(retain, nonatomic) UIColor *highlightLimitingColor; // @synthesize highlightLimitingColor=_highlightLimitingColor;
@property(retain, nonatomic) UIColor *highlightColor; // @synthesize highlightColor=_highlightColor;
@property(retain, nonatomic) UIColor *chevronShimmerColor; // @synthesize chevronShimmerColor=_chevronShimmerColor;
@property(retain, nonatomic) UIColor *shimmerColor; // @synthesize shimmerColor=_shimmerColor;
@property(retain, nonatomic) UIColor *tintColor; // @synthesize tintColor=_tintColor;
@property(readonly, nonatomic) float referenceContrast; // @synthesize referenceContrast=_referenceContrast;
//@property(readonly, nonatomic) _UILegibilitySettings *legibilitySettings; // @synthesize legibilitySettings=_legibilitySettings;
@property(readonly, nonatomic) UIColor *referenceColor; // @synthesize referenceColor=_referenceColor;
@property(readonly, nonatomic) int style; // @synthesize style=_style;
- (id)highlightLimitingViewWithFrame:(struct CGRect)arg1;
- (id)tintViewWithFrame:(struct CGRect)arg1;
- (id)_computeSourceColorDodgeColorForDestinationColor:(id)arg1 producingLuminanceChange:(float)arg2;
- (int)_style;
- (unsigned int)hash;
- (BOOL)isEqual:(id)arg1;
- (void)dealloc;
- (id)initWithReferenceColor:(id)arg1 referenceContrast:(float)arg2 legibilitySettings:(id)arg3;

@end

typedef struct {
    BOOL itemIsEnabled[29];
    char timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    char serviceString[100];
    char serviceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned dataNetworkType;
    int batteryCapacity;
    unsigned batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned thermalSunlightMode : 1;
    unsigned slowActivity : 1;
    unsigned syncActivity : 1;
    char activityDisplayId[256];
    unsigned bluetoothConnected : 1;
    unsigned displayRawGSMSignal : 1;
    unsigned displayRawWifiSignal : 1;
    unsigned locationIconType : 1;
    unsigned quietModeInactive : 1;
    unsigned tetheringConnectionCount;
    unsigned batterySaverModeActive : 1;
    unsigned deviceIsRTL : 1;
    char breadcrumbTitle[256];
    char breadcrumbSecondaryTitle[256];
    char personName[100];
} StatusBarData;

@interface UIStatusBar : UIView
+ (CGFloat)heightForStyle:(int)arg1 orientation:(int)arg2;
- (void)setOrientation:(int)arg1;
- (void)requestStyle:(int)arg1;
-(void) forceUpdateToData:(StatusBarData*)arg1 animated:(BOOL)arg2;
@end

@interface UIStatusBarServer
+(StatusBarData*) getStatusBarData;
@end

@interface SBNotificationCenterViewController : UIViewController
@property (nonatomic,readonly) CGRect contentFrame;
-(CGRect)_containerFrame;
-(void)_setContainerFrame:(CGRect)arg1 ;
-(void)prepareLayoutForDefaultPresentation;
-(void)_loadContainerView;
-(void)_loadContentView;
@end

@interface SBSearchEtceteraLayoutContentView : UIView
@end

@interface SBSearchEtceteraLayoutView : UIView
@property (getter=_visibleView,nonatomic,retain,readonly) SBSearchEtceteraLayoutContentView * visibleView;
-(id)_visibleView;
@end

@interface SBNotificationCenterController : NSObject
+(id) sharedInstance;
-(SBNotificationCenterViewController *)viewController;
-(BOOL) isVisible;
-(double)percentComplete;
-(BOOL)isTransitioning;
-(BOOL)isPresentingControllerTransitioning;
@end

@interface SBSearchEtceteraIsolatedViewController : UIViewController
@property (nonatomic,retain,readonly) SBSearchEtceteraLayoutView * contentView;
-(SBSearchEtceteraLayoutView *)contentView;
+(id)sharedInstance;
@end

@interface UIStatusBarItem : NSObject
-(NSString*)indicatorName;
@end

@interface UIScreen (ohBoy)
- (CGRect)_gkBounds;
-(CGRect) _referenceBounds;
- (CGPoint)convertPoint:(CGPoint)arg1 toCoordinateSpace:(id)arg2;
+ (CGPoint)convertPoint:(CGPoint)arg1 toView:(id)arg2;

-(CGRect) _interfaceOrientedBounds; // ios 8
-(CGRect) RA_interfaceOrientedBounds; // ios 8 + 9 (wrapper)
@end

@interface UIAutoRotatingWindow : UIWindow
- (instancetype)_initWithFrame:(CGRect)arg1 attached:(BOOL)arg2;
- (void)updateForOrientation:(UIInterfaceOrientation)arg1;
@end

@interface LSApplicationProxy
+ (id)applicationProxyForIdentifier:(id)arg1;
- (NSArray*) UIBackgroundModes;
@property (nonatomic, readonly) NSURL *appStoreReceiptURL;
@property (nonatomic, readonly) NSURL *bundleContainerURL;
@property (nonatomic, readonly) NSURL *bundleURL;
@end

@interface UIViewController ()
- (void)setInterfaceOrientation:(UIInterfaceOrientation)arg1;
- (void)_setInterfaceOrientationOnModalRecursively:(int)arg1;
- (void)_updateInterfaceOrientationAnimated:(BOOL)arg1;
@end

@interface SBWallpaperController
@property (nonatomic,retain) SBFStaticWallpaperView *sharedWallpaperView;
+(id) sharedInstance;
-(void) beginRequiringWithReason:(NSString*)reason;
-(void) endRequiringWithReason:(NSString*)reason;
@end

@interface BBAction
+ (id)actionWithCallblock:(id /* block */)arg1;
+ (id)actionWithTextReplyCallblock:(id)arg1;
+ (id)actionWithLaunchBundleID:(id)arg1 callblock:(id)arg2;
+ (id)actionWithLaunchURL:(id)arg1 callblock:(id)arg2;
+ (id)actionWithCallblock:(id)arg1;
@end

typedef enum
{
    NSNotificationSuspensionBehaviorDrop = 1,
    NSNotificationSuspensionBehaviorCoalesce = 2,
    NSNotificationSuspensionBehaviorHold = 3,
    NSNotificationSuspensionBehaviorDeliverImmediately = 4
} NSNotificationSuspensionBehavior;

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (instancetype)defaultCenter;
- (void)addObserver:(id)notificationObserver selector:(SEL)notificationSelector name:(NSString *)notificationName object:(NSString *)notificationSender suspensionBehavior:(NSNotificationSuspensionBehavior)suspendedDeliveryBehavior;
- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(NSString *)notificationSender;
- (void)postNotificationName:(NSString *)notificationName object:(NSString *)notificationSender userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately;
@end

@interface SBLockStateAggregator
-(void) _updateLockState;
-(BOOL) hasAnyLockState;
@end

@interface BBBulletinRequest : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *sectionID;
@property (nonatomic, copy) BBAction *defaultAction;
@property (nonatomic, copy) NSDate *date;

@property(copy) BBAction * acknowledgeAction;
@property(copy) BBAction * replyAction;

@property(retain) NSDate * expirationDate;
@end

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(BBBulletinRequest *)bulletin forFeed:(int)feed;
-(void) observer:(id)observer addBulletin:(BBBulletinRequest*) bulletin forFeed:(int)feed playLightsAndSirens:(BOOL)guess1 withReply:(id)guess2;
@end

@interface SBAppSwitcherWindow : UIWindow
@end

@interface SBChevronView : UIView
@property(retain, nonatomic) _SBFVibrantSettings *vibrantSettings;
-(void) setState:(int)state animated:(BOOL)animated;
- (void)setBackgroundView:(id)arg1;
@property(retain, nonatomic) UIColor *color;
@end

@interface SBControlCenterGrabberView : UIView
-(SBChevronView*) chevronView;
- (void)_setStatusState:(int)arg1;
@end

@interface SBAppSwitcherController
- (void)forceDismissAnimated:(_Bool)arg1;
- (void)animateDismissalToDisplayLayout:(id)arg1 withCompletion:(id/*block*/)arg2;
- (void)animatePresentationFromDisplayLayout:(id)arg1 withViews:(id)arg2 withCompletion:(id/*block*/)arg3;
@property(nonatomic, copy) NSObject *startingDisplayLayout; // @synthesize startingDisplayLayout=_startingDisplayLayout;
- (void)switcherWasPresented:(_Bool)arg1;
@end

@interface SBUIController : NSObject
+(id) sharedInstance;
+ (id)_zoomViewWithSplashboardLaunchImageForApplication:(id)arg1 sceneID:(id)arg2 screen:(id)arg3 interfaceOrientation:(long long)arg4 includeStatusBar:(_Bool)arg5 snapshotFrame:(struct CGRect *)arg6;
-(id) switcherController;
- (id)_appSwitcherController;
-(void) activateApplicationAnimated:(SBApplication*)app;
- (id)switcherWindow;
- (void)_animateStatusBarForSuspendGesture;
- (void)_showControlCenterGestureCancelled;
- (void)_showControlCenterGestureFailed;
- (void)_hideControlCenterGrabber;
- (void)_showControlCenterGestureEndedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2;
- (void)_showControlCenterGestureChangedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2 duration:(CGFloat)arg3;
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1;
- (void)restoreContentUpdatingStatusBar:(_Bool)arg1;
-(void) restoreContentAndUnscatterIconsAnimated:(BOOL)arg1;
- (_Bool)shouldShowControlCenterTabControlOnFirstSwipe;- (_Bool)isAppSwitcherShowing;
-(BOOL) _activateAppSwitcher;
- (void)_releaseTransitionOrientationLock;
- (void)_releaseSystemGestureOrientationLock;
- (void)releaseSwitcherOrientationLock;
- (void)_lockOrientationForSwitcher;
- (void)_lockOrientationForSystemGesture;
- (void)_lockOrientationForTransition;
- (void)_dismissSwitcherAnimated:(_Bool)arg1;
- (void)dismissSwitcherAnimated:(_Bool)arg1;
- (void)_dismissAppSwitcherImmediately;
- (void)dismissSwitcherForAlert:(id)arg1;

- (void)activateApplication:(id)arg1;
@end

@interface SBDisplayItem : NSObject <NSCopying>
+ (id)displayItemWithType:(NSString *)arg1 displayIdentifier:(id)arg2;

@property(readonly, nonatomic) NSString *displayIdentifier; // @synthesize displayIdentifier=_displayIdentifier;
@property(readonly, nonatomic) NSString *type; // @synthesize type=_type;
@end

@interface SBHomeScreenViewController : UIViewController
@end

@interface SBHomeScreenWindow : UIWindow
@property (nonatomic, weak,readonly) SBHomeScreenViewController *homeScreenViewController;
@end

@interface SBLockScreenManager
+(id) sharedInstance;
-(BOOL) isUILocked;
@end

@interface BKSWorkspace : NSObject
- (NSString *)topActivatingApplication;
@end

@interface SpringBoard (OrientationSupport)
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation;
@end

typedef struct {
    int type;
    int modifier;
    NSUInteger pathIndex;
    NSUInteger pathIdentity;
    CGPoint location;
    CGPoint previousLocation;
    CGPoint unrotatedLocation;
    CGPoint previousUnrotatedLocation;
    double totalDistanceTraveled;
    UIInterfaceOrientation interfaceOrientation;
    UIInterfaceOrientation previousInterfaceOrientation;
    double timestamp;
    BOOL isValid;
} SBActiveTouch;

typedef NS_ENUM(NSInteger, UIScreenEdgePanRecognizerType) {
    UIScreenEdgePanRecognizerTypeMultitasking,
    UIScreenEdgePanRecognizerTypeNavigation,
    UIScreenEdgePanRecognizerTypeOther
};

@protocol _UIScreenEdgePanRecognizerDelegate;

@interface _UIScreenEdgePanRecognizer : NSObject
- (id)initWithType:(UIScreenEdgePanRecognizerType)type;
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation forceState:(int)arg5;
- (void)reset;
@property (nonatomic, assign) id <_UIScreenEdgePanRecognizerDelegate> delegate;
@property (nonatomic, readonly) NSInteger state;
@property (nonatomic) UIRectEdge targetEdges;
@property (nonatomic) CGRect screenBounds;
@end

@protocol _UIScreenEdgePanRecognizerDelegate <NSObject>
@optional
- (void)screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer;
@end

@interface UIDevice (UIDevicePrivate)
- (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;
@end

@interface _UIBackdropViewSettings : NSObject
@property (nonatomic) CGFloat grayscaleTintAlpha;
@property (nonatomic) CGFloat grayscaleTintLevel;
- (void)setBlurQuality:(id)arg1;
+ (id)settingsForStyle:(int)arg1;
+ (id)settingsForStyle:(int)arg1 graphicsQuality:(int)arg2;
- (void)setBlurRadius:(CGFloat)arg1;
@end

@interface _UIBackdropView : UIView
@property (retain, nonatomic) _UIBackdropViewSettings *outputSettings;
@property (retain, nonatomic) _UIBackdropViewSettings *inputSettings;
@property (assign,nonatomic) double _blurRadius;
@property (nonatomic) int blurHardEdges;
- (void)_applyCornerRadiusToSubviews;
- (void)_setCornerRadius:(double)arg1 ;
- (void) setBlursWithHardEdges:(BOOL)arg1;
- (void)setBlurQuality:(id)arg1;
- (void)setBlurRadius:(CGFloat)radius;
- (void)setBlurRadiusSetOnce:(BOOL)v;
- (id)initWithStyle:(NSInteger)style;
@property (nonatomic) BOOL autosizesToFitSuperview;
@property (nonatomic) BOOL blursBackground;
- (void)_setBlursBackground:(BOOL)arg1;
- (void)setBlurFilterWithRadius:(float)arg1 blurQuality:(id)arg2 blurHardEdges:(int)arg3;
@end

@interface SBOffscreenSwipeGestureRecognizer : NSObject // SBPanGestureRecognizer <_UIScreenEdgePanRecognizerDelegate>
-(id) initForOffscreenEdge:(int)edge;
-(void) setTypes:(NSInteger)types;
-(void) setMinTouches:(NSInteger)amount;
-(void) setHandler:(id)arg;
-(void) setCanBeginCondition:(id)arg;
-(void) setShouldUseUIKitHeuristics:(BOOL)val;
@end

@interface UIInternalEvent : UIEvent {
    __GSEvent *_gsEvent;
    __IOHIDEvent *_hidEvent;
}

- (__GSEvent*)_gsEvent;
- (__IOHIDEvent*)_hidEvent;
- (id)_screen;
- (void)_setGSEvent:(__GSEvent*)arg1;
- (void)_setHIDEvent:(__IOHIDEvent*)arg1;
@end

@interface UIKeyboardImpl
+ (id)activeInstance;
+ (id)sharedInstance;
- (void)handleKeyEvent:(id)arg1;
- (void)handleKeyWithString:(id)arg1 forKeyEvent:(id)arg2 executionContext:(id)arg3;
- (void)deleteBackward;
-(void) setInHardwareKeyboardMode:(BOOL)arg1;
@end

@interface UIPhysicalKeyboardEvent
+ (id)_eventWithInput:(id)arg1 inputFlags:(int)arg2;
@property(retain, nonatomic) NSString *_privateInput; // @synthesize _privateInput;
@property(nonatomic) int _inputFlags; // @synthesize _inputFlags;
@property(nonatomic) int _modifierFlags; // @synthesize _modifierFlags;
@property(retain, nonatomic) NSString *_markedInput; // @synthesize _markedInput;
@property(retain, nonatomic) NSString *_commandModifiedInput; // @synthesize _commandModifiedInput;
@property(retain, nonatomic) NSString *_shiftModifiedInput; // @synthesize _shiftModifiedInput;
@property(retain, nonatomic) NSString *_unmodifiedInput; // @synthesize _unmodifiedInput;
@property(retain, nonatomic) NSString *_modifiedInput; // @synthesize _modifiedInput;
@property(readonly, nonatomic) int _gsModifierFlags;
- (void)_privatizeInput;
- (void)dealloc;
- (id)_cloneEvent;
- (BOOL)isEqual:(id)arg1;
- (BOOL)_matchesKeyCommand:(id)arg1;
- (void)_setHIDEvent:(struct __IOHIDEvent *)arg1 keyboard:(struct __GSKeyboard *)arg2;
@property(readonly, nonatomic) long _keyCode;
@property(readonly, nonatomic) BOOL _isKeyDown;
- (int)type;
@end

@interface FBWorkspaceEvent : NSObject
+ (instancetype)eventWithName:(NSString *)label handler:(id)handler;
@end

@interface FBDisplayManager : NSObject
+(id)sharedInstance;
+(id)mainDisplay;
@end

@interface SBWorkspaceApplicationTransitionContext : NSObject
@property(nonatomic) _Bool animationDisabled; // @synthesize animationDisabled=_animationDisabled;
- (void)setEntity:(id)arg1 forLayoutRole:(int)arg2;
@end

@interface SBWorkspaceDeactivatingEntity : NSObject
@property(nonatomic) long long layoutRole; // @synthesize layoutRole=_layoutRole;
+ (id)entity;
@end

@interface SBWorkspaceHomeScreenEntity : NSObject
@end

@interface SBMainWorkspaceTransitionRequest : NSObject
- (id)initWithDisplay:(id)arg1;
- (void)setApplicationContext:(SBWorkspaceApplicationTransitionContext *)arg1 ;
@end

@interface SBAppToAppWorkspaceTransaction
- (void)begin;
- (id)initWithAlertManager:(id)alertManager exitedApp:(id)app;
- (id)initWithAlertManager:(id)arg1 from:(id)arg2 to:(id)arg3 withResult:(id)arg4;
- (id)initWithTransitionRequest:(id)arg1;
@end

@interface FBWorkspaceEventQueue : NSObject
+ (instancetype)sharedInstance;
- (void)executeOrAppendEvent:(FBWorkspaceEvent *)event;
@end

@interface SBDeactivationSettings
-(id)init;
-(void)setFlag:(int)flag forDeactivationSetting:(unsigned)deactivationSetting;
@end

@interface SBWorkspace : NSObject
+(id) sharedInstance;
-(BOOL) isUsingReachApp;
- (void)_exitReachabilityModeWithCompletion:(id)arg1;
- (void)_disableReachabilityImmediately:(_Bool)arg1;
- (void)handleReachabilityModeDeactivated;
-(void) RA_animateWidgetSelectorOut:(id)completion;
-(void) RA_setView:(UIView*)view preferredHeight:(CGFloat)preferredHeight;
-(void) RA_launchTopAppWithIdentifier:(NSString*) bundleIdentifier;
-(void) RA_showWidgetSelector;
-(void) updateViewSizes:(CGPoint)center animate:(BOOL)animate;
-(void) RA_closeCurrentView;
-(void) RA_handleLongPress:(UILongPressGestureRecognizer*)gesture;
-(void) RA_updateViewSizes;
-(void) appViewItemTap:(id)sender;
@end

@interface SBMainWorkspace : SBWorkspace // replaces SBWorkspace on iOS 9
@end

@interface SBDisplayLayout : NSObject {
  int _layoutSize;
  NSMutableArray* _displayItems;
  NSString* _uniqueStringRepresentation;
}
@property(readonly, assign, nonatomic) NSArray* displayItems;
@property(readonly, assign, nonatomic) int layoutSize;
+(id)fullScreenDisplayLayoutForApplication:(id)application;
+(id)homeScreenDisplayLayout;
+(id)displayLayoutWithPlistRepresentation:(id)plistRepresentation;
+(id)displayLayoutWithLayoutSize:(int)layoutSize displayItems:(id)items;
-(id)displayLayoutBySettingSize:(int)size;
-(id)displayLayoutByReplacingDisplayItemOnSide:(int)side withDisplayItem:(id)displayItem;
-(id)displayLayoutByRemovingDisplayItems:(id)items;
-(id)displayLayoutByRemovingDisplayItem:(id)item;
-(id)displayLayoutByAddingDisplayItem:(id)item side:(int)side withLayout:(int)layout;
-(BOOL)isEqual:(id)equal;
-(unsigned)hash;
-(id)uniqueStringRepresentation;
-(id)_calculateUniqueStringRepresentation;
-(id)description;
-(id)copyWithZone:(NSZone*)zone;
-(void)dealloc;
-(id)plistRepresentation;
-(id)initWithLayoutSize:(int)layoutSize displayItems:(id)items;
@end

@interface FBProcessManager ()
- (void)_updateWorkspaceLockedState;
- (void)applicationProcessWillLaunch:(id)arg1;
- (void)noteProcess:(id)arg1 didUpdateState:(id)arg2;
- (void)noteProcessDidExit:(id)arg1;
- (id)_serviceClientAddedWithPID:(int)arg1 isUIApp:(BOOL)arg2 isExtension:(BOOL)arg3 bundleID:(id)arg4;
- (id)_serviceClientAddedWithConnection:(id)arg1;
- (id)_systemServiceClientAdded:(id)arg1;
- (BOOL)_isWorkspaceLocked;
- (id)createApplicationProcessForBundleID:(id)arg1 withExecutionContext:(id)arg2;
- (id)createApplicationProcessForBundleID:(id)arg1;
- (id)applicationProcessForPID:(int)arg1;
- (id)applicationProcessesForBundleIdentifier:(id)arg1;
- (id)processesForBundleIdentifier:(id)arg1;
- (id)allApplicationProcesses;
- (id)allProcesses;
@end

@interface UIGestureRecognizerTarget : NSObject {
  id _target;
}
@end

@interface FBWindowContextHostManager
- (id)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (void)resumeContextHosting;
- (id)_hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (id)snapshotViewWithFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3;
- (id)snapshotUIImageForFrame:(struct CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3 outTransform:(struct CGAffineTransform *)arg4;
- (id)visibleContexts;
- (void)orderRequesterFront:(id)arg1;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 priority:(int)arg2;
- (void)disableHostingForRequester:(id)arg1;
- (void)_updateHostViewFrameForRequester:(id)arg1;
- (void)invalidate;

@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface FBSSceneSettings : NSObject <NSCopying, NSMutableCopying>
{
    CGRect _frame;
    CGPoint _contentOffset;
    float _level;
    int _interfaceOrientation;
    BOOL _backgrounded;
    BOOL _occluded;
    BOOL _occludedHasBeenCalculated;
    NSSet *_ignoreOcclusionReasons;
    NSArray *_occlusions;
    //BSSettings *_otherSettings;
    //BSSettings *_transientLocalSettings;
}

+ (BOOL)_isMutable;
+ (id)settings;
@property(readonly, copy, nonatomic) NSArray *occlusions; // @synthesize occlusions=_occlusions;
@property(readonly, nonatomic, getter=isBackgrounded) BOOL backgrounded; // @synthesize backgrounded=_backgrounded;
@property(readonly, nonatomic) int interfaceOrientation; // @synthesize interfaceOrientation=_interfaceOrientation;
@property(readonly, nonatomic) float level; // @synthesize level=_level;
@property(readonly, nonatomic) CGPoint contentOffset; // @synthesize contentOffset=_contentOffset;
@property(readonly, nonatomic) CGRect frame; // @synthesize frame=_frame;
- (id)valueDescriptionForFlag:(int)arg1 object:(id)arg2 ofSetting:(unsigned int)arg3;
- (id)keyDescriptionForSetting:(unsigned int)arg1;
- (id)description;
- (BOOL)isEqual:(id)arg1;
- (unsigned int)hash;
- (id)_descriptionOfSettingsWithMultilinePrefix:(id)arg1;
- (id)transientLocalSettings;
- (BOOL)isIgnoringOcclusions;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
- (BOOL)isOccluded;
- (CGRect)bounds;
- (void)dealloc;
- (id)init;
- (id)initWithSettings:(id)arg1;
@end

@interface FBSMutableSceneSettings : FBSSceneSettings
{
}

+ (BOOL)_isMutable;
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
@property(copy, nonatomic) NSArray *occlusions;
- (id)transientLocalSettings;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;
@property(nonatomic) int interfaceOrientation;
@property(nonatomic) float level;
@property(nonatomic) struct CGPoint contentOffset;
@property(nonatomic) struct CGRect frame;

@end

@interface UIMutableApplicationSceneSettings : FBSMutableSceneSettings
@end

@interface FBScene ()
-(FBWindowContextHostManager*) contextHostManager;
- (void)updateSettings:(id)arg1 withTransitionContext:(id)arg2;
@end

@interface SBApplication ()
-(void) _setDeactivationSettings:(SBDeactivationSettings*)arg1;
-(void) clearDeactivationSettings;
-(FBScene*) mainScene;
-(id) mainScreenContextHostManager;
-(id) mainSceneID;
- (void)activate;

- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(_Bool)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;

@property(readwrite, nonatomic) int pid;
@end

@interface SBApplicationController : NSObject
+(id) sharedInstance;
-(SBApplication*) applicationWithBundleIdentifier:(NSString*)identifier;
-(SBApplication*) applicationWithDisplayIdentifier:(NSString*)identifier;
-(SBApplication*)applicationWithPid:(int)arg1;
-(SBApplication*) RA_applicationWithBundleIdentifier:(NSString*)bundleIdentifier;
@end

@interface FBWindowContextHostWrapperView : UIView
@property(readonly, nonatomic) FBWindowContextHostManager *manager; // @synthesize manager=_manager;
@property(nonatomic) unsigned int appearanceStyle; // @synthesize appearanceStyle=_appearanceStyle;
- (void)_setAppearanceStyle:(unsigned int)arg1 force:(BOOL)arg2;
- (id)_stringForAppearanceStyle;
- (id)window;
@property(readonly, nonatomic) struct CGRect referenceFrame; // @dynamic referenceFrame;
@property(readonly, nonatomic, getter=isContextHosted) BOOL contextHosted; // @dynamic contextHosted;
- (void)clearManager;
- (void)_hostingStatusChanged;
- (BOOL)_isReallyHosting;
- (void)updateFrame;

@property(retain, nonatomic) UIColor *backgroundColorWhileNotHosting;
@property(retain, nonatomic) UIColor *backgroundColorWhileHosting;
@end
@interface FBWindowContextHostView : UIView
@end

@interface UIKeyboard : UIView
+ (BOOL)isOnScreen;
+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (CGRect)defaultFrameForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (id)activeKeyboard;

- (BOOL)isMinimized;
- (void)minimize;
@end

@interface BKSProcessAssertion ()
- (id)initWithBundleIdentifier:(id)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(id)arg4 withHandler:(id)arg5;
- (void)invalidate;
@property(readonly, nonatomic) BOOL valid;
@end

@interface SBReachabilityManager
+ (id)sharedInstance;
@property(readonly, nonatomic) _Bool reachabilityModeActive; // @synthesize reachabilityModeActive=_reachabilityModeActive;
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
@end
@interface SBAppSwitcherModel : NSObject
+ (id)sharedInstance;
- (id)snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary;
- (id)snapshot;
- (void)remove:(id)arg1;
- (void)removeDisplayItem:(id)arg1;
- (void)addToFront:(id)arg1;
- (void)_verifyAppList;
- (id)_recentsFromPrefs;
- (id)_recentsFromLegacyPrefs;

// iOS 9
- (id)commandTabDisplayItems;
- (id)displayItemsForAppsOfRoles:(id)arg1;
- (id)mainSwitcherDisplayItems;
//- (void)remove:(id)arg1;
- (void)addToFront:(id)arg1 role:(long long)arg2;
- (void)_warmUpIconForDisplayItem:(id)arg1;
- (void)_warmUpRecentIcons;
- (void)_pruneRoles;
- (id)_displayItemRolesFromPrefsForLoadedDisplayItems:(id)arg1;
- (void)_saveRecents;
- (void)_saveRecentsDelayed;
- (void)_invalidateSaveTimer;
- (void)_appActivationStateDidChange:(id)arg1;

@end

@interface UIImage ()
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface FBApplicationProcess : NSObject
- (void)launchIfNecessary;
- (BOOL)bootstrapAndExec;
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(id)arg3 completion:(id/*block*/)arg4;
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(id)arg3;
@property(readonly, copy, nonatomic) NSString *bundleIdentifier;
- (void)processWillExpire:(id)arg1;
@end

@interface UITextEffectsWindow : UIWindow
+ (instancetype)sharedTextEffectsWindow;
- (unsigned int)contextID;
@end

@interface UIWindow ()
+(instancetype) keyWindow;
-(id) firstResponder;
+ (void)setAllWindowsKeepContextInBackground:(BOOL)arg1;
-(void) _setRotatableViewOrientation:(UIInterfaceOrientation)orientation duration:(CGFloat)duration force:(BOOL)force;
- (void)_setRotatableViewOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 force:(BOOL)arg4;
- (void)_rotateWindowToOrientation:(int)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4;
- (unsigned int)_contextId;
-(UIInterfaceOrientation) _windowInterfaceOrientation;
@end

@interface UIApplication ()
@property (nonatomic) BOOL RA_networkActivity;
- (void)_handleKeyUIEvent:(id)arg1;
-(UIStatusBar*) statusBar;
- (id)_mainScene;
- (BOOL)_isSupportedOrientation:(int)arg1;

// SpringBoard methods
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)suspended;
-(SBApplication*) _accessibilityFrontMostApplication;
-(void)setWantsOrientationEvents:(BOOL)events;
-(void)_relaunchSpringBoardNow;

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3;

-(void) RA_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting;
-(void) RA_forceStatusBarVisibility:(BOOL)visible orRevert:(BOOL)revert;
-(void) RA_updateWindowsForSizeChange:(CGSize)size isReverting:(BOOL)revert;

- (void)applicationDidResume;
- (void)_sendWillEnterForegroundCallbacks;
- (void)suspend;
- (void)applicationWillSuspend;
- (void)_setSuspended:(BOOL)arg1;
- (void)applicationSuspend;
- (void)_deactivateForReason:(int)arg1 notify:(BOOL)arg2;
@end

@interface SBIconLabelView : UIView
@end

@interface SBIcon (iOS81)
-(BOOL) isBeta;
- (_Bool)isApplicationIcon;
@end

@interface SBIconModel (iOS81)
- (id)visibleIconIdentifiers;
- (id)applicationIconForBundleIdentifier:(id)arg1;
@end

@interface SBIconModel (iOS40)
- (/*SBApplicationIcon*/SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBIcon (iOS40)
- (void)prepareDropGlow;
- (UIImageView *)dropGlow;
- (void)showDropGlow:(BOOL)showDropGlow;
- (long long)badgeValue;
- (id)leafIdentifier;
- (SBApplication*)application;
- (NSString*)applicationBundleID;
@end

@interface SBIconController (iOS40)
- (BOOL)canUninstallIcon:(SBIcon *)icon;
@end

@protocol SBIconViewDelegate, SBIconViewLocker;
@class SBIconImageContainerView, SBIconBadgeImage;

@interface SBIconAccessoryImage : UIImage
-(id)initWithImage:(id)arg1 ;
@end

@interface SBDarkeningImageView : UIImageView
- (void)setImage:(id)arg1 brightness:(double)arg2;
- (void)setImage:(id)arg1;
@end

@interface _UILegibilityImageSet : NSObject
+ (_UILegibilityImageSet*) imageFromImage: (UIImage*) image withShadowImage: (UIImage*) imag_sh;
@property(retain) UIImage * image;
@property(retain) UIImage * shadowImage;
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

@interface SBIconView : UIView {
  SBIcon *_icon;
  id<SBIconViewDelegate> _delegate;
  id<SBIconViewLocker> _locker;
  SBIconImageContainerView *_iconImageContainer;
  SBIconImageView *_iconImageView;
  UIImageView *_iconDarkeningOverlay;
  UIImageView *_ghostlyImageView;
  UIImageView *_reflection;
  UIImageView *_shadow;
  SBIconBadgeImage *_badgeImage;
  UIImageView *_badgeView;
  SBIconLabel *_label;
  BOOL _labelHidden;
  BOOL _labelOnWallpaper;
  UIView *_closeBox;
  int _closeBoxType;
  UIImageView *_dropGlow;
  unsigned _drawsLabel : 1;
  unsigned _isHidden : 1;
  unsigned _isGrabbed : 1;
  unsigned _isOverlapping : 1;
  unsigned _refusesRecipientStatus : 1;
  unsigned _highlighted : 1;
  unsigned _launchDisabled : 1;
  unsigned _isJittering : 1;
  unsigned _allowJitter : 1;
  unsigned _touchDownInIcon : 1;
  unsigned _hideShadow : 1;
  NSTimer *_delayedUnhighlightTimer;
  unsigned _onWallpaper : 1;
  unsigned _ghostlyRequesters;
  int _iconLocation;
  float _iconImageAlpha;
  float _iconImageBrightness;
  float _iconLabelAlpha;
  float _accessoryAlpha;
  CGPoint _unjitterPoint;
  CGPoint _grabPoint;
  NSTimer *_longPressTimer;
  unsigned _ghostlyTag;
  UIImage *_ghostlyImage;
  BOOL _ghostlyPending;
  }


-(void) RA_updateIndicatorView:(NSInteger)info;
-(void) RA_updateIndicatorViewWithExistingInfo;
-(BOOL) RA_isIconIndicatorInhibited;
-(void) RA_setIsIconIndicatorInhibited:(BOOL)value;
-(void) RA_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2;

+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
+ (BOOL)allowsRecycling;
+ (id)_jitterPositionAnimation;
+ (id)_jitterTransformAnimation;
+ (struct CGSize)defaultIconImageSize;
+ (struct CGSize)defaultIconSize;

- (id)initWithDefaultSize;
- (void)dealloc;

@property(assign) id<SBIconViewDelegate> delegate;
@property(assign) id<SBIconViewLocker> locker;
@property(readonly, retain) SBIcon *icon;
- (void)setIcon:(SBIcon *)icon;

- (int)location;
- (void)setLocation:(int)location;
- (void)showIconAnimationDidStop:(id)showIconAnimation didFinish:(id)finish icon:(id)icon;
- (void)setIsHidden:(BOOL)hidden animate:(BOOL)animate;
- (BOOL)isHidden;
- (BOOL)isRevealable;
- (void)positionIconImageView;
- (void)applyIconImageTransform:(CATransform3D)transform duration:(float)duration delay:(float)delay;
- (void)setDisplayedIconImage:(id)image;
- (id)snapshotSettings;
- (id)iconImageSnapshot:(id)snapshot;
- (id)reflectedIconWithBrightness:(CGFloat)brightness;
- (void)setIconImageAlpha:(CGFloat)alpha;
- (void)setIconLabelAlpha:(CGFloat)alpha;
- (SBIconImageView *)iconImageView;
- (void)setLabelHidden:(BOOL)hidden;
- (void)positionLabel;
- (CGSize)_labelSize;
- (Class)_labelClass;
- (void)updateLabel;
- (void)_updateBadgePosition;
- (id)_overriddenBadgeTextForText:(id)text;
- (void)updateBadge;
- (id)_automationID;
- (BOOL)pointMostlyInside:(CGPoint)inside withEvent:(UIEvent *)event;
- (CGRect)frameForIconOverlay;
- (void)placeIconOverlayView;
- (void)updateIconOverlayView;
- (void)_updateIconBrightness;
- (BOOL)allowsTapWhileEditing;
- (BOOL)delaysUnhighlightWhenTapped;
- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)highlighted;
- (void)setHighlighted:(BOOL)highlighted delayUnhighlight:(BOOL)unhighlight;
- (void)_delayedUnhighlight;
- (BOOL)isInDock;
- (id)_shadowImage;
- (void)_updateShadow;
- (void)updateReflection;
- (void)setDisplaysOnWallpaper:(BOOL)wallpaper;
- (void)setLabelDisplaysOnWallpaper:(BOOL)wallpaper;
- (BOOL)showsReflection;
- (float)_reflectionImageOffset;
- (void)setFrame:(CGRect)frame;
- (void)setIsJittering:(BOOL)isJittering;
- (void)setAllowJitter:(BOOL)allowJitter;
- (BOOL)allowJitter;
- (void)removeAllIconAnimations;
- (void)setIconPosition:(CGPoint)position;
- (void)setRefusesRecipientStatus:(BOOL)status;
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (double)grabDurationForEvent:(id)event;
- (void)setIsGrabbed:(BOOL)grabbed;
- (BOOL)isGrabbed;
- (void)setIsOverlapping:(BOOL)overlapping;
- (CGAffineTransform)transformToMakeDropGlowShrinkToIconSize;
- (void)prepareDropGlow;
- (void)showDropGlow:(BOOL)glow;
- (void)removeDropGlow;
- (id)dropGlow;
- (BOOL)isShowingDropGlow;
- (void)placeGhostlyImageView;
- (id)_genGhostlyImage:(id)image;
- (void)prepareGhostlyImageIfNeeded;
- (void)prepareGhostlyImage;
- (void)prepareGhostlyImageView;
- (void)setGhostly:(BOOL)ghostly requester:(int)requester;
- (void)setPartialGhostly:(float)ghostly requester:(int)requester;
- (void)removeGhostlyImageView;
- (BOOL)isGhostly;
- (int)ghostlyRequesters;
- (void)longPressTimerFired;
- (void)cancelLongPressTimer;
- (void)touchesCancelled:(id)cancelled withEvent:(id)event;
- (void)touchesBegan:(id)began withEvent:(id)event;
- (void)touchesMoved:(id)moved withEvent:(id)event;
- (void)touchesEnded:(id)ended withEvent:(id)event;
- (BOOL)isTouchDownInIcon;
- (void)setTouchDownInIcon:(BOOL)icon;
- (void)hideCloseBoxAnimationDidStop:(id)hideCloseBoxAnimation didFinish:(id)finish closeBox:(id)box;
- (void)positionCloseBoxOfType:(int)type;
- (id)_newCloseBoxOfType:(int)type;
- (void)setShowsCloseBox:(BOOL)box;
- (void)setShowsCloseBox:(BOOL)box animated:(BOOL)animated;
- (BOOL)isShowingCloseBox;
- (void)closeBoxTapped;
- (BOOL)pointInside:(CGPoint)inside withEvent:(id)event;
- (UIEdgeInsets)snapshotEdgeInsets;
- (void)setShadowsHidden:(BOOL)hidden;
- (void)_updateShadowFrameForShadow:(id)shadow;
- (void)_updateShadowFrame;
- (BOOL)_delegatePositionIsEditable;
- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (int)_delegateCloseBoxType;
- (id)createShadowImageView;
- (void)prepareForRecycling;
- (CGRect)defaultFrameForProgressBar;
- (void)iconImageDidUpdate:(id)iconImage;
- (void)iconAccessoriesDidUpdate:(id)iconAccessories;
- (void)iconLaunchEnabledDidChange:(id)iconLaunchEnabled;
- (SBIconImageView*)_iconImageView;

@end

@interface SBIconView ()
@property (nonatomic, assign) BOOL RA_isIconIndicatorInhibited;
@end

@class NSMapTable;

@interface SBIconViewMap : NSObject {
  NSMapTable* _iconViewsForIcons;
  id<SBIconViewDelegate> _iconViewdelegate;
  NSMapTable* _recycledIconViewsByType;
  NSMapTable* _labels;
  NSMapTable* _badges;
}
+ (SBIconViewMap *)switcherMap;
+(SBIconViewMap *)homescreenMap;
+(Class)iconViewClassForIcon:(SBIcon *)icon location:(int)location;
-(id)init;
-(void)dealloc;
-(SBIconView *)mappedIconViewForIcon:(SBApplicationIcon *)icon;
-(SBIconView *)_iconViewForIcon:(SBApplicationIcon *)icon;
-(SBIconView *)iconViewForIcon:(SBApplicationIcon *)icon;
-(void)_addIconView:(SBIconView *)iconView forIcon:(SBIcon *)icon;
-(void)purgeIconFromMap:(SBIcon *)icon;
-(void)_recycleIconView:(SBIconView *)iconView;
-(void)recycleViewForIcon:(SBIcon *)icon;
-(void)recycleAndPurgeAll;
-(id)releaseIconLabelForIcon:(SBIcon *)icon;
-(void)captureIconLabel:(id)label forIcon:(SBIcon *)icon;
-(void)purgeRecycledIconViewsForClass:(Class)aClass;
-(void)_modelListAddedIcon:(SBIcon *)icon;
-(void)_modelRemovedIcon:(SBIcon *)icon;
-(void)_modelReloadedIcons;
-(void)_modelReloadedState;
-(void)iconAccessoriesDidUpdate:(SBIcon *)icon;
@end

@interface SBIconViewMap (iOS6)
@property (nonatomic, readonly) SBIconModel *iconModel;
@end

@interface SBIconController (iOS90)
@property (nonatomic,readonly) SBIconViewMap *homescreenIconViewMap;
+ (id)sharedInstance;
@end

@interface SBApplication (iOS6)
- (BOOL)isRunning;
- (id)badgeNumberOrString;
- (NSString*)bundleIdentifier;
- (_Bool)_isRecentlyUpdated;
- (_Bool)_isNewlyInstalled;
-(UIInterfaceOrientation)statusBarOrientation;
@end

@interface SBIconBlurryBackgroundView : UIView
{
    struct CGRect _wallpaperRelativeBounds;
    _Bool _isBlurring;
    id _wantsBlurEvaluator;
    struct CGPoint _wallpaperRelativeCenter;
}

@property(copy, nonatomic) id wantsBlurEvaluator; // @synthesize wantsBlurEvaluator=_wantsBlurEvaluator;
@property(readonly, nonatomic) _Bool isBlurring; // @synthesize isBlurring=_isBlurring;
@property(nonatomic) struct CGPoint wallpaperRelativeCenter; // @synthesize wallpaperRelativeCenter=_wallpaperRelativeCenter;
- (_Bool)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)setBlurring:(_Bool)arg1;
- (void)setWallpaperColor:(struct CGColor *)arg1 phase:(struct CGSize)arg2;
- (_Bool)wantsBlur:(id)arg1;
- (struct CGRect)wallpaperRelativeBounds;
- (void)didAddSubview:(id)arg1;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
@end

@interface SBFolderIconBackgroundView : SBIconBlurryBackgroundView
- (id)initWithDefaultSize;
@end

@interface BBBulletin
@property(copy, nonatomic) NSString *bulletinID; // @synthesize bulletinID=_bulletinID;
@property(copy, nonatomic) NSString *sectionID; // @synthesize sectionID=_sectionID;
@property(copy, nonatomic) NSString *section;
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) NSString *subtitle;
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) NSDate *date;
@end

@interface BBServer
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3;
- (id)_allBulletinsForSectionID:(id)arg1;

- (id)allBulletinIDsForSectionID:(id)arg1;
- (id)noticesBulletinIDsForSectionID:(id)arg1;
- (id)bulletinIDsForSectionID:(id)arg1 inFeed:(unsigned long long)arg2;
@end

@interface FBSystemService : NSObject
- (id)sharedInstance;
- (void)exitAndRelaunch:(bool)arg1;
@end

@interface SBSwitcherSnapshotImageView : UIView
@property (nonatomic,readonly) UIImage * image;
- (UIImage *)image;
@end

@interface _SBAppSwitcherSnapshotContext : NSObject {
  SBSwitcherSnapshotImageView* _snapshotImageView;
}
@property (nonatomic,retain) SBSwitcherSnapshotImageView * snapshotImageView;              //@synthesize snapshotImageView=_snapshotImageView - In the implementation block
- (SBSwitcherSnapshotImageView *)snapshotImageView;
- (void)setSnapshotImageView:(SBSwitcherSnapshotImageView *)arg1 ;
- (CGRect)snapshotReferenceFrame;
- (void)setSnapshotReferenceFrame:(CGRect)arg1 ;
@end

@interface SBMainSwitcherViewController : UIViewController
+ (id)sharedInstance;
- (BOOL)dismissSwitcherNoninteractively;
- (BOOL)isVisible;
- (BOOL)activateSwitcherNoninteractively;
- (void)RA_dismissSwitcherUnanimated;
@end

@interface SBSwitcherContainerView : UIView
@property (nonatomic,retain) UIView * contentView;
- (void)layoutSubviews;
- (UIView *)contentView;
@end

@interface SBUIChevronView : UIView
@property (assign,nonatomic) long long state;
@property (nonatomic,retain) UIColor * color;
-(id)initWithFrame:(CGRect)arg1;
-(id)initWithColor:(id)arg1 ;
-(void)setColor:(UIColor *)arg1 ;
-(void)setState:(long long)arg1 animated:(BOOL)arg2;
-(void)setBackgroundView:(id)arg1;
@end

@interface SBPagedScrollView : UIScrollView
- (NSArray *)pageViews;
- (void)setPageViews:(NSArray *)arg1;
@end
