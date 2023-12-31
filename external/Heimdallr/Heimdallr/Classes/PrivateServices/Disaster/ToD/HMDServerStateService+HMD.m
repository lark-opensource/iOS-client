//
//  HMDServerStateService.m
//  Heimdallr
//
//  Created by wangyinhui on 2021/11/18.
//

#import "HMDServerStateService.h"
#include <stdatomic.h>
#import "HMDServerStateManager.h"
// Utility
#import "HMDUserDefaults.h"
#import "NSDictionary+HMDSafe.h"

// 当发现服务异常时开启
static atomic_bool isServerAbnormal = false;

BOOL hmd_is_server_abnormal(void) {
    // 从文件中查询上次是否出现服务异常
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber *maxNextAvailableTimeInterval = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:HMDMaxNextAvailableTimeInterval];
        if([maxNextAvailableTimeInterval isKindOfClass:[NSNumber class]]) {
            NSTimeInterval nextAviaibleTimeInterval = [maxNextAvailableTimeInterval doubleValue];
            if ([[NSDate date] timeIntervalSince1970] < nextAviaibleTimeInterval){
                isServerAbnormal = true;
            }
        }
    });
    return isServerAbnormal ? YES : NO;
}

#pragma mark - 通用容灾API

BOOL hmd_drop_all_data(HMDReporter report) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report];
        if (check) {
            return [check dropAllData];
        }
    }
    return NO;
}

BOOL hmd_drop_data(HMDReporter report) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report];
        if (check) {
            return [check dropData];
        }
    }
    return NO;
}

BOOL hmd_is_server_available(HMDReporter report) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report];
        if (check) {
            return [check isServerAvailable];
        }
    }
    return YES;
}

HMDServerState hmd_update_server_checker(HMDReporter report, NSDictionary *result, NSInteger statusCode) {
    // 只有出现异常时，开启容灾
    if (result && [result hmd_hasKey:@"message"] && ![[result hmd_stringForKey:@"message"] isEqualToString:@"success"]) {
        isServerAbnormal = true;
    }
    if (statusCode < 200 || statusCode > 299) {
        isServerAbnormal = true;
    }
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report];
        if (check) {
            return [check updateStateWithResult:result statusCode:statusCode];
        }
    }
    return HMDServerStateSuccess;
}

#pragma mark - 存在 SDK 上报场景时使用

BOOL hmd_drop_all_data_sdk(HMDReporter report, NSString *aid) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report forApp:aid];
        if (check) {
            return [check dropAllData];
        }
    }
    return NO;
}

BOOL hmd_drop_data_sdk(HMDReporter report, NSString *aid) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report forApp:aid];
        if (check) {
            return [check dropData];
        }
    }
    return NO;
}

BOOL hmd_is_server_available_sdk(HMDReporter report, NSString *aid) {
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report forApp:aid];
        if (check) {
            return [check isServerAvailable];
        }
    }
    return YES;
}

HMDServerState hmd_update_server_checker_sdk(HMDReporter report, NSString *aid, NSDictionary *result, NSInteger statusCode) {
    // 只有出现异常时，开启容灾
    if (result && [result hmd_hasKey:@"message"] && ![[result hmd_stringForKey:@"message"] isEqualToString:@"success"]) {
        isServerAbnormal = true;
    }
    if (statusCode < 200 || statusCode > 299) {
        isServerAbnormal = true;
    }
    if (hmd_is_server_abnormal()) {
        HMDServerStateChecker *check = [[HMDServerStateManager shared] getServerChecker:report forApp:aid];
        if (check) {
            return [check updateStateWithResult:result statusCode:statusCode];
        }
    }
    return HMDServerStateSuccess;
}
