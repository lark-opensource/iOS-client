//
//  Heimdallr+DebugReal.m
//  Heimdallr
//
//  Created by joy on 2018/8/13.
//

#import "Heimdallr+DebugReal.h"
#import <TTReachability/TTReachability.h>
#import "HMDNetworkReachability.h"
#import "HMDDebugRealConfig.h"
#import "HMDPerformanceReporterManager.h"
#import "HMDExceptionReporter.h"
#import "Heimdallr+Private.h"

NSString *const kHMDDebugRealFetchKey = @"kHMDDebugRealFetchKey";

@implementation Heimdallr (DebugReal)

+ (void)uploadDebugRealDataWithStartTime:(NSTimeInterval)fetchStartTime endTime:(NSTimeInterval)fetchEndTime wifiOnly:(BOOL)wifiOnly {
    
    NSMutableDictionary *dataConfig = [NSMutableDictionary new];
    
    [dataConfig setValue:@(fetchStartTime) forKey:@"fetch_start_time"];
    [dataConfig setValue:@(fetchEndTime) forKey:@"fetch_end_time"];
    [dataConfig setValue:@(wifiOnly) forKey:@"wifi_only"];
    BOOL isWifi = [HMDNetworkReachability isWifiConnected];
    // 如果要求 Wi-Fi，但是当前环境非 Wi-Fi 则缓存下来，等待新的时机上报数据
    if (wifiOnly && !isWifi) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dataConfig];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:kHMDDebugRealFetchKey];
    } else {
        HMDDebugRealConfig *config = [[HMDDebugRealConfig alloc] initWithParams:dataConfig];
        [[HMDPerformanceReporterManager sharedInstance] reportDebugRealPerformanceDataWithConfig:config];
        [[HMDExceptionReporter sharedInstance] reportDebugRealExceptionData:config exceptionTypes:@[@(HMDDefaultExceptionType)]];
    }
}

+ (void)uploadDebugRealDataWithLocalConfig {
    BOOL isWifi = [HMDNetworkReachability isWifiConnected];
    if (isWifi) {
        [self uploadLocalConfigDebugRealData];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appReachStateChanged:)
                                                     name:TTReachabilityChangedNotification
                                                   object:nil];
    });
}

+ (void)uploadLocalConfigDebugRealData {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kHMDDebugRealFetchKey];
    if (data) {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([dict isKindOfClass:[NSDictionary class]] && [dict count] > 0) {
            HMDDebugRealConfig *config = [[HMDDebugRealConfig alloc] initWithParams:dict];
            
            [[HMDPerformanceReporterManager sharedInstance] reportDebugRealPerformanceDataWithConfig:config];
            [[HMDExceptionReporter sharedInstance] reportDebugRealExceptionData:config exceptionTypes:@[@(HMDDefaultExceptionType)]];
            // 移除本地缓存
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHMDDebugRealFetchKey];
        }
    }
}

+ (void)appReachStateChanged:(NSNotification *)notification{
    TTReachability *reach = [notification object];
    if([reach isKindOfClass:[TTReachability class]]){
        NetworkStatus status = [reach currentReachabilityStatus];
        if (status == ReachableViaWiFi) {
            [self uploadLocalConfigDebugRealData];
        }
    }
}

@end
