//
//  CJPayMemRecogFaceRequest.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/30.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemberFaceVerifyResponse;
@interface CJPayMemRecogFaceRequest : CJPayBaseRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void(^)(NSError *error, CJPayMemberFaceVerifyResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
