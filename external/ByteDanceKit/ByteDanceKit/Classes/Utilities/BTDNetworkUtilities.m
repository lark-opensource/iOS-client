//
//  Created by David Alpha Fox on 3/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <pthread.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netdb.h>
#include <arpa/inet.h>
#import "BTDReachability.h"
#import "BTDNetworkUtilities.h"
#import "BTDMacros.h"

extern BTDNetworkFlags BTDNetworkGetFlags(void) {
    NSInteger flags = 0;
    if (BTDNetwork2GConnected() || BTDNetwork3GConnected() || BTDNetwork4GConnected()) {
        flags |= BTDNetworkFlagMobile;
    }
    if (BTDNetwork2GConnected()) {
        flags |= BTDNetworkFlag2G;
    }
    if (BTDNetwork3GConnected()) {
        flags |= BTDNetworkFlag3G;
    }
    if (BTDNetwork4GConnected()) {
        flags |= BTDNetworkFlag4G;
    }
    if (BTDNetworkWifiConnected()) {
        flags |= BTDNetworkFlagWifi;
    }
    return flags;
}

BOOL BTDNetworkConnected(void) 
{
    return [[BTDReachabilityManager sharedManager] isReachable];
}

BOOL BTDNetworkWifiConnected(void)
{
    return [[BTDReachabilityManager sharedManager] isReachableViaWiFi];

}

BOOL BTDNetworkCellPhoneConnected(void)
{
    return [[BTDReachabilityManager sharedManager] isReachableViaWWAN];
}

BOOL BTDNetwork2GConnected(void)
{
    return [BTDNetworkUtilities is2GConnected];
}

BOOL BTDNetwork3GConnected(void)
{
    return [BTDNetworkUtilities is3GConnected];
}

BOOL BTDNetwork4GConnected(void)
{
    return [BTDNetworkUtilities is4GConnected];
}

void BTDNetworkStartNotifier(void)
{
    [[BTDReachabilityManager sharedManager] startMonitoring];
}

void BTDNetworkStopNotifier(void)
{
    [[BTDReachabilityManager sharedManager] stopMonitoring];
}

@implementation BTDNetworkUtilities

static CTTelephonyNetworkInfo *telephoneInfo = nil;
static NSString *currentRadioAccessTechnology = nil;

+ (void)initialize
{
    telephoneInfo = [[CTTelephonyNetworkInfo alloc] init];
    currentRadioAccessTechnology = telephoneInfo.currentRadioAccessTechnology;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessTechnologyDidChange:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
}

+ (void)radioAccessTechnologyDidChange:(NSNotification *)notification {
    // CTTelephonyNetworkInfo 的 init 方法中，会同步发送此通知（从iOS 12+以后不再触发）
    // 因此每当外界创建一个 CTTelephonyNetworkInfo 实例，这里都会触发回调
    // 发现在iOS 12/iOS 13上，存在苹果SDK的Bug会导致如果就地使用当前Queue去访问，后续访问CTTelephonyNetworkInfo属性有小概率的Crash问题，因此统一Dispatch到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        currentRadioAccessTechnology = telephoneInfo.currentRadioAccessTechnology;
    });
}

+ (BOOL)is2GConnected
{
    BOOL result = NO;
    result = [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge];
    return result;
}

+ (BOOL)is3GConnected
{
    BOOL result = NO;
    result = [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]
    || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]
    || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]
    || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD];
    return result;
}

+ (BOOL)is4GConnected
{
    BOOL result = NO;
    result = [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE];
    return result;
}

//同步方法， 不要在主线程调用
+ (NSString*)addressOfHost:(NSString*)host
{
    NSString *result = @"";
    if(!BTD_isEmptyString(host))
    {
        struct hostent *hostentry;
        hostentry = gethostbyname([host UTF8String]);
        
        if(hostentry)
        {
            char *ipbuf = inet_ntoa(*((struct in_addr *)hostentry->h_addr_list[0]));
            result = @(ipbuf);
        }
    }
    
    return result;
}

+ (NSString*)connectMethodName
{
    NSString * netType = @"";
    if(BTDNetworkWifiConnected())
    {
        netType = @"WIFI";
    }
    else if(BTDNetwork4GConnected())
    {
        netType = @"4G";
    }
    else if(BTDNetwork3GConnected())
    {
        netType = @"3G";
    }
    else if(BTDNetworkConnected())
    {
        netType = @"mobile";
    }
    return netType;
}


@end

