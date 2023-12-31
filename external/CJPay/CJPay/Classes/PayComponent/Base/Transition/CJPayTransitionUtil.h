//
//  CJPayTransitionUtil.h
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import <Foundation/Foundation.h>

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

#define CJPayTransition [CJPayTransitionUtil sharedInstance]

typedef NS_ENUM(NSInteger, CJPayTransitionV2Type) {
    CJPayTransitionV2TypeEnter,       // 进场
    CJPayTransitionV2TypeExit,      // 出场
};

@class CJPayHalfPageBaseViewController;
@class CJPayFullPageBaseViewController;
@class CJPayPopUpBaseViewController;

@interface CJPayTransactionShareView : NSObject

@property (nonatomic, strong) UIViewController *fromVC;
@property (nonatomic, strong) UIViewController *toVC;

@property (nonatomic, strong) UIView *fromView;
@property (nonatomic, strong) UIView *toView;

@property (nonatomic, assign) CGRect fromFinalFrame;
@property (nonatomic, assign) CGRect toFinalFrame;

- (instancetype)initWith:(id<UIViewControllerContextTransitioning>)transitionContext;

@end

@interface CJPayTransitionUtil : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, assign, readonly) NSTimeInterval animationDuration;

// 进场动画
// 普通半屏页面进场
- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)halfVC
               isShowMaskView:(BOOL)isShowMaskView
                   completion:(void (^ __nullable)(BOOL finished))completion;

// 定制蒙层高度的半屏页面进场
- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)halfVC
               isShowMaskView:(BOOL)isShowMaskView
               maskViewHeight:(CGFloat)maskViewHeight
                   completion:(void (^)(BOOL))completion;

// 不同高度半屏页面进场
- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                   fromHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                containerView:(UIView *)containerView
          containerBottomView:(UIView *)bottomMaskView
                   completion:(void (^)(BOOL))completion;

// 半屏push半屏新转场动画（平移）
- (void)transitionTranslationEnterHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                              fromHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                           containerView:(UIView *)containerView
                     containerBottomView:(UIView *)bottomMaskView
                              completion:(void (^)(BOOL))completion;

// 全屏页面进场
- (void)transitionEnterFullVC:(UIViewController *)fullVC
            maskContainerView:(nullable UIView *)maskContainerView
                   completion:(void (^ __nullable)(BOOL finished))completion;

// 弹窗页面进场
- (void)transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)popupVC
                isShowMaskView:(BOOL)isShowMaskView
                    completion:(void (^ __nullable)(BOOL finished))completion;

// 出场动画
// 普通半屏页面出场
- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC
           maskContainerView:(nullable UIView *)maskContainerView
                  completion:(void (^ __nullable)(BOOL finished))completion;

// 定制蒙层高度的半屏页面出场
- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC
           maskContainerView:(nullable UIView *)maskContainerView
              maskViewHeight:(CGFloat)maskViewHeight
                  completion:(void (^)(BOOL))completion;

- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC
           maskContainerView:(UIView *)maskContainerView
              maskViewHeight:(CGFloat)maskViewHeight
         isRemoveBGImageView:(BOOL)isRemoveBGImageView
                  completion:(void (^)(BOOL))completion;


// 不同高度半屏页面出场
- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                    toHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
               containerView:(UIView *)containerView
         containerBottomView:(UIView *)bottomMaskView
                  completion:(void (^)(BOOL))completion;

// 半屏pop半屏新转场动画（平移）
- (void)transitionTranslationExitHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                             toHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                          containerView:(UIView *)containerView
                    containerBottomView:(UIView *)bottomMaskView
                             completion:(void (^)(BOOL))completion;

// 全屏页面出场
- (void)transitionExitFullVC:(UIViewController *)fullVC
           maskContainerView:(UIView *)maskContainerView
                  completion:(void (^ __nullable)(BOOL finished))completion;

// 弹窗页面出场
- (void)transitionExitPopUpVC:(CJPayPopUpBaseViewController *)popupVC
               isShowMaskView:(BOOL)isShowMaskView
                   completion:(void (^ __nullable)(BOOL finished))completion;

// 定制背景的弹窗页面出场
- (void)transitionExitPopUpVC:(CJPayPopUpBaseViewController *)popupVC
               isShowMaskView:(BOOL)isShowMaskView
          isRemoveBGImageView:(BOOL)isRemoveBGImageView completion:(void (^)(BOOL))completion;

// 普通页面出场
- (void)transitinNormalView:(UIView *)view
             transitionType:(CJPayTransitionV2Type)transionType
                   maskView:(UIView *)maskView
                 completion:(void (^ __nullable)(BOOL finished))completion;

#pragma mark - Interactive
- (UIView *)addMaskViewForView:(UIView *)maskContainerView;

- (void)updateInteractiveFullVC:(UIViewController *)fullVC
                       maskView:(UIView *)maskView
                percentComplete:(CGFloat)percentComplete
                     completion:(void (^ __nullable)(BOOL finished))completion;

- (void)finishInteractiveFullVC:(UIViewController *)fullVC
                       isCancel:(BOOL)isCancel
                       maskView:(UIView *)maskView
                     completion:(void (^ __nullable)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
