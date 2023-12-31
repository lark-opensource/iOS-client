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
@interface CJPayCreateOrderByTokenRequest : CJPayBaseRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock;

// @xiongpeng: 此方法可以通过highPriority参数设置优先级，一般情况下不要使用。
+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
              highPriority:(BOOL)highPriority
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END

