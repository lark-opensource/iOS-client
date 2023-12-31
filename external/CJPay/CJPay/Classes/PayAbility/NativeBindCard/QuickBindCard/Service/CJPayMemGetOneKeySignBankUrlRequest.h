//
//  CJPayMemGetOneKeySignBankUrlRequest.h
//  Pods
//
//  Created by renqiang on 2021/6/3.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemGetOneKeySignBankUrlResponse;
@interface CJPayMemGetOneKeySignBankUrlRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemGetOneKeySignBankUrlResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
