//
//  CJPayNewIAPSK2ConfirmRequest.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayNewIAPConfirmResponse;
@interface CJPayNewIAPSK2ConfirmRequest : CJPayBaseRequest

+ (void)startRequest:(NSDictionary *)bizParams
    bizContentParams:(NSDictionary *)params
          completion:(void(^)(NSError *error, CJPayNewIAPConfirmResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
