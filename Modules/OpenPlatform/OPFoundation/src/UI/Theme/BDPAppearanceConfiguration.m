//
//  BDPAppearanceConfiguration.m
//  Timor
//
//  Created by liuxiangxin on 2019/4/29.
//

#import "BDPAppearanceConfiguration.h"
#import "UIColor+BDPExtension.h"
#import "UIView+BDPExtension.h"

static NSString *const kDefaultPositiveColor = @"#F85959";
static NSString *const kDefaultPositiveTextColor = kDefaultPositiveColor;
static const CGFloat kDefaultLogoCornerRadiusRatio = .2f;
static const CGFloat kDefaultButtonCornerRadius = 4.f;
static const CGFloat kDefaultMorePanelCornerRadiusPortrait = 4.f;
static const CGFloat kDefaultMorePanelCornerRadiusLandscape = 10.f;
static const CGFloat kDefaultMorePanelItemCornerRadiusRatio = 8.f / 48.f;
static const NSTimeInterval kDefaultLoadingViewDismissAnimationDuration = 0.35f;

const CGFloat BDPAppearanceRadiusRatioMin = 0.f;
const CGFloat BDPAppearanceRadiusRatioMax = .5f;


#define CORNER_RADIUS_VALID(RATIO) \
({ \
    CGFloat newValue = MAX(BDPAppearanceRadiusRatioMin, RATIO); \
    newValue = MIN(BDPAppearanceRadiusRatioMax, RATIO); \
    newValue; \
})

@implementation BDPAppearanceConfiguration

+ (instancetype)defaultConfiguration
{
    return [self new];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _positiveColor = [UIColor colorWithHexString:kDefaultPositiveColor];
        _positiveTextColor = [UIColor colorWithHexString:kDefaultPositiveTextColor];
        _positiveItemTextColor = BDPNegativeColorWhite1;
        _appLogoCornerRadiusRatio = kDefaultLogoCornerRadiusRatio;
        _btnCornerRadius = kDefaultButtonCornerRadius;
        _avatorAppLogoCornerRadiusRatio = BDPCornerRadiusRatioAlwaysCircle;
        _morePanelItemCornerRadiusRatio = kDefaultMorePanelItemCornerRadiusRatio;
        _morePanelPortraitCornerRadius = kDefaultMorePanelCornerRadiusPortrait;
        _morePanelLandscapeCornerRadius = kDefaultMorePanelCornerRadiusLandscape;
        _tabBarRedDotColor = [UIColor colorWithHexString:@"#f85959"];
        _loadingViewDismissAnimationDuration = kDefaultLoadingViewDismissAnimationDuration;
        _hideAppWhenLaunchError = NO;
    }
    return self;
}

- (void)setAppLogoCornerRadiusRatio:(CGFloat)appLogoCornerRadiusRatio
{
    _appLogoCornerRadiusRatio = CORNER_RADIUS_VALID(appLogoCornerRadiusRatio);
}

- (UIColor *)positiveColor
{
    if (!_positiveColor) {
        _positiveColor = [UIColor colorWithHexString:kDefaultPositiveColor];
    }
    
    return _positiveColor;
}

- (UIColor *)positiveTextColor
{
    if (!_positiveTextColor) {
        _positiveTextColor = [UIColor colorWithHexString:kDefaultPositiveTextColor];
    }
    
    return _positiveTextColor;
}

@end
