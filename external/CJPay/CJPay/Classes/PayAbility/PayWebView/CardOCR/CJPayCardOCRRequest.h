//
//  CJPayCardOCRRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/18.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayCardOCRResponse;
@interface CJPayCardOCRRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError *_Nonnull, CJPayCardOCRResponse *_Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
