//
//  CJPayBaseRequest+BDPay.h
//  CJPay
//
//  Created by wangxinhua on 2020/9/4.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseRequest(BDPay)

+ (NSString *)bdpayH5DeskServerHostString;

+ (NSString *)bdpayDeskServerUrlString;

+ (void)setGBDPayConfigHost:(NSString *)configHost;

+ (NSString *)getGBDPayConfigHost;

+ (NSString *)buildServerUrl;

+ (NSString *)apiPath;

+ (NSDictionary *)apiMethod;

@end

NS_ASSUME_NONNULL_END
