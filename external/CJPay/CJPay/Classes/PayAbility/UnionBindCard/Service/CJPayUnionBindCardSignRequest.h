//
//  CJPayUnionBindCardSignRequest.h
//  Pods
//
//  Created by chenbocheng on 2021/9/27.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardSignResponse;
@interface CJPayUnionBindCardSignRequest : CJPayBaseRequest

+ (void)startRequestWithAppId:(NSString *)appId merchantId:(NSString *)merchantId bizContentParam:(NSDictionary *)bizParam  completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardSignResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
