//
//  ACCExposureSlider.h
//  CameraClient-Pods-Aweme
//
//  Created by guoshuai on 2020/11/10.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ACCExposureSliderDirection) {
    ACCExposureSliderDirectionUp = 0,
    ACCExposureSliderDirectionRight,
    ACCExposureSliderDirectionDown,
    ACCExposureSliderDirectionLeft,
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCExposureSlider : UISlider

@property (nonatomic, assign) CGFloat trackHeight; // default 1.0.

@property (nonatomic, assign) CGSize thumbSize; // default (20, 20).

@property (nonatomic, assign, getter=isThumbBackgroundClear) BOOL thumbBackgroundClear; // default NO.

@property (nonatomic, assign) CGFloat thumbMargin; // default 5.0. Be active when thumbBackgroundClear is YES.

@property (nonatomic, assign) ACCExposureSliderDirection direction; // default ACCExposureSliderDirectionUp.

@property (nonatomic, assign) BOOL trackHidden; // default NO.

@property (nonatomic, assign) CGFloat trackAlpha; // default 1.0

+ (instancetype)new NS_UNAVAILABLE;

- (void)setThumbScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
