//
//  ACCCutSameCropMaskView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutSameCropMaskView : UIView

@property (nonatomic, assign) CGSize frameSize;

@property (nonatomic, assign) CGPoint offset;

- (instancetype)initWithFrame:(CGRect)frame isBlackMask:(BOOL)isBlackMask;

- (void)animateForBlurEffect:(BOOL)blur animate:(BOOL)animate;

@end

NS_ASSUME_NONNULL_END
