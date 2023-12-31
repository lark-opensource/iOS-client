//
//  CJPayHalfPageBaseViewController.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/17.
//

#import <UIKit/UIKit.h>
//#import "CJPayNavigationController.h"
//#import "CJPayUIMacro.h"
#import "CJPayNavigationBarView.h"
#import "CJPayEnumUtil.h"
#import "CJPayBaseViewController.h"



NS_ASSUME_NONNULL_BEGIN
typedef void(^AnimationCompletionBlock)(BOOL);

typedef NS_ENUM(NSUInteger ,HalfVCEntranceType) {
    HalfVCEntranceTypeNone, // 这个作为默认值
    HalfVCEntranceTypeFromBottom,
    HalfVCEntranceTypeFromRight,
    HalfVCEntranceTypeNoSetting     // 退出动画默认与进入保持一致，可单独定义
};

@interface CJPayHalfPageBaseViewController : CJPayBaseViewController

@property (nonatomic, assign) HalfVCEntranceType animationType;
@property (nonatomic, assign) HalfVCEntranceType exitAnimationType;
@property (nonatomic, copy) AnimationCompletionBlock closeActionCompletionBlock;
@property (nonatomic, strong) UIView *containerView; // 包含导航栏
@property (nonatomic, strong) UIView *contentView;   // 不包含导航栏
@property (nonatomic, strong) UIView *topView; // 半屏上方透明区域

@property (nonatomic, copy) NSString *from;

@property (nonatomic, strong, readonly) UIView *backColorView;

@property (nonatomic, assign) BOOL isSupportClickMaskBack;

@property (nonatomic, assign) BOOL clipToHalfPageBounds; // 默认YES，不显示白屏containerView之外的内容

@property (nonatomic, assign) BOOL forceOriginPresentAnimation; //为YES时，首页不会修改此页面的present入场动画参数

- (void)showMask:(BOOL)show;

- (CGFloat)maskAlpha;

- (CGFloat)loadingShowheight;
- (CGFloat)containerHeight;

- (void)close;

- (void)closeWithAnimation:(BOOL)animated comletion:(nullable AnimationCompletionBlock)completion;

- (void)hideBackButton;
- (void)showBackButton;

- (void)addLoadingViewInTopLevel:(UIImageView *)loadingView;
- (UIColor *)getHalfPageBGColor;
@end

NS_ASSUME_NONNULL_END
