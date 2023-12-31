//
//  CJPayQueryPayTypeRequest.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryPayTypeResponse;
@interface CJPayQueryPayTypeRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void(^)(NSError *error, CJPayQueryPayTypeResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
