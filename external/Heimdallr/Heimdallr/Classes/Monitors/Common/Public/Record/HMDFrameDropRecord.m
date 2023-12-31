//
//  HMDFrameDropRecord.m
//  Heimdallr
//
//  Created by 王佳乐 on 2019/3/6.
//

#import "HMDFrameDropRecord.h"
#import "HMDMacro.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDMonitorRecord+Private.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasCounter.h"

@implementation HMDFrameDropRecord
- (NSDictionary *)reportDictionary
{
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];

    long long time = MilliSecond(self.timestamp);
    NSString *logType = hermas_enabled() ? @"performance_monitor" : @"performance_monitor_debug";
    
    // normal
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:@"fps_drop" forKey:@"service"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:@(self.slidingTime) forKey:@"total_scroll_time"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];
    [dataValue setValue:@(self.duration) forKey:@"dur"];
    [dataValue setValue:@(self.hitchDuration) forKey:@"hitch_dur"];
    [dataValue setValue:self.hitchDurDic forKey:@"hitch_dur_dic"];

    if (!CGPointEqualToPoint(self.touchReleasedVelocity, CGPointZero)) {
        [dataValue setValue:[NSString stringWithFormat:@"%.3f,%.3f", self.touchReleasedVelocity.x, self.touchReleasedVelocity.y] forKey:@"velocity"];
        [dataValue setValue:[NSString stringWithFormat:@"%.0f,%.0f", self.targetScrollDistance.x, self.targetScrollDistance.y] forKey:@"distance"];
    }
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    if (hermas_enabled() && !self.needAggregate) {
        self.sequenceCode = self.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:NSStringFromClass([self class])] : -1;
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    
    // extra value
    NSMutableDictionary *extraValue = [NSMutableDictionary new];
    [self.frameDropInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *value, BOOL * _Nonnull stop) {
       if (value) {
           [extraValue setValue:value forKey:key];
       }
    }];
    [dataValue setValue:extraValue forKey:@"extra_values"];

    // extra status
    NSMutableDictionary *extraStatus = [NSMutableDictionary new];
    if(self.scene.length > 0) {
        [extraStatus setValue:self.scene forKey:@"scene"];
    }
    if (self.customScene.length > 0) {
        [extraStatus setValue:self.customScene forKey:@"custom_scene"];
    }
    if (self.refreshRate == 0) {
        self.refreshRate = 60; //默认 60 帧;
    }
    [extraStatus setValue:@(self.isScrolling) forKey:@"isScrolling"];
    [extraStatus setValue:@(self.refreshRate) forKey:@"refresh_rate"];
    [extraStatus setValue:@(self.isLowPowerMode) forKey:@"is_low_power_mode"];

    [extraStatus setValue:@(self.baseSample) forKey:@"base_sample"];
    [extraStatus setValue:@(self.isEvilMethod) forKey:@"is_evil_method"];
    [extraStatus setValue:@(self.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];

    [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];

    NSString *useAppTimeTag = @"in_app_time_step";
    NSTimeInterval inAppTime = self.inAppTime;
    if (inAppTime > 0 && inAppTime <= 10) {
        [extraStatus setValue:kHMDMonitorLaunchTagIn10sec forKey:useAppTimeTag];
    } else if (inAppTime > 10 && inAppTime <= 30) {
        [extraStatus setValue:kHMDMonitorLaunchTagIn30sec forKey:useAppTimeTag];
    } else if (inAppTime > 30 && inAppTime <= 60) {
        [extraStatus setValue:kHMDMonitorLaunchTagInOneMin forKey:useAppTimeTag];
    } else if (inAppTime > 60) {
        [extraStatus setValue:kHMDMonitorLaunchTagGreaterThanOneMin forKey:useAppTimeTag];
    }
    
    [HMDFrameDropRecord setupFilterFromFilter:self.filters toDataDict:extraStatus];
    [dataValue setValue:extraStatus forKey:@"extra_status"];
    
    // custom extra
    if (self.customExtra && self.customExtra.count > 0) {
        [dataValue hmd_setSafeObject:self.customExtra forKey:@"extra"];
    }
    
    // enable_upload
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];
    
    if (hermas_enabled()) {
        if (self.blockDuration > 0) {
            [extraValue setValue:@(self.blockDuration) forKey:@"total_block_duration"];
        }
        if (self.blockCount) {
            [extraValue setValue:@(self.blockCount) forKey:@"block_count"];
        }
    }
    return dataValue;
}
+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDFrameDropRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray new];
    for (int index = 0; index < records.count; index ++)  {
        @autoreleasepool {
            HMDFrameDropRecord *record = [records hmd_objectAtIndex:index];
            if (!record) { continue; }
            NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];

            long long time = MilliSecond(record.timestamp);

            [dataValue setValue:@(time) forKey:@"timestamp"];
            [dataValue setValue:record.sessionID forKey:@"session_id"];
            [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
            [dataValue setValue:@"fps_drop" forKey:@"service"];
            [dataValue setValue:@"performance_monitor" forKey:@"log_type"];
            [dataValue setValue:@(record.slidingTime) forKey:@"total_scroll_time"];
            [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
            [dataValue setValue:@(record.duration) forKey:@"dur"];
            [dataValue setValue:@(record.hitchDuration) forKey:@"hitch_dur"];
            [dataValue setValue:record.hitchDurDic forKey:@"hitch_dur_dic"];

            if (!CGPointEqualToPoint(record.touchReleasedVelocity, CGPointZero)) {
                [dataValue setValue:[NSString stringWithFormat:@"%.3f,%.3f", record.touchReleasedVelocity.x, record.touchReleasedVelocity.y]
                             forKey:@"velocity"];
                [dataValue setValue:[NSString stringWithFormat:@"%.0f,%.0f", record.targetScrollDistance.x, record.targetScrollDistance.y] forKey:@"distance"];
            }
            NSMutableDictionary *extraValue = [NSMutableDictionary new];
            [record.frameDropInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *value, BOOL *_Nonnull stop) {
                if (value) {
                    [extraValue setValue:value forKey:key];
                }
            }];
            if (record.blockDuration > 0) {
                [extraValue setValue:@(record.blockDuration) forKey:@"total_block_duration"];
            }
            if (record.blockCount) {
                [extraValue setValue:@(record.blockCount) forKey:@"block_count"];
            }
            [dataValue setValue:extraValue forKey:@"extra_values"];

            NSMutableDictionary *extraStatus = [NSMutableDictionary new];
            if (record.scene.length > 0) {
                [extraStatus setValue:record.scene forKey:@"scene"];
            }
            if (record.customScene.length > 0) {
                [extraStatus setValue:record.customScene forKey:@"custom_scene"];
            }
            if (record.refreshRate == 0) {
                record.refreshRate = 60; //默认 60 帧;
            }
            if (record.customExtra && record.customExtra.count > 0) {
                [dataValue hmd_setSafeObject:record.customExtra forKey:@"extra"];
            }
            [extraStatus setValue:@(record.isScrolling) forKey:@"isScrolling"];
            [extraStatus setValue:@(record.refreshRate) forKey:@"refresh_rate"];
            [extraStatus setValue:@(record.isLowPowerMode) forKey:@"is_low_power_mode"];
            [extraStatus setValue:@(record.baseSample) forKey:@"base_sample"];
            [extraStatus setValue:@(record.isEvilMethod) forKey:@"is_evil_method"];
            [extraStatus setValue:@(record.isSpecialSceneOpenRecord) forKey:@"is_special_scene_open"];
            NSString *useAppTimeTag = @"in_app_time_step";
            NSTimeInterval inAppTime = record.inAppTime;
            if (inAppTime > 0 && inAppTime <= 10) {
                [extraStatus setValue:kHMDMonitorLaunchTagIn10sec forKey:useAppTimeTag];
            } else if (inAppTime > 10 && inAppTime <= 30) {
                [extraStatus setValue:kHMDMonitorLaunchTagIn30sec forKey:useAppTimeTag];
            } else if (inAppTime > 30 && inAppTime <= 60) {
                [extraStatus setValue:kHMDMonitorLaunchTagInOneMin forKey:useAppTimeTag];
            } else if (inAppTime > 60) {
                [extraStatus setValue:kHMDMonitorLaunchTagGreaterThanOneMin forKey:useAppTimeTag];
            }
            
            [extraStatus hmd_addEntriesFromDict:[HMDMonitorRecord getInjectedPatchFilters]];

            [HMDFrameDropRecord setupFilterFromFilter:record.filters toDataDict:extraStatus];
            [dataValue setValue:extraStatus forKey:@"extra_status"];
            [dataArray hmd_addObject:dataValue];
        }
    }
    return dataArray;
}

+ (void)setupFilterFromFilter:(NSDictionary *)filterDict toDataDict:(NSMutableDictionary *)dict {
    if([dict isKindOfClass:[NSMutableDictionary class]]) {
        NSString *isNewInstall = [filterDict valueForKey:@"is_new_install"];
        if(isNewInstall) {
            if ([isNewInstall isKindOfClass:NSString.class]) {
                [dict setValue:@(isNewInstall.boolValue) forKey:@"is_new_install"];
            } else {
                [dict setValue:isNewInstall forKey:@"is_new_install"];
            }
        }
        NSString *isFirstLaunch = [filterDict valueForKey:@"is_first_launch"];
        if (isFirstLaunch) {
            if ([isFirstLaunch isKindOfClass:NSString.class]) {
                [dict setValue:@(isFirstLaunch.boolValue) forKey:@"is_first_launch"];
            } else {
                [dict setValue:isFirstLaunch forKey:@"is_first_launch"];
            }
        }
        NSString *isFirstLaunchAndWithin30Seconds = [filterDict valueForKey:@"is_first_launch_within_30sec"];
        if (isFirstLaunchAndWithin30Seconds) {
            if ([isFirstLaunchAndWithin30Seconds isKindOfClass:NSString.class]) {
                [dict setValue:@(isFirstLaunchAndWithin30Seconds.boolValue) forKey:@"is_first_launch_within_30sec"];
            } else {
                [dict setValue:isFirstLaunchAndWithin30Seconds forKey:@"is_first_launch_within_30sec"];
            }
        }
    }
}

- (BOOL)needAggregate {
    return NO;
}

@end
