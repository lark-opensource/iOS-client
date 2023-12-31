//
//  CJPayFaceRecogSignRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/20.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBaseResponse;
@interface CJPayFaceRecogSignRequest : CJPayBaseRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
              bizContentParams:(NSDictionary *)bizContentParams
                  completion:(void(^)(NSError *error, CJPayBaseResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
