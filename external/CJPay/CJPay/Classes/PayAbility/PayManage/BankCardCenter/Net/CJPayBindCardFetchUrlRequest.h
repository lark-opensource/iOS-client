//
//  CJPayBindCardFetchUrlRequest.h
//  Pods
//
//  Created by youerwei on 2022/4/25.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBindCardFetchUrlResponse;
@interface CJPayBindCardFetchUrlRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
              bizParam:(NSDictionary *)bizParam
            completion:(void(^)(NSError *, CJPayBindCardFetchUrlResponse *))completion;

@end

NS_ASSUME_NONNULL_END
