//
//  BDPAppearanceConfiguration+Private.m
//  Timor
//
//  Created by liuxiangxin on 2019/4/29.
//

#import "BDPAppearanceConfiguration+Private.h"
#import "BDPCheckbox.h"
#import "BDPView.h"
#import "BDPImageView.h"
#import "BDPButton.h"
#import "BDPSwitch.h"
#import "BDPStyleCategoryDefine.h"

#import "UIView+BDPExtension.h"
#import "UIView+BDPAppearance.h"
#import "UIColor+BDPExtension.h"

static const BDPNegativeColor kDefaultNegativeTextColor = BDPNegativeColorBlack2;
static const BDPNegativeColor kDefaultSwitchNegativeColor = BDPNegativeColorWhite1;

@implementation BDPAppearanceConfiguration (Private)

- (void)bdp_applyLogoAppearance
{
    
    BDPView *view = [BDPView bdp_styleForCategory:BDPStyleCategoryLogo];
    view.bdp_cornerRadiusRatio = self.appLogoCornerRadiusRatio;
    view.clipsToBounds = YES;

    BDPImageView *logoImageView = [BDPImageView bdp_styleForCategory:BDPStyleCategoryLogo];
    logoImageView.bdp_cornerRadiusRatio = self.appLogoCornerRadiusRatio;
    logoImageView.clipsToBounds = YES;
}

- (void)bdp_applyPositiveColor
{
    BDPButton *buttonAppearance = [BDPButton bdp_styleForCategory:BDPStyleCategoryPositive];
    BDPSwitch *switchAppearance = [BDPSwitch bdp_styleForCategory:BDPStyleCategoryPositive];
    BDPCheckBox *checkbox = [BDPCheckBox bdp_styleForCategory:BDPStyleCategoryPositive];
    
    UIColor *positiveItemTextColor = [UIColor bdp_negativeColor:self.positiveItemTextColor];
    [buttonAppearance setBackgroundColor:self.positiveColor];
    [buttonAppearance setTitleColor:positiveItemTextColor forState:UIControlStateNormal];
    [switchAppearance setOnTintColor:self.positiveColor];
    [checkbox setTintColor:self.positiveColor forStatus:BDPCheckBoxStatusSelected];
}

- (void)bdp_applyNegativeColor
{
    BDPSwitch *switchAppearance = [BDPSwitch bdp_styleForCategory:BDPStyleCategoryNegative];
    UIColor *negativeColor = [UIColor bdp_negativeColor:kDefaultSwitchNegativeColor];
    [switchAppearance setTintColor:negativeColor];
    
    BDPButton *buttonAppearance = [BDPButton bdp_styleForCategory:BDPStyleCategoryNegative];
    [buttonAppearance setBackgroundColor:[UIColor bdp_BlackColor8]];
    [buttonAppearance setTitleColor:UIColor.bdp_BlackColor1 forState:UIControlStateNormal];
}

- (void)bdp_applyButtonCornerRadius
{
    BDPButton *button = [BDPButton bdp_styleForCategory:BDPStyleCategoryButton];
    
    [button setBdp_cornerRadius:self.btnCornerRadius];
}

- (void)bdp_applyAvatarTheme
{
    BDPView *view = [BDPView bdp_styleForCategory:BDPStyleCategoryAvatar];
    view.bdp_cornerRadiusRatio = self.avatorAppLogoCornerRadiusRatio;
    view.clipsToBounds = YES;
    
    BDPImageView *imageView = [BDPImageView bdp_styleForCategory:BDPStyleCategoryAvatar];
    imageView.bdp_cornerRadiusRatio = self.avatorAppLogoCornerRadiusRatio;
    imageView.clipsToBounds = YES;
}

- (void)bdp_applyMorePanel
{
    // set portraint more panel corner radius
    BDPView *portraitPanel = [BDPView bdp_styleForCategory:BDPStyleCategoryMorePanelPortrait];
    portraitPanel.bdp_cornerRadii = CGSizeMake(self.morePanelPortraitCornerRadius, self.morePanelPortraitCornerRadius);
    portraitPanel.bdp_rectCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
    
    //set landscape more panel corner radius
    BDPView *landscapePanel = [BDPView bdp_styleForCategory:BDPStyleCategoryMorePanelLandscape];
    landscapePanel.bdp_cornerRadii = CGSizeMake(self.morePanelLandscapeCornerRadius, self.morePanelLandscapeCornerRadius);
    landscapePanel.bdp_rectCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
    
    // set item corner radius
    BDPView *imageBox = [BDPView bdp_styleForCategory:BDPStyleCategoryMorePanelItem];
    imageBox.clipsToBounds = YES;
    imageBox.bdp_cornerRadiusRatio = self.morePanelItemCornerRadiusRatio;
}

- (void)bdp_applyTabBarRedDot
{
    BDPView *tabBarRedDotView = [BDPView bdp_styleForCategory:BDPStyleCategoryTabBarRedDot];
    tabBarRedDotView.backgroundColor = self.tabBarRedDotColor;
}

- (void)bdp_apply
{
    [self bdp_applyPositiveColor];
    [self bdp_applyNegativeColor];
    [self bdp_applyLogoAppearance];
    [self bdp_applyButtonCornerRadius];
    [self bdp_applyAvatarTheme];
    [self bdp_applyMorePanel];
    [self bdp_applyTabBarRedDot];
}

@end
