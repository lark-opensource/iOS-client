//
//  CJPayUnlockBankCardRequest.h
//  Aweme
//
//  Created by youerwei on 2023/6/7.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseResponse;
@interface CJPayUnlockBankCardRequest : CJPayBaseRequest

+ (void)startRequestWithBizParam:(NSDictionary *)bizParam completion:(void (^)(NSError *, CJPayBaseResponse *))completion;

@end

NS_ASSUME_NONNULL_END
