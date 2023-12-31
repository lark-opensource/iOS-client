//
//  CJPayAuthCreateRequest.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/26.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayAuthCreateResponse;
@interface CJPayAuthCreateRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPayAuthCreateResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
