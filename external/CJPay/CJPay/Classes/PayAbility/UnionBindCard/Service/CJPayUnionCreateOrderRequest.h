//
//  CJPayUnionCreateOrder.h
//  Pods
//
//  Created by xutianxi on 2021/10/8.
//

#import "CJPayBaseRequest.h"
#import "CJPayUnionCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayUnionCreateOrderRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayUnionCreateOrderResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
