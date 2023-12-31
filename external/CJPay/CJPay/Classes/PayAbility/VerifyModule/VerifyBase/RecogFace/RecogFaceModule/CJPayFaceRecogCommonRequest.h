//
//  CJPayFaceRecogCommonRequest.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayFaceRecogCommonResponse;
@interface CJPayFaceRecogCommonRequest : CJPayBaseRequest

+ (void)startFaceRecogRequestWithBizParams:(NSDictionary *)bizParams
                           completionBlock:(void(^)(NSError *error, CJPayFaceRecogCommonResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
