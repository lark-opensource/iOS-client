//
//  UIView+BDPAppearance.h
//  Timor
//
//  Created by liuxiangxin on 2019/4/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BDPAppearance)

/// 四个角中的部分角的圆角值
///
/// 跟bdp_cornerRadius, bdp_cornerRadiusRatio以及self.layer.corner属性冲突。
/// 设置了前面的三个属性会导致该属性值失效
@property (nonatomic, assign) UIRectCorner bdp_rectCorners UI_APPEARANCE_SELECTOR;
/// 配合bdp_rectCorners使用的圆角值
@property (nonatomic, assign) CGSize bdp_cornerRadii;
/// 圆角值
@property (nonatomic, assign) CGFloat bdp_cornerRadius UI_APPEARANCE_SELECTOR;
/// 圆角率。 定义为 cornerRadius / 短边边长
@property (nonatomic, assign) CGFloat bdp_cornerRadiusRatio UI_APPEARANCE_SELECTOR;

- (void)bdp_updateCornerRadius;
- (void)bdp_updateRectCorners;

@end

NS_ASSUME_NONNULL_END
