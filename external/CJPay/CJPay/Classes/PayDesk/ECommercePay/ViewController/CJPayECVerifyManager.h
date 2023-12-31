//
//  CJPayECVerifyManager.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayBaseVerifyManager.h"
#import "CJPayNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayFrontCashierContext;
@interface CJPayECVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, strong) CJPayFrontCashierContext *payContext;

// 返回给电商的性能统计，时间戳
- (NSDictionary *)getPerformanceInfo;

@end

NS_ASSUME_NONNULL_END
