//
//  TSPKSignalManager.m
//  Musically
//
//  Created by ByteDance on 2022/11/8.
//

#import "TSPKSignalManager.h"
#import <pthread/pthread.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKUtils.h"
#import "TSPKStatisticEvent.h"
#import "TSPKReporter.h"
#import "TSPKLogger.h"

static NSInteger const kSignalUploadSize = 200;
static NSTimeInterval const kBeforeStartRange = 5;
static NSString * const contentKey = @"content";
static NSString * const typeKey = @"sType";
NSString * const TSPKSignalTimeKey = @"time";
static NSString * const timeStrKey = @"t";
static NSString * const extraContentKey = @"extra";
static NSString * const sysMethodStr = @"sys_method";
static NSString * const pairMethodStr = @"pair_method";
static NSString * const guardStr = @"guard";
static NSString * const systemStr = @"system";
static NSString * const customStr = @"custom";
static NSString * const commonStr = @"common";
static NSString * const logStr = @"log";

@interface TSPKSignalManager ()
{
    pthread_rwlock_t _rwPermissionInfoLock;
    dispatch_queue_t _writeQueue;
}

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *> * permissionInfo;
@property (nonatomic, copy) NSDictionary *config;
@property (nonatomic, copy) NSDictionary *logConfig;

@end

@implementation TSPKSignalManager

+ (instancetype)sharedManager
{
    static TSPKSignalManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKSignalManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _writeQueue = dispatch_queue_create("com.bytedance.privacykit.signal.write", DISPATCH_QUEUE_SERIAL);
        pthread_rwlock_init(&_rwPermissionInfoLock, NULL);
        self.permissionInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - config

- (void)setConfig:(nonnull NSDictionary*)config {
    _config = config;
    _logConfig = [config btd_dictionaryValueForKey:@"alog"];
}

#pragma mark - add common signal

+ (void)addCommonSignalWithType:(TSPKCommonSignalType)signalType
                        content:(nonnull NSString*)content {
    [self addCommonSignalWithType:signalType content:content extraInfo:nil];
}

+ (void)addCommonSignalWithType:(TSPKCommonSignalType)signalType
                        content:(nonnull NSString*)content
                      extraInfo:(nullable NSDictionary*)extraInfo {
    [[TSPKSignalManager sharedManager] addCommonSignalWithType:signalType content:content extraInfo:extraInfo];
}

- (void)addCommonSignalWithType:(TSPKCommonSignalType)signalType
                         content:(nonnull NSString*)content
                       extraInfo:(nullable NSDictionary*)extraInfo {
    if (![self isEnabled]) {
        return;
    }
    
    if (content.length == 0 && extraInfo.allKeys.count == 0) {
        return;
    }
    
    // only save cared page info
    if (signalType == TSPKCommonSignalTypePage && ![self isRecordAllPagesEnabled]) {
        BOOL isCarePage = NO;
        
        for (NSString *carePage in [self carePages]) {
            if ([content containsString:carePage]) {
                isCarePage = YES;
                break;
            }
        }
        
        if (!isCarePage) {
            return;
        }
    }
    
    NSTimeInterval timestamp = [TSPKUtils getUnixTime];
    dispatch_async(_writeQueue, ^{
        NSDictionary *signal = [self signalWithType:TSPKSignalTypeCommon content:content extraInfo:extraInfo timestamp:timestamp];
        
        pthread_rwlock_wrlock(&self->_rwPermissionInfoLock);
        
        NSDictionary *permissionSignalTypeInfo = [self signalTypesWithAllPermissionTypes];
        [permissionSignalTypeInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull permissionType, NSArray * _Nonnull signalTypes, BOOL * _Nonnull stop) {
            if ([signalTypes containsObject:commonStr]) {
                if (!self.permissionInfo[permissionType]) {
                    self.permissionInfo[permissionType] = [NSMutableArray array];
                }
                
                NSMutableArray *mutableSinglePermissionInfo = self.permissionInfo[permissionType];
                [mutableSinglePermissionInfo addObject:signal];
                [self removeFirstObjectIfExceed:mutableSinglePermissionInfo];
                
            }
        }];
        
        pthread_rwlock_unlock(&self->_rwPermissionInfoLock);
        //[TSPKLogger logWithTag:@"zyiyi" message:signal];
    });
}

#pragma mark - add signal

+ (void)addInstanceSignalWithType:(TSPKSignalType)signalType
                   permissionType:(nonnull NSString*)permissionType
                          content:(nonnull NSString*)content
                  instanceAddress:(nonnull NSString*)instanceAddress {
    NSDictionary *extraInfo = instanceAddress.length > 0 ? @{@"instance" : instanceAddress} :  nil;
    [TSPKSignalManager addSignalWithType:signalType permissionType:permissionType content:content extraInfo:extraInfo];
}

+ (void)addSignalWithType:(TSPKSignalType)signalType
           permissionType:(nonnull NSString*)permissionType
                  content:(nonnull NSString*)content {
    [self addSignalWithType:signalType permissionType:permissionType content:content extraInfo:nil];
}

+ (void)addSignalWithType:(TSPKSignalType)signalType
           permissionType:(nonnull NSString*)permissionType
                  content:(nonnull NSString*)content
                extraInfo:(nullable NSDictionary*)extraInfo {
    [[TSPKSignalManager sharedManager] addSignalWithType:signalType permissionType:permissionType content:content extraInfo:extraInfo];
}

- (void)addSignalWithType:(TSPKSignalType)signalType
            permissionType:(nonnull NSString*)permissionType
                   content:(nonnull NSString*)content
                 extraInfo:(nullable NSDictionary*)extraInfo {
    if (![self isEnabled]) {
        return;
    }
    
    if (permissionType.length == 0 || (content.length == 0 && extraInfo.allKeys.count == 0)) {
        return;
    }
        
    NSArray *allowSignalTypes = [self signalTypesWithPermissionType:permissionType];
    if (![allowSignalTypes containsObject:[self signalStringWithType:signalType]]) {
        return;
    }
    
    NSTimeInterval timestamp = [TSPKUtils getUnixTime];
    
    dispatch_async(_writeQueue, ^{
        NSDictionary *signal = [self signalWithType:signalType content:content extraInfo:extraInfo timestamp:timestamp];
        pthread_rwlock_wrlock(&self->_rwPermissionInfoLock);
        if (!self.permissionInfo[permissionType]) {
            self.permissionInfo[permissionType] = [NSMutableArray array];
        }
        
        NSMutableArray *mutableSinglePermissionInfo = self.permissionInfo[permissionType];
        
        [mutableSinglePermissionInfo addObject:signal];
        [self removeFirstObjectIfExceed:mutableSinglePermissionInfo];
        pthread_rwlock_unlock(&self->_rwPermissionInfoLock);
        //[TSPKLogger logWithTag:@"zyiyi" message:signal];
    });
}

#pragma mark - get signal flow

+ (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType {
    CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
    NSArray *flow = [self signalFlowWithPermissionType:permissionType startTimestamp:0];
    NSString *methodName = [NSString stringWithFormat:@"TSPKSignalManager signalFlowWithPermissionType:%@", permissionType];
    TSPKStatisticEvent *event = [TSPKStatisticEvent initWithMethodName:methodName startedTime:before];
    [[TSPKReporter sharedReporter] report:event];
    
    return flow;
}

+ (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType
                                    startTimestamp:(NSTimeInterval)startTimestamp {
    return [[TSPKSignalManager sharedManager] signalFlowWithPermissionType:permissionType startTimestamp:startTimestamp];
}

- (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType
                                    startTimestamp:(NSTimeInterval)startTimestamp {
    return [self signalFlowWithPermissionType:permissionType startTimestamp:startTimestamp needFormatTime:NO];
}

- (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType
                                    startTimestamp:(NSTimeInterval)startTimestamp
                                    needFormatTime:(BOOL)needFormatTime {
    if (![self isEnabled]) {
        return nil;
    }
    
    if (permissionType.length == 0) {
        return nil;
    }
    
    pthread_rwlock_rdlock(&_rwPermissionInfoLock);
    NSArray *singlePermissionSignals = [self.permissionInfo btd_arrayValueForKey:permissionType];
    // deep copy collection
    // refer to https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Collections/Articles/Copying.html
    if (singlePermissionSignals.count > 0) {
        singlePermissionSignals = [NSKeyedUnarchiver unarchiveObjectWithData:
                                   [NSKeyedArchiver archivedDataWithRootObject:singlePermissionSignals]];
    }
    pthread_rwlock_unlock(&_rwPermissionInfoLock);
    
    if (singlePermissionSignals.count == 0) {
        return nil;
    }
    
    NSMutableArray *mutableSinglePermissionSignals = singlePermissionSignals.mutableCopy;

    // remove useless info
    if (startTimestamp > DBL_EPSILON) {
        [self removeObjectsBeforeTimestamp:startTimestamp - [self beforeStartRange] inArray:mutableSinglePermissionSignals];
    }
    
    // format
    NSDateFormatter * formatter;
    if (needFormatTime) {
        formatter = [[NSDateFormatter alloc ] init];
        [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss.SSS"];
    }
    NSArray *signals = [mutableSinglePermissionSignals btd_map:^id _Nullable(NSDictionary * _Nonnull signal) {
        NSMutableDictionary *mutableSignal = signal.mutableCopy;
        // add timestamp str
        NSTimeInterval timestamp = [signal btd_doubleValueForKey:TSPKSignalTimeKey];
        mutableSignal[timeStrKey] = @((NSInteger)((timestamp - startTimestamp) * 1000.0));
        
        if (needFormatTime) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
            NSString *formatTime =  [formatter stringFromDate:date];
            mutableSignal[@"unix_time"] = formatTime;
        }
        
        // remove time
        [mutableSignal removeObjectForKey:TSPKSignalTimeKey];
        return mutableSignal.copy;
    }];
    
    return signals.copy;
}

#pragma mark - private

+ (void)removeAllSignalsWithPermissionType:(NSString *)permissionType {
    [[TSPKSignalManager sharedManager] removeAllSignalsWithPermissionType:permissionType];
}

- (void)removeAllSignalsWithPermissionType:(NSString *)permissionType {
    if (permissionType.length == 0) {
        return;
    }
    
    pthread_rwlock_wrlock(&self->_rwPermissionInfoLock);
    NSMutableArray *mutableSinglePermissionInfo = self.permissionInfo[permissionType];
    [mutableSinglePermissionInfo removeAllObjects];
    pthread_rwlock_unlock(&self->_rwPermissionInfoLock);
}

- (void)removeObjectsBeforeTimestamp:(NSTimeInterval)timestamp inArray:(NSMutableArray *)array {
    NSInteger index = [self binarySearchIndexBeforeTimestamp:timestamp inArray:array];
    if (index > 0 && index <= array.count) {
        [array removeObjectsInRange:NSMakeRange(0, index)];
    }
}

- (NSInteger)binarySearchIndexBeforeTimestamp:(NSTimeInterval)timestamp inArray:(NSArray *)array
{
    NSInteger start = 0;
    NSInteger end = array.count - 1;

    while (start <= end && start >= 0 && end >= 0) {
        NSInteger middle = start + (end - start) / 2;
        NSTimeInterval curTimestamp = [array[middle][TSPKSignalTimeKey] doubleValue];
        
        if (curTimestamp - timestamp == 0) {
            return middle;
        }
        if (curTimestamp - timestamp > DBL_EPSILON) {
            end = middle - 1;
        }
        if (curTimestamp - timestamp < DBL_EPSILON) {
            start = middle + 1;
        }
    }
    return start;
}

- (NSDictionary *)signalWithType:(TSPKSignalType)signalType
                        content:(nonnull NSString*)content
                          extraInfo:(nullable NSDictionary*)extraInfo
                      timestamp:(NSTimeInterval)timestamp {
    NSMutableDictionary *mutableSignal = [NSMutableDictionary dictionary];
    if (content.length > 0) {
        mutableSignal[contentKey] = content;
    }
    mutableSignal[typeKey] = @(signalType);
    mutableSignal[TSPKSignalTimeKey] = @(timestamp);
    
    NSArray *extraInfoKeys = extraInfo.allKeys;
    if (extraInfoKeys.count > 0) {
        NSArray *excludeKeys = @[TSPKSignalTimeKey, timeStrKey, @"timestamp"];
        NSMutableSet *intersection = [NSMutableSet setWithArray:extraInfoKeys];
        [intersection intersectSet:[NSSet setWithArray:excludeKeys]];
        NSArray *shouldDeleteKeys = [intersection allObjects];
        
        if (shouldDeleteKeys.count > 0) {
            NSMutableDictionary *mutableExtraInfo = extraInfo.mutableCopy;
            [mutableExtraInfo removeObjectsForKeys:shouldDeleteKeys];
            extraInfo = mutableExtraInfo.copy;
        }
    }
    
    [mutableSignal addEntriesFromDictionary:extraInfo];
    
    return mutableSignal.copy;
}

- (void)removeFirstObjectIfExceed:(NSMutableArray *)array {
    if (array.count == 0) {
        return;
    }
    
    if (array.count > [self maxUploadSize]) {
        [array removeObjectAtIndex:0];
    }
}

- (NSString *)signalStringWithType:(TSPKSignalType)type {
    switch (type) {
        case TSPKSignalTypeSystemMethod:
            return sysMethodStr;
        case TSPKSignalTypePairMethod:
            return pairMethodStr;
        case TSPKSignalTypeCommon:
            return commonStr;
        case TSPKSignalTypeGuard:
            return guardStr;
        case TSPKSignalTypeSystem:
            return systemStr;
        case TSPKSignalTypeCustom:
            return customStr;
        case TSPKSignalTypeLog:
            return logStr;
    }
}

- (NSDictionary *)signalTypesWithAllPermissionTypes {
    return [self.config btd_dictionaryValueForKey:@"composition"];;
}

- (NSArray *)signalTypesWithPermissionType:(NSString *)permissionType {
    NSDictionary *composition = [self signalTypesWithAllPermissionTypes];
    return [composition btd_arrayValueForKey:permissionType];
}

- (BOOL)isEnabled {
    return _config != nil;
}

- (NSInteger)maxUploadSize {
    return [_config btd_intValueForKey:@"max_signal_size" default:kSignalUploadSize];
}

- (NSInteger)beforeStartRange {
    return [_config btd_intValueForKey:@"before_start_range" default:kBeforeStartRange];
}

- (BOOL)isRecordAllPagesEnabled {
    return [_config btd_boolValueForKey:@"enable_record_all_pages" default:NO];
}

- (NSArray *)carePages {
    return [_config btd_arrayValueForKey:@"carePages"];
}

@end
