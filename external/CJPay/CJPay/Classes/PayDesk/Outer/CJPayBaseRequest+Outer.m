//
//  CJPayBaseRequest+Outer.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/10.
//

#import "CJPayBaseRequest+Outer.h"

#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayHostModel.h"
#import "CJPaySDKMacro.h"

static NSString *gOuterConfigHost = @"https://webcast.amemv.com";//@"https://cashier.douyinpay.com";//线上环境
//static NSString *gBDPayConfigHost = @"http://bytepay-boe.byted.org";//BOE环境
static NSString *gOuterH5ConfigHost = @"https://webcast.amemv.com";//@"https://cashier.douyinpay.com";//H5固定域名

@implementation CJPayBaseRequest (Outer)

+ (NSString *)outerH5DeskServerHostString {
    return gOuterH5ConfigHost;
}

+ (NSString *)outerDeskServerUrlString {
    return [NSString stringWithFormat:@"%@/gateway-bytepay", [self getOuterConfigHost]];
}

+ (NSString *)buildOuterServerUrl {
    NSMutableString *url = [NSMutableString stringWithString:[self outerDeskServerUrlString]];
    [url appendString:[self apiPath]];
    return [url copy];
}

+ (NSString *)getOuterConfigHost{
    return gOuterConfigHost;
}

+ (void)setOuterConfigHost:(NSString *)configHost {
    if (configHost && configHost.length > 0) {
        gOuterConfigHost = configHost;
    }
}
@end
