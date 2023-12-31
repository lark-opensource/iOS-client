//
//  CJPayPopUpBaseViewController.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/4.
//

#import "CJPayBaseViewController.h"

#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPopUpBaseViewController : CJPayBaseViewController

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong, readonly) UIView *backColorView;
@property (nonatomic, copy) void(^closeActionCompletionBlock)(BOOL success);

- (void)setupUI;
- (void)dismissSelfWithCompletionBlock:(void(^ _Nullable)(void))completionBlock;
- (void)showMask:(BOOL)show;
- (CGFloat)maskAlpha;

@end

NS_ASSUME_NONNULL_END
