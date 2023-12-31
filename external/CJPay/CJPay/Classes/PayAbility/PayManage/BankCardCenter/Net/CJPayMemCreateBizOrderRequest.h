//
//  CJPayMemCreateBizOrderRequest.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemCreateBizOrderResponse;
@interface CJPayMemCreateBizOrderRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemCreateBizOrderResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
