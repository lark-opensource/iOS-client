//
//  CJPayTransitionUtil.m
//  CJPay
//
//  Created by wangxiaohong on 2022/5/5.
//

#import "CJPayTransitionUtil.h"

#import "CJPayUIMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPaySettingsManager.h"

@interface CJPayTransitionUtil()

@property (nonatomic, assign) CGFloat maskMaxAlpha;
@property (nonatomic, assign) NSTimeInterval animationDuration;

@end

@implementation CJPayTransactionShareView

- (instancetype)initWith:(id<UIViewControllerContextTransitioning>)transitionContext {
    self = [super init];
    if (self) {
        _fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        _toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        
        _fromFinalFrame = [transitionContext finalFrameForViewController:_fromVC];
        _toFinalFrame = [transitionContext finalFrameForViewController:_toVC];
        
        if (![transitionContext respondsToSelector:@selector(viewForKey:)]) {
            _fromView = _fromVC.view;
            _toView = _toVC.view;
        } else {
            _fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
            _toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        }
    }
    return self;
}

@end

@implementation CJPayTransitionUtil

+ (instancetype)sharedInstance
{
    static CJPayTransitionUtil *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maskMaxAlpha = 0.34;
        _animationDuration = 0.3;
    }
    return self;
}

- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)halfVC isShowMaskView:(BOOL)isShowMaskView maskViewHeight:(CGFloat)maskViewHeight completion:(void (^)(BOOL))completion {
    
    UIView *transView = halfVC.containerView;
    
    UIColor *bgColor = halfVC.backColorView.backgroundColor;
    UIView *pMaskView = nil;
    if (isShowMaskView) {
        pMaskView = [self p_createMaskView];
        if (maskViewHeight > 0) {
            pMaskView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - maskViewHeight, CJ_SCREEN_WIDTH, maskViewHeight);
            [pMaskView cj_clipTopCorner:8];
        } else {
            pMaskView.frame = halfVC.view.bounds;
        }
        [halfVC.view insertSubview:pMaskView belowSubview:halfVC.containerView];
        halfVC.backColorView.backgroundColor = [UIColor clearColor];
    }
    
//    UIImageView *containerSnapImageView = nil;
//    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
//    if (isTransitionUseSnapshot) {
//        [halfVC.containerView layoutIfNeeded];
//        containerSnapImageView = [self p_createSnapshotForView:halfVC.containerView];
//        [halfVC.view insertSubview:containerSnapImageView belowSubview:halfVC.containerView];
//        halfVC.containerView.hidden = YES;
//        transView = containerSnapImageView;
//    }
    
    if (halfVC.animationType == HalfVCEntranceTypeFromBottom) {
        [self p_transitionHalfView:transView containerHeight:halfVC.containerHeight halfVCEntranceType:HalfVCEntranceTypeFromBottom transitionType:CJPayTransitionV2TypeEnter maskView:pMaskView completion:^(BOOL finished) {
            if (isShowMaskView) {
                halfVC.backColorView.backgroundColor = bgColor;
                [pMaskView removeFromSuperview];
            }
            CJ_CALL_BLOCK(completion, finished);
            
//            if (isTransitionUseSnapshot) {
//                halfVC.containerView.hidden = NO;
//                [containerSnapImageView removeFromSuperview];
//            }
        }];
        return;
    }
    
    [self p_transitionHalfView:transView containerHeight:halfVC.containerHeight halfVCEntranceType:HalfVCEntranceTypeFromRight transitionType:CJPayTransitionV2TypeEnter maskView:pMaskView completion:^(BOOL finished) {
        if (isShowMaskView) {
            halfVC.backColorView.backgroundColor = bgColor;
            [pMaskView removeFromSuperview];
        }
        CJ_CALL_BLOCK(completion, finished);
        
//        if (isTransitionUseSnapshot) {
//            halfVC.containerView.hidden = NO;
//            [containerSnapImageView removeFromSuperview];
//        }
    }];
}

- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)halfVC isShowMaskView:(BOOL)isShowMaskView completion:(void (^)(BOOL))completion {
    [self transitionEnterHalfVC:halfVC isShowMaskView:isShowMaskView maskViewHeight:0 completion:completion];
}

- (void)transitionEnterHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                   fromHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                containerView:(UIView *)containerView
          containerBottomView:(UIView *)containerBottomView
                   completion:(void (^)(BOOL))completion {

    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
    
    UIView *fromTransView = fromHalfVC.containerView;
    UIView *toTransView = toHalfVC.containerView;
    
    CGRect fromVCBeginFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - fromContainerViewHeight, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    CGRect fromVCEndFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - toContainerViewHeight, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    
    CGFloat toVCBeginY = toContainerViewHeight > fromContainerViewHeight ? CJ_SCREEN_HEIGHT - fromContainerViewHeight : CJ_SCREEN_HEIGHT - toContainerViewHeight;
    CGRect toVCBeginFrame = CGRectMake(CJ_SCREEN_WIDTH, toVCBeginY, CJ_SCREEN_WIDTH, toContainerViewHeight);
    CGRect toVCEndFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - toContainerViewHeight, CJ_SCREEN_WIDTH, toContainerViewHeight);
    // 增加fromVC.containerView上的蒙层
    UIView *fromTransMaskView = [self p_createMaskView];
    
    UIImageView *fromTransImageView = nil;
    UIImageView *toTransImageView = nil;
    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
    if (isTransitionUseSnapshot) {
        // 使用截图来做转场动画
        [toTransView layoutIfNeeded];
        fromTransImageView = [self p_createSnapshotForView:fromTransView];
        toTransImageView = [self p_createSnapshotForView:toTransView];
        
        [containerView addSubview:fromTransImageView];
        [containerView addSubview:toTransImageView];
//        [fromHalfVC.view insertSubview:fromTransImageView aboveSubview:fromTransView];
//        [toHalfVC.view insertSubview:toTransImageView aboveSubview:toTransView];
        fromTransView.hidden = YES;
        toTransView.hidden = YES;
        fromTransImageView.frame = fromVCBeginFrame;
        toTransImageView.frame = toVCBeginFrame;
        
        [fromTransImageView addSubview:fromTransMaskView];
    } else {
        fromTransView.frame = fromVCBeginFrame;
        toTransView.frame = toVCBeginFrame;
        [fromTransView addSubview:fromTransMaskView];
    }
    
    fromTransMaskView.frame = fromTransView.bounds;
    fromTransMaskView.alpha = 0;
    [fromTransMaskView cj_clipTopCorner:8];
    
    // 增加containerBottomView上的蒙层
    UIView *containerBottomMaskView;
    if (containerBottomView) {
        containerBottomMaskView = [self p_createMaskView];
        [containerBottomView addSubview:containerBottomMaskView];
        containerBottomMaskView.frame = containerBottomView.bounds;
        containerBottomMaskView.alpha = 0;
    }
    
    UIColor *toBgColor = toHalfVC.backColorView.backgroundColor;
    toHalfVC.backColorView.backgroundColor = [UIColor clearColor];
    @CJWeakify(self)
    [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{
        @CJStrongify(self);
        
        fromTransView.frame = fromVCEndFrame;
        toTransView.frame = toVCEndFrame;
        if (isTransitionUseSnapshot) {
            fromTransImageView.frame = fromVCEndFrame;
            toTransImageView.frame = toVCEndFrame;
        }
        
        fromTransMaskView.alpha = self.maskMaxAlpha;
        containerBottomMaskView.alpha = self.maskMaxAlpha;
        
    } completion:^(BOOL finished) {
        
        if (isTransitionUseSnapshot) {
            fromTransView.hidden = NO;
            toTransView.hidden = NO;
            [fromTransImageView removeFromSuperview];
            [toTransImageView removeFromSuperview];
//            fromTransView.frame = fromVCEndFrame;
//            toTransView.frame = toVCEndFrame;
        }
        [fromTransMaskView removeFromSuperview];
        [containerBottomMaskView removeFromSuperview];
        
        toHalfVC.backColorView.backgroundColor = toBgColor;
        // 当有矮半屏->高半屏转场时，结束转场后矮半屏需回归正常高度，否则高半屏再推出新矮半屏时背景异常
        if (fromContainerViewHeight < toContainerViewHeight) {
            fromTransView.frame = fromVCBeginFrame;
        }
        CJ_CALL_BLOCK(completion, finished);
    }];
}

// 半屏push半屏新转场动画（平移）
// 转场动画实例见https://bytedance.feishu.cn/docx/AJrvds7JUo8eRIx1FVrcG9AynEg
- (void)transitionTranslationEnterHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                              fromHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                           containerView:(UIView *)containerView
                     containerBottomView:(UIView *)bottomMaskView
                              completion:(void (^)(BOOL))completion {
    
    UIView *fromTransView = fromHalfVC.containerView;
    UIView *toTransView = toHalfVC.containerView;
    [toTransView layoutIfNeeded];
    
    UIImageView *fromTransImageView = [self p_createSnapshotForView:fromTransView];
    UIImageView *toTransImageView = [self p_createSnapshotForView:toTransView];
 
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
    
    // 设定fromContainerView的Y轴终态、toContainerView的Y轴初态
    CGFloat fromViewEndY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
    CGFloat toViewBeginY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
    
    // 设定底部遮罩的frame和平移动画
    CGFloat containerHeightDiff = 0;
    CGFloat bottomMaskViewEndX = 0;
    CGFloat bottomMaskViewEndY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
    
    // 高半屏push矮半屏
    if (fromContainerViewHeight > toContainerViewHeight) {
        toViewBeginY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
        fromViewEndY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
        
        containerHeightDiff = fromContainerViewHeight - toContainerViewHeight;
        bottomMaskView.frame = CGRectMake(CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT - containerHeightDiff, CJ_SCREEN_WIDTH, containerHeightDiff);
        bottomMaskView.backgroundColor = [toHalfVC getHalfPageBGColor];
        bottomMaskViewEndX = 0;
        bottomMaskViewEndY = CJ_SCREEN_HEIGHT;
        
    } else if (fromContainerViewHeight < toContainerViewHeight) {
        // 矮半屏push高半屏
        fromViewEndY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
        toViewBeginY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
                
        containerHeightDiff = toContainerViewHeight - fromContainerViewHeight;
        bottomMaskView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT, CJ_SCREEN_WIDTH, containerHeightDiff);
        bottomMaskView.backgroundColor = [fromHalfVC getHalfPageBGColor];
        bottomMaskViewEndX = -CJ_SCREEN_WIDTH;
        bottomMaskViewEndY = CJ_SCREEN_HEIGHT - containerHeightDiff;
    }
    
    // 设置fromContainerView和toContainerView的frame变化
    CGRect fromBeginFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - fromContainerViewHeight, CJ_SCREEN_WIDTH, fromContainerViewHeight);;
    CGRect fromEndFrame = CGRectMake(-CJ_SCREEN_WIDTH, fromViewEndY, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    
    CGRect toBeginFrame = CGRectMake(CJ_SCREEN_WIDTH, toViewBeginY, CJ_SCREEN_WIDTH, toContainerViewHeight);
    CGRect toEndFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - toContainerViewHeight, CJ_SCREEN_WIDTH, toContainerViewHeight);
    
    UIColor *toBgColor = toHalfVC.backColorView.backgroundColor;
    toHalfVC.backColorView.backgroundColor = [UIColor clearColor];
    
    UIView *topMarginFillView = [UIView new];
    topMarginFillView.backgroundColor = [fromHalfVC getHalfPageBGColor] == UIColor.clearColor ? UIColor.whiteColor : [fromHalfVC getHalfPageBGColor];
    [containerView insertSubview:topMarginFillView belowSubview:toHalfVC.view];
    topMarginFillView.frame = CGRectMake(CJ_SCREEN_WIDTH-8, CJ_SCREEN_HEIGHT - fromContainerViewHeight, 8 * 2, 8);  //设置两个半屏页面顶部圆角填充视图的Frame，其中8为圆角的半径
    
    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
    
    if (isTransitionUseSnapshot) {
        // 使用截图来做转场动画
        [fromHalfVC.view insertSubview:fromTransImageView aboveSubview:fromTransView];
        fromTransView.hidden = YES;
        fromTransImageView.frame = fromBeginFrame;
        
        [toHalfVC.view insertSubview:toTransImageView aboveSubview:toTransView];
        toTransView.hidden = YES;
        toTransImageView.frame = toBeginFrame;
    } else {
        fromTransView.frame = fromBeginFrame;
        toTransView.frame = toBeginFrame;
    }
    
    [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{

        fromTransView.frame = fromEndFrame;
        toTransView.frame = toEndFrame;
        if (isTransitionUseSnapshot) {
            fromTransImageView.frame = fromEndFrame;
            toTransImageView.frame = toEndFrame;
        }
        topMarginFillView.frame = CGRectMake(-8, fromViewEndY, 8 * 2, 8);
        bottomMaskView.frame = CGRectMake(bottomMaskViewEndX, bottomMaskViewEndY, CJ_SCREEN_WIDTH, containerHeightDiff);

    } completion:^(BOOL finished) {

        toHalfVC.backColorView.backgroundColor = toBgColor;
        if (isTransitionUseSnapshot) {
            toTransView.hidden = NO;
            [fromTransImageView removeFromSuperview];
            [toTransImageView removeFromSuperview];
        } else {
            // 转场动画做完后需把fromTransView归位，否则无动画pop回到fromVC时会看不到fromTransView
            fromTransView.hidden = YES;
            fromTransView.frame = fromBeginFrame;
        }
        [fromTransView performSelector:@selector(setHidden:) withObject:@(NO) afterDelay:0.05];
        [topMarginFillView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}

- (void)transitionEnterFullVC:(UIViewController *)fullVC maskContainerView:(UIView *)maskContainerView completion:(void (^ __nullable)(BOOL finished))completion {
    UIView *pMaskView = nil;

    if (maskContainerView) {
        pMaskView = [self p_createMaskView];
        pMaskView.frame = maskContainerView.bounds;
        [maskContainerView addSubview:pMaskView];
    }
    [self transitinNormalView:fullVC.view transitionType:CJPayTransitionV2TypeEnter maskView:pMaskView completion:^(BOOL finished) {
        [pMaskView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}

- (void)transitionEnterPopUpVC:(CJPayPopUpBaseViewController *)popupVC isShowMaskView:(BOOL)isShowMaskView completion:(void (^)(BOOL))completion {
    UIColor *bgColor = popupVC.backColorView.backgroundColor;
    UIView *pMaskView = nil;
    if (isShowMaskView) {
        pMaskView = [self p_createMaskView];
        pMaskView.frame = popupVC.view.frame;
        [popupVC.view insertSubview:pMaskView belowSubview:popupVC.containerView];
        popupVC.backColorView.backgroundColor = [UIColor clearColor];
    }
    CJPayLogInfo(@"transitionEnterPopUpVC-before: popupVC = %@, isShowMaskView = %@, maskView = %@", popupVC, @(isShowMaskView).stringValue, pMaskView);
    
    [self p_transitionPopupView:popupVC.containerView transitionType:CJPayTransitionV2TypeEnter maskView:pMaskView completion:^(BOOL finished) {
        
        popupVC.backColorView.backgroundColor = bgColor;
        [pMaskView removeFromSuperview];
        
        CJPayLogInfo(@"transitionEnterPopUpVC-before: popupVC = %@, isShowMaskView = %@, maskView = %@", popupVC, @(isShowMaskView).stringValue, pMaskView);
        CJ_CALL_BLOCK(completion,finished);
    }];
}


- (UIView *)addMaskViewForView:(UIView *)maskContainerView {
    UIView *pMaskView = [self p_createMaskView];
    pMaskView.frame = maskContainerView.bounds;
    [maskContainerView addSubview:pMaskView];
    pMaskView.alpha = self.maskMaxAlpha;
    return pMaskView;
}

- (void)transitionExitFullVC:(UIViewController *)fullVC maskContainerView:(UIView *)maskContainerView completion:(void (^)(BOOL))completion {
    UIView *pMaskView = nil;

    if (maskContainerView) {
        pMaskView = [self p_createMaskView];
        pMaskView.frame = maskContainerView.bounds;
        [maskContainerView addSubview:pMaskView];
    }
    [self transitinNormalView:fullVC.view transitionType:CJPayTransitionV2TypeExit maskView:pMaskView completion:^(BOOL finished) {
        [pMaskView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}

- (void)transitionExitPopUpVC:(CJPayPopUpBaseViewController *)popupVC isShowMaskView:(BOOL)isShowMaskView isRemoveBGImageView:(BOOL)isRemoveBGImageView completion:(void (^)(BOOL))completion {
    if (popupVC.transitionBGImageView && isRemoveBGImageView) {
        popupVC.transitionBGImageView.hidden = YES;
    }

    UIView *pMaskView = nil;
    if (isShowMaskView) {
        pMaskView = [self p_createMaskView];
        pMaskView.frame = popupVC.view.bounds;
        [popupVC.view insertSubview:pMaskView belowSubview:popupVC.containerView];
        popupVC.backColorView.backgroundColor = [UIColor clearColor];
    }
    CJPayLogInfo(@"transitionExitPopUpVC-before: popupVC = %@, isShowMaskView = %@, isRemoveBGImageView = %@, maskView = %@", popupVC, @(isShowMaskView).stringValue, @(isRemoveBGImageView).stringValue, pMaskView);

    [self p_transitionPopupView:popupVC.containerView transitionType:CJPayTransitionV2TypeExit maskView:pMaskView completion:^(BOOL finished) {
//        if (isShowMaskView) { //全屏 -》半屏 -》弹框 -》dismiss，如果不注释全屏会有黑蒙层
//            popupVC.backColorView.backgroundColor = bgColor;
//        }
        [pMaskView removeFromSuperview];
        if (isRemoveBGImageView) {
            [popupVC.transitionBGImageView removeFromSuperview];
        }

        CJPayLogInfo(@"transitionExitPopUpVC-after: popupVC = %@, isShowMaskView = %@, isRemoveBGImageView = %@, maskView = %@", popupVC, @(isShowMaskView).stringValue, @(isRemoveBGImageView).stringValue, pMaskView);
        CJ_CALL_BLOCK(completion,finished);
    }];
}


- (void)transitionExitPopUpVC:(CJPayPopUpBaseViewController *)popupVC isShowMaskView:(BOOL)isShowMaskView completion:(void (^)(BOOL))completion {
    [self transitionExitPopUpVC:popupVC isShowMaskView:isShowMaskView isRemoveBGImageView:YES completion:completion];
}

- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC maskContainerView:(UIView *)maskContainerView maskViewHeight:(CGFloat)maskViewHeight isRemoveBGImageView:(BOOL)isRemoveBGImageView completion:(void (^)(BOOL))completion {
    if (halfVC.transitionBGImageView && isRemoveBGImageView) {
        halfVC.transitionBGImageView.hidden = YES;
    }
    UIColor *bgColor = halfVC.backColorView.backgroundColor;
    
    UIView *pMaskView = nil;
    if (maskContainerView) {
        pMaskView = [self p_createMaskView];
        if (maskViewHeight > 0) {
            pMaskView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - maskViewHeight, CJ_SCREEN_WIDTH, maskViewHeight);
            [pMaskView cj_clipTopCorner:8];
        } else {
            pMaskView.frame = maskContainerView.bounds;
        }
        [maskContainerView addSubview:pMaskView];
        halfVC.backColorView.backgroundColor = [UIColor clearColor];
    }
    
    UIView *transView = halfVC.containerView;
    UIImageView *containerSnapImageView = nil;
    
    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
    if (isTransitionUseSnapshot) {
        containerSnapImageView = [self p_createSnapshotForView:halfVC.containerView];
        [halfVC.view insertSubview:containerSnapImageView belowSubview:halfVC.containerView];
        halfVC.containerView.hidden = YES;
        transView = containerSnapImageView;
    }
    
    if (halfVC.animationType == HalfVCEntranceTypeFromBottom) {
        [self p_transitionHalfView:transView containerHeight:halfVC.containerHeight halfVCEntranceType:HalfVCEntranceTypeFromBottom transitionType:CJPayTransitionV2TypeExit maskView:pMaskView completion:^(BOOL finished) {
            if (maskContainerView) {
                halfVC.backColorView.backgroundColor = bgColor;
                [pMaskView removeFromSuperview];
            }
            if (isRemoveBGImageView) {
                [halfVC.transitionBGImageView removeFromSuperview];
            }
            CJ_CALL_BLOCK(completion, finished);
            
            if (isTransitionUseSnapshot) {
//                halfVC.containerView.hidden = NO;
                [containerSnapImageView removeFromSuperview];
            }
        }];
        return;
    }
    
    [self p_transitionHalfView:transView containerHeight:halfVC.containerHeight halfVCEntranceType:HalfVCEntranceTypeFromRight transitionType:CJPayTransitionV2TypeExit maskView:pMaskView completion:^(BOOL finished) {
        if (maskContainerView) {
            halfVC.backColorView.backgroundColor = bgColor;
            [pMaskView removeFromSuperview];
        }
        if (isRemoveBGImageView) {
            [halfVC.transitionBGImageView removeFromSuperview];
        }
        CJ_CALL_BLOCK(completion, finished);
        
        if (isTransitionUseSnapshot) {
//            halfVC.containerView.hidden = NO;
            [containerSnapImageView removeFromSuperview];
        }
    }];
}

- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC
           maskContainerView:(UIView *)maskContainerView
                  completion:(void (^)(BOOL))completion {
    [self transitionExitHalfVC:halfVC maskContainerView:maskContainerView maskViewHeight:0 completion:completion];
}

- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)halfVC
           maskContainerView:(UIView *)maskContainerView
              maskViewHeight:(CGFloat)maskViewHeight
                  completion:(void (^)(BOOL))completion {
    [self transitionExitHalfVC:halfVC maskContainerView:maskContainerView maskViewHeight:maskViewHeight isRemoveBGImageView:YES completion:completion];
}

- (void)transitionExitHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                    toHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
               containerView:(UIView *)containerView
         containerBottomView:(UIView *)containerBottomView
                  completion:(void (^)(BOOL))completion {
    
    if (fromHalfVC.transitionBGImageView) {
        fromHalfVC.transitionBGImageView.hidden = YES;
    }
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;
    
    UIView *fromTransView = fromHalfVC.containerView;
    UIView *toTransView = toHalfVC.containerView;
    UIImageView *fromTransImageView = [self p_createSnapshotForView:fromTransView];
    UIImageView *toTransImageView = [self p_createSnapshotForView:toTransView];
    
    //
    CGFloat fromVCEndY = fromContainerViewHeight > toContainerViewHeight ? CJ_SCREEN_HEIGHT - toContainerViewHeight : CJ_SCREEN_HEIGHT - fromContainerViewHeight;
    CGRect fromVCBeginFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - fromContainerViewHeight, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    CGRect fromVCEndFrame = CGRectMake(CJ_SCREEN_WIDTH, fromVCEndY, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    
    CGRect toVCBeginFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - fromContainerViewHeight, CJ_SCREEN_WIDTH, toContainerViewHeight);
    CGRect toVCEndFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - toContainerViewHeight, CJ_SCREEN_WIDTH, toContainerViewHeight);
    
    fromTransView.frame = fromVCBeginFrame;
    toTransView.frame = toVCBeginFrame;
    UIView *toTransMaskView = [self p_createMaskView];
    
    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
    if (isTransitionUseSnapshot) {
        // 使用截图来做转场动画
//        [fromHalfVC.view insertSubview:fromTransImageView belowSubview:fromTransView];
//        [toHalfVC.view insertSubview:toTransImageView belowSubview:toTransView];
        [containerView addSubview:toTransImageView];
        [containerView addSubview:fromTransImageView];
        
        fromTransView.hidden = YES;
        toTransView.hidden = YES;
        fromTransImageView.frame = fromVCBeginFrame;
        toTransImageView.frame = toVCBeginFrame;
        
        [toTransImageView addSubview:toTransMaskView];
    } else {
        [toTransView addSubview:toTransMaskView];
    }
    toTransMaskView.frame = toTransView.bounds;
    toTransMaskView.alpha = self.maskMaxAlpha;
    [toTransMaskView cj_clipTopCorner:8];

    UIView *containerBottomMaskView;
    if (containerBottomView) {
        containerBottomMaskView = [self p_createMaskView];
        [containerBottomView addSubview:containerBottomMaskView];
        containerBottomMaskView.frame = containerBottomView.bounds;
        containerBottomMaskView.alpha = self.maskMaxAlpha;
    }
    
    [self p_transitionWithTransitionType:CJPayTransitionV2TypeExit action:^{
        
        fromTransView.frame = fromVCEndFrame;
        toTransView.frame = toVCEndFrame;
        if (isTransitionUseSnapshot) {
            fromTransImageView.frame = fromVCEndFrame;
            toTransImageView.frame = toVCEndFrame;
        }
        
        toTransMaskView.alpha = 0;
        containerBottomMaskView.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        if (isTransitionUseSnapshot) {
            toTransView.hidden = NO;
            fromTransView.hidden = NO;
            [toTransImageView removeFromSuperview];
            [fromTransImageView removeFromSuperview];
        }
        [toTransMaskView removeFromSuperview];
        [containerBottomMaskView removeFromSuperview];
        [fromHalfVC.transitionBGImageView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
    
}

// 半屏pop半屏新转场动画（平移）
// 转场动画实例见https://bytedance.feishu.cn/docx/AJrvds7JUo8eRIx1FVrcG9AynEg
- (void)transitionTranslationExitHalfVC:(CJPayHalfPageBaseViewController *)fromHalfVC
                               toHalfVC:(CJPayHalfPageBaseViewController *)toHalfVC
                          containerView:(UIView *)containerView
                    containerBottomView:(UIView *)bottomMaskView
                             completion:(void (^)(BOOL))completion {
    // 转场前先隐藏fromVC的背景截图，避免遮挡
    if (fromHalfVC.transitionBGImageView) {
        fromHalfVC.transitionBGImageView.hidden = YES;
    }
    
    UIView *fromTransView = fromHalfVC.containerView;
    UIView *toTransView = toHalfVC.containerView;
    if (toTransView.isHidden) {
        toTransView.hidden = NO;
    }
    UIImageView *fromTransImageView = [self p_createSnapshotForView:fromTransView];
    UIImageView *toTransImageView = [self p_createSnapshotForView:toTransView];
    
    CGFloat fromContainerViewHeight = fromHalfVC.containerHeight;
    CGFloat toContainerViewHeight = toHalfVC.containerHeight;

    // 设定fromContainerView、toContainerView和背景视图bottomMaskView的位置
    CGFloat fromViewEndY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
    CGFloat toViewBeginY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
    
    CGFloat containerHeightDiff = 0;
    CGFloat bottomMaskViewEndX = 0;
    CGFloat bottomMaskViewEndY = CJ_SCREEN_HEIGHT;
    
    if (fromContainerViewHeight > toContainerViewHeight) {
        // 高半屏pop矮半屏
        toViewBeginY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
        fromViewEndY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
        
        bottomMaskView.backgroundColor = [toHalfVC getHalfPageBGColor];
        
        containerHeightDiff = fromContainerViewHeight - toContainerViewHeight;
        bottomMaskView.frame = CGRectMake(-CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT - containerHeightDiff, CJ_SCREEN_WIDTH, containerHeightDiff);
        bottomMaskViewEndX = 0;
        bottomMaskViewEndY = CJ_SCREEN_HEIGHT;
        
    } else if (fromContainerViewHeight < toContainerViewHeight) {
        // 矮半屏pop高半屏
        fromViewEndY = CJ_SCREEN_HEIGHT - toContainerViewHeight;
        toViewBeginY = CJ_SCREEN_HEIGHT - fromContainerViewHeight;
        
        bottomMaskView.backgroundColor = [fromHalfVC getHalfPageBGColor];
        
        containerHeightDiff = toContainerViewHeight - fromContainerViewHeight;
        bottomMaskView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT, CJ_SCREEN_WIDTH, containerHeightDiff);
        bottomMaskViewEndX = CJ_SCREEN_WIDTH;
        bottomMaskViewEndY = CJ_SCREEN_HEIGHT - containerHeightDiff;
    }
    
    // 设置fromContainerView和toContainerView的frame变化
    CGRect fromBeginFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - fromContainerViewHeight, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    CGRect fromEndFrame = CGRectMake(CJ_SCREEN_WIDTH, fromViewEndY, CJ_SCREEN_WIDTH, fromContainerViewHeight);
    
    CGRect toBeginFrame = CGRectMake(-CJ_SCREEN_WIDTH, toViewBeginY, CJ_SCREEN_WIDTH, toContainerViewHeight);
    CGRect toEndFrame = CGRectMake(0, CJ_SCREEN_HEIGHT - toContainerViewHeight, CJ_SCREEN_WIDTH, toContainerViewHeight);

    UIView *topMarginFillView = [UIView new];
    topMarginFillView.backgroundColor = [fromHalfVC getHalfPageBGColor] == UIColor.clearColor ? UIColor.whiteColor : [fromHalfVC getHalfPageBGColor];
    [containerView insertSubview:topMarginFillView belowSubview:fromHalfVC.view];
    topMarginFillView.frame = CGRectMake(-8, CJ_SCREEN_HEIGHT - fromContainerViewHeight, 8 * 2, 8);  //设置两个半屏页面顶部圆角填充视图的Frame，其中8为圆角的半径
    
    fromTransView.frame = fromBeginFrame;
    toTransView.frame = toBeginFrame;

    BOOL isTransitionUseSnapshot = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isTransitionUseSnapshot;
    if (isTransitionUseSnapshot) {
        
//        [fromHalfVC.view insertSubview:fromTransImageView aboveSubview:fromTransView];
        [containerView addSubview:fromTransImageView];
        fromTransView.hidden = YES;
        fromTransImageView.frame = fromBeginFrame;
        
//        [toHalfVC.view insertSubview:toTransImageView aboveSubview:toTransView];
        [containerView addSubview:toTransImageView];
        toTransView.hidden = YES;
        toTransImageView.frame = toBeginFrame;
    }
    
    [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{

        fromTransView.frame = fromEndFrame;
        toTransView.frame = toEndFrame;
        topMarginFillView.frame = CGRectMake(CJ_SCREEN_WIDTH-8, fromViewEndY, 8 * 2, 8);
        
        if (isTransitionUseSnapshot) {
            fromTransImageView.frame = fromEndFrame;
            toTransImageView.frame = toEndFrame;
        }
        
        bottomMaskView.frame = CGRectMake(bottomMaskViewEndX, bottomMaskViewEndY, CJ_SCREEN_WIDTH, containerHeightDiff);
    } completion:^(BOOL finished) {
        
        if (isTransitionUseSnapshot) {
            fromTransView.hidden = NO;
            toTransView.hidden = NO;
            [fromTransImageView removeFromSuperview];
            [toTransImageView removeFromSuperview];
        }
        [topMarginFillView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}

- (void)transitinNormalView:(UIView *)view transitionType:(CJPayTransitionV2Type)transionType maskView:(UIView *)maskView completion:(void (^ __nullable)(BOOL finished))completion {
    UIView *transView = view;
    CGFloat viewWidth = view.cj_width;
    CGFloat viewHeight = view.cj_height;
    if (transionType == CJPayTransitionV2TypeEnter) {
        transView.frame = CGRectMake(viewWidth, 0, viewWidth, viewHeight);
        maskView.alpha = 0;
        @CJWeakify(self)
        [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{
            @CJStrongify(self);
            transView.frame = CGRectMake(0, 0, viewWidth, viewHeight);
            maskView.alpha = self.maskMaxAlpha;
        } completion:completion];
        return;
    }
    if (transionType == CJPayTransitionV2TypeExit) {
        transView.frame = CGRectMake(0, 0, viewWidth, viewHeight);
        maskView.alpha = self.maskMaxAlpha;
        [self p_transitionWithTransitionType:CJPayTransitionV2TypeExit action:^{
            transView.frame = CGRectMake(viewWidth, 0, viewWidth, viewHeight);
            maskView.alpha = 0;
        } completion:completion];
        return;
    }
    CJ_CALL_BLOCK(completion,YES);
}

#pragma mark - Interactive
- (void)updateInteractiveFullVC:(UIViewController *)fullVC maskView:(UIView *)maskView percentComplete:(CGFloat)percentComplete completion:(nullable void (^)(BOOL))completion {
    if (maskView) {
        maskView.alpha = self.maskMaxAlpha * (1 - percentComplete);
    }
    
    UIView *transView = fullVC.view;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    transView.cj_left = MAX(0, percentComplete * width);
    CJ_CALL_BLOCK(completion, YES);
}

- (void)finishInteractiveFullVC:(UIViewController *)fullVC isCancel:(BOOL)isCancel maskView:(UIView *)maskView completion:(void (^)(BOOL))completion {
    @CJWeakify(self)
    [UIView animateWithDuration:self.animationDuration
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        fullVC.view.cj_left = isCancel ? 0 : [UIScreen mainScreen].bounds.size.width;
        @CJStrongify(self)
        maskView.alpha = isCancel ? self.maskMaxAlpha : 0;
    } completion:^(BOOL finished) {
        [maskView removeFromSuperview];
        CJ_CALL_BLOCK(completion, finished);
    }];
}

#pragma mark - Private Method
- (void)p_transitionHalfView:(UIView *)view
             containerHeight:(CGFloat)halfViewHeight
          halfVCEntranceType:(HalfVCEntranceType)entranceType
              transitionType:(CJPayTransitionV2Type)transionType
                    maskView:(UIView *)maskView
                  completion:(void (^ __nullable)(BOOL finished))completion {
    
    UIView *transView = view;
    if (transionType == CJPayTransitionV2TypeEnter) {
        if (entranceType == HalfVCEntranceTypeFromRight) {
            transView.frame = CGRectMake(CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
            maskView.alpha = 0;
            @CJWeakify(self)
            [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{
                @CJStrongify(self);
                transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
                maskView.alpha = self.maskMaxAlpha;
            } completion:completion];
            return;
        }
        if (entranceType == HalfVCEntranceTypeFromBottom) {
            transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT, CJ_SCREEN_WIDTH, halfViewHeight);
            maskView.alpha = 0;
            @CJWeakify(self)
            [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{
                @CJStrongify(self);
                transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
                maskView.alpha = self.maskMaxAlpha;
            } completion:completion];
            return;
        }
        CJ_CALL_BLOCK(completion,YES);
        return;
    }
    
    if (transionType == CJPayTransitionV2TypeExit) {
        if (entranceType == HalfVCEntranceTypeFromRight) {
            maskView.alpha = self.maskMaxAlpha;
            transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
            [self p_transitionWithTransitionType:CJPayTransitionV2TypeExit action:^{
                transView.frame = CGRectMake(CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
                maskView.alpha = 0;
            } completion:completion];
            return;
        }
        if (entranceType == HalfVCEntranceTypeFromBottom) {
            transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT - halfViewHeight, CJ_SCREEN_WIDTH, halfViewHeight);
            maskView.alpha = self.maskMaxAlpha;
            [self p_transitionWithTransitionType:CJPayTransitionV2TypeExit action:^{
                transView.frame = CGRectMake(0, CJ_SCREEN_HEIGHT, CJ_SCREEN_WIDTH, halfViewHeight);
                maskView.alpha = 0;
            } completion:completion];
            return;
        }
        CJ_CALL_BLOCK(completion, YES);
        return;
    }
    CJ_CALL_BLOCK(completion, YES);
}

- (void)p_transitionPopupView:(UIView *)view transitionType:(CJPayTransitionV2Type)transionType maskView:(UIView *)maskView completion:(void (^ __nullable)(BOOL finished))completion {
    UIView *transView = view;
    
    if (transionType == CJPayTransitionV2TypeEnter) {
        transView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        maskView.alpha = 0;
        transView.alpha = 0;
        [self p_transitionWithTransitionType:CJPayTransitionV2TypeEnter action:^{
            transView.transform = CGAffineTransformMakeScale(1, 1);
            maskView.alpha = self.maskMaxAlpha;
            transView.alpha = 1;
        } completion:completion];
        return;
    }
    
    if (transionType == CJPayTransitionV2TypeExit) {
        transView.transform = CGAffineTransformMakeScale(1, 1);
        transView.alpha = 1;
        maskView.alpha = self.maskMaxAlpha;
        [self p_transitionWithTransitionType:CJPayTransitionV2TypeExit action:^{
            transView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            transView.alpha = 0;
            maskView.alpha = 0;
        } completion:completion];
        return;
    }
    
    CJ_CALL_BLOCK(completion,YES);
}

- (void)p_transitionWithTransitionType:(CJPayTransitionV2Type)transionType action:(void(^)(void))action completion:(void (^ __nullable)(BOOL finished))completion {

    [UIView animateWithDuration:self.animationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        CJ_CALL_BLOCK(action);
    }
                     completion:completion];
}

- (UIView *)p_createMaskView {
    UIView *maskView = [UIView new];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.alpha = self.maskMaxAlpha;
    return maskView;
}

- (UIImageView *)p_createSnapshotForView:(UIView *)view {
    UIImage *snapImage = [CJPayCommonUtil snapViewToImageView:view];
    UIImageView *snapImageView = [[UIImageView alloc] initWithImage:snapImage];
    snapImageView.contentMode = UIViewContentModeScaleAspectFit;
    snapImageView.backgroundColor = UIColor.clearColor;
    
    return snapImageView;
}
@end
