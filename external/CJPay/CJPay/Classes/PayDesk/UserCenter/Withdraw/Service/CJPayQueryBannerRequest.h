//
//  CJPayQueryBannerRequest.h
//  Pods
//
//  Created by mengxin on 2020/12/24.
//

#import "CJPayBaseRequest.h"
#import "CJPayBannerResponse.h"

NS_ASSUME_NONNULL_BEGIN


@interface CJPayQueryBannerRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
              bizParam:(NSDictionary *)bizParam
            completion:(void(^)(NSError * _Nullable error, CJPayBannerResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
