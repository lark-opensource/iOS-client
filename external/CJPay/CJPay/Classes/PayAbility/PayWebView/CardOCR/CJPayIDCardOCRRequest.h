//
//  CJPayIDCardOCRRequest.h
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayBaseRequest.h"
#import "CJPayIDCardOCRResponse.h"
#import "CJPayIDCardOCRViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIDCardOCRRequest : CJPayBaseRequest

+ (void)startWithScanStatus:(CJPayIDCardOCRScanStatus)scanStatus bizParams:(NSDictionary *)bizParams completion:(void (^)(NSError *_Nonnull, CJPayIDCardOCRResponse *_Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
