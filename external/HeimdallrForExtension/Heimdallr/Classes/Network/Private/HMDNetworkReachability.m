//
//  HMDNetworkReachability.m
//  Heimdallr
//
//  Created by fengyadong on 2018/1/26.
//

#import "HMDNetworkReachability.h"
#import <TTReachability/TTReachability.h>
#include "pthread_extended.h"

static TTReachability *_gHMDReachability = nil;

extern HMDNetworkFlags HMDNetworkGetFlags(void) {
    NSInteger flags = 0;
    if ([HMDNetworkReachability is2GConnected] || [HMDNetworkReachability is3GConnected] || [HMDNetworkReachability is4GConnected]) {
        flags |= HMDNetworkFlagMobile;
    }
    if ([HMDNetworkReachability is2GConnected]) {
        flags |= HMDNetworkFlag2G;
    }
    if ([HMDNetworkReachability is3GConnected]) {
        flags |= HMDNetworkFlag3G;
    }
    if ([HMDNetworkReachability is4GConnected]) {
        flags |= HMDNetworkFlag4G;
    }
    if ([HMDNetworkReachability isWifiConnected]) {
        flags |= HMDNetworkFlagWifi;
    }
    return flags;
}

@implementation HMDNetworkReachability

+ (void)initialize {
    if (self == [HMDNetworkReachability class]) {
        _gHMDReachability = [TTReachability reachabilityForInternetConnection];
    }
}

+ (BOOL)isConnected {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"kHMDNetworkConnectOptimize"] &&[[NSUserDefaults standardUserDefaults] boolForKey:@"kHMDNetworkConnectOptimize"]) {
        return [TTReachability isNetworkConnected];
    } else {
        //return NO; // force for offline testing
        NetworkStatus netStatus = [_gHMDReachability currentReachabilityStatus];
        if(netStatus != NotReachable) return YES;
        
        //double check，防止误伤
        TTReachability *retry = [TTReachability reachabilityWithHostName:@"www.apple.com"];
        netStatus = [retry currentReachabilityStatus];
        return (netStatus != NotReachable);
    }
}

+ (BOOL)isWifiConnected {
    static NSString *channelName;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channelName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
    });
    if ([channelName isEqualToString:@"local_test"] || [channelName isEqualToString:@"dev"]) {
        BOOL isDebugDisbaleWIFI = [[NSUserDefaults standardUserDefaults] boolForKey:@"debug_disable_network"];
        if (isDebugDisbaleWIFI) {
            return NO;
        }
    }
    
    NetworkStatus netStatus = [_gHMDReachability currentReachabilityStatus];
    if(netStatus == NotReachable) {
        return NO;
    }
    if (netStatus == ReachableViaWiFi) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCellPhoneConnected {
    NetworkStatus netStatus = [_gHMDReachability currentReachabilityStatus];
    if (netStatus == NotReachable) {
        return NO;
    }
    if (netStatus == ReachableViaWWAN) {
        return YES;
    }
    if (netStatus == ReachableViaWiFi) {
        // 在 reachable 为 wifi 连接的情况下，通过 TelephonyNetworkInfo 的信息来判断是否有蜂窝网络连接
        return [HMDNetworkReachability is4GConnected] || [HMDNetworkReachability is3GConnected] || [HMDNetworkReachability is2GConnected];
    }
    return NO;
}

+ (BOOL)is2GConnected {
    return [TTReachability is2GConnected];
}

+ (BOOL)is3GConnected {
    return [TTReachability is3GConnected];
}

+ (BOOL)is4GConnected {
    return [TTReachability is4GConnected];
}

+ (BOOL)is5GConnected {
    return [TTReachability is5GConnected];
}

+ (BOOL)isCellularDisabled {
    if ([_gHMDReachability currentNetworkAuthorizationStatus] != TTNetworkAuthorizationStatusNotDetermined) {
        return YES;
    }
    return NO;
}

+ (BOOL)isCellularAndWLANDisabled {
    if ([_gHMDReachability currentNetworkAuthorizationStatus] == TTNetworkAuthorizationStatusWLANAndCellularNotPermitted) {
        return YES;
    }
    return NO;
}


+ (void)startNotifier {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_gHMDReachability startNotifier];
    });
}

+ (void)stopNotifier {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_gHMDReachability stopNotifier];
    });
}

@end
