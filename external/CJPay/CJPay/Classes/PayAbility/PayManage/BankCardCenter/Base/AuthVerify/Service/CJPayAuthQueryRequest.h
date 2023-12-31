//
//  CJPayAuthQueryRequest.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayAuthQueryResponse;
@interface CJPayAuthQueryRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPayAuthQueryResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
