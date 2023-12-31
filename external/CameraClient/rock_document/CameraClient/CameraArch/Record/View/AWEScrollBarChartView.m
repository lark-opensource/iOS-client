//
//  AWEScrollBarChartView.m
//  Pods
//
//  Created by jindulys on 2019/5/21.
//

#import "AWEScrollBarChartView.h"

#import <Masonry/View+MASAdditions.h>

@interface AWEScrollBarChartView () <UIScrollViewDelegate>
@end

@implementation AWEScrollBarChartView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.bounces = NO;
        _cavasLayer = [[CALayer alloc] init];
        _progressLayer = [[CALayer alloc] init];
        _progressMaskLayer = [CAShapeLayer layer];
        _progressLayer.mask = _progressMaskLayer;
        _barWidth = 6.0;
        _space = 4.0;
        _time = 9;
        _maxBarHeight = -1.0;
        _minBarHeight = -1.0;
        [self setupUI];
    }
    return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:NSStringFromSelector(@selector(range))]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (HTSAudioRange)range
{
    CGFloat scale = self.maxLength / CGRectGetWidth(self.bounds);
    HTSAudioRange range;
    range.location = self.scrollView.contentOffset.x * scale;
    CGFloat diff = self.scrollView.contentSize.width - self.scrollView.contentOffset.x;
    if (diff < CGRectGetWidth(self.bounds)) {
        range.length = diff * scale;
    } else {
        range.length = self.maxLength;
    }
    return range;
}

- (void)setRangeStart:(CGFloat)location
{
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.x = location * CGRectGetWidth(self.bounds) / self.maxLength;
    if (contentOffset.x >= 0 && contentOffset.x <= self.scrollView.contentSize.width) {
        self.scrollView.contentOffset = contentOffset;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.currentLength == 0 ? 0 : round(self.scrollView.contentSize.width * self.time / self.currentLength);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, width, self.scrollView.contentSize.height)];
    self.progressMaskLayer.path = path.CGPath;
}

#pragma mark - Public

- (void)updateBarWithHeights:(NSArray<NSNumber *> *)heights
{
    for (CALayer *layer in [self.cavasLayer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    for (CALayer *layer in [self.progressLayer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    self.scrollView.contentSize = CGSizeMake((self.barWidth + self.space) * heights.count - self.space, self.frame.size.height);
    self.cavasLayer.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    self.progressLayer.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    for (int i = 0; i < heights.count; i++) {
        NSNumber *heightNumber = heights[i];
        CGFloat height = [heightNumber floatValue];
        [self addBarAtIndex:i height:height color:self.drawColor toLayer:self.progressLayer];
        [self addBarAtIndex:i height:height color:self.barDefaultColor toLayer:self.cavasLayer];
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
    CGFloat xPos = (self.barWidth + self.space) * i;
    CGFloat yPos = (self.frame.size.height - validHeight) / 2.0;
    CALayer *barLayer = [[CALayer alloc] init];
    barLayer.backgroundColor = color.CGColor;
    barLayer.cornerRadius = self.barWidth / 2.0;
    barLayer.frame = CGRectMake(xPos, yPos, self.barWidth, validHeight);
    [toLayer addSublayer:barLayer];
}

- (CGFloat)barCountForFullWidth
{
    CGFloat barAreaWidth = self.barWidth + self.space;
    CGFloat counts = CGRectGetWidth(self.bounds) / barAreaWidth;
    // TODO(liyansong): more accurate?
    return round(counts);
}

- (void)setTime:(CGFloat)time
{
    if (time != NAN && !isnan(time)) {
        _time = time;
    }
    [self setNeedsLayout];
}

#pragma mark - Protocols
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self notifyRangeChanged:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
{
    [self notifyRangeChanged:scrollView];
}

- (void)notifyRangeChanged:(UIScrollView *)scrollView
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(range))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(range))];
}

#pragma mark - Private

- (void)setupUI
{
    [self addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *maker) {
        maker.edges.equalTo(self);
    }];
    [self.scrollView.layer addSublayer:self.cavasLayer];
    [self.scrollView.layer addSublayer:self.progressLayer];
}

@end
