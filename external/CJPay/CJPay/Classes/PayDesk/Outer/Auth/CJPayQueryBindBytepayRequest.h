//
//  CJPayQueryBindBytepayRequest.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryBindBytepayResponse;
@interface CJPayQueryBindBytepayRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
              bizParam:(NSDictionary *)bizParam
            completion:(void(^)(NSError *, CJPayQueryBindBytepayResponse *))completion;

@end

NS_ASSUME_NONNULL_END
