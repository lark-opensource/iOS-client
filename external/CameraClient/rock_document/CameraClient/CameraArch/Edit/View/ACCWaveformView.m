//
//  ACCWaveformView.m
//  Pods
//
//  Created by Shen Chen on 2020/7/6.
//

#import "ACCWaveformView.h"

@interface ACCWaveformView()
@property (nonatomic, strong) NSMutableArray<CALayer *> *barLayers;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat barSpace;
@property (nonatomic, assign) CGFloat minBarHeight;
@property (nonatomic, assign) CGFloat maxBarHeight;

@end

@implementation ACCWaveformView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.barWidth = 2;
        self.barSpace = 3;
        self.maxBarHeight = 28;
        self.minBarHeight = 4;
        self.barLayers = [NSMutableArray array];
    }
    return self;
}

- (NSInteger)barCountForWidth:(CGFloat)width
{
    return (NSInteger)((width - self.barWidth) / (self.barWidth + self.barSpace)) + 1;
}

- (NSInteger)indexOfSucceedingBarWithPosition:(CGFloat)position
{
    return (position + self.barWidth * 0.5 + self.barSpace) / (self.barWidth + self.barSpace);
}

- (void)updateWithAmplitudes:(NSArray<NSNumber *> *)amplitudes
{
    for (CALayer *layer in self.barLayers) {
        [layer removeFromSuperlayer];
    }
    [self.barLayers removeAllObjects];
    if (!self.barLayers) {
        self.barLayers = [NSMutableArray arrayWithCapacity:amplitudes.count];
    }
    
    for (int i = 0; i < amplitudes.count; i++) {
        [self addBarAtIndex:i amplitude:amplitudes[i].doubleValue color:[self defaultColor]];
    }
}

- (void)setBarColor:(UIColor *)color atIndex:(NSInteger)index {
    if (index < self.barLayers.count) {
        self.barLayers[index].backgroundColor = color.CGColor;
    }
}

- (void)addBarAtIndex:(int)index amplitude:(CGFloat)amplitude color:(UIColor *)color
{
    CGFloat h = MAX(self.minBarHeight, amplitude * self.maxBarHeight);
    
    CGFloat x = index * (self.barWidth + self.barSpace);
    CGFloat y = (self.frame.size.height - h) / 2.0;
    
    CALayer *barLayer = [[CALayer alloc] init];
    barLayer.backgroundColor = color.CGColor;
    barLayer.cornerRadius = self.barWidth / 2.0;
    barLayer.frame = CGRectMake(x, y, self.barWidth, h);
    [self.layer addSublayer:barLayer];
    [self.barLayers addObject:barLayer];
}

@end
