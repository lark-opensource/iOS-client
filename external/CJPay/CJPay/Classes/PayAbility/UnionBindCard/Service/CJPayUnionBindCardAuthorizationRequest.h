//
//  CJPayUnionBindCardAuthorizationRequest.h
//  Pods
//
//  Created by chenbocheng on 2021/9/28.
//

#import "CJPayBaseRequest.h"

#import "CJPayUnionBindCardAuthorizationResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardAuthorizationResponse;
@interface CJPayUnionBindCardAuthorizationRequest : CJPayBaseRequest

+ (void)startRequestWithParams:(NSDictionary *)params  completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardAuthorizationResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
