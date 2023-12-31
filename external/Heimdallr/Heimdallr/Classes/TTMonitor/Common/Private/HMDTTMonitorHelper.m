//
//  HMDTTMonitorHelper.m
//  Heimdallr
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import "HMDTTMonitorHelper.h"
#import "HMDTTMonitor.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+CustomInfo.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+DeviceEnv.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDDynamicCall.h"
#include <stdatomic.h>
#import <os/lock.h>
#include <pthread.h>
#import <mach/mach.h>
#import <stdatomic.h>

#define kMaxMonitorCrashCustomLogLength 128

static atomic_ullong insert_id;
static atomic_ullong upload_id;

static char savedTypeString[kMaxMonitorCrashCustomLogLength];

static void hmd_tt_monitor_crash_callback(char * _Nullable * _Nonnull dynamic_key,
                                      char * _Nullable * _Nonnull dynamic_data,
                                      uint64_t crash_time,
                                      uint64_t fault_address,
                                      thread_t current_thread,
                                      thread_t crash_thread) {
    savedTypeString[kMaxMonitorCrashCustomLogLength - 1] = '\0';
    
    dynamic_key[0] = "ttmonitor_latest_logtype";
    dynamic_data[0] = savedTypeString;
}

@implementation HMDTTMonitorHelper

+ (void)registerCrashCallbackToLog {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    DC_CL(HMDCrashCallback, registerCallback:, hmd_tt_monitor_crash_callback);
}

+ (void)saveLatestLogWithServiceName:(NSString *)serviceName logType:(NSString *)logType appID:(NSString *)appID {
    NSString *logStr = [NSString stringWithFormat:@"service = %@, logType = %@, aid = %@", serviceName, logType, appID];
    strncpy(savedTypeString, logStr.UTF8String, kMaxMonitorCrashCustomLogLength - 1);
    savedTypeString[kMaxMonitorCrashCustomLogLength - 1] = '\0';
}

+ (NSString *)logTypeStrForType:(HMDTTMonitorTrackerType)type {
    NSString * logTypeStr = nil;
    switch (type) {
        case HMDTTMonitorTrackerTypeAPIError:
        {
            logTypeStr = @"api_error";
        }
            break;
        case HMDTTMonitorTrackerTypeAPISample:
        {
            logTypeStr = @"api_sample";
        }
            break;
        case HMDTTMonitorTrackerTypeDNSReport:
        {
            logTypeStr = @"dns_report";
        }
            break;
        case HMDTTMonitorTrackerTypeDebug:
        {
            logTypeStr = @"debug_real";
        }
            break;
        case HMDTTMonitorTrackerTypeAPIAll:
        {
            logTypeStr = @"api_all";
        }
            break;
        case HMDTTMonitorTrackerTypeHTTPHiJack:
        {
            logTypeStr = @"ss_sign_sample";
        }
            break;
        case HMDTTMonitorTrackerTypeLocalLog:
        {
            logTypeStr = @"log_exception";
        }
            break;
        default:
        {
            logTypeStr = nil;
        }
            break;
    }
    return logTypeStr;
}

+ (NSDictionary *)filterTrackerReservedKeysWithDataDict:(NSDictionary *)dataDict {
    if (!dataDict) { return nil;}
    NSMutableDictionary *dataDictCopy = [NSMutableDictionary dictionary];
    @try {
        [dataDictCopy addEntriesFromDictionary:dataDict];
    } @catch (NSException *exception) {
        dataDictCopy = nil;
#ifdef DEBUG
            NSAssert(NO, @"Error: HMDTTMonitorTracker NSDictionary Exception !!!");
#endif
    }
    NSArray *reservedKeys = @[@"log_type", @"service"];
    for (NSString *reservedKey in reservedKeys) {
        if ([dataDictCopy objectForKey:reservedKey]) {
            // 如果和 MonitorTracker的保留字段冲突,去掉这个字段以MonitorTracker的为准
            [dataDictCopy removeObjectForKey:reservedKey];
#ifdef DEBUG
            NSAssert(NO, @"Error: USED HMDTTMonitorTracker RESEVERED KEY !!!");
#endif
        }
    }
    return [dataDictCopy copy];
}

//早期已经是String，这里为了兼容不改成Number
+ (NSString *)generateLogID {
    unsigned long long curLogID = atomic_fetch_add_explicit(&insert_id, 1, memory_order_acq_rel); // atomic
    return [NSString stringWithFormat:@"%llu", curLogID];
}

+ (NSNumber *)generateUploadID {
    unsigned long long curUploadID = atomic_fetch_add_explicit(&upload_id, 1, memory_order_acq_rel); // atomic
    return [NSNumber numberWithUnsignedLongLong:curUploadID];
}

#pragma mark - check NSCoding
+ (BOOL)checkDictionaryDataFormat:(NSDictionary *)data {
    __block BOOL formatIsRight = YES;
    if ([data isKindOfClass:[NSDictionary class]]) {
        [data.allValues enumerateObjectsUsingBlock:^(NSObject *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            formatIsRight = [obj conformsToProtocol:@protocol(NSCoding)];

            if ([obj isKindOfClass:[NSDictionary class]]) {
                formatIsRight = [self checkDictionaryDataFormat:(NSDictionary *)obj];
            }
            if ([obj isKindOfClass:[NSArray class]]) {
                formatIsRight = [self checkArrayDataFormat:(NSArray *)obj];
            }
            if ([obj isKindOfClass:[NSSet class]]) {
                NSSet *set = (NSSet *)obj;
                formatIsRight = [self checkArrayDataFormat:set.allObjects];
            }
            
            NSAssert(formatIsRight,@"Monitor‘s event tracing does not support the type of data unrealized NSCoding.");
            if (!formatIsRight) *stop = YES;
        }];
    }
    return formatIsRight;
}

+ (BOOL)checkArrayDataFormat:(NSArray *)array {
    __block BOOL formatIsRight = YES;
    if ([array isKindOfClass:[NSArray class]]) {
        [array enumerateObjectsUsingBlock:^(NSObject *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            formatIsRight = [obj conformsToProtocol:@protocol(NSCoding)];
            
            if ([obj isKindOfClass:[NSDictionary class]]) {
                formatIsRight = [self checkDictionaryDataFormat:(NSDictionary *)obj];
            }
            if ([obj isKindOfClass:[NSArray class]]) {
                formatIsRight = [self checkArrayDataFormat:(NSArray *)obj];
            }
            if ([obj isKindOfClass:[NSSet class]]) {
                NSSet *set = (NSSet *)obj;
                formatIsRight = [self checkArrayDataFormat:set.allObjects];
            }
            NSAssert(formatIsRight,@"Monitor‘s event tracing  does not support the type of data unrealized NSCoding.");
            if (!formatIsRight) *stop = YES;
        }];
    }
    return formatIsRight;
}

+ (BOOL)fastCheckDictionaryDataFormat:(NSDictionary *)data {
    __block BOOL formatIsRight = YES;
    if ([data isKindOfClass:[NSDictionary class]]) {
        [data enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]] ||
                [obj isKindOfClass:[NSNumber class]]) {
                formatIsRight = YES;
            }
            else if ([obj isKindOfClass:[NSDictionary class]]) {
                formatIsRight = [self fastCheckDictionaryDataFormat:(NSDictionary *)obj];
            }
            else if ([obj isKindOfClass:[NSArray class]]) {
                formatIsRight = [self fastCheckArrayDataFormat:(NSArray *)obj];
            }
            else if ([obj isKindOfClass:[NSSet class]]) {
                NSSet *set = (NSSet *)obj;
                formatIsRight = [self fastCheckArrayDataFormat:set.allObjects];
            }
            else {
                formatIsRight = [obj conformsToProtocol:@protocol(NSCoding)];
            }
            
            NSAssert(formatIsRight,@"Monitor‘s event tracing does not support the type of data unrealized NSCoding.");
            if (!formatIsRight) *stop = YES;
        }];
    }
    return formatIsRight;
}

+ (BOOL)fastCheckArrayDataFormat:(NSArray *)array {
    __block BOOL formatIsRight = YES;
    if ([array isKindOfClass:[NSArray class]]) {
        [array enumerateObjectsUsingBlock:^(NSObject *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]] ||
                [obj isKindOfClass:[NSNumber class]]) {
                formatIsRight = YES;
            }
            else if ([obj isKindOfClass:[NSDictionary class]]) {
                formatIsRight = [self fastCheckDictionaryDataFormat:(NSDictionary *)obj];
            }
            else if ([obj isKindOfClass:[NSArray class]]) {
                formatIsRight = [self fastCheckArrayDataFormat:(NSArray *)obj];
            }
            else if ([obj isKindOfClass:[NSSet class]]) {
                NSSet *set = (NSSet *)obj;
                formatIsRight = [self fastCheckArrayDataFormat:set.allObjects];
            } else {
                formatIsRight = [obj conformsToProtocol:@protocol(NSCoding)];
            }
            
            NSAssert(formatIsRight,@"Monitor‘s event tracing  does not support the type of data unrealized NSCoding.");
            if (!formatIsRight) *stop = YES;
        }];
    }
    return formatIsRight;
}

+ (NSDictionary *)reportHeaderParamsWithInjectedInfo:(HMDTTMonitorUserInfo *)injectedInfo {
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithCapacity:30];
    
    //customHeader
    if (injectedInfo.appID) {
        if (injectedInfo.customHeader.count > 0) {
            [header addEntriesFromDictionary:injectedInfo.customHeader];
        }
    }
    
    //deviceInfo
    [header setValue:@"iOS" forKey:@"os"];
    NSInteger millisecondsFromGMT =  [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
    [header setValue:@(millisecondsFromGMT) forKey:@"timezone"];
    [header setValue:[NSNumber numberWithBool:[[HMDInfo defaultInfo] isEnvAbnormal]] forKey:@"is_env_abnormal"];
    [header setValue:[[HMDInfo defaultInfo] systemVersion] forKey:@"os_version"];
    [header setValue:[[HMDInfo defaultInfo] decivceModel] forKey:@"device_model"];
    [header setValue:[[HMDInfo defaultInfo] currentLanguage] forKey:@"language"];
    [header setValue:[[HMDInfo defaultInfo] resolutionString] forKey:@"resolution"];
    [header setValue:[[HMDInfo defaultInfo] countryCode] forKey:@"region"];
    [header setValue:[NSNumber numberWithUnsignedInteger:[[HMDInfo defaultInfo] devicePerformaceLevel]] forKey:@"device_performance_level"];
    
    //appInfo
    [header setValue:[[HMDInfo defaultInfo] bundleIdentifier] forKey:@"package_name"];
    [header setValue:[[HMDInfo defaultInfo] shortVersion] forKey:@"app_version"];
    [header setValue:[[HMDInfo defaultInfo] buildVersion] forKey:@"update_version_code"];
    [header setValue:[[HMDInfo defaultInfo] appDisplayName] forKey:@"display_name"];
    [header setValue:@([[HMDInfo defaultInfo] isUpgradeUser]) forKey:@"is_upgrade_user"];
    [header setValue:[[HMDInfo defaultInfo] sdkVersion] forKey:@"heimdallr_version"];
    [header setValue:@([[HMDInfo defaultInfo] sdkVersionCode]) forKey:@"heimdallr_version_code"];
    
    //networkInfo
    NSString *carrierName = [HMDNetworkHelper carrierName] ?: @"";
    [header setValue:carrierName forKey:@"carrier"];
    NSString *carrierMCC = [HMDNetworkHelper carrierMCC] ?: @"";
    NSString *carrierMNC = [HMDNetworkHelper carrierMNC] ?: @"";
    [header setValue:[NSString stringWithFormat:@"%@%@",carrierMCC,carrierMNC] forKey:@"mcc_mnc"];
    [header setValue:[HMDNetworkHelper connectTypeName] forKey:@"access"];
    NSArray<NSString *> *carrierRegions = [HMDNetworkHelper carrierRegions];
    if (carrierRegions.count == 0) {
        [header setValue:@"" forKey:@"carrier_region"];
    } else {
        [header setValue:carrierRegions.firstObject forKey:@"carrier_region"];
        
        for (NSUInteger index = 1; index < carrierRegions.count; index++) {
            [header setValue:[carrierRegions objectAtIndex:index]forKey:[NSString stringWithFormat:@"carrier_region%lu",(unsigned long)index]];
        }
    }
    
    if (injectedInfo.appID) {
        // HMDTTMonitorUserInfo
        [header setValue:injectedInfo.appID forKey:@"aid"];
        //优先用用户自定义传入的，否则用宿主初始化传入的兜底
        NSString *hostAppID = injectedInfo.hostAppID ?: [HMDInjectedInfo defaultInfo].appID;
        [header setValue:hostAppID forKey:@"host_aid"];
        
        NSString *did = injectedInfo.deviceID;
        if (did == nil || did.length == 0 || [did isEqualToString:@"0"]) {
            [header setValue:[HMDInjectedInfo defaultInfo].deviceID forKey:@"device_id"];
        } else {
            [header setValue:did forKey:@"device_id"];
        }
        
        NSString *uid = injectedInfo.userID;
        if (uid == nil || uid.length == 0 || [uid isEqualToString:@"0"]) {
            [header setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"uid"];
        } else {
            [header setValue:uid forKey:@"uid"];
        }
        
        if (injectedInfo.scopedDeviceID) {
            [header setValue:injectedInfo.scopedDeviceID forKey:@"scoped_device_id"];
        } else if ([HMDInjectedInfo defaultInfo].scopedDeviceID) {
            [header setValue:[HMDInjectedInfo defaultInfo].scopedDeviceID forKey:@"scoped_device_id"];
        }
        
        if (injectedInfo.scopedUserID) {
            [header setValue:injectedInfo.scopedUserID forKey:@"scoped_user_id"];
        } else if ([HMDInjectedInfo defaultInfo].scopedUserID) {
            [header setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
        }
        
        if (injectedInfo.channel) {
            [header setValue:injectedInfo.channel forKey:@"channel"];
        } else if ([HMDInjectedInfo defaultInfo].channel) {
            [header setValue:[HMDInjectedInfo defaultInfo].channel forKey:@"channel"];
        }
        
        if (injectedInfo.sdkVersion) {
            [header setValue:injectedInfo.sdkVersion forKey:@"sdk_version"];
        }
    }
    
    // atuoTestInfo
    if ([HMDInfo isBytest]) {
        [header setValue:[[HMDInfo defaultInfo] automationTestInfoDic] forKey:@"test_runtime"];
        
        // offlineInfo
        [header setValue:@(YES) forKey:@"offline"];
    }
    
    return [header copy];
}


@end
