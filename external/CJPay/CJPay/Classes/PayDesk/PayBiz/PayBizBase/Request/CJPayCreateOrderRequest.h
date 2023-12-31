//
//  CJPayCreateOrderRequest.h
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"
#import "CJPayCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN
//下单请求
@interface CJPayCreateOrderRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock;

@end
NS_ASSUME_NONNULL_END

