//
//  CJPayQueryOneKeySignRequest.h
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryOneKeySignResponse;
@interface CJPayQueryOneKeySignRequest : CJPayBaseRequest

// 签约状态查询
+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void(^)(NSError *error, CJPayQueryOneKeySignResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
