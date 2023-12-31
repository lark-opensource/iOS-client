//
//  HTSVideoProgressView.m
//  Pods
//
//  Created by 何海 on 16/7/4.
//
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "HTSVideoProgressView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEStudioProgressView ()

@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation AWEStudioProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.rounded = YES;
        [self shapeLayer].lineCap = kCALineCapButt;
        [self shapeLayer].strokeStart = 0.0;
        [self shapeLayer].strokeEnd = 0.0;
    }
    return self;
}

- (CAShapeLayer *)maskLayer
{
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
    }
    return _maskLayer;
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)self.layer;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
    _progressTintColor = progressTintColor;
    [self shapeLayer].strokeColor = progressTintColor.CGColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    _trackTintColor = trackTintColor;
    [self shapeLayer].backgroundColor = trackTintColor.CGColor;
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (!animated) {
        [[self shapeLayer] removeAllAnimations];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self shapeLayer].strokeEnd = progress;
        [CATransaction commit];
    } else {
        CABasicAnimation * basicAnimation = [[CABasicAnimation alloc] init];
        basicAnimation.keyPath = @"strokeEnd";
        basicAnimation.removedOnCompletion = NO;
        basicAnimation.fillMode = kCAFillModeForwards;
        basicAnimation.toValue = @(progress);
        basicAnimation.duration = 0.25;
        [[self shapeLayer] addAnimation:basicAnimation forKey:nil];
    }
}

- (void)setRounded:(BOOL)rounded
{
    _rounded = rounded;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.bounds;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, frame.size.height / 2)];
    [path addLineToPoint:CGPointMake(frame.size.width, frame.size.height / 2)];
    [self shapeLayer].path = path.CGPath;
    [self shapeLayer].lineWidth = frame.size.height;
    
    if (self.rounded) {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(frame.size.height * 0.5, frame.size.height * 0.5)];
        self.maskLayer.path = maskPath.CGPath;
        [self shapeLayer].mask = self.maskLayer;
    } else {
        [self shapeLayer].mask = nil;
    }
}

@end


@interface HTSVideoProgressView ()

@property (nonatomic, strong) NSMutableArray *markedProgresses;
@property (nonatomic, strong) NSMutableArray *markedProgressViews;
@property (nonatomic, strong) UIImage *markImage;

@property (nonatomic, strong) UIImageView *standardDurationLocation;
@property (nonatomic, assign) BOOL showStandardDurationLocation;
@property (nonatomic, assign) double standardDuration;
@property (nonatomic, strong) UIImageView *blinkingView;
@property (nonatomic, assign) CGFloat markWidth;

@end

@implementation HTSVideoProgressView

- (CGFloat)markWidth
{
    if (_markWidth == 0) {
        _markWidth = 2;
    }
    return _markWidth;
}

- (void)loadStandardDurationIndicatorIfNeed
{
    if (_standardDurationLocation) {
        return;
    }

    _standardDurationLocation = [[UIImageView alloc] initWithImage:self.markImage];
    _standardDurationLocation.contentMode = UIViewContentModeScaleToFill;
    _standardDurationLocation.frame = CGRectMake(0, 0, self.markWidth, 6);
    _standardDurationLocation.hidden = YES;
    [self addSubview:_standardDurationLocation];
}

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration
{
    self.standardDuration = standardDuration;

    BOOL needShow = longVideoEnabled && maxDuration > standardDuration && standardDuration > 0 && maxDuration > 30;
    if (needShow) {
        [self loadStandardDurationIndicatorIfNeed];

        self.standardDurationLocation.acc_left = ACC_SCREEN_WIDTH * standardDuration / maxDuration;
        // 镜像语言进度条还是由左往右
        self.standardDurationLabel.acc_centerX = self.standardDurationLocation.acc_centerX + 8;
        self.standardDurationLabel.acc_top = self.standardDurationLocation.acc_bottom + 7;
    
        self.standardDurationLocation.alpha = 1.0;
        self.standardDurationLabel.alpha = 1.0;
        self.standardDurationLocation.hidden = NO;
        self.standardDurationLabel.hidden = NO;
        self.showStandardDurationLocation = YES;
    } else {
        self.standardDurationLocation.alpha = 0.0;
        self.standardDurationLabel.alpha = 0.0;
        self.standardDurationLocation.hidden = YES;
        self.standardDurationLabel.hidden = YES;
        self.showStandardDurationLocation = NO;
    }
}

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated
{
    [super setProgress:progress animated:animated];

    if (self.showStandardDurationLocation) {
        if (duration > self.standardDuration) {
            if (!self.standardDurationLocation.hidden) {
                [UIView animateWithDuration:0.15 animations:^{
                    self.standardDurationLocation.alpha = 0.0;
                    self.standardDurationLabel.alpha = 0.0;
                } completion:^(BOOL finished) {
                    self.standardDurationLocation.hidden = YES;
                    self.standardDurationLabel.hidden = YES;
                }];
            }
        } else {
            if (self.standardDurationLocation.hidden) {
                [UIView animateWithDuration:0.15 animations:^{
                    self.standardDurationLocation.alpha = 1.0;
                    self.standardDurationLabel.alpha = 1.0;
                } completion:^(BOOL finished) {
                    self.standardDurationLocation.hidden = NO;
                    if (!self.hidden) {
                        self.standardDurationLabel.hidden = NO;
                    }
                }];
            }
        }
    }
}


- (void)layoutSegments:(NSArray*)segments toalTime:(CGFloat)totalTime {
    [self.markedProgressViews enumerateObjectsUsingBlock:^(UIView*  v, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < segments.count) {
            if ([segments[idx] floatValue] < 0.0001 || totalTime <= 0 || isnan(totalTime)) {
                return;
            }
            ACCMasReMaker(v, {
                make.width.equalTo(@(2));
                make.top.equalTo(self.mas_top);
                make.height.equalTo(self.mas_height);
                make.centerX.equalTo(self.mas_right).multipliedBy([segments[idx] floatValue] / totalTime);
            });
        }
    }];
}


- (void)updateViewWithTimeSegments:(NSArray *)segments totalTime:(CGFloat)totalTime
{
    if (segments.count == self.markedProgresses.count || isnan(totalTime) || totalTime <= 0) {
        return; 
    }

    if (segments.count > self.markedProgresses.count) {
        for (NSInteger i = self.markedProgresses.count; i<segments.count; i++) {
            [self addMarkedProgress:@([segments[i] floatValue]/totalTime)];
        }
    } else if (segments.count < self.markedProgresses.count) {
        NSRange range = NSMakeRange(segments.count, self.markedProgresses.count - segments.count);
        NSArray *toRemove = [self.markedProgressViews subarrayWithRange:range];
        [toRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.markedProgresses removeObjectsInRange:range];
        [self.markedProgressViews removeObjectsInRange:range];
    }

    if (self.standardDurationLocation) {
        [self bringSubviewToFront:self.standardDurationLocation];
        [self bringSubviewToFront:self.standardDurationLabel];
    }
}

- (void)addMarkedProgress:(NSNumber *)currentProgress
{
    if (isnan([currentProgress doubleValue])) {
        return;
    }
    NSNumber *lastProgress = [self.markedProgresses lastObject];
    if (![lastProgress isEqualToNumber:currentProgress]) {
        [self.markedProgresses addObject:currentProgress];
        UIImageView *imageView = [self newMarkAtProgress:currentProgress.doubleValue];
        if (currentProgress.doubleValue >= 0.99999 && self.isRightEnd) {
            [imageView setHidden:YES];
        }
        [self.markedProgressViews addObject:imageView];
    }

    if (self.standardDurationLocation) {
        [self bringSubviewToFront:self.standardDurationLocation];
        [self bringSubviewToFront:self.standardDurationLabel];
    }
}

- (UIImageView *)newMarkAtProgress:(CGFloat)progress
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.markImage];
    imageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:imageView];
    
    CGFloat ratio = progress;
    if (self.acc_width > 0 ) {
        CGFloat leftInset = self.isLeftEnd ? self.markWidth * 0.5 : 0;
        CGFloat rightInset = self.isRightEnd ? self.markWidth * 0.5 : 0;
        ratio = (progress * (self.acc_width - leftInset - rightInset) + leftInset) / self.acc_width;
    }
    ratio = ratio ?: 0.0001; // avoid crash when mas_contraint multiplied by 0
    ACCMasMaker(imageView, {
        make.width.equalTo(@(self.markWidth));
        make.top.equalTo(self.mas_top);
        make.height.equalTo(self.mas_height);
        make.centerX.equalTo(self.mas_right).multipliedBy(ratio);
    });
    return imageView;
}

- (void)blinkMarkAtCurrentProgress:(BOOL)on
{
    if (self.markedProgressViews.count == 0) {
        return;
    }
    if (on) {
        self.blinkingView = self.markedProgressViews.lastObject;
        if (!self.blinkingView) {
            return;
        }
        self.blinkingView.alpha = 0;
        [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
            self.blinkingView.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    } else if (self.blinkingView) {
        [self.blinkingView.layer removeAllAnimations];
        self.blinkingView = nil;
    }
}

- (void)blinkProgressBarOnce {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    animation.fromValue = (id)self.progressTintColor.CGColor;
    animation.toValue = (id)self.tintColor.CGColor;
    animation.duration = 0.35;
    animation.repeatCount = 1;
    animation.autoreverses = YES;
    [[self shapeLayer] addAnimation:animation forKey:@"blinkStrokeColor"];
}

- (UIImage *)markImage
{
    if (!_markImage) {
        _markImage = [HTSVideoProgressView imageFromColor:self.tintColor];
    }
    return _markImage;
}

+ (UIImage *)imageFromColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Private

- (NSMutableArray *)markedProgresses
{
    if (!_markedProgresses) {
        _markedProgresses = [NSMutableArray arrayWithCapacity:5];
    }
    return _markedProgresses;
}

- (NSMutableArray *)markedProgressViews
{
    if (!_markedProgressViews) {
        _markedProgressViews = [NSMutableArray arrayWithCapacity:5];
    }
    return _markedProgressViews;
}

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration
{
    [super acc_fadeShow:show duration:duration];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (show) {
            self.standardDurationLabel.alpha = 1.0f;
        } else {
            self.standardDurationLabel.alpha = 0.0f;
        }
    } completion:nil];
}

@end
