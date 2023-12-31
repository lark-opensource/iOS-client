//
//  ACCLightningRecordRingView.m
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <CreativeKit/UIColor+CameraClientResource.h>

#import "ACCLightningRecordRingView.h"

#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>

static const CGFloat kProgressRingWidth = 4;
static const CGFloat kProgressRingWidthStory = 4;

static const CGFloat kDiameter1 = 76 - kProgressRingWidth; // ACCRecordButtonBegin
static const CGFloat kDiameter2 = 130 - kProgressRingWidth; // ACCRecordButtonRecording
static const CGFloat kDiameter3 = 100 - kProgressRingWidth; // ACCRecordButtonPaused

@interface ACCLightningRecordRingView ()
// whiteLayer + whitePath 暂停时的边界
@property (nonatomic, strong) CAShapeLayer *whiteLayer;

// reshoot with range limit
@property (nonatomic, strong) CAShapeLayer *rangeLayer;
@property (nonatomic, assign) CGFloat startLimit;
@property (nonatomic, assign) CGFloat endLimit;

@end

@implementation ACCLightningRecordRingView

@synthesize state = _state;
@synthesize recordMode = _recordMode;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectMake(0, 0, kDiameter1, kDiameter1)]) {
        CAShapeLayer *layer = (CAShapeLayer *)self.layer;
        layer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(kDiameter1 / 2, kDiameter1 / 2) radius:kDiameter1 / 2 startAngle:-M_PI_2 endAngle:3 * M_PI_2 clockwise:YES].CGPath;
        layer.fillColor = [UIColor clearColor].CGColor;
        layer.strokeColor = [UIColor whiteColor].CGColor;
        layer.lineWidth = kProgressRingWidth;

        _rangeLayer = [CAShapeLayer layer];
        _rangeLayer.frame = self.bounds;
        _rangeLayer.fillColor = [UIColor clearColor].CGColor;
        _rangeLayer.strokeColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.34].CGColor;
        _rangeLayer.lineWidth = kProgressRingWidth;
        _rangeLayer.hidden = YES;
        [self.layer addSublayer:_rangeLayer];

        _whiteLayer = [CAShapeLayer layer];
        _whiteLayer.frame = self.bounds;
        _whiteLayer.fillColor = [UIColor clearColor].CGColor;
        _whiteLayer.strokeColor = [UIColor whiteColor].CGColor;
        _whiteLayer.lineWidth = kProgressRingWidth;
        [self.layer addSublayer:_whiteLayer];

        [self resetWhitePath];

        _marks = [NSArray array];

        _startLimit = 0.0;
        _endLimit = 1.0;
    }
    return self;
}

- (UIColor *)progressColor {
    if (_progressColor == nil) {
        return ACCResourceColor(ACCUIColorConstPrimary);
    }
    return _progressColor;
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer
{
    return (CAShapeLayer *)self.layer;
}

- (void)setState:(ACCRecordButtonState)state
{
    [self shapeLayer].hidden = NO;
    self.alpha = 1;

    switch (state) {
        case ACCRecordButtonBegin: {
            [self shapeLayer].affineTransform = CGAffineTransformIdentity;
            [self shapeLayer].strokeColor = [UIColor whiteColor].CGColor;
            [self shapeLayer].strokeEnd = 1;
            [self shapeLayer].lineWidth = self.recordMode.isStoryStyleMode ? kProgressRingWidthStory : kProgressRingWidth;
            self.progress = 0;
            [self resetWhitePath];
            break;
        }
        case ACCRecordButtonRecording: {
            if (ACCConfigBool(kConfigBool_longtail_shoot_animation) && self.recordMode.isStoryStyleMode) {
                [self shapeLayer].hidden = YES;
            }

            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter2 / kDiameter1;
                [self shapeLayer].affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
                [self shapeLayer].strokeColor = self.progressColor.CGColor;
                [self shapeLayer].strokeEnd = self.progress;
                [self shapeLayer].lineWidth = kProgressRingWidth / scale;
            }];
            break;
        }
        case ACCRecordButtonPaused: {
            [self addSeparator:self.progress]; // 冗余，但 flowService 回调太慢，回调会将其覆盖
            [UIView animateWithDuration:kACCRecordAnimateDuration animations:^{
                CGFloat scale = kDiameter3 / kDiameter1;
                [self shapeLayer].affineTransform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
                [self shapeLayer].strokeColor = self.progressColor.CGColor;
                [self shapeLayer].strokeStart = self.startLimit;
                [self shapeLayer].strokeEnd = self.progress;
                [self shapeLayer].lineWidth = kProgressRingWidth / scale;
            }];
            break;
        }
        case ACCRecordButtonPicture: {
            self.transform = CGAffineTransformIdentity;
            // no further operation
            break;
        }
        default:
            break;
    }
    _state = state;
    self.whiteLayer.lineWidth = [self shapeLayer].lineWidth;
}

- (void)addSeparator:(CGFloat)progress
{
    CGFloat start = -M_PI_2 + progress * M_PI * 2;
    CGMutablePathRef whitePath = (CGMutablePathRef)self.whiteLayer.path;
    CGPathAddPath(whitePath, NULL, [UIBezierPath bezierPathWithArcCenter:CGPointMake(kDiameter1 / 2, kDiameter1 / 2) radius:kDiameter1 / 2 startAngle:start endAngle:start + 0.05 clockwise:YES].CGPath);
    self.whiteLayer.path = whitePath;
}

- (CGFloat)convertProgress:(CGFloat)progress {
    // reshoot 限制范围时，progress 相应缩小
    if (self.startLimit > 0 || self.endLimit < 1) {
        return (self.endLimit - self.startLimit) * progress + self.startLimit;
    }
    return progress;
}

// 内部保存的 progress 对应整个圆 [0, 1] => [-M_PI_2, 3 * M_PI_2]
// 外部传入的 progress 在 reshoot 模式下只映射到一个扇区
- (void)setProgress:(CGFloat)progress {
    _progress = [self convertProgress:progress];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    progress = MIN(1, MAX(0, progress));

    if (self.state != ACCRecordButtonRecording && self.state !=  ACCRecordButtonPaused) {
        self.progress = progress;
        return;
    }

    NSString *animationKey = @"progress";
    [[self shapeLayer] removeAnimationForKey:animationKey];

    __auto_type block = ^{
        self.progress = progress;
        [self shapeLayer].strokeStart = self.startLimit;
        [self shapeLayer].strokeEnd = self.progress;
    };
    if (animated) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(self.progress);
        block();
        animation.toValue = @(self.progress);
        animation.duration = kACCRecordAnimateDuration;
        [[self shapeLayer] addAnimation:animation forKey:animationKey];
    } else {
        block();
    }
}

- (void)resetWhitePath
{
    CGPathRef whitePath = CGPathCreateMutable();
    self.whiteLayer.path = whitePath;
    CGPathRelease(whitePath);
}

- (void)setMarks:(NSArray<NSNumber *> *)marks
{
    [self resetWhitePath];

    for (NSNumber *mark in marks) {
        [self addSeparator:[self convertProgress:MIN(1, MAX(0, mark.floatValue))]];
    }

    if (self.endLimit < 1) {
        [self addSeparator:1]; // 100%
    }
}

// reshoot 时前后的边界, [0-start][-reshoot-][end-1.0]
- (void)addRangeIndicatorWithStart:(float)start end:(float)end {
    self.startLimit = start;
    self.endLimit = end;

    self.progress = 0;
    self.state = ACCRecordButtonPaused; // [0-start] 的末尾 addSeparator

    // [end-1.0] 的末尾 100% addSeparator
    if (self.endLimit < 1) {
        [self addSeparator:1];
    }

    self.rangeLayer.hidden = NO;
    self.rangeLayer.lineWidth = [self shapeLayer].lineWidth;

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithArcCenter:CGPointMake(kDiameter1 / 2, kDiameter1 / 2) radius:kDiameter1 / 2 startAngle:-M_PI_2 endAngle:-M_PI_2 + 2 * M_PI * start clockwise:YES].CGPath);
    CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithArcCenter:CGPointMake(kDiameter1 / 2, kDiameter1 / 2) radius:kDiameter1 / 2 startAngle:-M_PI_2 + 2 * M_PI * end endAngle:3 * M_PI_2 clockwise:YES].CGPath);
    self.rangeLayer.path = path;
    CGPathRelease(path);
}

@end
