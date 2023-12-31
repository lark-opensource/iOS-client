//
//  CJPayHalfVerifyPasswordBaseViewController.h
//  Pods
//
//  Created by chenbocheng on 2022/4/12.
//

#import "CJPayHalfPageBaseViewController.h"

@class CJPayEvent;

NS_ASSUME_NONNULL_BEGIN

@class CJPayVerifyPasswordViewModel;

@interface CJPayHalfVerifyPasswordBaseViewController : CJPayHalfPageBaseViewController

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel;
- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType viewModel:(CJPayVerifyPasswordViewModel *)viewModel;

@property (nonatomic, strong, readonly) CJPayVerifyPasswordViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
