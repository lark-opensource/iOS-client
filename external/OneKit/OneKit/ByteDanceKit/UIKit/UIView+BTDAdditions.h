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
 Properties about the coordinate.
 */
@property (nonatomic, assign) CGFloat btd_x;
@property (nonatomic, assign) CGFloat btd_y;
@property (nonatomic, assign) CGFloat btd_centerX;
@property (nonatomic, assign) CGFloat btd_centerY;
@property (nonatomic, assign) CGFloat btd_width;
@property (nonatomic, assign) CGFloat btd_height;
/**
 Capture a snapshot, some layer doesn't support(EX CAEAGLLayer).

 @return The snapshot image of the current view.
 */
- (nullable UIImage *)btd_snapshotImage;

/**
 Capture a snapshot, support all layer.

 @return The snapshot image of the current view.
 */
- (nullable UIImage *)btd_screenshotImage;

/**
 Capture a snapshot, support CAEAGLLayer snapshot.
 @param size snapshot image size
 @param imageScale snapshot image scale
 @return The snapshot image of the current view.
 */
- (nullable UIImage *)btd_screenshotImageWithSize:(CGSize)size imageScale:(CGFloat)imageScale;

/**
 Set the layer's shadow.

 @param color The shadow's color.
 @param offset The shadow's offset.
 @param radius The shadow's radius.
 */
- (void)btd_setLayerShadow:(nonnull UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

/**
 Remove all subviews.
 */
- (void)btd_removeAllSubviews;

/**
 Return the UIViewController of the view.

 @return A UIViewController.
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
