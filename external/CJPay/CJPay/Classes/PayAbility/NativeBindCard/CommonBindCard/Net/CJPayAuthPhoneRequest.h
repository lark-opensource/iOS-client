//
//  CJPayAuthPhoneRequest.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAuthPhoneResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *mobile;

@end

@interface CJPayAuthPhoneRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params
             completion:(void(^)(NSError * _Nullable error, CJPayAuthPhoneResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
