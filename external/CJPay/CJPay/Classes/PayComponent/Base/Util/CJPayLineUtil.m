//
//  CJPayLineUtil.m
//  CJPay
//
//  Created by wangxiaohong on 2019/10/10.
//

#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"

#import <objc/runtime.h>

@implementation CJPayLineUtil

+ (UIView *)addTopLineToView:(UIView *)toView
                  marginLeft:(CGFloat)marginLeft
                 marginRight:(CGFloat)marginRight
                   marginTop:(CGFloat)marginTop {
    return [CJPayLineUtil addTopLineToView:toView
                                marginLeft:marginLeft
                               marginRight:marginRight
                                 marginTop:marginTop
                                     color:[UIColor cj_divideLineColor]];
}

+ (UIView *)addTopLineToView:(UIView *)toView
                  marginLeft:(CGFloat)marginLeft
                 marginRight:(CGFloat)marginRight
                   marginTop:(CGFloat)marginTop
                       color:(UIColor *)color {

    UIView *sepView = [[UIView alloc] init];
    [toView addSubview:sepView];
    sepView.backgroundColor = color;
    CJPayMasMaker(sepView, {
        make.top.equalTo(toView).offset(marginTop);
        make.left.equalTo(toView).offset(marginLeft);
        make.right.equalTo(toView).offset(-marginRight);
        make.height.mas_equalTo([CJPayLineUtil lineHeight]);
    });
    return sepView;
}

+ (UIView *)addBottomLineToView:(UIView *)toView
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom {
    return [CJPayLineUtil addBottomLineToView:toView
                                   marginLeft:marginLeft
                                  marginRight:marginRight
                                 marginBottom:marginBottom
                                        color:[UIColor cj_divideLineColor]];
}

+ (UIView *)addBottomLineToView:(UIView *)toView
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom
                          color:(UIColor *)color {

    return [self addBottomLineToView:toView
                          lineHeight:[self lineHeight]
                          marginLeft:marginLeft
                         marginRight:marginRight
                        marginBottom:marginBottom color:color];
}

+ (UIView *)addBottomLineToView:(UIView *)toView
                     lineHeight:(CGFloat)lineHeight
                     marginLeft:(CGFloat)marginLeft
                    marginRight:(CGFloat)marginRight
                   marginBottom:(CGFloat)marginBottom
                          color:(UIColor *)color {
    
    UIView *sepView = [[UIView alloc] init];
    sepView.backgroundColor = color;
    [toView addSubview:sepView];
    
    CJPayMasMaker(sepView, {
        make.left.equalTo(toView).offset(marginLeft);
        make.right.equalTo(toView).offset(-marginRight);
        make.bottom.equalTo(toView).offset(-marginBottom);
        make.height.mas_equalTo(lineHeight);
    });
    
    objc_setAssociatedObject(toView, @selector(removeBottomLineFromView:), sepView, OBJC_ASSOCIATION_RETAIN);
    
    return sepView;
}

+ (UIView *)addRightLineToView:(UIView *)toView
                     marginTop:(CGFloat)marginTop
                  marginBottom:(CGFloat)marginBottom
                 marginRight:(CGFloat)marginRight
{
    return [self addRightLineToView:toView
                          marginTop:marginTop
                       marginBottom:marginBottom
                        marginRight:marginRight
                              color:[UIColor cj_divideLineColor]];
}

+ (UIView *)addRightLineToView:(UIView *)toView
                     marginTop:(CGFloat)marginTop
                  marginBottom:(CGFloat)marginBottom
                   marginRight:(CGFloat)marginRight
                         color:(UIColor *)color
{
    UIView *sepView = [[UIView alloc] init];
    sepView.backgroundColor = color;
    [toView addSubview:sepView];
    
    CJPayMasMaker(sepView, {
        make.right.equalTo(toView).offset(-marginRight);
        make.top.equalTo(toView).offset(marginTop);
        make.bottom.equalTo(toView).offset(-marginBottom);
        make.width.mas_equalTo([self lineHeight]);
    });

    return sepView;
}

+ (void)cj_drawLines:(CJPayLine)lines withRoundedCorners:(UIRectCorner)corners radius:(CGFloat)radius viewRect:(CGRect)rect
{
    [self cj_drawLines:lines
   withRoundedCorners:corners
               radius:radius
             viewRect:rect
                color:[UIColor cj_divideLineColor]];
}

+ (void)cj_drawLines:(CJPayLine)lines
 withRoundedCorners:(UIRectCorner)corners
             radius:(CGFloat)radius
           viewRect:(CGRect)rect
              color:(UIColor *)color
{
    [color set];
    
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height - CJ_PIXEL_WIDTH;
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    maskPath.lineWidth = CJ_PIXEL_WIDTH;
    
    [maskPath moveToPoint:CGPointMake(x, y + height - radius)];
    
    if (lines & CJPayLineLeft) {
        [maskPath addLineToPoint:CGPointMake(x, y + radius)];
        if (lines & CJPayLineTop && corners & UIRectCornerTopLeft) {
            [maskPath addArcWithCenter:CGPointMake(x + radius, y + radius) radius:radius startAngle:CJPI endAngle: 3 * CJPI / 2 clockwise:YES];
        } else {
            [maskPath addLineToPoint:CGPointMake(x, y)];
        }
    } else {
        [maskPath moveToPoint:CGPointMake(x, y)];
    }
    
    if (lines & CJPayLineTop) {
        [maskPath addLineToPoint:CGPointMake(x + width - radius, y)];
        if (lines & CJPayLineRight && corners & UIRectCornerTopRight) {
            [maskPath addArcWithCenter:CGPointMake(x + width - radius, y + radius) radius:radius startAngle: 3 * CJPI / 2 endAngle: 0 clockwise:YES];
        } else {
            [maskPath addLineToPoint:CGPointMake(x + width, y)];
        }
    } else {
        [maskPath moveToPoint:CGPointMake(x + width, y)];
    }
    
    if (lines & CJPayLineRight) {
        [maskPath addLineToPoint:CGPointMake(x + width, y + height - radius)];
        if (lines & CJPayLineBottom && corners & UIRectCornerBottomRight) {
            [maskPath addArcWithCenter:CGPointMake(x + width - radius, y + height - radius) radius:radius startAngle: 0 endAngle: - 3 * CJPI / 2 clockwise:YES];
        } else {
            [maskPath addLineToPoint:CGPointMake(x + width, y + height)];
        }
    } else {
        [maskPath moveToPoint:CGPointMake(x + width, y + height)];
    }
    
    if (lines & CJPayLineBottom) {
        [maskPath addLineToPoint:CGPointMake(x + width - radius, y + height)];
        if (lines & CJPayLineLeft && corners & UIRectCornerBottomLeft) {
            [maskPath addArcWithCenter:CGPointMake(x + radius, y + height - radius) radius:radius startAngle: - 3 * CJPI / 2 endAngle: -CJPI clockwise:YES];
        } else {
            [maskPath addLineToPoint:CGPointMake(x, y + height)];
        }
    } else {
        [maskPath moveToPoint:CGPointMake(x, y + height)];
    }
    
    if (lines & CJPayLineLeft) {
        [maskPath addLineToPoint:CGPointMake(x, y + height - radius)];
    }
    [maskPath stroke];
}

+ (void)removeBottomLineFromView:(UIView *)view
{
    UIView *bottomView = objc_getAssociatedObject(view, @selector(removeBottomLineFromView:));
    if(bottomView) {
        [bottomView removeFromSuperview];
    }
}

+ (CGFloat)lineHeight {
    return CJ_PIXEL_WIDTH;
}

@end
