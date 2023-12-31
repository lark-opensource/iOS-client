//
//  HMDNetworkHelper.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/26.
//

#import "HMDNetworkHelper.h"
#import "HMDNetworkReachability.h"
#include <ifaddrs.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <netdb.h>
#import <TTReachability/TTReachability+Conveniences.h>
#import "HMDNetQualityTracker.h"
#if !SIMPLIFYEXTENSION
#import "HMDInjectedInfo.h"
#endif

#if __has_feature(modules)
@import CoreTelephony;
#else
#import <CoreTelephony/CoreTelephony.h>
#endif

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

typedef NS_ENUM(NSUInteger, HMDNetworkTypeUploadCode) {
    HMDNetworkTypeUploadCodeUnKnown = -1,
    HMDNetworkTypeUploadCodeUnConnect = 0,
    HMDNetworkTypeUploadCodeMobile = 1,
    HMDNetworkTypeUploadCode2G = 2,
    HMDNetworkTypeUploadCode3G = 3,
    HMDNetworkTypeUploadCodeWiFi = 4,
    HMDNetworkTypeUploadCode4G = 5,
    HMDNetworkTypeUploadCode5G = 6
};

@implementation HMDNetworkHelper

+ (NSString *)connectTypeName {
    NSString * netType = @"";
    if([HMDNetworkReachability isWifiConnected])
    {
        netType = @"WIFI";
    }
    else if([HMDNetworkReachability is5GConnected])
    {
        netType = @"5G";
    }
    else if([HMDNetworkReachability is4GConnected])
    {
        netType = @"4G";
    }
    else if([HMDNetworkReachability is3GConnected])
    {
        netType = @"3G";
    }
    else if([HMDNetworkReachability isConnected])
    {
        netType = @"mobile";
    }
    return netType;
}

+ (NSInteger)connectTypeCode {
    NSInteger netCode = -1;
    if([HMDNetworkReachability isWifiConnected])
    {
        netCode = 4;
    }
    else if ([HMDNetworkReachability is5GConnected])
    {
        netCode = 6;
    }
    else if([HMDNetworkReachability is4GConnected])
    {
        netCode = 5;
    }
    else if([HMDNetworkReachability is3GConnected])
    {
        netCode = 3;
    }
    else if ([HMDNetworkReachability is2GConnected])
    {
        netCode = 2;
    }
    else if(![HMDNetworkReachability isConnected])
    {
        netCode = 0;
    }
    return netCode;
}

+ (NSString *)connectTypeNameForCellularDataService {
    // 如果当前是 WiFi 直接返回 WiFi
    if([HMDNetworkReachability isWifiConnected]) {
        return @"WIFI";
    }
    // 如果是非 WiFi 环境,那么使用的是数据流量,数据流量的网络类型优先判断流量卡的
    if (@available(iOS 13.0, *)) {
        NSString * networkTypeName = @"";
        TTCellularNetworkConnectionType networkType = [TTReachability currentCellularConnectionForDataService];
        switch (networkType) {
            case TTCellularNetworkConnectionNone:
            case TTCellularNetworkConnectionUnknown:
            {
                networkTypeName = [HMDNetworkHelper connectTypeName];
            }
                break;
            case TTCellularNetworkConnection2G:
                networkTypeName = @"mobile";
                break;
            case TTCellularNetworkConnection3G:
                networkTypeName = @"3G";
                break;
            case TTCellularNetworkConnection4G:
                networkTypeName = @"4G";
                break;
            case TTCellularNetworkConnection5G:
                networkTypeName = @"5G";
                break;
            default:
                networkTypeName = @"unknown";
                break;
        }
        return networkTypeName;
    }

    return [HMDNetworkHelper connectTypeName];
}

+ (NSInteger)connectTypeCodeForCellularDataService {
    // 如果当前是 WiFi 直接返回 WiFi
    if([HMDNetworkReachability isWifiConnected]) {
        return HMDNetworkTypeUploadCodeWiFi;
    }
    // 如果是非 WiFi 环境,那么使用的是数据流量,数据流量的网络类型优先判断流量卡的
    if (@available(iOS 13.0, *)) {
        NSInteger networkTypeCode = -1;
        TTCellularNetworkConnectionType networkType = [TTReachability currentCellularConnectionForDataService];
        switch (networkType) {
            case TTCellularNetworkConnectionNone:
            case TTCellularNetworkConnectionUnknown:
            {
                networkTypeCode = [HMDNetworkHelper connectTypeCode];
            }
                break;
            case TTCellularNetworkConnection2G:
                networkTypeCode = HMDNetworkTypeUploadCode2G;
                break;
            case TTCellularNetworkConnection3G:
                networkTypeCode = HMDNetworkTypeUploadCode3G;
                break;
            case TTCellularNetworkConnection4G:
                networkTypeCode = HMDNetworkTypeUploadCode4G;
                break;
            case TTCellularNetworkConnection5G:
                networkTypeCode = HMDNetworkTypeUploadCode5G;
                break;
            default:
                networkTypeCode = HMDNetworkTypeUploadCodeUnKnown;
                break;
        }
        return networkTypeCode;
    }

    return [HMDNetworkHelper connectTypeCode];
}

#if !SIMPLIFYEXTENSION
+ (NSString *)carrierName {
    HMDCarrierMessageBlock block = [HMDInjectedInfo defaultInfo].carrierMessageBlock;
    NSString *carrierName = nil;
    if (block) {
        NSArray<NSString *> *carriersName = block(HMDCarrrierPropertyCarrierName);
        if (carriersName.count == 0) return nil;
        carrierName = [carriersName firstObject];
    } else {
        NSArray<CTCarrier *> *carriers = [TTReachability currentPrioritizedCellularProviders];
        if(carriers.count == 0) return nil;
        CTCarrier *mainCarrier = carriers.firstObject;
        carrierName = [mainCarrier carrierName];
    }
    
    NSData *carrierNameData = [carrierName dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64CarrierName = [carrierNameData base64EncodedStringWithOptions:0];
    if ([base64CarrierName isEqualToString:@"5Lit5Zu956e75Yqo"]){
        return @"CMobile";
    } else if ([base64CarrierName isEqualToString:@"5Lit5Zu955S15L+h"]){
        return @"CTelecom";
    } else if ([base64CarrierName isEqualToString:@"5Lit5Zu96IGU6YCa"]){
        return @"CUnicom";
    }
    
    return carrierName;
}

+ (NSString *)carrierMCC {
    HMDCarrierMessageBlock block = [HMDInjectedInfo defaultInfo].carrierMessageBlock;
    NSString *mcc = nil;
    if (block) {
        NSArray<NSString *> *carriersMCC = block(HMDCarrrierPropertyMCC);
        if (carriersMCC.count == 0) return nil;
        mcc = [carriersMCC firstObject];
    } else {
        NSArray<CTCarrier *> *carriers = [TTReachability currentPrioritizedCellularProviders];
        if(carriers.count == 0) return nil;
        CTCarrier *mainCarrier = carriers.firstObject;
        mcc = [mainCarrier mobileCountryCode];
    }
    return mcc;
}

+ (NSString *)carrierMNC {
    HMDCarrierMessageBlock block = [HMDInjectedInfo defaultInfo].carrierMessageBlock;
    NSString *mnc = nil;
    if (block) {
        NSArray<NSString *> *carriersMNC = block(HMDCarrrierPropertyMNC);
        if (carriersMNC.count == 0) return nil;
        mnc = [carriersMNC firstObject];
    } else {
        NSArray<CTCarrier *> *carriers = [TTReachability currentPrioritizedCellularProviders];
        if(carriers.count == 0) return nil;
        CTCarrier *mainCarrier = carriers.firstObject;
        mnc = [mainCarrier mobileNetworkCode];
    }
    return mnc;
}

+ (nullable NSArray<NSString *> *)carrierRegions {
    HMDCarrierMessageBlock block = [HMDInjectedInfo defaultInfo].carrierMessageBlock;
    if (block) {
        NSArray<NSString *> *carriersRegion = block(HMDCarrrierPropertyISOCountryCode);
        return carriersRegion;
    } else {
        NSArray<CTCarrier *> *carriers = [TTReachability currentPrioritizedCellularProviders];
        if(carriers.count == 0) return nil;
        NSMutableArray<NSString *> *carrierRegions = [NSMutableArray array];
        for (CTCarrier *carrier in carriers) {
            NSString *regionCode = [[carrier isoCountryCode] uppercaseString];
            if (regionCode) {
                [carrierRegions addObject:regionCode];
            }
        }
        return [carrierRegions copy];
    }
}
#endif

+ (NSString *)currentRadioAccessTechnology {
    NSArray<NSString *> *accessTechbologies = [TTReachability currentPrioritizedRadioAccessTechnologies];
    if (accessTechbologies.count == 0) return nil;
    
    NSString *mainAccessTechbology = accessTechbologies.firstObject;
    return mainAccessTechbology;
}

+ (NSInteger)currentNetQuality {
    return [HMDNetQualityTracker sharedTracker].currentNetQuality;
}

@end
