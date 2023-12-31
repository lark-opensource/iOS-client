//
//  OKReachability+Authorization.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKReachability+Authorization.h"
#import "OKCellular.h"
#import <ifaddrs.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#import <CoreTelephony/CTCellularData.h>

typedef NS_OPTIONS(NSInteger, OKActiveIfAddrsStatus) {
    OKActiveIfAddrsStatusNone = 1,
    OKActiveIfAddrsStatusWithWWAN = OKActiveIfAddrsStatusNone << 1,
    OKActiveIfAddrsStatusWithWiFi = OKActiveIfAddrsStatusNone << 2
};

@implementation OKReachability (Authorization)


+ (OKActiveIfAddrsStatus)fastDetectActiveIfAddrsStatus {
    // 执行速度 < 1ms (iPhone 6s, 10.3.2)
    OKActiveIfAddrsStatus status = OKActiveIfAddrsStatusNone;
    @try {
        struct ifaddrs *interfaces, *i;
        if (!getifaddrs(&interfaces)) {
            i = interfaces;
            while(i != NULL) {
                if(i->ifa_addr->sa_family == AF_INET
                   || i->ifa_addr->sa_family == AF_INET6) {
                    const char *name = i->ifa_name;
                    const char *address = inet_ntoa(((struct sockaddr_in *)i->ifa_addr)->sin_addr);
                    /**
                     iOS的WiFi切换，在从关闭到打开的状态下，约有2秒的延迟后，SCNetworkReachabilityRef才会触发callback
                     但是在切换的瞬间，WiFi intertface（en0）就立即能够获取，这2秒内，对应的IP地址会先变成0.0.0.0，或者127.0.0.1，最后才是正确的IP
                     因此，这里判断需要过滤一次，否则网络权限检测会误判定这2秒内属于WLANAndCellularNotPermitted
                     */
                    if (strcmp(address, "0.0.0.0") != 0 && strcmp(address, "127.0.0.1") != 0) {
                        if (strcmp(name, "en0") == 0) {
                            status |= OKActiveIfAddrsStatusWithWiFi;
                        } else if (strcmp(name, "pdp_ip0") == 0) {
                            // 卡1
                            status |= OKActiveIfAddrsStatusWithWWAN;
                        } else if (strcmp(name, "pdp_ip1") == 0) {
                            // 卡2
                            status |= OKActiveIfAddrsStatusWithWWAN;
                        }
                    }
                }
                // 如果两个都有了，不用再继续判断了
                if ((status & OKActiveIfAddrsStatusWithWiFi)
                    && (status & OKActiveIfAddrsStatusWithWWAN)) {
                    break;
                }
                i = i->ifa_next;
            }
        }
        
        freeifaddrs(interfaces);
        interfaces = NULL;
    } @catch (NSException *exception) {
    }
    
    // 如果 status != None，说明已经找到 WWAN 或者 WiFi，将 None 去除
    if (status != OKActiveIfAddrsStatusNone) {
        status ^= OKActiveIfAddrsStatusNone;
    }
    
    return status;
}

+ (OKNetworkAuthorizationStatus)currentAuthorizationStatus {
    OKReachabilityStatus status = [[OKReachability sharedInstance] currentReachabilityStatus];
    if (status != OKReachabilityStatusNotReachable) {
        return OKNetworkAuthorizationStatusNotDetermined;
    }
    
    OKActiveIfAddrsStatus activeIfAddrs = [OKReachability fastDetectActiveIfAddrsStatus];
    ///  当前 App 当前不可联网
    ///    如果系统有 WiFi 连接，则判断为 未开启无线局域网与蜂窝移动网络权限
    ///    如果系统有 WWAN 连接，则判断为 未开启蜂窝移动网络权限
    ///    判断顺序为先 WiFi 后 WWAN，不能反，否则会在国行 iPhone 上造成误判，将 “全部未开” 误判成 “未开蜂窝”
    BOOL dataRestricted;
    if (@available(iOS 9.0, *)) {
        CTCellularDataRestrictedState cellState = [[CTCellularData alloc] init].restrictedState; /// 蜂窝授权状态
        dataRestricted = (cellState == kCTCellularDataRestricted);
    } else {
        dataRestricted = YES; /// iOS 9以下假设永远受限，走复杂判定逻辑
    }
    if (dataRestricted && (activeIfAddrs & OKActiveIfAddrsStatusNone) == 0) {
        /// 蜂窝未授权，且手机实际已联网
        /// 由于发现苹果WiFi状态变化有时候会滞后，这里加一个额外的判定逻辑
        /// 如果经过一次App活跃状态切换，并且上一次“可用的检测”还没别覆盖，直接返回NotDetermined
        if ([OKReachability sharedInstance].telephoneInfoIndeterminateStatus) {
            return OKNetworkAuthorizationStatusNotDetermined;
        }
        if (activeIfAddrs & OKActiveIfAddrsStatusWithWiFi) {
            return OKNetworkAuthorizationStatusWLANAndCellularNotPermitted;
        } else if (activeIfAddrs & OKActiveIfAddrsStatusWithWWAN) {
            return OKNetworkAuthorizationStatusCellularNotPermitted;
        }
    }
    
    return OKNetworkAuthorizationStatusNotDetermined;
}

@end
