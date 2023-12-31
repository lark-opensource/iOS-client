//
//  TTNetInitMetrics.m
//  TTNetworkManager
//
//  Created by taoyiyuan on 2021/3/16.
//

#import <Foundation/Foundation.h>

#import "TTNetInitMetrics.h"
#import "components/cronet/cronet_global_state.h"

#define T_TTNET_INIT 1

#define NS_MSBridgeML @"MSBML"
#define NS_MSBridgeOV @"MSBOV"
#define HTTP_CALLBACK @"http_callback"
#define WS_CALLBACK @"ws_callback"

static TTNetInitMetrics *manager = nil;

static inline NSNumber* validateTimingValue(int64_t x, int64_t y) {
    if (x < 0 || y < 0 || x > y) {
        return [NSNumber numberWithLong:-1];
    }
    return [NSNumber numberWithLong: (y - x)];
}

@implementation TTNetInitMetrics

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}
-(bool)initMSSdk {
    _initMssdkStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    const auto& handles = cronet::GetOpaqueFuncAddress();
    NSCAssert(handles.size() == 2, @"GetOpaqueFuncAddress failed.");
    NSDictionary *funcAddress = @{HTTP_CALLBACK: [NSString stringWithFormat:@"%lld", handles[0]],
                                  WS_CALLBACK: [NSString stringWithFormat:@"%lld", handles[1]]};
    Class clz = NSClassFromString(NS_MSBridgeML);
    if (!clz) {
        clz = NSClassFromString(NS_MSBridgeOV);
    }
    
    if (clz) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([clz respondsToSelector:@selector(a:info:)]) {
            [clz performSelector:@selector(a:info:) withObject:@T_TTNET_INIT withObject:funcAddress];
#pragma clang diagnostic pop
            return true;
        }
    }
    _initMssdkEndTime = [[NSDate date] timeIntervalSince1970] * 1000;
    return false;
}

-(NSDictionary *) constructTTNetInitTimingInfo:(const net::CronetInitTimingInfo *) cronetTimingInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSDictionary *timeStampDict = @{@"ttnet_start":[NSNumber numberWithLong:_initTTNetStartTime],
                                    @"ttnet_end":[NSNumber numberWithLong:_initTTNetEndTime],
                                    @"main_start":[NSNumber numberWithLong:_mainStartTime],
                                    @"main_end":[NSNumber numberWithLong:_mainEndTime],
                                    @"network_start":[NSNumber numberWithLong:cronetTimingInfo->network_thread_init_start],
                                    @"network_end":[NSNumber numberWithLong:cronetTimingInfo->network_thread_init_end],
                                    @"preconnect_start":[NSNumber numberWithLong:cronetTimingInfo->preconnect_init_start]
                                    };
    NSDictionary *durationDict = @{@"init_ttnet":validateTimingValue(_initTTNetStartTime, _initTTNetEndTime),
                                   @"main_thread":validateTimingValue(_initTTNetStartTime, _initTTNetEndTime),
                                   @"init_mssdk":validateTimingValue(_initMssdkStartTime, _initTTNetEndTime),
                                   @"network_thread":validateTimingValue(cronetTimingInfo->network_thread_init_start, cronetTimingInfo->network_thread_init_end),
                                   @"init_total":validateTimingValue(_initTTNetStartTime, cronetTimingInfo->network_thread_init_end),
                                   @"prefs_init":validateTimingValue(cronetTimingInfo->prefs_init_start, cronetTimingInfo->prefs_init_end),
                                   @"context_build":validateTimingValue(cronetTimingInfo->context_builder_start, cronetTimingInfo->context_builder_end),
                                   @"tnc_config":validateTimingValue(cronetTimingInfo->tnc_config_init_start, cronetTimingInfo->tnc_config_init_end),
                                   @"update_appinfo":validateTimingValue(cronetTimingInfo->update_appinfo_start, cronetTimingInfo->update_appinfo_end),
                                   @"netlog_init":validateTimingValue(cronetTimingInfo->netlog_init_start, cronetTimingInfo->netlog_init_end),
                                   @"nqe_detect":validateTimingValue(cronetTimingInfo->nqe_init_start, cronetTimingInfo->nqe_init_end),
                                   @"preconnect_url":validateTimingValue(cronetTimingInfo->preconnect_init_start, cronetTimingInfo->preconnect_init_end),
                                   @"ssl_session":validateTimingValue(cronetTimingInfo->ssl_session_init_start, cronetTimingInfo->ssl_session_init_end),
                                   @"install_cert":validateTimingValue(cronetTimingInfo->install_cert_init_start, cronetTimingInfo->install_cert_init_end),
                                   @"ttnet_config":validateTimingValue(cronetTimingInfo->ttnet_config_init_start, cronetTimingInfo->ttnet_config_init_end)
                                   };
    [dict setObject:timeStampDict forKey:@"ttnet_timestamp"];
    [dict setObject:durationDict forKey:@"ttnet_duration"];
    return [dict copy];
}

@end
