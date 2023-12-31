//
//  AWECountDownBarChartView.m
//  Pods
//
//  Created by jindulys on 2019/5/26.
//

#import "AWECountDownBarChartView.h"
#import <CreativeKit/ACCMacros.h>

@interface AWECountDownBarChartView()

@property (nonatomic, strong) CALayer *recordedLayer;

@property (nonatomic, strong) CALayer *countDownLayer;

@property (nonatomic, strong) CAShapeLayer *recordedMaskLayer;

@property (nonatomic, strong) CAShapeLayer *countDownMaskLayer;

@property (nonatomic, assign) CGFloat lastTimeBoundWidth;

@end

@implementation AWECountDownBarChartView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.drawColor = ACCUIColorFromRGBA(0xFACE15, 0.9);
        _recordedColor = ACCUIColorFromRGBA(0xbbbbbb, 1.0);
        _unReachedColor = UIColor.whiteColor;
        _recordedLayer = [[CALayer alloc] init];
        _recordedMaskLayer = [CAShapeLayer layer];
        _recordedLayer.mask = _recordedMaskLayer;
        _countDownLayer = [[CALayer alloc] init];
        _countDownMaskLayer = [CAShapeLayer layer];
        _countDownLayer.mask = _countDownMaskLayer;
        _countDownLocation = 1;
        [self.scrollView.layer addSublayer:_countDownLayer];
        [self.scrollView.layer insertSublayer:self.progressLayer above:_countDownLayer];
        [self.scrollView.layer addSublayer:_recordedLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat hasRecordedWidth = round(self.scrollView.contentSize.width * self.hasRecordedLocation);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, hasRecordedWidth, self.scrollView.contentSize.height)];
    self.recordedMaskLayer.path = path.CGPath;
    CGFloat countDownWidth = round(self.scrollView.contentSize.width * self.countDownLocation);
    path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, countDownWidth, self.scrollView.contentSize.height)];
    self.countDownMaskLayer.path = path.CGPath;
    CGFloat width = round(self.scrollView.contentSize.width * self.time);

    // handle the case when progressLayerWidth is negative and progressLayerWidth exceeds the countDownWidth
    if (width < 0) {
        width = 0;
    } else if (width > countDownWidth) {
        width = countDownWidth;
    }

    path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, width, self.scrollView.contentSize.height)];
    self.progressMaskLayer.path = path.CGPath;
    if (self.lastTimeBoundWidth != self.bounds.size.width) {
        self.lastTimeBoundWidth = self.bounds.size.width;
        if (self.updateMusicBlock) {
            self.updateMusicBlock();
        }
    }
}

- (void)addBarAtIndex:(int)i height:(CGFloat)height color:(UIColor *)color toLayer:(CALayer *)toLayer
{
    CGFloat validHeight = MIN(1, MAX(0, height));
    if (self.maxBarHeight > 0) {
        validHeight = self.maxBarHeight * validHeight;
    } else {
        validHeight = self.frame.size.height * validHeight;
    }
    if (self.minBarHeight > 0) {
        validHeight = MAX(self.minBarHeight, validHeight);
    }
    CGFloat xPos = (self.barWidth + self.space) * i + self.space;
    CGFloat yPos = (self.frame.size.height - validHeight) / 2.0;
    CALayer *barLayer = [[CALayer alloc] init];
    barLayer.backgroundColor = color.CGColor;
    barLayer.cornerRadius = self.barWidth / 2.0;
    barLayer.frame = CGRectMake(xPos, yPos, self.barWidth, validHeight);
    [toLayer addSublayer:barLayer];
}

#pragma mark - Public

- (CGFloat)barCountForFullWidth
{
    CGFloat barAreaWidth = self.barWidth + self.space;
    CGFloat counts = (CGRectGetWidth(self.bounds) - 2 * self.space) / barAreaWidth;
    // TODO(liyansong): more accurate?
    return round(counts);
}

- (void)setHasRecordedLocation:(CGFloat)hasRecordedLocation
{
    if (hasRecordedLocation != NAN && !isnan(hasRecordedLocation)) {
        _hasRecordedLocation = hasRecordedLocation;
    }
    [self setNeedsLayout];
}

- (void)setCountDownLocation:(CGFloat)countDownLocation
{
    if (countDownLocation != NAN && !isnan(countDownLocation)) {
        _countDownLocation = countDownLocation;
    }
    [self setNeedsLayout];
}

- (void)updateBarWithHeights:(NSArray<NSNumber *> *)heights
{
    for (CALayer *layer in @[self.cavasLayer, self.countDownLayer, self.recordedLayer, self.progressLayer]) {
        for (CALayer *subLayer in [layer.sublayers copy]) {
            [subLayer removeFromSuperlayer];
        }
    }
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
    CGRect layerFrame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    self.recordedLayer.frame = layerFrame;
    self.countDownLayer.frame = layerFrame;
    self.progressLayer.frame = layerFrame;
    self.cavasLayer.frame = layerFrame;
    for (int i = 0; i < heights.count; i++) {
        NSNumber *heightNumber = heights[i];
        CGFloat height = [heightNumber floatValue];
        [self addBarAtIndex:i height:height color:self.recordedColor toLayer:self.recordedLayer];
        [self addBarAtIndex:i height:height color:self.countDownColor toLayer:self.countDownLayer];
        [self addBarAtIndex:i height:height color:self.drawColor toLayer:self.progressLayer];
        [self addBarAtIndex:i height:height color:self.unReachedColor toLayer:self.cavasLayer];
    }
}

@end
