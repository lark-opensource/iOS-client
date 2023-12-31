//
//  AWERangeSlider.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/3/24.
//

#import "AWESlider.h"

@interface AWERangeSlider : AWESlider
@property (nonatomic, strong, readonly) UIView *defaultIndicator;
@property (nonatomic, strong, readonly) UIView *maskView;
@property (nonatomic, strong, readonly) UIView *backgroundTrackView;

@property (nonatomic, assign) BOOL showDefaultIndicator;
@property (nonatomic, assign) BOOL enableSliderAdsorbToDefault;
@property (nonatomic, assign) CGFloat defaultIndicatorPosition;
@property (nonatomic, assign) CGFloat minimumAdsorptionDistance; // (0,1)
@property (nonatomic, assign) CGFloat originPosition;
@property (nonatomic, strong) UIColor *rangeMinimumTrackColor;
@property (nonatomic, strong) UIColor *rangeMaximumTrackColor;

@end
