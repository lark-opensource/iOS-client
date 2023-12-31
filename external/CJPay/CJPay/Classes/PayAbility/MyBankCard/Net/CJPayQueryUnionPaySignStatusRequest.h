//
//  CJPayQueryUnionPaySignStatusRequest.h
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/8/31.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryUnionPaySignStatusResponse;

@interface CJPayQueryUnionPaySignStatusRequest : CJPayBaseRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void (^)(NSError * _Nonnull, CJPayQueryUnionPaySignStatusResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
