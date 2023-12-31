//
//  AWEAnimatedRecordLayerProtocol.h
//  Pods
//
// Created by Hao Yipeng on May 23, 2019
//

#ifndef AWEAnimatedRecordLayerProtocol_h
#define AWEAnimatedRecordLayerProtocol_h

@protocol AWEAnimatedRecordLayerProtocol <NSObject>

@property (nonatomic, strong) CALayer *maskLayer;

- (instancetype)initWithFrame:(CGRect)frame;

/**
 Set the initial skeleton ratio
 
 @param ratio skeleton ratio
 */
- (void)setInitialHollowRatio:(CGFloat)ratio;
- (CABasicAnimation *)createColorChangeAnimationWithColor:(UIColor *)color duration:(CFTimeInterval)duration;
- (CABasicAnimation *)createHollowOutAnimationWithRatio:(CGFloat)ratio duration:(CFTimeInterval)duration;
- (CABasicAnimation *)createScaleAnimationWithRatio:(CGFloat)ratio duration:(CFTimeInterval)duration;
- (CABasicAnimation *)createBreathingAnimationWithFromRatio:(CGFloat)startRatio toRatio:(CGFloat)toRatio duration:(CFTimeInterval)duration;
- (CABasicAnimation *)createCornerRadiusAnimationWithCornerRadius:(CGFloat)cornerRadius duration:(CFTimeInterval)duration;

@end


#endif /* AWEAnimatedRecordLayerProtocol_h */
