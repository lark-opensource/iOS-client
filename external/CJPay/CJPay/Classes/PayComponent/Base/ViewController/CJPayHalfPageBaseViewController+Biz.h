//
//  CJPayHalfPageBaseViewController+Biz.h
//  CJPay
//
//  Created by 王新华 on 10/10/19.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayStateView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHalfPageBaseViewController(Biz)<CJPayStateDelegate>

@property (nonatomic, strong, readonly) CJPayStateView *stateView;

- (void)showState:(CJPayStateType)stateType;

@end

NS_ASSUME_NONNULL_END
