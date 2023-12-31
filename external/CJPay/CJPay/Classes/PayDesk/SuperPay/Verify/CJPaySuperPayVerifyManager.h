//
//  CJPaySuperPayVerifyManager.h
//  Pods
//
//  Created by wangxiaohong on 2022/11/1.
//

#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayFrontCashierContext;
@class CJPayHintInfo;
@interface CJPaySuperPayVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;

@end

NS_ASSUME_NONNULL_END
