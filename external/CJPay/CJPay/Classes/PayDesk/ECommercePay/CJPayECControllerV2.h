//
//  CJPayECControllerV2.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/2.
//

#import <Foundation/Foundation.h>

#import "CJPayDouPayProcessController.h"
#import "CJPayECController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayECControllerV2 : NSObject

@property (nonatomic, assign, readonly) CJPayCashierScene cashierScene; //标识前置收银台使用场景

- (void)startPaymentWithParams:(NSDictionary *)params completion:(void (^)(CJPayDouPayResultCode resultCode, NSString *errorMsg))completion;

// 返回给电商的性能统计，时间戳
- (NSDictionary *)getPerformanceInfo;
- (NSString *)checkTypeName;

@end

NS_ASSUME_NONNULL_END
