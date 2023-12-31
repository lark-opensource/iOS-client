//
//  CJPayFetchIMServiceRequest.h
//  Pods
//
//  Created by youerwei on 2021/11/24.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayFetchIMServiceResponse;
@interface CJPayFetchIMServiceRequest : CJPayBaseRequest

+ (void)startWithAppID:(NSString *)appID completion:(void(^)(NSError *error, CJPayFetchIMServiceResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
