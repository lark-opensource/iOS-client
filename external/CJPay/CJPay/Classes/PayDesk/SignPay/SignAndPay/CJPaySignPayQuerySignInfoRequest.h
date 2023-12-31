//
//  CJPaySignPayQuerySignInfoRequest.h
//  Pods
//
//  Created by chenbocheng on 2022/7/12.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignPayQuerySignInfoResponse;

@interface CJPaySignPayQuerySignInfoRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignPayQuerySignInfoResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
