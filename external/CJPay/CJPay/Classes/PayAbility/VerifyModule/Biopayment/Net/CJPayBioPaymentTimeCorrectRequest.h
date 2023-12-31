//
//  CJPayBioPaymentTimeCorrectRequest.h
//  CJPay
//
//  Created by 王新华 on 2019/1/22.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"


NS_ASSUME_NONNULL_BEGIN
extern double CJPayLocalTimeServerTimeDelta;

@interface CJPayBioPaymentTimeCorrectRequest : CJPayBaseRequest

+ (void)checkServerTimeStamp;

@end

NS_ASSUME_NONNULL_END
