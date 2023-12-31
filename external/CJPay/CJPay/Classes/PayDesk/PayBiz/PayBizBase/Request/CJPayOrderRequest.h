//
//  CJPayOrderRequest.h
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"
#import "CJPayOrderResponse.h"
#import "CJPayCreateOrderResponse.h"

@interface CJPayOrderRequest : CJPayBaseRequest

+ (void)startConfirmWithParams:(NSDictionary *)params
                     traceId:(NSString *)traceId
               processInfoStr:(NSString *)processStr
                   completion:(void(^)(NSError *error, CJPayOrderResponse *response))completionBlock;


@end

