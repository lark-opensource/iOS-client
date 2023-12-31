//
//  DYOpenHalfScreenBaseViewController.h
//  <AWEBizUIComponent/AWEHalfScreenBaseViewController>
//
//  Created by 刘宁宁 on 2020/5/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DYOpenHalfScreenBaseVCAnimationStyle) {
    DYOpenHalfScreenBaseVCAnimationStyleDefault    = 0,
    DYOpenHalfScreenBaseVCAnimationStyleFade       = 1,
};

typedef NS_ENUM(NSUInteger, DYOpenHalfScreenBaseVCViewStyle) {
    DYOpenHalfScreenBaseVCViewStyleDefault    = 0,
    DYOpenHalfScreenBaseVCViewStylePanel      = 1,
};

@interface DYOpenHalfScreenBaseViewController : UIViewController

@property (nonatomic, readonly) UIView *containerView;

@property (nonatomic, assign) DYOpenHalfScreenBaseVCAnimationStyle animationStyle;
@property (nonatomic, assign) DYOpenHalfScreenBaseVCViewStyle viewStyle;
// need to set when StylePanel
@property (nonatomic, assign) CGFloat containerWidth;
// need to set
@property (nonatomic, assign) CGFloat containerHeight;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic) BOOL onlyTopCornerClips;

@property (nonatomic) BOOL isContentViewScroll;
// need to set if isContentViewScroll == YES
@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) dispatch_block_t dismissBlock;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic, readonly, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL disablePanGes;
@property (nonatomic, assign) BOOL disableTapGes; /// 禁止点击 mask 退出
@property (nonatomic, strong) UIColor *maskColor;

/// use the same animation curve as share panel in iOS, default is NO
@property (nonatomic, assign) BOOL useSmootherTransition;

- (void)presentViewController:(void (^ _Nullable)(void))completion;
- (void)presentOnViewController:(UIViewController *)viewController;
- (void)showOnView:(UIView *)view;
- (void)dismiss;
- (void)dismiss:(void (^)(void))afterDismissBlock;
- (void)dismissWithDuration:(CGFloat)duration afterDismissBlock:(void (^)(void))afterDismissBlock;
- (void)tapDismiss;
- (void)slideDismiss;

@end

NS_ASSUME_NONNULL_END
