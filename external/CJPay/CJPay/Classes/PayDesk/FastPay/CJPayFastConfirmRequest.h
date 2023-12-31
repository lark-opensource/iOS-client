//
//  CJPayFastConfirmRequest.h
//  Pods
//
//  Created by bytedance on 2021/5/21.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseRequest.h"
#import "CJPayOrderResultResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFastConfirmRequest : CJPayBaseRequest

+ (void)startFastWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayOrderResultResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
