//
//  BDUGAccountNetworkHelper.m
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/7/29.
//

#import "BDUGAccountNetworkHelper.h"
#import <CoreTelephony/CTCarrier.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <TTReachability/TTReachability.h>
#import "BDUGOnekeySettingManager.h"
#import <TYRZSDK/TYRZSDK.h>


@implementation BDUGAccountNetworkHelper

+ (BDUGAccountNetworkType)networkType {
    NetworkStatus reachablityNetworkStatus = [[TTReachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (reachablityNetworkStatus == NotReachable) {
        return BDUGAccountNetworkTypeNoNet;
    } else if (reachablityNetworkStatus == ReachableViaWWAN) {
        return BDUGAccountNetworkTypeDataFlow;
    } else {
        if ([self fastDetectActiveIfAddrsStatus] & BDUGAccountIfAddrsStatusWithWWAN) {
            return BDUGAccountNetworkTypeDataFlowAndWifi;
        } else {
            return BDUGAccountNetworkTypeWifi;
        }
    }
}

+ (BDUGAccountCarrierType)carrierType {
    NSDictionary<NSString *, NSNumber *> *networkInfo = [[UASDKLogin shareLogin] networkInfo];
    BDUGAccountCarrierType networkInfoCarrier = networkInfo[@"carrier"].unsignedLongValue;
    if (networkInfoCarrier != BDUGAccountCarrierTypeUnknown) {
        return networkInfoCarrier;
    } else {
        return [self carrierTypeUseOldMethod];
    }
}

+ (BDUGAccountCarrierType)carrierTypeUseOldMethod {
    if (@available(iOS 13.0, *)) {
        CTCarrier *carrier = [TTReachability currentCellularProviderForDataService];
        if (carrier && [carrier isKindOfClass:[CTCarrier class]]) {
            NSString *carrierName = carrier.carrierName;
            if ([carrierName isEqualToString:@"中国移动"]) {
                return BDUGAccountCarrierTypeMobile;
            } else if ([carrierName isEqualToString:@"中国联通"]) {
                return BDUGAccountCarrierTypeUnicom;
            } else if ([carrierName isEqualToString:@"中国电信"]) {
                return BDUGAccountCarrierTypeTelecom;
            } else {
                return BDUGAccountCarrierTypeUnknown;
            }
        }
    } else if (@available(iOS 12.0, *)) {
        NSArray *array = [[TTReachability currentAvailableCellularServices] copy];
        if (array.count == 2 && [[BDUGOnekeySettingManager sharedInstance] useNewAPIGetCarrier]) {
            UIApplication *app = [UIApplication sharedApplication];
            id statusBar = [app valueForKeyPath:@"statusBar"];
            if ([statusBar isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
                id curData = [statusBar valueForKeyPath:@"statusBar.currentData.cellularEntry.string"];
                if ([curData isEqualToString:@"中国电信"]) {
                    return BDUGAccountCarrierTypeTelecom;
                } else if ([curData isEqualToString:@"中国联通"]) {
                    return BDUGAccountCarrierTypeUnicom;
                } else if ([curData isEqualToString:@"中国移动"]) {
                    return BDUGAccountCarrierTypeMobile;
                }
            }
        }
    }
    BDUGAccountCarrierType carrierType = BDUGAccountCarrierTypeUnknown;
    TTCellularServiceType currentCellular = [self currentDataCellular];
    CTCarrier *carrier = [TTReachability currentCellularProviderForService:currentCellular];
    if (carrier) {
        NSString *mcc = carrier.mobileCountryCode;
        NSString *mnc = carrier.mobileNetworkCode;
        if ([mcc isEqualToString:@"460"]) {
            if ([mnc isEqualToString:@"00"] ||
                [mnc isEqualToString:@"02"] ||
                [mnc isEqualToString:@"04"] ||
                [mnc isEqualToString:@"07"]) {
                carrierType = BDUGAccountCarrierTypeMobile;
            }
            if ([mnc isEqualToString:@"01"] ||
                [mnc isEqualToString:@"06"] ||
                [mnc isEqualToString:@"09"]) {
                carrierType = BDUGAccountCarrierTypeUnicom;
            }
            if ([mnc isEqualToString:@"03"] ||
                [mnc isEqualToString:@"05"] ||
                [mnc isEqualToString:@"11"]) {
                carrierType = BDUGAccountCarrierTypeTelecom;
            }
        }
    }
    return carrierType;
}

// 当前流量卡,都没有开启时返回主卡类型
+ (TTCellularServiceType)currentDataCellular {
    NSArray *array = [[TTReachability currentAvailableCellularServices] copy];
    if (array) {
        for (NSNumber *number in array) {
            if ([number integerValue] == 2 && [self isOpenDataOfCellular:TTCellularServiceTypeSecondary]) {
                return TTCellularServiceTypeSecondary;
            }
        }
    }
    return TTCellularServiceTypePrimary;
}

// 该类型卡是否开启数据流量
+ (BOOL)isOpenDataOfCellular:(TTCellularServiceType)serviceType {
    TTCellularNetworkConnectionType networkType = [TTReachability currentCellularConnectionForService:serviceType];
    if (networkType == TTCellularNetworkConnectionNone) {
        return NO;
    } else {
        return YES;
    }
}

+ (BDUGAccountIfAddrsStatus)fastDetectActiveIfAddrsStatus {
    // 执行速度 < 1ms (iPhone 6s, 10.3.2)
    BDUGAccountIfAddrsStatus status = BDUGAccountIfAddrsStatusNone;
    @try {
        struct ifaddrs *interfaces, *i;
        if (!getifaddrs(&interfaces)) {
            i = interfaces;
            while (i != NULL) {
                if (i->ifa_addr->sa_family == AF_INET || i->ifa_addr->sa_family == AF_INET6) {
                    const char *name = i->ifa_name;
                    const char *address = inet_ntoa(((struct sockaddr_in *)i->ifa_addr)->sin_addr);
                    /**
                     iOS的WiFi切换，在从关闭到打开的状态下，约有2秒的延迟后，SCNetworkReachabilityRef才会触发callback
                     但是在切换的瞬间，WiFi intertface（en0）就立即能够获取，这2秒内，对应的IP地址会先变成0.0.0.0，或者127.0.0.1，最后才是正确的IP
                     因此，这里判断需要过滤一次，否则网络权限检测会误判定这2秒内属于WLANAndCellularNotPermitted
                     */
                    if (strcmp(address, "0.0.0.0") != 0 && strcmp(address, "127.0.0.1") != 0) {
                        if (strcmp(name, "en0") == 0) {
                            status |= BDUGAccountIfAddrsStatusWithWIFI;
                        } else if (strcmp(name, "pdp_ip0") == 0) {
                            status |= BDUGAccountIfAddrsStatusWithWWAN;
                        }
                    }
                }
                // 如果两个都有了，不用再继续判断了
                if ((status & BDUGAccountIfAddrsStatusWithWIFI) && (status & BDUGAccountIfAddrsStatusWithWWAN)) {
                    break;
                }
                i = i->ifa_next;
            }
        }

        freeifaddrs(interfaces);
        interfaces = NULL;
    } @catch (NSException *exception) {
    }

    // 如果 status != None，说明已经找到 WWAN 或者 WIFI，将 None 去除
    if (status != BDUGAccountIfAddrsStatusNone) {
        status ^= BDUGAccountIfAddrsStatusNone;
    }
    return status;
}

@end
