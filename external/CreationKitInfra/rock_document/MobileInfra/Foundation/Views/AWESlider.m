//
//  AWESlider.m
//  AWEStudio
//
// Created by Hao Yipeng on July 24, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWESlider.h"
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCMacros.h>
#import "NSString+ACCAdditions.h"
#import <CreativeKit/ACCFontProtocol.h>

static NSString * const AWESliderMinimumTrackTintColor = @"awe.slider.minimum.track.tint.color";

@interface AWESlider ()

@property (nonatomic, strong, readwrite) UILabel *indicatorLabel;

@end

@implementation AWESlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.minimumTrackTintColor = ACCResourceColor(AWESliderMinimumTrackTintColor);
        self.maximumTrackTintColor = ACCResourceColor(ACCUIColorLineSecondary);
        [self setThumbImage:ACCResourceImage(@"iconBeautySliderThumb") forState:UIControlStateNormal];
        @weakify(self);
        _valueDisplayBlock = ^{
            @strongify(self);
            return [NSString stringWithFormat:@"%ld",(long)[@(roundf(self.value)) integerValue]];
        };
        _showIndicatorLabel = NO;
        _indicatorLabelBotttomMargin = 0.5;
        [self addSubview:self.indicatorLabel];
        self.indicatorLabel.hidden = YES;
    
        [self addTarget:self action:@selector(valueChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect originalBounds = [super trackRectForBounds:bounds];
    return CGRectMake(originalBounds.origin.x, originalBounds.origin.y, originalBounds.size.width, 3);
}

- (void)setShowIndicatorLabel:(BOOL)showIndicatorLabel
{
    _showIndicatorLabel = showIndicatorLabel;
    if (showIndicatorLabel) {
        [self updateIndicatorLabelDisplayAndFrame];
        self.indicatorLabel.hidden = NO;
    } else {
        self.indicatorLabel.hidden = YES;
    }
}

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    if (self.showIndicatorLabel) {
        [self updateIndicatorLabelDisplayAndFrame];
    }
}

- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    if (self.showIndicatorLabel) {
        [self updateIndicatorLabelDisplayAndFrame];
    }
}

- (UILabel *)indicatorLabel
{
    if (!_indicatorLabel) {
        _indicatorLabel = [[UILabel alloc] init];
        _indicatorLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        _indicatorLabel.font = ACCStandardFont(ACCFontClassP3, ACCFontWeightSemibold);
        _indicatorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _indicatorLabel;
}

- (UIColor *)indicatorLabelTextColor {
    return self.indicatorLabel.textColor;
}

- (void)setIndicatorLabelTextColor:(UIColor *)color {
    self.indicatorLabel.textColor = color;
}

- (void)valueChanged:(UISlider *)slider forEvent:(UIEvent *)event
{
    [self handleValueChanged];
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
        case UITouchPhaseStationary:
        case UITouchPhaseMoved: {
            [self updateIndicatorLabelDisplayAndFrame];
            [self.delegate slider:self valueDidChanged:self.value];
        }
            break;
        case UITouchPhaseEnded:
        case UITouchPhaseCancelled: {
            [self updateIndicatorLabelDisplayAndFrame];
            if ([self.delegate respondsToSelector:@selector(slider:didFinishSlidingWithValue:)]) {
                [self.delegate slider:self didFinishSlidingWithValue:self.value];
            }
            break;
        }
        default:
            break;
    }
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self updateIndicatorLabelDisplay];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.showIndicatorLabel) {
        [self updateIndicatorLabelFrame];
    }
}

- (void)updateIndicatorLabelDisplayAndFrame
{
    [self updateIndicatorLabelDisplay];
    [self updateIndicatorLabelFrame];
}

- (void)updateIndicatorLabelDisplay
{
    self.indicatorLabel.text = self.valueDisplayBlock();
}

- (void)updateIndicatorLabelFrame
{
    // Calculating the frame of sliding small circle point
    CGRect thumbImageRect = [self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value];
    UIFont *font = self.indicatorLabel.font;
    // Calculate the size of the indicatorlabel
    CGSize labelSize = [self.indicatorLabel.text acc_sizeWithFont:font width:100 maxLine:1];
    // Adjust the frame of the indicator label according to the frame of the sliding dot
    CGRect labelFrame = CGRectInset(thumbImageRect,
                                   (thumbImageRect.size.width - labelSize.width)/2,
                                   (thumbImageRect.size.height -labelSize.height)/2);
    labelFrame.origin.y = thumbImageRect.origin.y - labelSize.height - self.indicatorLabelBotttomMargin;
    self.indicatorLabel.frame = labelFrame;
}


- (void)setEnabled:(BOOL)enabled {
    if (enabled) {
        self.alpha = 1.0f;
    } else {
        self.alpha = 0.5f;
    }
    [super setEnabled:enabled];
}

#pragma mark - For Subclassing

- (void)handleValueChanged
{
    
}

@end
