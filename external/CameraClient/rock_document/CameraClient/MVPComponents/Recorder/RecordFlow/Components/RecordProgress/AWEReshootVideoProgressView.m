//
//  AWEReshootVideoProgressView.m
//  AWEStudio
//
//  Created by Shen Chen on 2019/10/28.
//

#import "AWEReshootVideoProgressView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "HTSVideoProgressView.h"
#import <CreationKitInfra/UIView+ACCRTL.h>

@interface AWEReshootVideoProgressView ()
@property (nonatomic, strong) HTSVideoProgressView *progressView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *container;
@property (nonatomic, assign, readwrite) float progress;
@end

@implementation AWEReshootVideoProgressView

@synthesize originTrackTintColor = _originTrackTintColor;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.accrtl_viewType = ACCRTLViewTypeNormalWithAllDescendants;
    UIColor *tintColor = ACCResourceColor(ACCColorPrimary);
    self.container = [UIView new];
    self.container.backgroundColor = UIColor.clearColor;
    self.container.frame = CGRectMake(8, 0, self.acc_width - 16, 6);
    self.container.layer.cornerRadius = 3;
    self.container.clipsToBounds = YES;
    [self addSubview:self.container];
    
    self.backgroundView = [UIView new];
    self.backgroundView.backgroundColor = [tintColor colorWithAlphaComponent:0.34];
    self.backgroundView.frame = self.container.bounds;
    [self.container addSubview:self.backgroundView];
    
    self.progressView = [[HTSVideoProgressView alloc] init];
    self.progressView.rounded = NO;
    [self.container addSubview:self.progressView];
    self.progressView.progressTintColor = tintColor;
    _originTrackTintColor = self.progressView.trackTintColor = [UIColor acc_colorWithColorName:ACCUIColorSDInverse];
    self.progressView.tintColor = [UIColor acc_colorWithColorName:ACCUIColorIconInverse];
    
    [self setReshootTimeFrom:0.0 to:1.0 totalDuration:1.0];
}

#pragma mark - Public

- (void)setReshootTimeFrom:(NSTimeInterval)startTime to:(NSTimeInterval)endTime totalDuration:(NSTimeInterval)totalDuration
{
    CGFloat x = startTime / totalDuration * self.container.acc_width;
    CGFloat w = (endTime - startTime) / totalDuration * self.container.acc_width;
    self.progressView.frame = CGRectMake(x, 0, w, self.container.acc_height);
    CGRect maskFrame = [self.progressView convertRect:self.progressView.bounds toView:self.backgroundView];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathAddRect(maskPath, nil, self.backgroundView.bounds);
    CGPathAddRect(maskPath, nil, maskFrame);
    [maskLayer setPath:maskPath];
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    CGPathRelease(maskPath);
    self.backgroundView.layer.mask = maskLayer;
    self.progressView.isLeftEnd = startTime == 0;
    self.progressView.isRightEnd = endTime == totalDuration;
}

- (void)setProgress:(float)progress duration:(double)duration animated:(BOOL)animated {
    [self.progressView setProgress:progress duration:duration animated:animated];
    self.progress = progress;
}

- (void)updateViewWithTimeSegments:(NSArray *)segments
                         totalTime:(CGFloat)totalTime {
    [self.progressView updateViewWithTimeSegments:segments totalTime:totalTime];
}

- (void)updateStandardDurationIndicatorWithLongVideoEnabled:(BOOL)longVideoEnabled
                                           standardDuration:(double)standardDuration
                                                maxDuration:(double)maxDuration {
    [self.progressView updateStandardDurationIndicatorWithLongVideoEnabled:longVideoEnabled
                                                          standardDuration:standardDuration
                                                               maxDuration:maxDuration];
}

- (void)blinkMarkAtCurrentProgress:(BOOL)on
{
    [self.progressView blinkMarkAtCurrentProgress:on];
}

- (void)blinkReshootProgressBarOnce
{
    [self.progressView blinkProgressBarOnce];
}

#pragma mark - AWEVideoProgressViewColorState

- (UIColor *)trackTintColor
{
    return self.progressView.trackTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    self.progressView.trackTintColor = trackTintColor;
}

@end
