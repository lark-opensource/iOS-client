//
//  CJPayUnionBindCardListRequest.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUnionBindCardListResponse;
@interface CJPayUnionBindCardListRequest : CJPayBaseRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardListResponse * _Nonnull))completionBlock;


@end

NS_ASSUME_NONNULL_END
