//
//  CJPayBaseVerifyManagerQueen.h
//  Pods
//
//  Created by wangxiaohong on 2021/11/15.
//

#import <Foundation/Foundation.h>
#import "CJPayVerifyManagerHeader.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@interface CJPayBaseVerifyManagerQueen : NSObject<CJPayTrackerProtocol>

@property (nonatomic, weak, readonly) CJPayBaseVerifyManager *verifyManager;

- (NSDictionary *)cashierExtraTrackerParams;

// 绑定verifyManager
- (void)bindManager:(CJPayBaseVerifyManager *)verifyManager;
// 上报验证组件埋点
- (void)trackVerifyWithEventName:(NSString *)eventName params:(NSDictionary *)params;
// 上报收银台埋点 => 支付、提现、充值
- (void)trackCashierWithEventName:(NSString *)eventName params:(nullable NSDictionary *)params;

// 在获取到confirm结果前
- (void)beforeConfirmRequest;
// 获取到confirm 结果
- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse;
// 调用query查询前的处理。一次支付或提现流程最多一次
- (void)beforQueryResult;
// 最后一次结果查询结束后调用，因为支付最多会轮训5次，这个时机是最后一次查询，一次支付或提现流程最多一次
- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response;
// 挽留用户，用户点击继续会退出支付流程
- (void)retainUsers;

@end

NS_ASSUME_NONNULL_END
