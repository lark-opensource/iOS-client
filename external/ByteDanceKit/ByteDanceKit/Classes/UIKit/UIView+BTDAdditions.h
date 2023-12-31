//
//  UIView+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BTDAdditions)

/*
 坐标相关
 */
@property (nonatomic, assign) CGFloat btd_x;
@property (nonatomic, assign) CGFloat btd_y;
@property (nonatomic, assign) CGFloat btd_centerX;
@property (nonatomic, assign) CGFloat btd_centerY;
@property (nonatomic, assign) CGFloat btd_width;
@property (nonatomic, assign) CGFloat btd_height;
/**
 截图操作

 @return 根据当前view生成一个UIImage
 */
- (nullable UIImage *)btd_snapshotImage;

/**
 设置view的layer的 shadow

 @param color shadow 的颜色
 @param offset shadow 的 offset
 @param radius shadow 的圆角
 */
- (void)btd_setLayerShadow:(nonnull UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

/**
 移出所有子控件
 */
- (void)btd_removeAllSubviews;

/**
 查找当前view所在的控制器

 @return 当前view所在的控制器
 */
- (nullable UIViewController *)btd_viewController;

@property (nonatomic, assign) CGFloat btd_left;

@property (nonatomic, assign) CGFloat btd_right;

@property (nonatomic, assign) CGFloat btd_top;

@property (nonatomic, assign) CGFloat btd_bottom;

/**
 * Return the x coordinate on the screen.
 */
@property (nonatomic, assign, readonly) CGFloat btd_screenX;

/**
 * Return the y coordinate on the screen.
 */
@property (nonatomic, assign, readonly) CGFloat btd_screenY;

/**
 *  safeAreaInsets osVersion safe
 */
@property (nonatomic, assign, readonly) UIEdgeInsets btd_safeAreaInsets;

@property(nonatomic, assign) UIEdgeInsets btd_hitTestEdgeInsets;

- (void)btd_eachSubview:(void (^)(UIView *subview))block;

@end

NS_ASSUME_NONNULL_END
