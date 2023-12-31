//
//  AWEVideoEffectRangeView.m
//  Pods
//
//  Created by zhangchengtao on 2019/3/11.
//

#import "AWEVideoEffectRangeView.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface AWEVideoEffectScalableRangeView ()

@property (nonatomic) NSUInteger touchPosition; // 0 head, 1 body, 2 tail, -1 invalid area
@property (nonatomic) CGRect originalFrame;

@property (nonatomic) NSArray<NSNumber *> *panTouchPositionProhibits;

@property (nonatomic, assign) BOOL playVibrateLimitFlag;

@property (nonatomic, strong) id feedBackGenertor;

@end

@implementation AWEVideoEffectScalableRangeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        [self setUpGesture];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame panTouchPositionProhibits:(NSArray *)panTouchPositionProhibits
{
    if (self = [self initWithFrame:frame]) {
        self.panTouchPositionProhibits = [panTouchPositionProhibits copy];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)setUpGesture
{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];
}

- (void)setEffectColor:(UIColor *)effectColor
{
    if (_effectColor != effectColor) {
        _effectColor = effectColor;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_effectColor && CGRectGetWidth(self.bounds) > 24 && CGRectGetHeight(self.bounds) > 4) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect rect = CGRectMake(12, 2, self.bounds.size.width - 24, self.bounds.size.height - 4);
        if (self.useEnhancedHandle) {
            rect = CGRectMake(14, 2, self.bounds.size.width - 28, self.bounds.size.height - 4);
        }
        
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGPathRef path0 = CGPathCreateWithRect(self.bounds, NULL);
        CGContextAddPath(context, path0);
        CGContextFillPath(context);
        CGPathRelease(path0);
        
        UIColor *fillColor = self.useEnhancedHandle ? [UIColor whiteColor] : [_effectColor colorWithAlphaComponent:1.0];
        CGContextSetFillColorWithColor(context, fillColor.CGColor);
        CGMutablePathRef path1 = CGPathCreateMutable();
        CGPathAddRoundedRect(path1, NULL, self.bounds, 2, 2);
        CGPathAddRect(path1, NULL, rect);
        CGContextAddPath(context, path1);
        CGContextDrawPath(context, kCGPathEOFill);
        CGPathRelease(path1);

        CGContextSetFillColorWithColor(context, [_effectColor colorWithAlphaComponent:0.5].CGColor);
        CGPathRef path2 = CGPathCreateWithRect(rect, NULL);
        CGContextAddPath(context, path2);
        CGContextFillPath(context);
        CGPathRelease(path2);
        
        if (self.useEnhancedHandle) {
            CGContextSetFillColorWithColor(context, ACCResourceColor(ACCColorPrimary).CGColor);
            CGPathRef line0 = CGPathCreateWithRect(CGRectMake(6, 12, 2, 12), NULL);
            CGContextAddPath(context, line0);
            CGContextFillPath(context);
            CGPathRelease(line0);
            
            CGPathRef line1 = CGPathCreateWithRect(CGRectMake(self.bounds.size.width - 2 - 6, 12, 2, 12), NULL);
            CGContextAddPath(context, line1);
            CGContextFillPath(context);
            CGPathRelease(line1);
        } else {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            
            CGPathRef line0 = CGPathCreateWithRect(CGRectMake(3.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line0);
            CGContextFillPath(context);
            CGPathRelease(line0);
            
            CGPathRef line1 = CGPathCreateWithRect(CGRectMake(5.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line1);
            CGContextFillPath(context);
            CGPathRelease(line1);
            
            CGPathRef line2 = CGPathCreateWithRect(CGRectMake(7.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line2);
            CGContextFillPath(context);
            CGPathRelease(line2);
            
            CGPathRef line3 = CGPathCreateWithRect(CGRectMake(self.bounds.size.width - 1 - 3.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line3);
            CGContextFillPath(context);
            CGPathRelease(line3);
            
            CGPathRef line4 = CGPathCreateWithRect(CGRectMake(self.bounds.size.width - 1 - 5.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line4);
            CGContextFillPath(context);
            CGPathRelease(line4);
            
            CGPathRef line5 = CGPathCreateWithRect(CGRectMake(self.bounds.size.width - 1 - 7.5, 8, 1, 12), NULL);
            CGContextAddPath(context, line5);
            CGContextFillPath(context);
            CGPathRelease(line5);
        }
    }
}

#pragma mark - Events

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    if (UIGestureRecognizerStateBegan == pan.state) {
        self.playVibrateLimitFlag = NO;
        self.originalFrame = self.frame;
        CGPoint touchPoint = [pan locationInView:self];
        if (touchPoint.x < 30 && touchPoint.x > -12) {
            self.touchPosition = 0; // head
        } else if (touchPoint.x > CGRectGetWidth(self.bounds) - 30 && touchPoint.x < CGRectGetWidth(self.bounds) + 12) {
            self.touchPosition = 2; // tail
        } else if (touchPoint.x >= 30 && touchPoint.x <= CGRectGetWidth(self.bounds) - 30){
            self.touchPosition = 1; // body
        } else {
            self.touchPosition = -1;
        }
        if ([self.panTouchPositionProhibits containsObject:@(self.touchPosition)]) {
            self.touchPosition = -1;
            return;
        }
        if ([self.delegate respondsToSelector:@selector(rangeView:willChangeFrameWithType:)]) {
            [self.delegate rangeView:self willChangeFrameWithType:self.touchPosition];
        }
    } else if (UIGestureRecognizerStateChanged == pan.state) {
        if (self.touchPosition == -1) {
            return;
        }
        CGRect rect = self.originalFrame;
        const CGFloat left = rect.origin.x;
        const CGFloat right = rect.origin.x + rect.size.width;
        const CGFloat translation = [pan translationInView:self.superview].x;
        if (self.touchPosition == 0) { // head
            if (left + translation < self.leftBoundary) {
                rect.origin.x = self.leftBoundary;
                rect.size.width = right - self.leftBoundary;
            } else if (rect.size.width - translation < self.minLength) {
                rect.origin.x = right - self.minLength;
                rect.size.width = self.minLength;
                [self playVibrate]; // 向右滑动时，小于允许的最小间距，震动
            } else {
                rect.origin.x += translation;
                rect.size.width -= translation;
            }
        } else if (self.touchPosition == 1) { // body
            if (left + translation < self.leftBoundary) {
                rect.origin.x = self.leftBoundary;
            } else if (right + translation > self.rightBoundary) {
                rect.origin.x = self.rightBoundary - rect.size.width;
            } else {
                rect.origin.x += translation;
            }
        } else if (self.touchPosition == 2) { // tail
            if (rect.size.width + translation < self.minLength) {
                rect.size.width = self.minLength;
                [self playVibrate]; // 向左滑动时，小于允许的最小间距，震动
            } else if (right + translation > self.rightBoundary) {
                rect.size.width = self.rightBoundary - left;
            } else {
                rect.size.width += translation;
            }
        }
        CGFloat couldChangeWidth = -1;
        if ([self.delegate respondsToSelector:@selector(rangeViewFrame:couldChangeFrameWithType:)]) {
            couldChangeWidth = [self.delegate rangeViewFrame:rect couldChangeFrameWithType:self.touchPosition];
            if (couldChangeWidth > 0) {
                if (self.touchPosition == 0) {
                    rect.origin.x = self.frame.origin.x + self.frame.size.width - couldChangeWidth;
                }
                rect.size.width = couldChangeWidth;
                self.frame = rect;
                if ([self.delegate respondsToSelector:@selector(rangeView:didChangeFrameWithType:)]) {
                    [self.delegate rangeView:self didChangeFrameWithType:self.touchPosition];
                }
            }
        }
        if (couldChangeWidth < 0) {
            self.frame = rect;
            if ([self.delegate respondsToSelector:@selector(rangeView:didChangeFrameWithType:)]) {
                [self.delegate rangeView:self didChangeFrameWithType:self.touchPosition];
            }
        }
    } else if (UIGestureRecognizerStateCancelled == pan.state ||
               UIGestureRecognizerStateEnded == pan.state) {
        if (self.touchPosition == -1) {
            return;
        }
        if (!CGRectEqualToRect(self.frame, self.originalFrame)) {
            if ([self.delegate respondsToSelector:@selector(rangeView:didFinishChangeFrameWithType:)]) {
                [self.delegate rangeView:self didFinishChangeFrameWithType:self.touchPosition];
            }
        }
    }
}

- (void)playVibrate
{
    if (self.playVibrateLimitFlag == NO) {
        if (@available(iOS 10.0, *)) {
            if ([UIDevice acc_isBetterThanIPhone7]) {
                if (!self.feedBackGenertor) {
                    self.feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                }
                [self.feedBackGenertor impactOccurred];

            }
        }
        CGFloat minGap = 1.f;
        NSString *toastStr = [NSString stringWithFormat:ACCLocalizedString(@"upload_min_duration_toast", @"最小可选择%.1f秒"),minGap];
        [ACCToast() show:toastStr];
        self.playVibrateLimitFlag = YES;
    }
}

#pragma mark - AWEVideoEffectRangeProtocol

- (void)updateNormalizedRangeFrom:(CGFloat)start to:(CGFloat)end
{
    CGFloat extraPadding = 12;
    self.frame = CGRectMake(start * self.containerSize.width - extraPadding, 0, (end - start) * self.containerSize.width + 2 * extraPadding, self.containerSize.height);
}

- (void)removeFromContainer
{
    [self removeFromSuperview];
}

@end
