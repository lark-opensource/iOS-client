//
//  BDUGOnekeyLoginTracker.m
//  Pods
//
//  Created by xunianqiang on 2020/6/17.
//

#import "BDUGOnekeyLoginTracker.h"
#import "BDUGAccountOnekeyLogin.h"
#if __has_include(<BDTrackerProtocol/BDTrackerProtocol.h>)
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#endif


@implementation BDUGOnekeyLoginTracker

+ (NSString *)trackServiceOfService:(NSString *)service {
    if ([service isEqualToString:BDUGAccountOnekeyMobile]) {
        return @"china_mobile";
    } else if ([service isEqualToString:BDUGAccountOnekeyTelecom]) {
        return @"china_telecom";
    } else if ([service isEqualToString:BDUGAccountOnekeyUnion]) {
        return @"china_unicom";
    } else {
        return @"unkonwn";
    }
}

+ (NSString *)trackNetworkTypeOfService:(BDUGAccountNetworkType)networkType {
    NSString *result = @"error";
    switch (networkType) {
        case BDUGAccountNetworkTypeWifi:
            result = @"wifi";
            break;
        case BDUGAccountNetworkTypeDataFlow:
            result = @"cellular";
            break;
        case BDUGAccountNetworkTypeDataFlowAndWifi:
            result = @"cellular&wifi";
            break;
        case BDUGAccountNetworkTypeNoNet:
            result = @"no_network";
            break;
        case BDUGAccountNetworkTypeUnknown:
            result = @"error";
            break;
        default:
            break;
    }

    return result;
}

+ (void)trackerEvent:(NSString *)event params:(NSDictionary *_Nullable)params {
    NSMutableDictionary *trackParams = params.mutableCopy ?: [NSMutableDictionary dictionary];
    [trackParams setValue:@"uc_login" forKey:@"params_for_special"];
    [BDUGAccountOnekeyLogin.sharedInstance.delegate event:event params:trackParams];
#if __has_include(<BDTrackerProtocol/BDTrackerProtocol.h>)
    [BDTrackerProtocol eventV3:event params:[trackParams copy]];
#endif
}

@end
