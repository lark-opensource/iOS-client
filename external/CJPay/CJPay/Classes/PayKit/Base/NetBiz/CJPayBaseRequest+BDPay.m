//
//  CJPayBaseRequest+BDPay.m
//  CJPay
//
//  Created by wangxinhua on 2020/9/4.
//

#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayHostModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

static NSString *gBDPayConfigHost = @"https://cashier.ulpay.com";//线上环境
//static NSString *gBDPayConfigHost = @"http://bytepay-boe.byted.org";//BOE环境
static NSString *gBDPayH5ConfigHost = @"https://cashier.ulpay.com";//H5固定域名


@implementation CJPayBaseRequest(BDPay)

+ (NSString *)bdpayH5DeskServerHostString {
    return gBDPayH5ConfigHost;
}

+ (NSString *)bdpayDeskServerUrlString {
    NSString *bdpayPath = [CJPayRequestParam isSaasEnv] ? @"gateway-bytepay-saas" : @"gateway-bytepay";
    return [NSString stringWithFormat:@"%@/%@", [self getGBDPayConfigHost], bdpayPath];
}

+ (NSString *)buildServerUrl {
    NSMutableString *url = [NSMutableString stringWithString:[self bdpayDeskServerUrlString]];
    [url appendString:[self apiPath]];
    return [url copy];
}


+ (NSString *)apiPath {
    return @"";
}

+ (NSDictionary *)apiMethod {
    NSString *str = [[self apiPath] stringByReplacingOccurrencesOfString:@"/" withString:@"."];
    if (str.length >= 1) {
        str = [str substringFromIndex:1];
    }
    return @{@"method":str};
}

+ (NSString *)getGBDPayConfigHost{
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    NSString *bdHost = curSettings.cjpayNewCustomHost.bdHostDomain;
    if (curSettings && Check_ValidString(bdHost)) {
        if([bdHost hasPrefix:@"http"]){
            gBDPayConfigHost = bdHost;
        }else{
            gBDPayConfigHost = [NSString stringWithFormat:@"https://%@", bdHost];
        }
    }
    return gBDPayConfigHost;
}

+ (void)setGBDPayConfigHost:(NSString *)configHost {
    if (configHost && configHost.length > 0) {
        gBDPayConfigHost = configHost;
    }
}

@end
