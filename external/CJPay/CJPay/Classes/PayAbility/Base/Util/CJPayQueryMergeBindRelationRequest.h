//
//  CJPayQueryMergeBindRelationRequest.h
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/9/25.
//

#import "CJPayBaseRequest.h"
#import "CJPayQueryMergeBindRelationResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQueryMergeBindRelationRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void(^)(NSError *error, CJPayQueryMergeBindRelationResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
