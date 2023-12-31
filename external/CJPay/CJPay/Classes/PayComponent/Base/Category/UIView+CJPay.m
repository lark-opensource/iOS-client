//
//  UIView+CJExtension.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/30.
//

#import "UIView+CJPay.h"
#import "UIColor+CJPay.h"
#import "UIView+CJLayout.h"
#import "NSArray+CJPay.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"

#import <objc/runtime.h>

static NSString *cjpayInnerRectLayerNameKey = @"cjpayInnerRectLayerNameKey";

@interface UIView (CJPay)

@property (nonatomic, strong) UIControl *cjpay_controlView;
@property (nonatomic, strong) UIView *cjpay_mockInteractionView;

@end

@implementation UIView (CJPay)

- (void)cj_removeAllSubViews {
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (UIImage *)cjpay_snapShotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size,self.opaque,1.3);
    CGRect rect = self.bounds;
    [self drawViewHierarchyInRect:rect afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)cj_customCorners:(UIRectCorner)corners radius:(CGFloat)radius{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius,radius)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (void)cj_innerRect:(CGRect)rect
           fillColor:(UIColor *)fillColor
         strokeColor:(UIColor *)strokeColor {
    [self cj_innerRect:rect
            rectCorner:UIRectCornerAllCorners
          cornerRadius:CGSizeMake(0, 0)
             fillColor:fillColor
           strokeColor:strokeColor];
}

- (void)cj_innerRect:(CGRect)rect
          rectCorner:(UIRectCorner)rectCorner
        cornerRadius:(CGSize)radius
           fillColor:(UIColor *)fillColor
         strokeColor:(UIColor *)strokeColor {
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                    byRoundingCorners:rectCorner
                                                          cornerRadii:radius];
    CAShapeLayer *oldInnerRectLayer = [[self.layer sublayers] cj_objectAtIndex:0];
    CAShapeLayer *newInnerRectLayer = [[CAShapeLayer alloc] init];
    newInnerRectLayer.frame = rect;
    newInnerRectLayer.path = innerPath.CGPath;
    newInnerRectLayer.fillColor = fillColor.CGColor;
    newInnerRectLayer.strokeColor = strokeColor.CGColor;
    newInnerRectLayer.name = @"cjpayInnerRectLayerName";
    
    if (![oldInnerRectLayer.name isEqualToString:@"cjpayInnerRectLayerName"]) {
        [self.layer insertSublayer:newInnerRectLayer atIndex:0];
    } else {
        [self.layer replaceSublayer:oldInnerRectLayer with:newInnerRectLayer];
    }
}

- (void)cj_clipTopCorner:(CGFloat)radius {
    [self cj_customCorners:UIRectCornerTopLeft | UIRectCornerTopRight radius:radius];
}

- (void)cj_clipTopLeftCorner:(CGFloat)radius {
    [self cj_customCorners:UIRectCornerTopLeft radius:radius];
}

- (void)cj_clipBottomCorner:(CGFloat)radius {
    [self cj_customCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight radius:radius];
}

- (void)cj_clipTopCorner:(CGFloat)topRadius bottomCorner:(CGFloat)bottomRadius {
    [self cj_customCorners:UIRectCornerTopLeft | UIRectCornerTopRight radius:topRadius];
    [self cj_customCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight radius:bottomRadius];
}

- (void)cj_showBorder:(UIColor *)color borderWidth:(CGFloat)borderWidth{
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = borderWidth;
}

- (void)cj_showCornerRadius:(CGFloat)radius{
    self.layer.cornerRadius = radius;
    self.clipsToBounds = YES;
}

- (void)cj_applyGradientWithStartColor:(UIColor *)startColor
                              endColor:(UIColor *)endColor
                            startPoint:(CGPoint)startPoint
                            startPoint:(CGPoint)endPoint {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.bounds;
    gradientLayer.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    [self.layer addSublayer:gradientLayer];
}

- (void)cj_applySketchShadow:(UIColor *)color alpha:(CGFloat)alpha x:(CGFloat)x y:(CGFloat)y blur:(CGFloat)blur spread:(CGFloat)spread{
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOpacity = alpha;
    self.layer.shadowOffset = CGSizeMake(x, y);
    self.layer.shadowRadius = blur / 2.0;
    if (spread == 0) {
        self.layer.shadowPath = nil;
    } else {
        CGRect rect = CGRectInset(self.bounds, -spread, -spread);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:rect].CGPath;
    }
}

- (CALayer *)cj_getShadowLayer:(UIColor *)color
                         alpha:(CGFloat)alpha
                             x:(CGFloat)x
                             y:(CGFloat)y
                          blur:(CGFloat)blur
                        spread:(CGFloat)spread
                  cornerRadius:(CGFloat)cornerRadius {
    //////// shadow /////////
    CALayer *shadowLayer = [CALayer layer];
    shadowLayer.frame = self.layer.frame;
    
    shadowLayer.shadowColor = color.CGColor;//shadowColor阴影颜色
    shadowLayer.shadowOffset = CGSizeMake(x, y);//shadowOffset阴影偏移，默认(0, -3),这个跟shadowRadius配合使用
    shadowLayer.shadowOpacity = alpha;//0.8;//阴影透明度，默认0
    shadowLayer.shadowRadius = blur / 2;//8;//阴影半径，默认3
    
    //路径阴影
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    float width = shadowLayer.bounds.size.width;
    float height = shadowLayer.bounds.size.height;
    float sx = self.bounds.origin.x;
    float sy = self.bounds.origin.y;
    
    CGPoint topLeft      = shadowLayer.bounds.origin;
    CGPoint topRight     = CGPointMake(sx + width, sy);
    CGPoint bottomRight  = CGPointMake(sx + width, sy + height);
    CGPoint bottomLeft   = CGPointMake(sx, sy + height);
    
    CGFloat offset = -spread;
    [path moveToPoint:CGPointMake(topLeft.x - offset, topLeft.y + cornerRadius)];
    [path addArcWithCenter:CGPointMake(topLeft.x + cornerRadius, topLeft.y + cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI endAngle:M_PI_2 * 3 clockwise:YES];
    [path addLineToPoint:CGPointMake(topRight.x - cornerRadius, topRight.y - offset)];
    [path addArcWithCenter:CGPointMake(topRight.x - cornerRadius, topRight.y + cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI_2 * 3 endAngle:M_PI * 2 clockwise:YES];
    [path addLineToPoint:CGPointMake(bottomRight.x + offset, bottomRight.y - cornerRadius)];
    [path addArcWithCenter:CGPointMake(bottomRight.x - cornerRadius, bottomRight.y - cornerRadius) radius:(cornerRadius + offset) startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [path addLineToPoint:CGPointMake(bottomLeft.x + cornerRadius, bottomLeft.y + offset)];
    [path addArcWithCenter:CGPointMake(bottomLeft.x + cornerRadius, bottomLeft.y - cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [path addLineToPoint:CGPointMake(topLeft.x - offset, topLeft.y + cornerRadius)];
    
    //设置阴影路径
    shadowLayer.shadowPath = path.CGPath;
    
    return shadowLayer;
}

- (UIView *)findViewThatIsFirstResponder
{
    if (self.isFirstResponder) {
        return self;
    }
    
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findViewThatIsFirstResponder];
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}

- (BOOL)isDisplayedInScreen {
    if (self == nil || self.superview == nil) {
        return NO;
    }
    
    if (self.hidden) {
        return NO;
    }
    
    // 转换view对应window的Rect，校正坐标系
    CGRect rect = [self convertRect:self.bounds toView:nil];
    
    if (CGRectIsEmpty(rect) ||
        CGRectIsNull(rect) ||
        CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGRect intersectionRect = CGRectIntersection(rect, screenRect);
    if (CGRectIsEmpty(intersectionRect) || CGRectIsNull(intersectionRect)) {
        return NO;
    }
    
    return YES;
}

- (UIView *)cj_copy {
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:self];
    UIView *copyView = (UIView *)[NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
    return copyView;
}
- (UIViewController *) cj_responseViewController {
    return (UIViewController *)[self cj_traverseResponderChainForUIViewController];
}

- (id) cj_traverseResponderChainForUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder cj_traverseResponderChainForUIViewController];
    } else {
        return nil;
    }
}

- (void)cj_setViewWidthEqualToScreen {
    CGRect oldFrame = self.frame;
    CGRect newFrame = CGRectMake(oldFrame.origin.x, oldFrame.origin.y, CJ_SCREEN_WIDTH, oldFrame.size.height);
    self.frame = newFrame;
}

- (void)cj_viewAddTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    BOOL disableViolentClickPrevent = [CJPaySettingsManager shared].currentSettings.disableViolentClickPrevent;
    if (disableViolentClickPrevent) {
        if (self.cjpay_controlView.superview) {
            [self.cjpay_controlView removeFromSuperview];
            self.cjpay_controlView = nil;
        }
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:target
                                                                                     action:action];
        [self addGestureRecognizer:tapGesture];
    } else {
        if (!self.cjpay_controlView) {
            self.userInteractionEnabled = YES;
            self.cjpay_controlView = [UIButton new];
            [self insertSubview:self.cjpay_controlView atIndex:0];
            [self.cjpay_controlView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.left.bottom.right.equalTo(self);
            }];
        }
        [self.cjpay_controlView addTarget:target action:action forControlEvents:controlEvents];
    }
}

- (void)cj_viewAddShakeAnimation:(CGFloat)amplitude withTimes:(CGFloat)times {
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.values = @[@(-amplitude), @(0), @(amplitude), @(0)];
    shake.repeatCount = times;
    shake.removedOnCompletion = YES;
    shake.duration = 0.1f;
    [self.layer addAnimation:shake forKey:@"shake"];
}

- (BOOL)isShowMask {
    return self.backgroundColor != UIColor.clearColor;
}

#pragma mark - cjpay_controlView

- (UIControl *)cjpay_controlView {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setCjpay_controlView:(UIControl *)controlView {
  objc_setAssociatedObject(self, @selector(cjpay_controlView), controlView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)cjpay_mockInteractionView {
    UIView *view = (UIView *)objc_getAssociatedObject(self, _cmd);
    if (!view) {
        view = [UIView new];
        objc_setAssociatedObject(self, _cmd, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        view.backgroundColor = [UIColor clearColor];
    }
    return view;
}

- (void)cj_setUserInteractionEnabled:(BOOL)enable {
    if (enable) {
        [self.cjpay_mockInteractionView removeFromSuperview];
        return;
    }
    if (self.cjpay_mockInteractionView.superview) {
        self.cjpay_mockInteractionView.frame = self.bounds;
        [self bringSubviewToFront:self.cjpay_mockInteractionView];
    } else {
        [self addSubview:self.cjpay_mockInteractionView];
        self.cjpay_mockInteractionView.frame = self.bounds;
    }
}

@end
