//
//  CJPayIAPConfigRequest.h
//  Aweme
//
//  Created by bytedance on 2022/12/16.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayIAPConfigResponse;

@interface CJPayIAPConfigRequest : CJPayBaseRequest

+ (void)startRequest:(NSDictionary *)params
          completion:(void(^)(NSError *error, CJPayIAPConfigResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
