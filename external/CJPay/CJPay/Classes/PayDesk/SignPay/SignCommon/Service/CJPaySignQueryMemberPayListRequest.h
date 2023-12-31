//
//  CJPaySignQueryMemberPayListRequest.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignQueryMemberPayListResponse;
@interface CJPaySignQueryMemberPayListRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignQueryMemberPayListResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
