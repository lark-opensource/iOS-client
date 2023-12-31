//
//  CJPayECSkipPwdUpgradeViewController.h
//  Pods
//
//  Created by 孟源 on 2021/10/12.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;

@interface CJPayECSkipPwdUpgradeViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy) void(^completion)(void);
@property (nonatomic, assign) BOOL isTradeCreateAgain;

- (instancetype)initWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager;

@end

NS_ASSUME_NONNULL_END
