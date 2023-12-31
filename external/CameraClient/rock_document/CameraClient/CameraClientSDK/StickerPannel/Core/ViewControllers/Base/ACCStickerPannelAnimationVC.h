//
//  ACCStickerPannelAnimationVC.h
//  Pods
//
//  Created by liyingpeng on 2020/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerPannelAnimationVCDelegate <NSObject>

- (void)stickerPannelVCDidDismiss;

@end

@interface ACCStickerPannelAnimationVC : UIViewController

@property (nonatomic, weak, nullable) id<ACCStickerPannelAnimationVCDelegate> transitionDelegate;
@property (nonatomic, weak, nullable) UIViewController *containerVC;
@property (nonatomic, weak, nullable) UIView *animationView;
@property (nonatomic, assign) CGFloat topOffset; // 顶部距离屏幕间距为屏幕高度的7.8%

- (void)showWithCompletion:(nullable void (^)(void))completion;
- (void)showAlphaWithCompletion:(nullable void (^)(void))completion;
- (void)showWithoutAnimation;

- (void)removeWithCompletion:(nullable void (^)(void))completion;
- (void)removeAlphaWithCompletion:(nullable void (^)(void))completion;
- (void)removeWithoutAnimation;

@end

NS_ASSUME_NONNULL_END
