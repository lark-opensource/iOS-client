//
//  BDPAppManagerTrackEvent.m
//  Timor
//
//  Created by liubo on 2018/12/7.
//

#import "BDPAppManagerTrackEvent.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPAppManagerCommonObj.h"
#import <OPFoundation/BDPUniqueID.h>

#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPModuleEngineType.h>

@implementation BDPAppManagerTrackEvent

#pragma mark - Utilities

+ (NSString *)trackerTypeStringFromType:(BDPType)type {
    return BDPTrackerApp;
}

+ (NSMutableDictionary *)commonParamWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom {
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
    [paramsDic setValue:uniqueID.appID forKey:BDPTrackerAppIDKey];
    [paramsDic setValue:OPAppTypeToString(uniqueID.appType) forKey:BDPTrackerAppTypeKey];
    [paramsDic setValue:OPAppVersionTypeToString(uniqueID.versionType) forKey:BDPTrackerVersionTypeKey];
    [paramsDic setValue:uniqueID.identifier forKey:BDPTrackerIdentifierKey];
    [paramsDic setValue:[BDPAppManagerTrackEvent trackerTypeStringFromType:uniqueID.appType] forKey:BDPTrackerParamSpecialKey];
    [paramsDic setValue:launchFrom forKey:BDPTrackerLaunchFromKey];
    [paramsDic setValue:@"" forKey:BDPTrackerMPNameKey];
    return paramsDic;
}

#pragma mark - Async Load Track Event

+ (void)asyncLoadTrackEventUseAsyncWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom {
    if (!uniqueID.isValid) return;
    
    NSMutableDictionary *paramsDic = [BDPAppManagerTrackEvent commonParamWithUniqueID:uniqueID launchFrom:launchFrom];
    BDPLogTagInfo(kBDPAppManagerLogTag, @"[Track]mp_start_with_async: %@", [paramsDic JSONRepresentation]);
    [BDPTracker event:@"mp_start_with_async" attributes:paramsDic uniqueID:nil];
}

+ (void)asyncLoadTrackEventNotifyEndWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom latestVersion:(NSString *)latestVersion currentVersion:(NSString *)currentVersion {
    if (!uniqueID.isValid || BDPIsEmptyString(latestVersion) || BDPIsEmptyString(currentVersion)) return;
    
    NSMutableDictionary *paramsDic = [BDPAppManagerTrackEvent commonParamWithUniqueID:uniqueID launchFrom:launchFrom];
    [paramsDic setValue:latestVersion forKey:BDPTrackerLatestVersionKey];
    [paramsDic setValue:currentVersion forKey:BDPTrackerCurrentVersionKey];
    BDPLogTagInfo(kBDPAppManagerLogTag, @"[Track]mp_notify: %@", [paramsDic JSONRepresentation]);
    [BDPTracker event:@"mp_notify" attributes:paramsDic uniqueID:nil];
}

+ (void)asyncLoadTrackEventApplyEndWithUniqueID:(BDPUniqueID *)uniqueID launchFrom:(NSString *)launchFrom latestVersion:(NSString *)latestVersion currentVersion:(NSString *)currentVersion {
    if (!uniqueID.isValid || BDPIsEmptyString(latestVersion) || BDPIsEmptyString(currentVersion)) return;
    
    NSMutableDictionary *paramsDic = [BDPAppManagerTrackEvent commonParamWithUniqueID:uniqueID launchFrom:launchFrom];
    [paramsDic setValue:latestVersion forKey:BDPTrackerLatestVersionKey];
    [paramsDic setValue:currentVersion forKey:BDPTrackerCurrentVersionKey];
    BDPLogTagInfo(kBDPAppManagerLogTag, @"[Track]mp_apply: %@", [paramsDic JSONRepresentation]);
    [BDPTracker event:@"mp_apply" attributes:paramsDic uniqueID:nil];
}

#pragma mark - Preload Track Event

//+ (void)preloadTrackEventAppPreloadListWithSuccess:(BOOL)success duration:(NSTimeInterval)duration errorMsg:(NSString *)errorMsg {
//    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
//    [paramsDic setValue:(success ? BDPTrackerResultSucc : BDPTrackerResultFail) forKey:BDPTrackerResultTypeKey];
//    [paramsDic setValue:@((NSUInteger)(duration * 1000)) forKey:BDPTrackerDurationKey];
//    [paramsDic setValue:errorMsg forKey:BDPTrackerErrorMsgKey];
//    [paramsDic setValue:BDPTrackerApp forKey:BDPTrackerParamSpecialKey];//目前暂定都是micro_app
//    [paramsDic setValue:@"" forKey:BDPTrackerMPNameKey];
//    BDPLogTagInfo(kBDPAppManagerLogTag, @"[Track]mp_preload_request_result: %@", [paramsDic JSONRepresentation]);
//    [BDPTracker event:@"mp_preload_request_result" attributes:paramsDic];
//}

+ (void)preloadTrackEventResourceWithResID:(NSString *)resID success:(BOOL)success duration:(NSTimeInterval)duration errorMsg:(NSString *)errorMsg {
    if (BDPIsEmptyString(resID)) return;
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
    [paramsDic setValue:BDPEmptyStringIfNil(resID) forKey:@"ext_src_id"];
    [paramsDic setValue:(success ? BDPTrackerResultSucc : BDPTrackerResultFail) forKey:BDPTrackerResultTypeKey];
    [paramsDic setValue:@((NSUInteger)(duration * 1000)) forKey:BDPTrackerDurationKey];
    [paramsDic setValue:errorMsg forKey:BDPTrackerErrorMsgKey];
    [paramsDic setValue:@"" forKey:BDPTrackerMPNameKey];
    BDPLogTagInfo(kBDPAppManagerLogTag, @"[Track]mp_es_download_result: %@", [paramsDic JSONRepresentation]);
    [BDPTracker event:@"mp_es_download_result" attributes:paramsDic uniqueID:nil];
}

@end
