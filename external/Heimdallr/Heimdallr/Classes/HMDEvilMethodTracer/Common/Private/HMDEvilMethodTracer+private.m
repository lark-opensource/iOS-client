//
//  HMDEvilMethodTracer+private.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/4.
//

#import "HMDEvilMethodTracer+private.h"
#import "NSDictionary+HMDJSON.h"
#import "NSString+HMDJSON.h"
#import "NSDictionary+HMDSafe.h"
#include "HMDEMMacro.h"
#import "NSArray+HMDSafe.h"
#import "HMDUploadHelper.h"
#import "HMDFileUploader.h"
#import <objc/runtime.h>
#import "HMDEMCollectData.h"
#include <pthread.h>
#import "HMDSessionTracker.h"
#import "HMDNetworkHelper.h"
#import "HMDDynamicCall.h"
#import "HMDGCD.h"
#import "HMDInfo+AppInfo.h"
#import "HMDServiceContext.h"
#import "HMDFrameDropServiceProtocol.h"

static pthread_mutex_t mutex_t = PTHREAD_MUTEX_INITIALIZER;;
static NSString *emLastScene;

@implementation HMDEvilMethodTracer (privateAPI)


- (char *)getEMParameter {
    NSDictionary *header = [HMDUploadHelper sharedInstance].headerInfo;
    if (!header) {
        return NULL;
    }
    
    static NSString *emUUID = nil;
    if (!emUUID) {
        emUUID = [[HMDInfo defaultInfo] emUUID];
    }
    
    if (!emUUID) {
        return NULL;
    }
    
    NSMutableDictionary *dicM = [NSMutableDictionary dictionaryWithDictionary:header];
    [dicM hmd_setObject:@"arm64" forKey:@"arch"];
    [dicM hmd_setObject:emUUID forKey:@"uuid"];
    
    NSString *str = [dicM hmd_jsonString];
    const char *t =(char*)[str UTF8String];
    if (t) {
        return strdup(t);
    }
    return  NULL;
}

- (NSDictionary *)getEventsParameter:(integer_t)runloopCostTime runloopStartTime:(uint64_t)runloopStartTime runloopEndTime:(uint64_t)runloopEndTime {
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    [parameter hmd_setObject:@(timestamp) forKey:@"timestamp"];
    [parameter hmd_setObject:@(runloopCostTime) forKey:@"runloop_cost_time"];
    [parameter hmd_setObject:@(runloopStartTime) forKey:@"runloop_start_time"];
    [parameter hmd_setObject:@(runloopEndTime) forKey:@"runloop_end_time"];
    [parameter hmd_setObject:[HMDNetworkHelper connectTypeName] forKey:@"access"];
    [parameter hmd_setObject:@([HMDSessionTracker currentSession].timeInSession) forKey:@"inapp_time"];
    [parameter hmd_setObject:[HMDSessionTracker currentSession].isBackgroundStatus?@"true":@"false" forKey:@"is_background"];
    pthread_mutex_lock(&mutex_t);
    NSString *lastScene = emLastScene;
    pthread_mutex_unlock(&mutex_t);
    [parameter hmd_setObject:lastScene?:@"unknown" forKey:@"last_scene"];
    return parameter.copy;
}

- (NSDictionary *)getEventsParameter:(integer_t)cost
                           startTime:(uint64_t)startTime
                             endTime:(uint64_t)endTime
                               hitch:(NSTimeInterval)hitch
                         isScrolling:(BOOL)isScrolling {
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    [parameter hmd_setObject:@(timestamp) forKey:@"timestamp"];
    [parameter hmd_setObject:@(cost) forKey:@"runloop_cost_time"];
    [parameter hmd_setObject:@(startTime) forKey:@"runloop_start_time"];
    [parameter hmd_setObject:@(hitch) forKey:@"hitch_duration"];
    [parameter hmd_setObject:@(isScrolling) forKey:@"isScrolling"];
    [parameter hmd_setObject:[HMDNetworkHelper connectTypeName] forKey:@"access"];
    [parameter hmd_setObject:@([HMDSessionTracker currentSession].timeInSession) forKey:@"inapp_time"];
    [parameter hmd_setObject:@([HMDSessionTracker currentSession].isBackgroundStatus) forKey:@"is_background"];
    
    id<HMDFrameDropServiceProtocol> monitor = hmd_get_framedrop_monitor();
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if([monitor enableFrameDropService]) {
        [filters hmd_addEntriesFromDict:monitor.getCustomFilterTag];
        [filters hmd_setObject:@(YES) forKey:@"is_frame_drop"];
    } else {
        [filters hmd_setObject:@(NO) forKey:@"is_frame_drop"];
    }
    [filters hmd_setObject:@(isScrolling) forKey:@"isScrolling"];
    [parameter hmd_setObject:filters forKey:@"filters"];

    pthread_mutex_lock(&mutex_t);
    NSString *lastScene = emLastScene;
    pthread_mutex_unlock(&mutex_t);
    [parameter hmd_setObject:lastScene?:@"unknown" forKey:@"last_scene"];
    return parameter.copy;
}

#pragma  mark - set&get

- (void)setUploader:(HMDEMUploader *)uploader {
    objc_setAssociatedObject(self, @selector(uploader), uploader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HMDEMUploader *)uploader {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - KVO
- (void)registerKVO {
    DC_OB(DC_CL(HMDUITrackerManager, sharedManager), addObserver:forKeyPath:options:context:, self, @"lastScene",
          (NSKeyValueObservingOptions)NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial, nil);
}

- (void)removeKVO {
    @try {
        DC_OB(DC_CL(HMDUITrackerManager, sharedManager), removeObserver:forKeyPath:, self, @"lastScene");
    } @catch (NSException *exception) {
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if ([keyPath isEqualToString:@"lastScene"]  && [newValue isKindOfClass:[NSString class]]) {
        pthread_mutex_lock(&mutex_t);
        emLastScene = newValue;
        pthread_mutex_unlock(&mutex_t);
    }
}

@end
