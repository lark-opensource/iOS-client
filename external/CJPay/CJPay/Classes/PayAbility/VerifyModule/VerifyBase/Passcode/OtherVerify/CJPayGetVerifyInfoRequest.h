//
//  CJPayGetVerifyInfoRequest.h
//  Pods
//
//  Created by wangxinhua on 2021/7/30.
//

#import "CJPayBaseRequest.h"
#import "CJPayVerifyInfoResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayGetVerifyInfoRequest : CJPayBaseRequest

+ (void)startVerifyInfoRequestWithAppid:(NSString *)appid merchantId:(NSString *)merchantId bizContentParams:(NSDictionary *)params completionBlock:(void(^)(NSError *error, CJPayVerifyInfoResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
