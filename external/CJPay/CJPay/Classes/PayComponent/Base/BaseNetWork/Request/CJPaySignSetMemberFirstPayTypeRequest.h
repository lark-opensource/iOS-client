//
//  CJPaySignSetMemberFirstPayTypeRequest.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignSetMemberFirstPayTypeResponse;
@interface CJPaySignSetMemberFirstPayTypeRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignSetMemberFirstPayTypeResponse *response))completionBlock;


@end

NS_ASSUME_NONNULL_END
