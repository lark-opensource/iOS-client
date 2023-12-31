//
//  CJPaySignOnlyBindBytePayAccountRequest.h
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignOnlyBindBytePayAccountResponse;
@interface CJPaySignOnlyBindBytePayAccountRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignOnlyBindBytePayAccountResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
