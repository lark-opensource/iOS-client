//
//  CJPayModifyMemberElementsRequest.h
//  CJPay
//
//  Created by youerwei on 2022/6/22.
//

#import "CJPayBaseRequest.h"
#import "CJPayModifyMemberElementsResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayModifyMemberElementsRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError *_Nonnull, CJPayModifyMemberElementsResponse *_Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
