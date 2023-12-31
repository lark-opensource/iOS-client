//
//  CJPayBaseRequest+BDPay.m
//  CJPay
//
//  Created by wangxinhua on 2020/9/4.
//

#import "CJPayBaseRequest+DyPay.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayHostModel.h"
#import "CJPaySDKMacro.h"

static NSString *gDyPayConfigHost = @"https://webcast.amemv.com";//@"https://cashier.douyinpay.com";//线上环境
//static NSString *gBDPayConfigHost = @"http://bytepay-boe.byted.org";//BOE环境
static NSString *gDyPayH5ConfigHost = @"https://webcast.amemv.com";//@"https://cashier.douyinpay.com";//H5固定域名

@implementation CJPayBaseRequest(DyPay)

+ (NSString *)dypayH5DeskServerHostString {
    return gDyPayH5ConfigHost;
}

+ (NSString *)dypayDeskServerUrlString {
    return [NSString stringWithFormat:@"%@/gateway-bytepay", [self getDyPayConfigHost]];
}

+ (NSString *)buildDyPayServerUrl {
    NSMutableString *url = [NSMutableString stringWithString:[self dypayDeskServerUrlString]];
    [url appendString:[self apiPath]];
    return [url copy];
}

+ (NSString *)getDyPayConfigHost{
    return gDyPayConfigHost;
}

+ (void)setDyPayConfigHost:(NSString *)configHost {
    if (configHost && configHost.length > 0) {
        gDyPayConfigHost = configHost;
    }
}

@end
