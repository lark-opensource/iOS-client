//
//  CJPayMemProtocolListRequest.h
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemProtocolListResponse;
@interface CJPayMemProtocolListRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemProtocolListResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
