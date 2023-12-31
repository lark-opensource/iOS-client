//
//  CJPayBaseRequest+DyPay.h
//  CJPay
//
//  Created by wangxinhua on 2020/9/4.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseRequest (DyPay)

+ (NSString *)dypayH5DeskServerHostString;

+ (NSString *)dypayDeskServerUrlString;

+ (void)setDyPayConfigHost:(NSString *)configHost;

+ (NSString *)getDyPayConfigHost;

+ (NSString *)buildDyPayServerUrl;

@end

NS_ASSUME_NONNULL_END
