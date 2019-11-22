#define kIdentifier @"com.dgh0st.forcelsshortcuts"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.forcelsshortcuts.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.forcelsshortcuts/settingschanged"

typedef enum BounceStrategy : NSInteger {
	Disable = 0,
	AutomaticBounce,
	Enable
} BounceStrategy;

typedef enum Visibility : NSInteger {
	Hidden = 0,
	AutomaticHide,
	Visible
} Visibility;

static BounceStrategy horizontalBounce = AutomaticBounce;
static Visibility pageControlVisibility = AutomaticHide;

@interface UICoverSheetButton : UIView // iOS 11 - 13
-(void)setEdgeInsets:(UIEdgeInsets)arg1; // iOS 11 - 13
@end

@interface QuickActionsButton : UICoverSheetButton // iOS 11 - 12 (SBDashBoardQuickActionsButton), iOS 13 (CSQuickActionsButton)
@end

@interface QuickActionView : UIView // iOS 11 - 12 (SBDashBoardQuickActionsView), iOS 13 (CSQuickActionsView)
@property (nonatomic, retain) QuickActionsButton *flashlightButton; // iOS 11 - 13
@property (nonatomic, retain) QuickActionsButton *cameraButton; // iOS 11 - 13
-(UIEdgeInsets)_buttonOutsets; // iOS 11 - 13
@end

@interface PagedScrollView : UIScrollView // iOS 10 - 12 (SBPagedScrollView), iOS 13 (SBFPagedScrollView)
-(void)setBouncesHorizontally:(BOOL)arg1; // inherited from UIScrollView
@end

@interface CSView : UIView // 10 - 12 (SBDashBoardView), iOS 13 (CSCoverSheetView)
@property (nonatomic, retain) PagedScrollView *scrollView; // iOS 10 - 13
@end

@interface FixedFooterView : UIView // iOS 11 - 12 (SBDashBoardFixedFooterView), iOS 13 (CSFixedFooterView)
-(void)_layoutPageControl; // iOS 11 - 13
@end

@interface FixedFooterViewController : UIViewController // iOS 11 - 12 (SBDashBoardFixedFooterViewController), iOS 13 (CSFixedFooterViewController)
@property (nonatomic, readonly) FixedFooterView *fixedFooterView; // iOS 11 - 13
@end

@interface CSViewController : UIViewController { // iOS 10 - 12 (SBDashBoardViewController), iOS 13 (CSCoverSheetViewController)
	FixedFooterViewController *_fixedFooterViewController; // iOS 11 - 13
}
@property (nonatomic, readonly) CSView *dashBoardView; // iOS 11 - 12
@property (nonatomic, readonly) CSView *coverSheetView; // iOS 13
@property (setter=_setAllowedPageViewControllers:, getter=_allowedPageViewControllers, nonatomic, copy) NSArray *allowedPageViewControllers; // iOS 10 - 13
-(void)_updatePageContent; // iOS 10 - 13
@end

@interface PageControl : UIPageControl // iOS 10 - 12 (SBDashBoardPageControl), iOS 13 (CSPageControl)
@property (assign, nonatomic) NSUInteger cameraPageIndex; // iOS 11 - 12
@end

@interface SBCoverSheetPresentationManager : NSObject // iOS 11 - 13
+(id)sharedInstance; // iOS 11 - 13
-(id)dashBoardViewController; // iOS 11 - 12
-(id)coverSheetViewController; // iOS 13
@end

%hook QuickActionsViewController
+(BOOL)deviceSupportsButtons {
	return YES;
}
%end

static inline CGFloat GetButtonSize(CGRect screenBounds) {
	if (screenBounds.size.height >= 812)
		return 58;
	if (screenBounds.size.height >= 736)
		return 50;
	return 42;
}

%hook QuickActionView
-(void)_layoutQuickActionButtons {
	UIEdgeInsets insets = [self _buttonOutsets];
	[[self flashlightButton] setEdgeInsets:insets];
	[[self cameraButton] setEdgeInsets:insets];

	UIUserInterfaceLayoutDirection layoutDirection = [UIApplication sharedApplication].userInterfaceLayoutDirection;
	CGRect screenBounds = [UIScreen mainScreen].bounds;
	CGFloat buttonSize = GetButtonSize(screenBounds);
	CGFloat xOffsetPadding = layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft ? insets.right : insets.left;
	CGFloat buttonWidth = buttonSize + insets.right + insets.left;
	CGFloat buttonHeight = buttonSize + insets.top + insets.bottom;
	CGFloat offsetY = screenBounds.size.height - buttonHeight - insets.bottom;

	CGRect flashLightRect;
	CGRect cameraRect;
	if (layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
		flashLightRect = CGRectMake(screenBounds.size.width - xOffsetPadding - buttonWidth, offsetY, buttonWidth, buttonHeight);
		cameraRect = CGRectMake(xOffsetPadding, offsetY, buttonWidth, buttonHeight);
	} else {
		flashLightRect = CGRectMake(xOffsetPadding, offsetY, buttonWidth, buttonHeight);
		cameraRect = CGRectMake(screenBounds.size.width - xOffsetPadding - buttonHeight, offsetY, buttonWidth, buttonHeight);
	}
	[self flashlightButton].frame = flashLightRect;
	[self cameraButton].frame = cameraRect;
}
%end

%hook CSViewController
-(void)_updatePageContent {
	%orig();

	CSView *view = [self respondsToSelector:@selector(dashBoardView)] ? [self dashBoardView] : [self coverSheetView];
	if (horizontalBounce == Disable) {
		[view.scrollView setBouncesHorizontally:NO];
	} else if (horizontalBounce == AutomaticHide && [self _allowedPageViewControllers].count <= 2) {
		for (id pageViewController in [self _allowedPageViewControllers]) {
			if ([pageViewController isKindOfClass:%c(SBDashBoardCameraPageViewController)]) {
				[view.scrollView setBouncesHorizontally:NO];
				break;
			}
		}
	} else if (horizontalBounce == Enable) {
		[view.scrollView setBouncesHorizontally:YES];
	}
}
%end

%hook PageControl
-(CGSize)sizeForNumberOfPages:(NSInteger)arg1 {
	if ((pageControlVisibility == AutomaticHide && [self cameraPageIndex] != NSIntegerMax && arg1 == 2) || pageControlVisibility == Hidden)
		[self setHidden:YES];
	else if (pageControlVisibility == Visible)
		[self setHidden:NO];
	return %orig();
}
%end

// %hook SBDashBoardCameraPageViewController
// +(BOOL)isAvailableForConfiguration {
// 	return NO; // remove camera page which would require passcode to use from shortcut
// }
// %end


static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (prefs == nil)
				prefs = [NSDictionary new];
			CFRelease(keyList);
		}
	} else {
		prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	}

	BounceStrategy previousHorizontalBounce = horizontalBounce;
	Visibility previousPageControlVisibility = pageControlVisibility;

	horizontalBounce = [prefs objectForKey:@"horizontalBounce"] ? (BounceStrategy)[[prefs objectForKey:@"horizontalBounce"] intValue] : AutomaticBounce;
	pageControlVisibility = [prefs objectForKey:@"pageControlVisibility"] ? (Visibility)[[prefs objectForKey:@"pageControlVisibility"] intValue] : AutomaticHide;

	static BOOL ignoreForceUpdate = true; // ignore force update on respring
	if (!ignoreForceUpdate) {
		ignoreForceUpdate = false;
		// force update if needed
		SBCoverSheetPresentationManager *csPresentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
		QuickActionsViewController *quickActionViewController = [csPresentationManager respondsToSelector:@selector(dashBoardViewController)] ? [csPresentationManager dashBoardViewController] : [csPresentationManager coverSheetViewController];
		if (horizontalBounce != previousHorizontalBounce)
			[quickActionViewController _updatePageContent];

		if (pageControlVisibility != previousPageControlVisibility)
			[[[quickActionViewController valueForKey:@"_fixedFooterViewController"] fixedFooterView] _layoutPageControl];
	}

	[prefs release];
}

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
}

%ctor {
	reloadPrefs();

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	Class quickActionsViewControllerClass = %c(SBDashBoardQuickActionsViewController) ?: %c(CSQuickActionsViewController);
	Class quickActionViewClass = %c(SBDashBoardQuickActionsView) ?: %c(CSQuickActionsView);
	Class csViewControllerClass = %c(SBDashBoardViewController) ?: %c(CSCoverSheetViewController);
	Class pageControlClass = %c(SBDashBoardPageControl) ?: %c(CSPageControl);
	%init(QuickActionsViewController=quickActionsViewControllerClass, QuickActionView=quickActionViewClass, CSViewController=csViewControllerClass, PageControl=pageControlClass);
}