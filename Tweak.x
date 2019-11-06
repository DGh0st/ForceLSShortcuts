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

@interface UIScreen (ForceLSShortcutsPrivate) // iOS 4 - 12
@property (nonatomic, readonly) CGRect _referenceBounds; // iOS 9 - 12
@end

@interface UICoverSheetButton : UIView // iOS 11 - 12
@end

@interface SBDashBoardQuickActionsButton : UICoverSheetButton // iOS 11 - 12
-(void)setEdgeInsets:(UIEdgeInsets)arg1; // iOS 11 - 12
@end

@interface SBDashBoardQuickActionsView : UIView // iOS 11 - 12
@property (nonatomic, retain) SBDashBoardQuickActionsButton *flashlightButton; // iOS 11 - 12
@property (nonatomic, retain) SBDashBoardQuickActionsButton *cameraButton; // iOS 11 - 12
-(UIEdgeInsets)_buttonOutsets; // iOS 11 - 12
@end

@interface SBPagedScrollView : UIScrollView // iOS 10 - 12
-(void)setBouncesHorizontally:(BOOL)arg1; // inherited from UIScrollView
@end

@interface SBDashBoardView : UIView // 10 - 12
@property (nonatomic, retain) SBPagedScrollView *scrollView; // iOS 10 - 12
@end

@interface SBDashBoardFixedFooterView : UIView // iOS 11 - 12
-(void)_layoutPageControl; // iOS 11 - 12
@end

@interface SBDashBoardFixedFooterViewController : UIViewController // iOS 11 - 12
@property (nonatomic, readonly) SBDashBoardFixedFooterView *fixedFooterView; // iOS 11 - 12
@end

@interface SBDashBoardViewController : UIViewController { // iOS 10 - 12
	SBDashBoardFixedFooterViewController *_fixedFooterViewController; // iOS 11 - 12
}
@property (nonatomic, readonly) SBDashBoardView *dashBoardView; // iOS 11 - 12
@property (setter=_setAllowedPageViewControllers:, getter=_allowedPageViewControllers, nonatomic, copy) NSArray *allowedPageViewControllers; // iOS 10 - 12
-(void)_updatePageContent; // iOS 10 - 12
@end

@interface SBCoverSheetPresentationManager : NSObject // iOS 11 - 12
+(id)sharedInstance; // iOS 11 - 12
-(id)dashBoardViewController; // iOS 11 - 12
@end

@interface SBDashBoardPageControl : UIPageControl // iOS 10 - 12
@property (assign, nonatomic) NSUInteger cameraPageIndex; // iOS 11 - 12
@end

%hook SBDashBoardQuickActionsViewController
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

%hook SBDashBoardQuickActionsView
-(void)_layoutQuickActionButtons {
	UIEdgeInsets insets = [self _buttonOutsets];
	[self.flashlightButton setEdgeInsets:insets];
	[self.cameraButton setEdgeInsets:insets];

	UIUserInterfaceLayoutDirection layoutDirection = [UIApplication sharedApplication].userInterfaceLayoutDirection;
	CGRect _referenceBounds = [UIScreen mainScreen]._referenceBounds;
	CGFloat buttonSize = GetButtonSize(_referenceBounds);
	CGFloat xOffsetPadding = layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft ? insets.right : insets.left;
	CGFloat buttonWidth = buttonSize + insets.right + insets.left;
	CGFloat buttonHeight = buttonSize + insets.top + insets.bottom;
	CGFloat offsetY = _referenceBounds.size.height - buttonHeight - insets.bottom;

	CGRect flashLightRect;
	CGRect cameraRect;
	if (layoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
		flashLightRect = CGRectMake(_referenceBounds.size.width - xOffsetPadding - buttonWidth, offsetY, buttonWidth, buttonHeight);
		cameraRect = CGRectMake(xOffsetPadding, offsetY, buttonWidth, buttonHeight);
	} else {
		flashLightRect = CGRectMake(xOffsetPadding, offsetY, buttonWidth, buttonHeight);
		cameraRect = CGRectMake(_referenceBounds.size.width - xOffsetPadding - buttonHeight, offsetY, buttonWidth, buttonHeight);
	}
	self.flashlightButton.frame = flashLightRect;
	self.cameraButton.frame = cameraRect;
}
%end

%hook SBDashBoardViewController
-(void)_updatePageContent {
	%orig();

	if (horizontalBounce == Disable) {
		[self.dashBoardView.scrollView setBouncesHorizontally:NO];
	} else if (horizontalBounce == AutomaticHide && self.allowedPageViewControllers.count <= 2) {
		for (id pageViewController in self.allowedPageViewControllers) {
			if ([pageViewController isKindOfClass:%c(SBDashBoardCameraPageViewController)]) {
				[self.dashBoardView.scrollView setBouncesHorizontally:NO];
				break;
			}
		}
	} else if (horizontalBounce == Enable) {
		[self.dashBoardView.scrollView setBouncesHorizontally:YES];		
	}
}
%end

%hook SBDashBoardPageControl
-(CGSize)sizeForNumberOfPages:(NSInteger)arg1 {
	if ((pageControlVisibility == AutomaticHide && self.cameraPageIndex != NSIntegerMax && arg1 == 2) || pageControlVisibility == Hidden)
		self.hidden = YES;
	else if (pageControlVisibility == Visible)
		self.hidden = NO;
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
		SBDashBoardViewController *dashBoardViewController = [[%c(SBCoverSheetPresentationManager) sharedInstance] dashBoardViewController];
		if (horizontalBounce != previousHorizontalBounce)
			[dashBoardViewController _updatePageContent];

		if (pageControlVisibility != previousPageControlVisibility)
			[((SBDashBoardFixedFooterViewController *)[dashBoardViewController valueForKey:@"_fixedFooterViewController"]).fixedFooterView _layoutPageControl];
	}

	[prefs release];
}

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
}

%ctor {
	reloadPrefs();

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}