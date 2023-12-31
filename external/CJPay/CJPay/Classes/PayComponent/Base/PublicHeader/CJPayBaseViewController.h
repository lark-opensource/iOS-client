//
//  CJPayBaseViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/3/10.
//

#import <UIKit/UIKit.h>
#import "CJPayEnumUtil.h"
#import "UIViewController+CJPay.h"
#import "CJPayPerformanceTracker.h"
#import "CJPayNavigationBarView.h"
@class CJPayNavigationController;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayBaseVCType) {
    CJPayBaseVCTypeFull,       // 全屏
    CJPayBaseVCTypePopUp,      // 弹框
    CJPayBaseVCTypeHalf,       // 半屏
};

@interface CJPayBaseViewController : UIViewController  <CJPayNavigationBarDelegate>

@property (nonatomic, strong) CJPayNavigationBarView *navigationBar;
@property (nonatomic, copy) void(^lifeCycleBlock)(CJPayVCLifeType type);
@property (nonatomic, assign, readonly) CJPayBaseVCType vcType;
@property (nonatomic, weak) UIImageView *transitionBGImageView;
@property (nonatomic, assign, readonly) BOOL isShowMask;

- (CJPayNavigationController *)presentWithNavigationControllerFrom:(UIViewController *_Nullable)fromVC
                                                           useMask:(BOOL)useMask
                                                        completion:(void (^ _Nullable)(void))completion;

- (void)useCloseBackBtn;
- (void)setNavTitle:(NSString *)title;
- (void)close;
@end

NS_ASSUME_NONNULL_END
