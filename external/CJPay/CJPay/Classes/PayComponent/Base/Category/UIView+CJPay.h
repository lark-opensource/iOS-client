//
//  UIView+CJPay.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CJPay)

- (void)cj_removeAllSubViews;

- (UIImage *)cjpay_snapShotImage;

//- (UIImage *)cjpay_newSnapShotImage;

/**
 添加顶部的圆角
 
 @param radius 圆角大小
 */
- (void)cj_clipTopCorner:(CGFloat) radius;

/**
 添加左上的圆角
 
 @param radius 圆角大小
 */
- (void)cj_clipTopLeftCorner:(CGFloat)radius;


/**
 添加底部的圆角
 
 @param radius 圆角大小
 */
- (void)cj_clipBottomCorner:(CGFloat)radius;

/**
 添加上面和下面的圆角，支持不同圆角半径
 
 @param topRadius top corner 圆角大小
 @param bottomRadius bottom corner 圆角大小
 */
- (void)cj_clipTopCorner:(CGFloat)topRadius bottomCorner:(CGFloat)bottomRadius;
- (void)cj_customCorners:(UIRectCorner)corners radius:(CGFloat)radius;

/**
 设置描边
 
 @param color 描边颜色
 @param borderWidth 描边宽度
 */
- (void)cj_showBorder:(UIColor *)color borderWidth:(CGFloat)borderWidth;

/**
 设置圆角
 
 @param radius 圆角的半径
 */
- (void)cj_showCornerRadius:(CGFloat)radius;

/**
 添加渐变
 
 @param startColor 起始颜色
 @param endColor   结束颜色
 @param startPoint 起始位置
 @param endPoint   结束位置
 */
- (void)cj_applyGradientWithStartColor:(UIColor *)startColor
                              endColor:(UIColor *)endColor
                            startPoint:(CGPoint)startPoint
                            startPoint:(CGPoint)endPoint;

/**
 添加阴影
 
 @param color 阴影颜色
 @param alpha 透明度
 @param x 偏移x
 @param y 偏移y
 @param blur blur
 @param spread 扩散
 */
- (void)cj_applySketchShadow:(UIColor *)color alpha:(CGFloat)alpha x:(CGFloat)x y:(CGFloat)y blur:(CGFloat)blur spread:(CGFloat)spread;


/**
 绘制底色
 
 @param rect 绘制区域
 @param rectCorner 圆角区域
 @param radius 圆角size
 @param fillColor 填充颜色
 @param strokeColor 边框颜色
 */
- (void)cj_innerRect:(CGRect)rect
          rectCorner:(UIRectCorner)rectCorner
        cornerRadius:(CGSize)radius
           fillColor:(UIColor *)fillColor
         strokeColor:(UIColor *)strokeColor;

- (void)cj_innerRect:(CGRect)rect
           fillColor:(UIColor *)fillColor
         strokeColor:(UIColor *)strokeColor;

/**
 将View的宽度修改为屏幕宽度
 */
- (void)cj_setViewWidthEqualToScreen;

- (CALayer *)cj_getShadowLayer:(UIColor *)color
                         alpha:(CGFloat)alpha
                             x:(CGFloat)x
                             y:(CGFloat)y
                          blur:(CGFloat)blur
                        spread:(CGFloat)spread
                  cornerRadius:(CGFloat)cornerRadius;

- (UIView *)findViewThatIsFirstResponder;

- (BOOL)isDisplayedInScreen;

- (UIView *)cj_copy;

- (UIViewController *)cj_responseViewController;

/**
 给View的添加UIControl的addTarget:action:能力
 */
- (void)cj_viewAddTarget:(nullable id)target action:(SEL _Nonnull)action forControlEvents:(UIControlEvents)controlEvents;

- (void)cj_viewAddShakeAnimation:(CGFloat)amplitude withTimes:(CGFloat)times;

- (BOOL)isShowMask;

- (void)cj_setUserInteractionEnabled:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
