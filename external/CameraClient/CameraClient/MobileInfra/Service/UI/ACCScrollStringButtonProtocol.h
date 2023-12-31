//
//  ACCScrollStringButtonProtocol.h
//  Pods
//
//  Created by guochenxiang on 2019/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCScrollStringButtonProtocol <NSObject>

@property (nonatomic, assign) BOOL shouldAnimate;//string animation
@property (nonatomic, assign) BOOL enableConstantSpeed;
@property (nonatomic, assign) CGFloat buttonWidth;
@property (nonatomic, assign) BOOL acc_enabled; //埋点 - "选择音乐"置灰，点击上报
@property (nonatomic, assign) BOOL hasMusic;
@property (nonatomic, assign) BOOL isDisableStyle;
@property (nonatomic, assign) UIEdgeInsets acc_hitTestEdgeInsets;

@property (nonatomic, assign) BOOL enableImageRotation;//used for a loding status

- (void)configWithImage:(UIImage *)image title:(NSString *)title hasMusic:(BOOL)hasMusic;
- (void)configWithImage:(UIImage *)image title:(NSString *)title hasMusic:(BOOL)hasMusic maxButtonWidth:(CGFloat)maxButtonWidth;
- (void)startAnimation;
- (void)stopAnimation;
- (void)addTarget:(id)target action:(SEL)action;
- (CGFloat)buttonHeight;
- (void)showLabelShadow;

@property (nonatomic, strong, readonly) UIButton *closeButton;
- (void)showCloseButton;
- (void)hideCloseButton;

@end

NS_ASSUME_NONNULL_END
