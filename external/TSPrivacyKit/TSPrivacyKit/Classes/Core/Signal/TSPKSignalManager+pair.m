//
//  TSPKSignalManager+pair.m
//  Musically
//
//  Created by ByteDance on 2022/11/17.
//

#import "TSPKSignalManager+pair.h"
#import "TSPKUtils.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <pthread/pthread.h>
#import "TSPKSignalManager+private.h"
#import "TSPKSignalManager.h"
#import <pthread.h>
#import "TSPKLogger.h"

static NSTimeInterval const kCleanDeallocInterval = 120;
static NSString * const usageStr = @"usage";

@interface TSPKSignalManager (pair)
/// store last record of each instance
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableDictionary *> *permissionInstanceInfo;
@end

@implementation TSPKSignalManager (pair)

#pragma mark - public

+ (void)addPairSignalWithAPIUsageType:(TSPKAPIUsageType)usageType
                       permissionType:(nonnull NSString*)permissionType
                              content:(nonnull NSString*)content
                      instanceAddress:(nonnull NSString*)instanceAddress {
    [TSPKSignalManager addPairSignalWithAPIUsageType:usageType permissionType:permissionType content:content instance:instanceAddress extraInfo:nil];
}

+ (void)addPairSignalWithAPIUsageType:(TSPKAPIUsageType)usageType
                       permissionType:(nonnull NSString*)permissionType
                              content:(nonnull NSString*)content
                             instance:(nonnull NSString*)instance
                            extraInfo:(nullable NSDictionary*)extraInfo {
    [[TSPKSignalManager sharedManager] addPairSignalWithAPIUsageType:usageType permissionType:permissionType content:content instance:instance extraInfo:extraInfo];
}

- (void)addPairSignalWithAPIUsageType:(TSPKAPIUsageType)usageType
                       permissionType:(nonnull NSString*)permissionType
                              content:(nonnull NSString*)content
                             instance:(nonnull NSString*)instance
                            extraInfo:(nullable NSDictionary*)extraInfo {
    if (![self isEnabled]) {
        return;
    }
    
    if (usageType != TSPKAPIUsageTypeStop
        && usageType != TSPKAPIUsageTypeDealloc
        && usageType != TSPKAPIUsageTypeStart) {
        return;
    }
    
    if (permissionType.length == 0 || content.length == 0 || instance.length == 0) {
        return;
    }
    
    TSPKSignalType signalType = TSPKSignalTypePairMethod;
    
    NSArray *allowSignalTypes = [self signalTypesWithPermissionType:permissionType];
    if (![allowSignalTypes containsObject:[self signalStringWithType:signalType]]) {
        return;
    }
    
    NSTimeInterval timestamp = [TSPKUtils getUnixTime];
    
    dispatch_async(_writeQueue, ^{
        NSDictionary *extraInfo = @{@"instance" : instance, usageStr : @(usageType)};
        NSDictionary *signal = [self signalWithType:signalType content:content extraInfo:extraInfo timestamp:timestamp];
        pthread_rwlock_wrlock(&self->_rwPermissionInfoLock);
        
        if (!self.permissionInfo[permissionType]) {
            self.permissionInfo[permissionType] = [NSMutableArray array];
        }
        // add signal to signals
        NSMutableArray *mutableSinglePermissionInfo = self.permissionInfo[permissionType];
        [mutableSinglePermissionInfo addObject:signal];
        [self removeFirstObjectIfExceed:mutableSinglePermissionInfo];
        
        NSMutableDictionary *curPermissionInstanceInfo = [self instancesInfoWithPermissionType:permissionType];
        
        // add signal to instance array
        if (curPermissionInstanceInfo[instance] == nil) {
            curPermissionInstanceInfo[instance] = [NSMutableArray array];
        }
        
        if ([curPermissionInstanceInfo[instance] isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *mutableInstanceSignals = curPermissionInstanceInfo[instance];
            [mutableInstanceSignals addObject:signal];
        }
        
        // clean dealloc instance
        NSMutableArray *cleanInstances = [NSMutableArray array];
        [curPermissionInstanceInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull instanceAddress, NSArray * _Nonnull signals, BOOL * _Nonnull stop) {
            NSDictionary *lastSignal = signals.lastObject;
            TSPKAPIUsageType usageType = [lastSignal btd_integerValueForKey:usageStr];
            if (usageType == TSPKAPIUsageTypeDealloc) {
                NSTimeInterval deallocTimestamp = [lastSignal btd_doubleValueForKey:TSPKSignalTimeKey];
                if (timestamp - deallocTimestamp - kCleanDeallocInterval > DBL_EPSILON) {
                    [cleanInstances addObject:instanceAddress];
                    *stop = YES;
                }
            }
        }];
        [curPermissionInstanceInfo removeObjectsForKeys:cleanInstances];
        
        pthread_rwlock_unlock(&self->_rwPermissionInfoLock);
        //[TSPKLogger logWithTag:@"zyiyi" message:signal];
    });
}

+ (nullable NSDictionary *)signalInfoWithPermissionType:(nonnull NSString *)permissionType instanceAddress:(nonnull NSString *)instanceAddress {
    return [[TSPKSignalManager sharedManager] signalInfoWithPermissionType:permissionType instanceAddress:instanceAddress needFormatTime:NO];
}

+ (nullable NSDictionary *)signalInfoWithPermissionType:(nonnull NSString *)permissionType
                                        instanceAddress:(nonnull NSString *)instanceAddress
                                         needFormatTime:(BOOL)needFormatTime {
    return [[TSPKSignalManager sharedManager] signalInfoWithPermissionType:permissionType instanceAddress:instanceAddress needFormatTime:needFormatTime];
}

+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType
                                             needFormatTime:(BOOL)needFormatTime {
    return [[TSPKSignalManager sharedManager] signalInfoWithPermissionType:permissionType instanceAddress:@"" needFormatTime:needFormatTime];
}

+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType {
    return [[TSPKSignalManager sharedManager] signalInfoWithPermissionType:permissionType instanceAddress:@"" needFormatTime:NO];
}

- (nullable NSDictionary *)signalInfoWithPermissionType:(nonnull NSString *)permissionType
                                        instanceAddress:(nonnull NSString *)instanceAddress
                                         needFormatTime:(BOOL)needFormatTime {
    if (permissionType.length == 0) {
        return nil;
    }
    
    __block NSTimeInterval timestamp = 0;
    pthread_rwlock_rdlock(&self->_rwPermissionInfoLock);
    
    // find latest start timestamp with a specified instance address
    if (instanceAddress.length > 0) {
        NSMutableDictionary *permissionInstanceInfo = [self instancesInfoWithPermissionType:permissionType];
        NSArray *signals = [permissionInstanceInfo btd_arrayValueForKey:instanceAddress];
        [signals enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull signal, NSUInteger idx, BOOL * _Nonnull stop) {
            TSPKAPIUsageType usageType = [signal btd_integerValueForKey:usageStr];
            if (usageType == TSPKAPIUsageTypeStart) {
                timestamp = [signal btd_doubleValueForKey:TSPKSignalTimeKey];
                *stop = YES;
            }
        }];
    } else {
        // find the latest unreleased instance
        NSMutableDictionary *permissionInstanceInfo = [self instancesInfoWithPermissionType:permissionType];
        __block NSDictionary *latestStartSignal;
        [permissionInstanceInfo enumerateKeysAndObjectsUsingBlock:^(NSDictionary * _Nonnull instanceAddress, NSArray * _Nonnull signals, BOOL * _Nonnull stop) {
            NSDictionary *signal = signals.lastObject;
            TSPKAPIUsageType usageType = [signal btd_integerValueForKey:usageStr];
            if (usageType != TSPKAPIUsageTypeStart) {
                return;
            }
            // compare and find latest
            if (latestStartSignal == nil) {
                latestStartSignal = signal.copy;
            } else {
                NSTimeInterval curTimestamp = [signal btd_doubleValueForKey:TSPKSignalTimeKey];
                NSTimeInterval compareTimestamp = [latestStartSignal btd_doubleValueForKey:TSPKSignalTimeKey];
                if (curTimestamp - compareTimestamp > DBL_EPSILON) {
                    latestStartSignal = signal.copy;
                }
            }
        }];
        timestamp = [latestStartSignal btd_doubleValueForKey:TSPKSignalTimeKey];
    }
    pthread_rwlock_unlock(&_rwPermissionInfoLock);
    NSArray *formattedSignals = [self signalFlowWithPermissionType:permissionType
                                                    startTimestamp:timestamp
                                                    needFormatTime:needFormatTime];
    
    if (formattedSignals.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    mutableDic[@"signals"] = formattedSignals;
    mutableDic[@"signal_start_time"] = @"0";
    
    if (instanceAddress.length > 0) {
        // find end time
        __block NSString *endTime;
        [formattedSignals enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull signal, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *content = [signal btd_stringValueForKey:@"content"];
            NSString *curInstanceAddress = [signal btd_stringValueForKey:@"instance"];
            
            if (content.length > 0 && curInstanceAddress.length > 0) {
                if (endTime.length == 0) {
                    if ([instanceAddress isEqualToString:curInstanceAddress] && [content containsString:@"Guard detect unreleased"]) {
                        endTime = [signal btd_stringValueForKey:@"t"];
                        *stop = YES;
                    }
                }
            }
        }];
        if (endTime.length > 0) {
            mutableDic[@"signal_end_time"] = endTime;
        }
    }
    
    return mutableDic.copy;
}

#pragma mark - instance info

- (NSMutableDictionary *)instancesInfoWithPermissionType:(NSString *)permissionType {
    NSMutableDictionary *permissionInstanceInfo = [self permissionInstancesInfo];
    
    if (!permissionInstanceInfo[permissionType]) {
        permissionInstanceInfo[permissionType] = [NSMutableDictionary dictionary];
    }
        
    if ([permissionInstanceInfo[permissionType] isKindOfClass:[NSMutableDictionary class]]) {
        return permissionInstanceInfo[permissionType];
    }
    return nil;
}

- (NSMutableDictionary *)permissionInstancesInfo
{
    NSString *key = @"InstanceInfo";
    NSMutableDictionary *info = [self btd_getAttachedObjectForKey:key];
    if (!info) {
        info = [NSMutableDictionary dictionary];
        [self btd_attachObject:info forKey:key];
    }
    return info;
}

@end
