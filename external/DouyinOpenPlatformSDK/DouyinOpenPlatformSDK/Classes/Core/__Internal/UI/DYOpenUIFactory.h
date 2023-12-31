//
//  DYOpenUIFactory.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenUIFactory : NSObject

/// 给 UIView 添加圆角
+ (void)applyRoundCornerForView:(UIView *)view radius:(CGFloat)radius byRoundingCorners:(UIRectCorner)corners;

/// 给 CALayer 添加圆角
+ (void)applyRoundCornerForLayer:(CALayer *)layer radius:(CGFloat)radius byRoundingCorners:(UIRectCorner)corners;

@end

NS_ASSUME_NONNULL_END
