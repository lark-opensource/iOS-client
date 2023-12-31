//
//  AWERangeSlider.m
//  CameraClient
//
//  Created by HuangHongsen on 2020/3/24.
//

#import "UIView+ACCMasonry.h"
#import "AWERangeSlider.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kAWERangeSliderDefaultIndicatorEdge = 6.f;
static const CGFloat kAWERangeSliderMaskViewHeight = 3.f;

@interface AWERangeSlider()
@property (nonatomic, strong, readwrite) UIView *defaultIndicator;
@property (nonatomic, strong, readwrite) UIView *maskView;
@property (nonatomic, strong, readwrite) UIView *backgroundTrackView;
@end

@implementation AWERangeSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.minimumTrackTintColor = UIColor.clearColor;
        self.maximumTrackTintColor = UIColor.clearColor;
        _minimumAdsorptionDistance = 0.05;
        _rangeMinimumTrackColor = ACCResourceColor(ACCColorPrimary);
        _rangeMaximumTrackColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        
        _backgroundTrackView = [[UIView alloc] init];
        _backgroundTrackView.backgroundColor = self.rangeMaximumTrackColor;
        _backgroundTrackView.layer.cornerRadius = kAWERangeSliderMaskViewHeight / 2.f;
        _backgroundTrackView.layer.masksToBounds = YES;
        _backgroundTrackView.userInteractionEnabled = NO;
        
        _defaultIndicator = [[UIView alloc] init];
        _defaultIndicator.layer.cornerRadius = kAWERangeSliderDefaultIndicatorEdge / 2;
        _defaultIndicator.layer.masksToBounds = YES;
        _defaultIndicator.backgroundColor = [UIColor whiteColor];
        _defaultIndicator.hidden = YES;
        _defaultIndicator.userInteractionEnabled = NO;
        
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = self.rangeMinimumTrackColor;
        _maskView.layer.cornerRadius = kAWERangeSliderMaskViewHeight / 2.f;
        _maskView.layer.masksToBounds = YES;
        _maskView.userInteractionEnabled = NO;
        
        [self addSubview:_backgroundTrackView];
        [self sendSubviewToBack:_backgroundTrackView];
        [self insertSubview:_maskView aboveSubview:_backgroundTrackView];
        [self insertSubview:_defaultIndicator aboveSubview:_maskView];
        
        
        ACCMasMaker(_backgroundTrackView, {
            make.center.width.equalTo(self);
            make.height.equalTo(@(kAWERangeSliderMaskViewHeight));
        });
        
        ACCMasMaker(_defaultIndicator, {
            make.center.equalTo(self);
            make.width.height.equalTo(@(kAWERangeSliderDefaultIndicatorEdge));
        });
        
        ACCMasMaker(_maskView, {
            make.center.equalTo(self);
            make.width.equalTo(@0);
            make.height.equalTo(@(kAWERangeSliderMaskViewHeight));
        });
    }
    return self;
}

- (void)setShowDefaultIndicator:(BOOL)showDefaultIndicator
{
    _showDefaultIndicator = showDefaultIndicator;
    self.defaultIndicator.hidden = !showDefaultIndicator;
}

- (void)setDefaultIndicatorPosition:(CGFloat)defaultIndicatorPosition
{
    _defaultIndicatorPosition = defaultIndicatorPosition;
    ACCMasReMaker(self.defaultIndicator, {
        make.centerX.equalTo(self.mas_right).multipliedBy(defaultIndicatorPosition);
        make.centerY.equalTo(self.maskView);
        make.width.height.equalTo(@(kAWERangeSliderDefaultIndicatorEdge));
    });
}

- (void)setRangeMaximumTrackColor:(UIColor *)rangeMaximumTrackColor
{
    _rangeMaximumTrackColor = rangeMaximumTrackColor;
    _backgroundTrackView.backgroundColor = rangeMaximumTrackColor;
}

- (void)setRangeMinimumTrackColor:(UIColor *)rangeMinimumTrackColor
{
    _rangeMinimumTrackColor = rangeMinimumTrackColor;
    _maskView.backgroundColor = rangeMinimumTrackColor;
}

- (void)setEnableSliderAdsorbToDefault:(BOOL)enableSliderAdsorbToDefault
{
    if (_enableSliderAdsorbToDefault != enableSliderAdsorbToDefault) {
        _enableSliderAdsorbToDefault = enableSliderAdsorbToDefault;
        
        if (enableSliderAdsorbToDefault) {
            [self addTarget:self action:@selector(rangeSliderValueChange:forEvent:) forControlEvents:UIControlEventValueChanged];
        } else {
            [self removeTarget:self action:@selector(rangeSliderValueChange:forEvent:) forControlEvents:UIControlEventValueChanged];
        }
    }
}

- (void)setValue:(float)value
{
    [super setValue:value];
    [self p_updateRange];
}

- (void)handleValueChanged
{
    [self p_updateRange];
}

#pragma mark - Action

- (void)rangeSliderValueChange:(UISlider *)slider forEvent:(UIEvent *)event
{
    [self handleValueChanged];
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
        case UITouchPhaseStationary:
        case UITouchPhaseMoved: {
            break;
        }
        case UITouchPhaseEnded:
        case UITouchPhaseCancelled: {
            CGRect thumbImageRect = [self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value];
            CGFloat currentPosition = CGRectGetMidX(thumbImageRect) / self.bounds.size.width;
            if (fabs(currentPosition - self.defaultIndicatorPosition) <= self.minimumAdsorptionDistance) {
                CGFloat nearValue = self.minimumValue + self.defaultIndicatorPosition * (self.maximumValue - self.minimumValue);
                [self setValue:nearValue animated:YES];
                
                self.value = nearValue;
                if ([self.delegate respondsToSelector:@selector(slider:didFinishSlidingWithValue:)]) {
                    [self.delegate slider:self didFinishSlidingWithValue:nearValue];
                }
            }
            break;
        }
        default:
            break;
    }
}


#pragma mark - Private Helper

- (void)p_updateRange
{
    CGFloat currentValueRatio = (self.value - self.minimumValue) / (self.maximumValue - self.minimumValue);
    CGFloat leftRatio = MIN(currentValueRatio, self.originPosition);
    CGFloat rightRatio = MAX(currentValueRatio, self.originPosition);
    if (leftRatio == 0.f) {
        leftRatio = ACC_FLOAT_ZERO;
    }
    if (rightRatio == 0.f) {
        rightRatio = ACC_FLOAT_ZERO;
    }
    
    ACCMasReMaker(self.maskView, {
        make.left.equalTo(self.mas_right).multipliedBy(leftRatio);
        make.right.equalTo(self.mas_right).multipliedBy(rightRatio);
        make.centerY.equalTo(self.mas_centerY);
        make.height.equalTo(@(kAWERangeSliderMaskViewHeight));
    });
}

@end
