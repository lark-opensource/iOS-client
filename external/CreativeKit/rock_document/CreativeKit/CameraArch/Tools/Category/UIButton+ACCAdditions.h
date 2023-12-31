//
//  UIButton+ACCAdditions.h
//  Pods
//
//  Created by Paul on 2017/11/7.
//

#import <UIKit/UIKit.h>

typedef void (^ACCUIButtonTapBlock)(void);

@interface UIButton (CameraClient)

@property (nonatomic, assign) UIEdgeInsets acc_hitTestEdgeInsets;
@property (nonatomic, copy) void(^acc_disableBlock)(void);
@property (nonatomic, copy) ACCUIButtonTapBlock tap_block;

- (void)acc_centerTitleAndImageWithSpacing:(CGFloat)spacing;
- (void)acc_centerTitleAndImageWithSpacing:(CGFloat)spacing contentEdgeInsets:(UIEdgeInsets)contentEdgeInsets;
- (void)acc_centerButtonAndImageWithSpacing:(CGFloat)spacing;

- (void)acc_setBackgroundColor:(UIColor *)color forState:(UIControlState)state;

- (void)acc_setBorderColor:(UIColor *)color forState:(UIControlState)state;

- (void)acc_setAlpha:(CGFloat)alpha forState:(UIControlState)state;

- (void)acc_setAlphaTransitionTime:(NSTimeInterval)time;

@end
