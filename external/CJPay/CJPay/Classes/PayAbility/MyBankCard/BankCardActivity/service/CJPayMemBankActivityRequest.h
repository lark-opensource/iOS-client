//
//  CJPayMemBankActivityRequest.h
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBaseRequest.h"

@class CJPayMemBankActivityResponse;
NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemBankActivityRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemBankActivityResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
