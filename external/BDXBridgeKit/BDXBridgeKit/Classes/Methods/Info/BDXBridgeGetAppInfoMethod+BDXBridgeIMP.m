//
//  BDXBridgeGetAppInfoMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/17.
//

#import "BDXBridgeGetAppInfoMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridge+Internal.h"
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <TTReachability/TTReachability.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@implementation BDXBridgeGetAppInfoMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeGetAppInfoMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeInfoServiceProtocol> infoService = bdx_get_service(BDXBridgeInfoServiceProtocol);
    bdx_complete_if_not_implemented(infoService);
    
    BDXBridgeGetAppInfoMethodResultModel *resultModel = [BDXBridgeGetAppInfoMethodResultModel new];
    if ([infoService respondsToSelector:@selector(channel)]) {
        resultModel.channel = [infoService channel];
    }
    if ([infoService respondsToSelector:@selector(language)]) {
        resultModel.language = [infoService language];
    }
    if ([infoService respondsToSelector:@selector(appTheme)]) {
        resultModel.appTheme = [infoService appTheme];
    }
    if ([infoService respondsToSelector:@selector(isTeenMode)]) {
        resultModel.isTeenMode = [infoService isTeenMode];
    }
    resultModel.appID = [UIApplication btd_appID];
    resultModel.appName = [UIApplication btd_appDisplayName];
    resultModel.appVersion = [UIApplication btd_versionName];
    resultModel.devicePlatform = [[UIApplication btd_platformName] lowercaseString];
    resultModel.deviceModel = [[UIDevice btd_hwmodel] lowercaseString];
    resultModel.osVersion = [UIDevice btd_OSVersion];
    resultModel.statusBarHeight = @(UIApplication.sharedApplication.statusBarFrame.size.height);
    resultModel.installID = [BDTrackerProtocol installID];
    resultModel.netType = [self netType];
    resultModel.carrier = [self carrierName];
    resultModel.is32Bit = (sizeof(void *) == 4);
    
    bdx_invoke_block(completionHandler, resultModel, nil);
}

- (NSString *)netType
{
    TTReachability *reachability = [TTReachability reachabilityForInternetConnection];
    if ([reachability currentReachabilityStatus]) {
        return @"wifi";
    } else if ([TTReachability is5GConnected]) {
        return @"5g";
    } else if ([TTReachability is4GConnected]) {
        return @"4g";
    } else if ([TTReachability is3GConnected]) {
        return @"3g";
    } else if ([TTReachability is2GConnected]) {
        return @"mobile";
    } else {
        return @"none";
    }
}

- (NSString *)carrierName
{
    CTTelephonyNetworkInfo *networkInfo = [CTTelephonyNetworkInfo new];
    return networkInfo.subscriberCellularProvider.carrierName;
}

@end
