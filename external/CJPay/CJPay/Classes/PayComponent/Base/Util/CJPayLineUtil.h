//
//  CJPayLineUtil.h
//  CJPay
//
//  Created by wangxiaohong on 2019/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CJPayLine) {
    CJPayLineLeft     = 1 << 0,
    CJPayLineRight    = 1 << 1,
    CJPayLineTop      = 1 << 2,
    CJPayLineBottom   = 1 << 3,
    CJPayLineAllLines = ~0UL
};

@interface CJPayLineUtil : NSObject

+ (UIView *)addTopLineToView:(UIView *)toView
                  marginLeft:(CGFloat)marginLeft
                 marginRight:(CGFloat)marginRight
                   marginTop:(CGFloat)marginTop;

+ (UIView *)addTopLineToView:(UIView *)toView
                  marginLeft:(CGFloat)marginLeft
                 marginRight:(CGFloat)marginRight
                   marginTop:(CGFloat)marginTop
                       color:(UIColor *)color;

+ (UIView *)addBottomLineToView:(UIView *)toView
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom;

+ (UIView *)addBottomLineToView:(UIView *)toView
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom
                          color:(UIColor *)color;

+ (UIView *)addBottomLineToView:(UIView *)toView
                     lineHeight:(CGFloat)lineHeight
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom
                          color:(UIColor *)color;

+ (UIView *)addRightLineToView:(UIView *)toView
                     marginTop:(CGFloat)marginTop
                  marginBottom:(CGFloat)marginBottom
                   marginRight:(CGFloat)marginRight;

+ (UIView *)addRightLineToView:(UIView *)toView
                     marginTop:(CGFloat)marginTop
                  marginBottom:(CGFloat)marginBottom
                   marginRight:(CGFloat)marginRight
                         color:(UIColor *)color;

// 默认边框颜色为e8e8e8e
+ (void)cj_drawLines:(CJPayLine)lines
 withRoundedCorners:(UIRectCorner)corners
             radius:(CGFloat)radius
           viewRect:(CGRect)rect;

/// 绘制带圆角的边框
/// @param lines 需要绘制的线枚举
/// @param corners 需要绘制的圆角枚举
/// @param radius 圆角的弧度
/// @param rect 边框的绘制范围
/// @param color 边框的颜色
+ (void)cj_drawLines:(CJPayLine)lines
 withRoundedCorners:(UIRectCorner)corners
             radius:(CGFloat)radius
           viewRect:(CGRect)rect
              color:(UIColor *)color;

+ (void)removeBottomLineFromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
