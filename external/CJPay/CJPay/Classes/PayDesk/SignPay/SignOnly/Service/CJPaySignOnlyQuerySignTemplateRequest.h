//
//  CJPaySignOnlyQuerySignTemplateRequest.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPaySignOnlyQuerySignTemplateResponse;
@interface CJPaySignOnlyQuerySignTemplateRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignOnlyQuerySignTemplateResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
