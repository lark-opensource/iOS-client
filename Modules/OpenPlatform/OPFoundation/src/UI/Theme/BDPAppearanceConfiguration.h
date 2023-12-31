//
//  BDPAppearanceConfiguration.h
//  Timor
//
//  Created by liuxiangxin on 2019/4/29.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDPNegativeColor.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN const CGFloat BDPAppearanceRadiusRatioMin;
FOUNDATION_EXTERN const CGFloat BDPAppearanceRadiusRatioMax;

@interface BDPAppearanceConfiguration : NSObject

/// 主要操作色
@property (nonatomic, strong) UIColor *positiveColor;
/// 主要文字色
@property (nonatomic, strong) UIColor *positiveTextColor;
/// 主要操作色上的文字色
@property (nonatomic, assign) BDPNegativeColor positiveItemTextColor;
/// 按钮圆角
@property (nonatomic, assign) CGFloat btnCornerRadius;
/// 应用Logo圆角率, 返回 0 ~ 0.5
@property (nonatomic, assign) CGFloat appLogoCornerRadiusRatio;
/// 用户头像圆角率, 返回 0 ~ 0.5
@property (nonatomic, assign) CGFloat avatorAppLogoCornerRadiusRatio;
/// 竖屏更多面板左上角和右上角的圆角值
@property (nonatomic, assign) CGFloat morePanelPortraitCornerRadius;
/// 横屏更多面板左上角和右上角的圆角值
@property (nonatomic, assign) CGFloat morePanelLandscapeCornerRadius;
/// 更多面板按钮圆角率。 取值范围 [0, 0.5]
@property (nonatomic, assign) CGFloat morePanelItemCornerRadiusRatio;
/// tabBar红点颜色
@property (nonatomic, strong) UIColor *tabBarRedDotColor;
/// loadingView 淡出动画时长
@property (nonatomic, assign) NSTimeInterval loadingViewDismissAnimationDuration;
//启动时出现错误则自动退出小程序
@property (nonatomic, assign) BOOL hideAppWhenLaunchError;

+ (instancetype)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
