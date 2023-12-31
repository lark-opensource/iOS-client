//
//  CJPayPayAgainTradeCreateRequest.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayPayAgainTradeCreateResponse;
@interface CJPayPayAgainTradeCreateRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void(^)(NSError *error, CJPayPayAgainTradeCreateResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
