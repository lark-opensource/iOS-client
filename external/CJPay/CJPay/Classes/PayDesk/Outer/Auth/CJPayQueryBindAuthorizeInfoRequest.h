//
//  CJPayQueryBindAuthorizeInfoRequest.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryBindAuthorizeInfoResponse;
@interface CJPayQueryBindAuthorizeInfoRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
              bizParam:(NSDictionary *)bizParam
            completion:(void(^)(NSError *, CJPayQueryBindAuthorizeInfoResponse *))completion;

@end

NS_ASSUME_NONNULL_END
