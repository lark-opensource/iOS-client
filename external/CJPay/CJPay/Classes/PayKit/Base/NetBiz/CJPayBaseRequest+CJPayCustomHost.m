//
//  CJPayBaseRequest+CJPayCustomHost.m
//  CJPay
//
//  Created by wangxinhua on 2020/4/28.
//

#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"

@implementation CJPayBaseRequest(CJPayCustomHost)

+ (NSString *)customDeskServerUrlString {
    if (Check_ValidString([self intergratedConfigHost])) {
        return [NSString stringWithFormat:@"https://%@/gateway-cashier2", [self intergratedConfigHost]];
    } else {
        return [self cashierServerUrlString];
    }
}

+ (NSString *)jhHostString {
    if (Check_ValidString([self intergratedConfigHost])) {
        return [NSString stringWithFormat:@"https://%@",[self intergratedConfigHost]];
    } else {
        return [self gConfigHost];
    }
}

+ (NSString *)superPayServerUrlString {
    if (Check_ValidString([self intergratedConfigHost])) {
        return [NSString stringWithFormat:@"https://%@/gateway", [self intergratedConfigHost]];
    } else {
        return [NSString stringWithFormat:@"%@/gateway", [self deskServerHostString]];
    }
}

+ (NSString *)intergratedConfigHost {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    return curSettings.cjpayCustomHost ?: @"";
}

@end
