//
//  ACCPinStickerBottom.h
//  CameraClient
//
//  Created by resober on 2019/10/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/AWESlider.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPinStickerBottomSliderDelegate <NSObject>
- (void)sliderDidSlideToValue:(CGFloat)value;
@end


@interface ACCPinStickerBottom : NSObject
@property (nonatomic, strong) UIButton *cancel;
@property (nonatomic, strong) UIButton *confirm;
@property (nonatomic, strong) AWESlider *slider;
@property (nonatomic, assign, readonly) CGFloat contentViewHeight;
@property (nonatomic, weak) id<ACCPinStickerBottomSliderDelegate> sliderDelegate;

- (UIView *)contentView;

- (void)buildBottomViewWithContainer:(nonnull UIView *)container;

- (void)updateSlideWithStartTime:(CGFloat)startTime
                        duration:(CGFloat)duration
                        currTime:(CGFloat)currTime;
@end

NS_ASSUME_NONNULL_END
