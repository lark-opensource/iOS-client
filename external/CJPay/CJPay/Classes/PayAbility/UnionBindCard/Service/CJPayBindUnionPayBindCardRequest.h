//
//  CJPayBindUnionPayBindCardRequest.h
//  CJPay-5b542da5
//
//  Created by bytedance on 2022/9/7.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBindUnionPayBankCardResponse;

@interface CJPayBindUnionPayBindCardRequest : CJPayBaseRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void (^)(NSError * _Nonnull, CJPayBindUnionPayBankCardResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
