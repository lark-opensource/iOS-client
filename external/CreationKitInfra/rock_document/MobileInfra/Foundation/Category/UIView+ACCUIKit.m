//
//  UIView+AWEUIKit.m
//  AWEUIKit
//
//  Created by zhangrenfeng on 2019/9/26.
//

#import "UIView+ACCMasonry.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "UIView+ACCRTL.h"

#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSObject+ACCSwizzle.h>
#import "UIView+ACCRTL.h"
#import <Masonry/View+MASAdditions.h>

@implementation UIView (ACCUIKit)

- (void)acc_disableUserInteractionWithTimeInterval:(NSTimeInterval)interval
{
    self.userInteractionEnabled = NO;
    [self performSelector:@selector(acc_enableUserInteraction) withObject:nil afterDelay:interval];
}

- (void)acc_enableUserInteraction
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(acc_enableUserInteraction) object:nil];
}

- (UIView * _Nonnull)acc_touchView
{
    return [self acc_touchViewWithSize:CGSizeMake(44, 44)];
}

- (void)acc_removeAllSubviews
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (UIViewController *)acc_viewController
{
    for (UIView *view = self; view; view = view.superview) {
        UIResponder *nextResponder = [view nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

- (UIView * _Nonnull)acc_touchViewWithSize:(CGSize)size
{
    UIView *touchView = [UIView new];
    touchView.backgroundColor = [UIColor clearColor];
    [touchView addSubview:self];

    ACCMasMaker(touchView, {
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    });
    ACCMasMaker(self, {
        make.center.equalTo(touchView);
    });

    return touchView;
}

- (void)acc_addRotateAnimationWithDuration:(CGFloat)duration
{
    [self acc_addRotateAnimationWithDuration:duration forKey:nil];
}

- (void)acc_addRotateAnimationWithDuration:(CGFloat)duration forKey:(nullable NSString *)key
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0];
    rotationAnimation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotationAnimation.duration = duration;
    rotationAnimation.repeatCount = HUGE_VALF;
    rotationAnimation.removedOnCompletion = NO;
    [self.layer addAnimation:rotationAnimation forKey:key];
}

- (void)acc_addBlurEffect
{
    [self acc_addSystemBlurEffect:UIBlurEffectStyleDark];
}

- (void)acc_addSystemBlurEffect:(UIBlurEffectStyle)style
{
    // on JAILBROKEN device, maybe have no resources for blureffect
    @try {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        [self addSubview:effectView];

        ACCMasMaker(effectView, {
            make.edges.equalTo(self);
        });
    } @catch (NSException *exception) {

    }
}

- (UIImage *)acc_snapshotImage
{
    if (@available(iOS 10.0, *)) {
        UIGraphicsImageRenderer *render = [[UIGraphicsImageRenderer alloc] initWithSize:self.bounds.size];
        return [render imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
            [self.layer renderInContext:rendererContext.CGContext];
        }];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return snap;
    }
}

- (UIImage *)acc_snapshotImageAfterScreenUpdates:(BOOL)afterUpdates
{
    if (![self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        return [self acc_snapshotImage];
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:afterUpdates];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImage *)acc_snapshotImageAfterScreenUpdates:(BOOL)afterUpdates withSize:(CGSize)size {
    if (![self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        return [self acc_snapshotImage];
    }
    UIGraphicsBeginImageContextWithOptions(size, self.opaque, 0);
    [self drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:afterUpdates];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImageView *)acc_snapshotImageView
{
    UIImage *image = [self acc_snapshotImage];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.accrtl_viewType = ACCRTLViewTypeNormal;
        imageView.frame = self.frame;
        return imageView;
    }
    return nil;
}

- (UIImageView *)acc_snapshotImageViewAfterScreenUpdates:(BOOL)afterUpdate
{
    UIImage *image = [self acc_snapshotImageAfterScreenUpdates:afterUpdate];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.accrtl_viewType = ACCRTLViewTypeNormal;
        imageView.frame = self.frame;
        return imageView;
    }
    return nil;
}

- (UIColor *)acc_colorOfPoint:(CGPoint)point
{
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

    CGContextTranslateCTM(context, -point.x, -point.y);

    [self.layer renderInContext:context];

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];

    return color;
}

- (void)setAcc_cornerRadius:(CGFloat)cornerRadius
{
    NSNumber *value = @(cornerRadius);
    objc_setAssociatedObject(self, @selector(acc_cornerRadius), value, OBJC_ASSOCIATION_RETAIN);
    CGRect bounds = self.bounds;
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:cornerRadius];
    layer.path = path.CGPath;
    if (cornerRadius > 0) {
        if (self.acc_innerLayer) {
            [self.acc_innerLayer removeFromSuperlayer];
            layer.fillColor = self.acc_innerLayer.fillColor;
        } else {
            layer.fillColor = self.backgroundColor.CGColor;
            self.backgroundColor = [UIColor clearColor];
        }
        self.acc_innerLayer = layer;
        [self.layer insertSublayer:self.acc_innerLayer atIndex:0];
    } else {
        [self.acc_innerLayer removeFromSuperlayer];
        self.acc_innerLayer = nil;
    }
}

- (CGFloat)acc_cornerRadius
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(acc_cornerRadius));
    return [value doubleValue];
}

-(void)setAcc_innerLayer:(CAShapeLayer *)acc_innerLayer
{
    objc_setAssociatedObject(self, @selector(acc_innerLayer), acc_innerLayer, OBJC_ASSOCIATION_RETAIN);
}

- (CAShapeLayer *)acc_innerLayer
{
    CAShapeLayer *layer = objc_getAssociatedObject(self, @selector(acc_innerLayer));
    return layer;
}

- (UIImage * _Nonnull)acc_roundedImage:(UIImage * _Nonnull)image
{
    CGFloat inset = 0.1f;
    UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    CGRect rect = CGRectMake(inset, inset, image.size.width - inset * 2.0f, image.size.height - inset * 2.0f);
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);

    [image drawInRect:rect];
    CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
    UIImage *newImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImg;
}

- (UIEdgeInsets)acc_safeAdjustment
{
    if (@available(iOS 11.0, *)) {
        if ([UIDevice acc_isIPhoneX]) {
            return self.safeAreaInsets;
        } else {
            return UIEdgeInsetsZero;
        }
    } else {
        return UIEdgeInsetsZero;
    }
}

- (CGRect)acc_frameInView:(UIView *)view
{
    return [view convertRect:self.bounds fromView:self];
}

- (CGPoint)acc_anchorOffsetWithPositive:(BOOL)positive
{
    CGPoint newPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x,
                                   self.bounds.size.height * self.layer.anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * 0.5,
                                   self.bounds.size.height * 0.5);
    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
    
    if (positive) {
        return CGPointMake(oldPoint.x - newPoint.x, oldPoint.y - newPoint.y);
    } else {
        return CGPointMake(newPoint.x - oldPoint.x, newPoint.y - oldPoint.y);
    }
}

- (void)acc_setAnchorPointForRotateAndScale:(CGPoint)anchorPoint
{
    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x,
                                   self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x,
                                   self.bounds.size.height * self.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
    
    CGPoint position = self.layer.position;
    position.x += newPoint.x - oldPoint.x;
    position.y += newPoint.y - oldPoint.y;
    
    if (isnan(position.x) || isnan(position.y)) {
        position = self.layer.position;
    }
    
    if (isnan(anchorPoint.x) || isnan(anchorPoint.y)) {
        anchorPoint = self.layer.anchorPoint;
    }
    
    self.layer.position = position;
    self.layer.anchorPoint = anchorPoint;
}

- (CGFloat)acc_centerToBorderDirection:(ACCViewDirection)direction
{
    CGFloat length = 0;
    if (direction == ACCViewDirectionLeft) {
        length = self.frame.size.width / 2.f + [self acc_anchorOffsetWithPositive:NO].x;
    } else if (direction == ACCViewDirectionRight) {
        length = self.frame.size.width / 2.f + [self acc_anchorOffsetWithPositive:YES].x;
    } else if (direction == ACCViewDirectionTop) {
        length = self.frame.size.height / 2.f + [self acc_anchorOffsetWithPositive:NO].y;
    } else if (direction == ACCViewDirectionBottom) {
        length = self.frame.size.height / 2.f + [self acc_anchorOffsetWithPositive:YES].y;
    }
    return length;
}

- (CGFloat)acc_maxScaleWithinRect:(CGRect)rect
{
    // only used in sticker container safe area; otherwise you need consider if there is case whose anchorPoint < 0 or > 1; in these cases, additional logic is needed
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat left = (self.layer.anchorPoint.x * width);
    CGFloat right = ((1 - self.layer.anchorPoint.x) * width);

    CGFloat top = (self.layer.anchorPoint.y * height);
    CGFloat bottom = ((1 - self.layer.anchorPoint.y) * height);

    CGFloat leftScale = CGFLOAT_MAX;
    CGFloat rightScale = CGFLOAT_MAX;
    CGFloat topScale = CGFLOAT_MAX;
    CGFloat bottomScale = CGFLOAT_MAX;

    if (left > 0) {
        leftScale = ((self.frame.origin.x - rect.origin.x) + left) / left;
    }
    if (right > 0) {
        rightScale = ((rect.origin.x + rect.size.width - (self.frame.origin.x + self.frame.size.width)) + right) / right;
    }
    if (top > 0) {
        topScale = ((self.frame.origin.y - rect.origin.y) + top) / top;
    }
    if (bottom > 0) {
        bottomScale = ((rect.origin.y + rect.size.height - (self.frame.origin.y + self.frame.size.height)) + bottom) / bottom;
    }
    return fmin(fmin(fmin(leftScale, rightScale), topScale), bottomScale);
}

- (void)acc_setupBorderWithTopLeftRadius:(CGSize)topLeftRadius
                          topRightRadius:(CGSize)topRightRadius
                        bottomLeftRadius:(CGSize)bottomLeftRadius
                       bottomRightRadius:(CGSize)bottomRightRadius
{
    UIBezierPath *maskPath = [self acc_bezierPathWithRect:self.bounds
                                         topLeftRadius:topLeftRadius
                                        topRightRadius:topRightRadius
                                      bottomLeftRadius:bottomLeftRadius
                                     bottomRightRadius:bottomRightRadius];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.allowsEdgeAntialiasing = YES;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (UIBezierPath *)acc_bezierPathWithRect:(CGRect)rect
                        topLeftRadius:(CGSize)topLeftRadius
                       topRightRadius:(CGSize)topRightRadius
                     bottomLeftRadius:(CGSize)bottomLeftRadius
                    bottomRightRadius:(CGSize)bottomRightRadius
{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    CGPoint topLeftAnchor = rect.origin;
    CGPoint topRightAnchor = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGPoint bottomLeftAnchor = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPoint bottomRightAnchor = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    
    if (CGSizeEqualToSize(topLeftRadius, CGSizeZero)) {
        [bezierPath moveToPoint:topLeftAnchor];
    } else {
        [bezierPath moveToPoint:CGPointMake(topLeftAnchor.x + topLeftRadius.width, topLeftAnchor.y)];
    }
    
    if (CGSizeEqualToSize(topRightRadius, CGSizeZero)) {
        [bezierPath addLineToPoint:topRightAnchor];
    } else {
        [bezierPath addLineToPoint:CGPointMake(topRightAnchor.x - topRightRadius.width, topRightAnchor.y)];
        [bezierPath addCurveToPoint:CGPointMake(topRightAnchor.x, topRightAnchor.y + topRightRadius.height)
                      controlPoint1:topRightAnchor
                      controlPoint2:CGPointMake(topRightAnchor.x, topRightAnchor.y + topRightRadius.height)];
    }
    
    if (CGSizeEqualToSize(bottomRightRadius, CGSizeZero)) {
        [bezierPath addLineToPoint:bottomRightAnchor];
    } else {
        [bezierPath addLineToPoint:CGPointMake(bottomRightAnchor.x, bottomRightAnchor.y - bottomRightRadius.height)];
        [bezierPath addCurveToPoint:CGPointMake(bottomRightAnchor.x - bottomRightRadius.width, bottomRightAnchor.y)
                      controlPoint1:bottomRightAnchor
                      controlPoint2:CGPointMake(bottomRightAnchor.x - bottomRightRadius.width, bottomRightAnchor.y)];
    }
    
    if (CGSizeEqualToSize(bottomLeftRadius, CGSizeZero)) {
        [bezierPath addLineToPoint:bottomLeftAnchor];
    } else {
        [bezierPath addLineToPoint:CGPointMake(bottomLeftAnchor.x + bottomLeftRadius.width, bottomLeftAnchor.y)];
        [bezierPath addCurveToPoint:CGPointMake(bottomLeftAnchor.x, bottomLeftAnchor.y - bottomLeftRadius.height)
                      controlPoint1:bottomLeftAnchor
                      controlPoint2:CGPointMake(bottomLeftAnchor.x, bottomLeftAnchor.y - bottomLeftRadius.height)];
    }
    
    if (CGSizeEqualToSize(topLeftRadius, CGSizeZero)) {
        [bezierPath moveToPoint:topLeftAnchor];
    } else {
        [bezierPath addLineToPoint:CGPointMake(topLeftAnchor.x, topLeftAnchor.y + topLeftRadius.height)];
        [bezierPath addCurveToPoint:CGPointMake(topLeftAnchor.x + topLeftRadius.width, topLeftAnchor.y)
                      controlPoint1:topLeftAnchor
                      controlPoint2:CGPointMake(topLeftAnchor.x + topLeftRadius.width, topLeftAnchor.y)];
    }
    
    [bezierPath closePath];
    return bezierPath;
}

@end


@implementation UIView (ACCLayout)

- (void)setAcc_top:(CGFloat)acc_top {
    self.frame = CGRectMake(self.acc_left, acc_top, self.acc_width, self.acc_height);
}

- (CGFloat)acc_top {
    return self.frame.origin.y;
}

- (void)setAcc_bottom:(CGFloat)acc_bottom {
    self.frame = CGRectMake(self.acc_left, acc_bottom - self.acc_height, self.acc_width, self.acc_height);
}

- (CGFloat)acc_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setAcc_left:(CGFloat)acc_left {
    self.frame = CGRectMake(acc_left, self.acc_top, self.acc_width, self.acc_height);
}

- (CGFloat)acc_left {
    return self.frame.origin.x;
}

- (void)setAcc_right:(CGFloat)acc_right {
    self.frame = CGRectMake(acc_right - self.acc_width, self.acc_top, self.acc_width, self.acc_height);
}

- (CGFloat)acc_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setAcc_width:(CGFloat)acc_width {
    self.frame = CGRectMake(self.acc_left, self.acc_top, acc_width, self.acc_height);
}

- (CGFloat)acc_width {
    return self.frame.size.width;
}

- (void)setAcc_height:(CGFloat)acc_height {
    self.frame = CGRectMake(self.acc_left, self.acc_top, self.acc_width, acc_height);
}

- (CGFloat)acc_height {
    return self.frame.size.height;
}

- (CGFloat)acc_centerX {
    return self.center.x;
}

- (void)setAcc_centerX:(CGFloat)acc_centerX {
    self.center = CGPointMake(acc_centerX, self.center.y);
}

- (CGFloat)acc_centerY {
    return self.center.y;
}

- (void)setAcc_centerY:(CGFloat)acc_centerY {
    self.center = CGPointMake(self.center.x, acc_centerY);
}

- (CGSize)acc_size {
    return self.frame.size;
}

- (void)setAcc_size:(CGSize)acc_size {
    self.frame = CGRectMake(self.acc_left, self.acc_top, acc_size.width, acc_size.height);
}

- (CGPoint)acc_origin {
    return self.frame.origin;
}

- (void)setAcc_origin:(CGPoint)acc_origin {
    self.frame = CGRectMake(acc_origin.x, acc_origin.y, self.acc_width, self.acc_height);
}

@end


@implementation UIView (ACCHierarchy)

- (id)acc_nearestAncestorOfClass:(Class)clazz
{
    if (!clazz) {
        return nil;
    }

    UIView *ancestor = self;

    while (![ancestor isKindOfClass:clazz] && ancestor.superview) {
        ancestor = ancestor.superview;
    }

    return ancestor;
}

@end


@implementation UIView (ACCAddGestureRecognizer)

- (UITapGestureRecognizer *)acc_addDoubleTapRecognizerWithTarget:(id)target action:(SEL)sel
{
    self.userInteractionEnabled = YES;

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:target action:sel];
    tapRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapRecognizer];

    return tapRecognizer;
}

- (UITapGestureRecognizer *)acc_addSingleTapRecognizerWithTarget:(id)target action:(SEL)sel
{
    self.userInteractionEnabled = YES;

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:target action:sel];
    tapRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapRecognizer];

    return tapRecognizer;
}

@end


@implementation UIView (ACCViewImageMirror)

- (UIImage *)acc_imageWithView
{
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)acc_imageWithViewOnScreenScale
{
    CGSize s = self.bounds.size;
    if (@available(iOS 10.0, *)) {
        UIGraphicsImageRenderer *render = [[UIGraphicsImageRenderer alloc] initWithSize:self.bounds.size];
        return [render imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
            [self.layer renderInContext:rendererContext.CGContext];
        }];
    } else {
        UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

- (UIImage *)acc_imageWithViewOnScale:(CGFloat)scale
{
    CGSize s = self.bounds.size;
    if (@available(iOS 10.0, *)) {
        UIGraphicsImageRenderer *render = [[UIGraphicsImageRenderer alloc] initWithSize:s format:({
            UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
            format.scale = scale;
            format;
        })];
        return [render imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
            [self.layer renderInContext:rendererContext.CGContext];
        }];
    } else {
        UIGraphicsBeginImageContextWithOptions(s, NO, scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage*image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
    
}

@end

@interface UIView (acc_FadeShowAndHiddenPrivate)

@property (nonatomic, assign) BOOL acc_eventuallyHidden;

@end

@implementation UIView (acc_FadeShowAndHiddenPrivate)

- (void)setAcc_eventuallyHidden:(BOOL)acc_eventuallyHidden
{
    objc_setAssociatedObject(self, @selector(acc_eventuallyHidden), @(acc_eventuallyHidden), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)acc_eventuallyHidden
{
    return [objc_getAssociatedObject(self, @selector(acc_eventuallyHidden)) boolValue];
}

@end


@interface UIView (acc_FadeShowAndHidden)

@end

@implementation UIView (acc_FadeShowAndHidden)

AWELazyRegisterPremainClassCategory(UIView,acc_FadeShowAndHidden)
{
    [NSObject acc_swizzleMethodsOfClass:[UIView class] originSelector:@selector(setHidden:) targetSelector:@selector(acc_setHidden:)];
}

- (void)acc_fadeShow {
    [self acc_fadeShowWithCompletion:nil];
}

- (void)acc_fadeHidden {
    [self acc_fadeHiddenWithCompletion:nil];
}

- (void)acc_fadeShowWithCompletion:(void(^)(void))completion
{
    [self acc_fadeShowWithDuration:0.3 completion:completion];
}

- (void)acc_fadeHiddenWithCompletion:(void(^)(void))completion
{
    [self acc_fadeHiddenWithDuration:0.3 completion:completion];
}

- (void)acc_fadeShowWithDuration:(NSTimeInterval)duration {
    [self acc_fadeShow:YES duration:duration completion:nil];
}

- (void)acc_fadeHiddenDuration:(NSTimeInterval)duration {
    [self acc_fadeShow:NO duration:duration completion:nil];
}

- (void)acc_fadeShowWithDuration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
    [self acc_fadeShow:YES duration:duration completion:completion];
}

- (void)acc_fadeHiddenWithDuration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
    [self acc_fadeShow:NO duration:duration completion:completion];
}

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration {
    
    [self acc_fadeShow:show duration:duration completion:nil];
}

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
    self.acc_eventuallyHidden = !show;
    if (show) {
        if (!self.hidden && ACC_FLOAT_EQUAL_TO(self.alpha, 1.0f)) {
            ACCBLOCK_INVOKE(completion);
            return;
        }
        if (self.hidden) {
            [self acc_setHidden:NO];
            self.alpha = 0.0;
        }
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alpha = 1.0;
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(completion);
            if (finished && !self.acc_eventuallyHidden) {
                [self acc_setHidden:NO];
                self.alpha = 1.0;
            }
        }];
    } else if (!show) {
        if (self.hidden) {
            ACCBLOCK_INVOKE(completion);
            return;
        }
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(completion);
            if (finished && self.acc_eventuallyHidden) {
                [self acc_setHidden:YES];
                self.alpha = 1.0;
            }
        }];
    }
}

- (void)acc_setHidden:(BOOL)hidden
{
    [self acc_setHidden:hidden];
    self.acc_eventuallyHidden = hidden;
}
@end


CGFloat const ACCEdgeFadeValue = 6;


@implementation ACCEdgeFadeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        _fadeLayer = [ACCEdgeFadeView fadeLayer];
        _fadeLayer.delegate = self;
    }
    return self;
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id)[NSNull null];
}

+ (CAGradientLayer *)fadeLayer
{
    CAGradientLayer *fadeLayer = [[CAGradientLayer alloc] init];
    fadeLayer.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                         (id)UIColor.whiteColor.CGColor,
                         (id)UIColor.whiteColor.CGColor,
                         (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    return fadeLayer;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self refresh];
}

- (void)refresh
{
    self.fadeLayer.frame = self.bounds;
    
    if (![self isValidFadeValue]) {
        self.fadeLayer.backgroundColor = UIColor.whiteColor.CGColor;
        return;
    }
    
    self.fadeLayer.backgroundColor = UIColor.clearColor.CGColor;
    
    CGPoint startPoint = CGPointZero, endPoint = CGPointZero;
    CGFloat fadeInRatio = [self getFadeRatio];
    switch (self.direction) {
        case ACCEdgeFadeDirectionHorizontal:
            startPoint = CGPointMake(0, 0.5);
            endPoint = CGPointMake(1, 0.5);
            break;
        case ACCEdgeFadeDirectionVertical:
            startPoint = CGPointMake(0.5, 0);
            endPoint = CGPointMake(0.5, 1);
            break;
        default:
            break;
    }
    
    self.fadeLayer.startPoint = startPoint;
    self.fadeLayer.endPoint = endPoint;
    self.fadeLayer.locations = @[@(0), @(fadeInRatio), @(1 - fadeInRatio)];
}

- (CGFloat)getFadeRatio {
    if (self.fadeRatio > 0) {
        return self.fadeRatio;
    } else {
        CGFloat length = (self.direction == ACCEdgeFadeDirectionHorizontal) ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
        if (length > 0) {
            return self.value / length;
        } else {
            return 0;
        }
    }
}

- (BOOL)isValidFadeValue
{
    CGFloat fadeRatio = [self getFadeRatio];
    return fadeRatio < 0.5 && fadeRatio > 0;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil;
    }
    return view;
}

@end


@implementation UIView (ACCEdgeFading)

- (void)acc_edgeFading
{
    [self acc_edgeFadingWithValue:ACCEdgeFadeValue];
}

- (void)acc_edgeFadingWithValue:(CGFloat)value
{
    [self acc_edgeFadingWithValue:value direction:ACCEdgeFadeDirectionHorizontal];
}

- (void)acc_edgeFadingWithDirection:(ACCEdgeFadeDirection)direction
{
    [self acc_edgeFadingWithValue:ACCEdgeFadeValue direction:direction];
}

- (void)acc_edgeFadingWithValue:(CGFloat)value direction:(ACCEdgeFadeDirection)direction
{
    ACCEdgeFadeView *fadeView = [self acc_fadeView];
    fadeView.value = value;
    fadeView.direction = direction;
    [fadeView refresh];
}

- (void)acc_edgeFadingWithRatio:(CGFloat)ratio
{
    ACCEdgeFadeView *fadeView = [self acc_fadeView];
    fadeView.fadeRatio = ratio;
    fadeView.direction = ACCEdgeFadeDirectionHorizontal;
    [fadeView refresh];
}

- (ACCEdgeFadeView *)acc_fadeView
{
    ACCEdgeFadeView *fadeView = objc_getAssociatedObject(self, _cmd);
    if (!fadeView) {
        fadeView = [[ACCEdgeFadeView alloc] init];
        [self addSubview:fadeView];
        ACCMasMaker(fadeView, {
            make.edges.equalTo(self);
        });
        self.layer.mask = fadeView.fadeLayer;
        objc_setAssociatedObject(self, _cmd, fadeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return fadeView;
}

@end



@implementation UIView (ACCVisible)

// Determine whether the view is displayed on the screen
- (BOOL)acc_isDisplayedOnScreen
{
    // Convert rect of window corresponding to view
    CGRect rect = [self convertRect:self.bounds toView:self.window];
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {
        return NO;
    }
    
    // Alpha is 0
    if (ACC_FLOAT_EQUAL_ZERO(self.alpha)) {
        return NO;
    }
    
    // If view is hidden
    if (self.hidden) {
        return NO;
    }
    
    // Without supervision
    if (self.superview == nil) {
        return NO;
    }
    
    // If size is cgrectzero
    if (CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
    // Get the rect where the view intersects with the window
    CGRect intersectionRect = CGRectIntersection(rect, screenRect);
    if (CGRectIsNull(intersectionRect) || CGRectIsEmpty(intersectionRect)) {
        return NO;
    }
    
    return YES;
}

@end
