//
//  HMDInspector.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/5/8.
//

#include <stdatomic.h>
#include "pthread_extended.h"
#include <objc/message.h>
#include <objc/runtime.h>
#import "HMDInspector.h"
#import "HMDALogProtocol.h"
#import "Heimdallr+Private.h"
#import "HMDMacro.h"
#import "HMDModuleConfig.h"
#import "HMDDynamicCall.h"
#import "HMDWeakProxy.h"
#import "HMDSimpleBackgroundTask.h"
#import "HMDMemoryUsage.h"
#import "hmd_section_data_utility.h"
#import "HMDRecordCleanALog.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP


#define HMDDBInspectDevastedLimitedToPercentage   0.1
#define HMDDBInspectorLimitedToCountMIN 100
#define HMDDBInspectFirstTimeDelayMIN 2
#define HMDDBInspectDevastedTorlerance 3
#define DefaultCleanupWeight         20
#define SEC_PRE_MIN 60
#define DBInspectInterval 60    // 分钟
#define HMDDBInspectMaxWeight 100
#define kHMDDBExpectedLevel_MIN 20      // MB
#define kHMDDBExpectedLevel_MAX 1024    // MB
#define kHMDDBExpectedLevel_DEF 50      // MB

HMD_LOCAL_MODULE_CONFIG(HMDInspector)

@interface HMDInspector ()
@property (atomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, assign, readwrite) BOOL isDBHandling;
@end

@implementation HMDInspector {
    @private
    
    // DB Inspect
     pthread_mutex_t _DBInspect_mutex;
                BOOL _isDBInspect_inProgress;   // DB_mutex
         atomic_uint _DBDevastedCount;
}

- (void)start {
    self.isRunning = YES;
    [self startDatabaseInspectation];
}

- (void)stop {
    self.isRunning = NO;
    [self stopDatabaseInspectation];
}

- (void)dealloc {
    if (_isDBInspect_inProgress) {
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
        } @catch (NSException *exception) {

        }
    }
}

#pragma mark - Database Inspectation

- (void)startDatabaseInspectation {
    pthread_mutex_lock(&_DBInspect_mutex);
    if(!_isDBInspect_inProgress) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundForTask:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        _isDBInspect_inProgress = YES;
    }
    pthread_mutex_unlock(&_DBInspect_mutex);
}

- (void)stopDatabaseInspectation {
    pthread_mutex_lock(&_DBInspect_mutex);
    if(_isDBInspect_inProgress) {
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
        } @catch (NSException *exception) {

        }
        _isDBInspect_inProgress = NO;
    }
    pthread_mutex_unlock(&_DBInspect_mutex);
}

- (void)enterBackgroundForTask:(NSNotification *)notification {
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:@"com.heimdallr.hmdDiskInspector.backgroundTask" expireTime:30 task:^(void (^ _Nonnull completeHandle)(void)) {
        // 延长到 30s,一些大的 wal 文件 checkpoint 可能需要较长的时间
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self handleDatabaseInspectation];
            if (completeHandle) {
                completeHandle();
            }
        });
    }];
}

#pragma mark Handle Level [Dealing with big database size]

- (void)handleDatabaseInspectation {
    if (hermas_enabled()) return;
    
    if (self.isDBHandling) { return;}
    self.isDBHandling = YES;

    // Without vaccum database size is not what it expected to be
    [[Heimdallr shared].database executeCheckpoint];
    unsigned long long DBBytes = [self databaseSize];

    NSUInteger databaseSize = DBBytes / HMD_MB;
    NSUInteger expectedSize = [HMDInspector expectedDatabaseSize];
    NSUInteger devastedSize = [HMDInspector resolveDevastedSizeByExpectedSize:expectedSize];
    if(databaseSize > expectedSize) {
        // 删除老数据(已经上报的 过期的 未命中采样的)
        [self handleCleanUploadRecordWithDBSize:databaseSize];

        //  老的逻辑 如果按比例清除数据;
        unsigned long long currentDBBytes = [self databaseSize];
        databaseSize = currentDBBytes / HMD_MB;
        if (databaseSize > expectedSize) {
             if(databaseSize > devastedSize && [self shouldPerformDevastedCleanup]) {
#ifdef DEBUG
                NSAssert(NO, @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.");
#endif
                [self databaseCleanupByDevastation];
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDInspector handleDatabaseInspectation] [Devasted Level]");
             } else {
                 CGFloat percentage = [HMDInspector cleanupPercentageWithDatabaseSize:databaseSize
                                                                         expectedSize:expectedSize
                                                                         devastedSize:devastedSize];
                 [self databaseCleanupByGranularity:percentage];
                 HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDInspector handleDatabaseInspectation] [Granularity] percentage %f", percentage);
             }
        }
    }
    self.isDBHandling = NO;
}

/// 清理上传过的数据
- (void)handleCleanUploadRecordWithDBSize:(NSUInteger)dbSize {
    NSArray<id<HeimdallrModule>> *allModuleArray = [[Heimdallr shared] copyAllRemoteModules];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (id module in allModuleArray) {
        if([module respondsToSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")]) {
            [module performSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")];
        }
        if ([module respondsToSelector:@selector(moduleName)]) {
            hmdDBClearModuleNeedlessReportDataALog([module moduleName].UTF8String);
        }
    }
    // TTMonitor
    id ttMonitor = DC_CL(HMDTTMonitor, defaultManager);
    if([ttMonitor respondsToSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")]) {
        [ttMonitor performSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")];
        hmdDBClearModuleNeedlessReportDataALog("TTMonitor");
    }
#pragma clang diagnostic pop
    BOOL isSuccess = [self dbVaccumIfEnvironmentAvailable];
    if (isSuccess && hmd_log_enable()) {
        unsigned long long currentDBBytes = [self databaseSize];
        NSUInteger currentSize = currentDBBytes / HMD_MB;
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDInspector handleDatabaseInspectation] dbSize before: %lu, after: %lu", (unsigned long)dbSize, (unsigned long)currentSize);
    }
}

- (void)databaseCleanupByGranularity:(CGFloat)percentage {
    NSAssert(percentage <= 1.0 && percentage >= 0.0 && !isnan(percentage) && !isinf(percentage),
             @"[FATAL ERROR] Please preserve current environment"
              " and contact Heimdallr developer ASAP");
    if(isnan(percentage) || isinf(percentage)) return;
    if(percentage > 1.0) percentage = 1.0;
    else if(percentage < 0.0) percentage = 0.0;
    
    NSArray<NSString *> *tableNameArray;
    NSDictionary<NSString *, NSNumber *> *countDictionary;
    NSDictionary<NSString *, NSNumber *> *cleanupWeightDictionary;
    
    if([self currentDatabaseTable:&tableNameArray count:&countDictionary cleanupWeight:&cleanupWeightDictionary]) {
        NSMutableSet<NSString *> *excludedTableSet = [NSMutableSet set];
        NSMutableSet<NSString *> *cleanAllTableSet = [NSMutableSet set];

        __block long long recordSum = 0; // 所有表的记录总数
        /* exclude cleanless table */
        [countDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, NSNumber * _Nonnull countObject, BOOL * _Nonnull stop) {
            if([countObject longLongValue] <= 0) [excludedTableSet addObject:tableName];
            recordSum += [countObject longLongValue];
        }];
        
        /* exclude clean empty table */
        __block long dropRecordCount = 0; // 所有需要 drop 的表的数量
        __block NSInteger cleanTableWeight = 0; // 所需清理的表的总权重
        [cleanupWeightDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, NSNumber * _Nonnull cleanupWeight, BOOL * _Nonnull stop) {
            if([cleanupWeight integerValue] >= HMDDBInspectMaxWeight) {
                [cleanAllTableSet addObject:tableName];
                [excludedTableSet addObject:tableName];
                NSNumber *recordCount = [countDictionary valueForKey:tableName];
                dropRecordCount += [recordCount longLongValue];
            } else {
                long long tableCount = [[countDictionary valueForKey:tableName] longLongValue];
                if (tableCount > 0) {
                    cleanTableWeight += [cleanupWeight integerValue];
                }
            }
        }];
        
        NSMutableArray<NSString *> *tempArray = [tableNameArray mutableCopy];
        [excludedTableSet enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, BOOL * _Nonnull stop) {
            [tempArray removeObject:tableName];
        }];
        tableNameArray = [tempArray copy];
        /* Caculate granularity */
        __block long long needCleanCount = (NSInteger)(recordSum * percentage);
        __block CGFloat deleteGranularity = (CGFloat)needCleanCount / (CGFloat)cleanTableWeight;
        [tableNameArray enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger tableWeight = [[cleanupWeightDictionary valueForKey:tableName] unsignedIntegerValue];
            long long tableCount = [[countDictionary valueForKey:tableName] longLongValue];
            long long tableNeedCleanCount = tableWeight * deleteGranularity;
            long long maxSizeCount = tableCount - tableNeedCleanCount;
            needCleanCount -= (tableCount > tableNeedCleanCount ? tableNeedCleanCount : tableCount);
            cleanTableWeight -= tableWeight;
            if (maxSizeCount < 0) {
                maxSizeCount = 0;
                // 如果分给给这个表的需要清理的数量 全部清理完了还不够的话, 把剩余的数量分配到剩余的表,并重新计算清理的单位(剩余需要清理的数量/剩余总重)
                if (cleanTableWeight > 0 && needCleanCount > 0) {
                    deleteGranularity = (CGFloat)(needCleanCount / cleanTableWeight);
                }
            }
            [[Heimdallr shared].database deleteObjectsFromTable:tableName limitToMaxSize:maxSizeCount];
        }];
        /* cleanup max weight table */
        [cleanAllTableSet enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, BOOL * _Nonnull stop) {
            [[Heimdallr shared].database dropTable:tableName];
        }];

        [self dbVaccumIfEnvironmentAvailable];
    }
}

/// 较大数据库执行 vacuum 的
- (BOOL)dbVaccumIfEnvironmentAvailable {
    if (![HMDSessionTracker currentSession].isBackgroundStatus) {return NO;} // 只在后台执行
    /* 参考的各种设备 OOM 的值 (估计值 并不严格准确) https://stackoverflow.com/questions/5887248/ios-app-maximum-memory-budget, 总体来说超过总内存的百分之五十到六十多就可能发生 OOM 这里取百分之五十作为标准 */
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    u_int64_t appUsedMemory = memoryBytes.appMemory;
    u_int64_t limitMemory = memoryBytes.totalMemory / 2;
    u_int64_t availabelMemeory = memoryBytes.availabelMemory;
    u_int64_t estimateDBUsed = (u_int64_t)(200 * 1024 * 1024); // 预留出 200M 的空间
    u_int64_t allUsedMemory = appUsedMemory + estimateDBUsed; // 预留出 200M 的空间
    // 如果当前 APP 使用的内存大小已经大于总内存的一半的时候 暂时不执行 vacuum
    // 如果当前 APP 期望使用的内存比可用内存要大 也不执行 vacuum
    if (allUsedMemory > limitMemory || estimateDBUsed > availabelMemeory) { return NO; }

    // sqlite 采用的是变长记录存储, 如果删除了数据, 删除后的数据不变只是会做一个标记, 所以执行以下 vaccum
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    [[Heimdallr shared].database immediatelyActiveVacuum];
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    // checkpoint 清理过程中产生的 - wal 要放到 vacuum 后面, 因为 vacuum 会产生一个较大的 wal 文件
    [[Heimdallr shared].database executeCheckpoint];
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[HMDInspector handleDatabaseInspectation] vacuum use time: second %lf", (end - start));
    }
    return YES;
}

- (void)databaseCleanupByDevastation {
    NSArray<NSString *> *tableNameArray;
    NSDictionary<NSString *, NSNumber *> *countDictionary;
    NSDictionary<NSString *, NSNumber *> *cleanupWeightDictionary;
    if([self currentDatabaseTable:&tableNameArray count:&countDictionary cleanupWeight:&cleanupWeightDictionary]) {
        
        NSMutableSet<NSString *> *excludedTableSet = [NSMutableSet set];
        
        /* exclude cleanless table */
        [countDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, NSNumber * _Nonnull countObject, BOOL * _Nonnull stop) {
            if([countObject integerValue] <= 0) [excludedTableSet addObject:tableName];
        }];
        
        NSMutableArray<NSString *> *tempArray = [tableNameArray mutableCopy];
        [excludedTableSet enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, BOOL * _Nonnull stop) {
            [tempArray removeObject:tableName];
        }];
        tableNameArray = [tempArray copy];
        
        [tableNameArray enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger count = [[countDictionary valueForKey:tableName] unsignedIntegerValue];
            NSUInteger limited = count * HMDDBInspectDevastedLimitedToPercentage;
            if(limited < HMDDBInspectorLimitedToCountMIN) limited = HMDDBInspectorLimitedToCountMIN;
            if(limited < count) {
                [[Heimdallr shared].database deleteObjectsFromTable:tableName limitToMaxSize:limited];
            }
        }];
    }

    [self dbVaccumIfEnvironmentAvailable];
}

#pragma mark - Aggressive Cleanup Info [Protect]

- (BOOL)currentDatabaseTable:(NSArray<NSString *> ** _Nonnull)allTableName
                       count:(NSDictionary<NSString *, NSNumber *> ** _Nonnull)allCount
               cleanupWeight:(NSDictionary<NSString *, NSNumber *> ** _Nonnull)allCleanupWeight {
    NSDictionary<NSString *, id<HeimdallrModule>> *localPairs = [HMDInspector allPossibleTableAndModulePairs];
    NSArray<NSString *> *additionalTableNames = [HMDInspector defaultAdditonalTableName];
    
    if(localPairs.count > 0 || additionalTableNames.count > 0) {
        
        NSDictionary<NSString *, NSNumber *> *cleanupWeight =
        [self cleanupWeightWithTableNameAndClassPairs:localPairs
                                 additionalTableNames:additionalTableNames];
        
        NSArray<NSString *> *localTableNames = localPairs.allKeys;
        
        NSArray<NSString *> *tableNames = [HMDInspector combineTables:localTableNames withTable:additionalTableNames];
        
        NSDictionary<NSString *, NSNumber *> *counts = [self recordCountsWithTableNames:tableNames];
        
        if(allTableName)     *allTableName = tableNames;
        if(allCount)         *allCount = counts;
        if(allCleanupWeight) *allCleanupWeight = cleanupWeight;
        
        return YES;
    }
    NSAssert(NO, @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP");
    return NO;
}

#pragma mark Database TableName [Private]

+ (NSDictionary<NSString *, id<HeimdallrModule>> * _Nullable)allPossibleTableAndModulePairs {
    static NSDictionary<NSString *, id<HeimdallrModule>> *allPairs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSString *, id<HeimdallrModule>> *tempAllPairs = [NSMutableDictionary dictionary];
        NSArray<id<HeimdallrModule>> *allModuleArray = [[Heimdallr shared] copyAllRemoteModules];
        for(id module in allModuleArray) {
            NSString *tableName = DC_IS(DC_OB(DC_OB(module, storeClass), tableName), NSString);
            if(tableName != nil) [tempAllPairs setValue:module forKey:tableName];
        }
        allPairs = [tempAllPairs copy];
    });
    return allPairs;
}


+ (NSArray<NSString *> * _Nullable)defaultAdditonalTableName {
    return @[@"network_monitor", @"crash", @"TTMetricEvent", @"TTServiceEvent"];
}

#pragma mark cleanup weight [Private]

- (NSDictionary<NSString *, NSNumber *> * _Nonnull)cleanupWeightWithTableNameAndClassPairs:(NSDictionary<NSString *, id<HeimdallrModule>> * _Nullable)pairs additionalTableNames:(NSArray<NSString *> * _Nullable)additionalTableNames {
    NSUInteger pairsCount = pairs.count;
    NSUInteger additionalCount = additionalTableNames.count;
    
    NSDictionary<NSString *, NSNumber *> *defaultOverrideDictionary = [HMDInspector defaultTableCleanupWeightOverride];
    NSMutableDictionary<NSString *, NSNumber *> *tempDictionary = [NSMutableDictionary dictionaryWithCapacity:pairsCount + additionalCount];
    
    [pairs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tableName, id<HeimdallrModule>  _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *override;
        if( (override = [defaultOverrideDictionary objectForKey:tableName]) != nil) {
            [tempDictionary setValue:override forKey:tableName];
        } else {
            Class storeClass = (Class)DC_OB(obj, storeClass);
            BOOL isRepsonseCleanSEL = storeClass ? [storeClass respondsToSelector:NSSelectorFromString(@"cleanupWeight")] : NO;
            if(isRepsonseCleanSEL && (override = DC_IS(DC_OB(DC_OB(obj, storeClass), cleanupWeight), NSNumber)) != nil) {
               NSUInteger value = override.unsignedIntegerValue;
               if(value >= HMDDBInspectMaxWeight) value = HMDDBInspectMaxWeight;
               [tempDictionary setValue:@(value) forKey:tableName];
            }
            else {
                [tempDictionary setValue:[HMDInspector defaultCleanupWeightForTableName:tableName] forKey:tableName];
            }
        }

    }];
    
    [additionalTableNames enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, NSUInteger idx, BOOL * _Nonnull stop) {
        if([pairs objectForKey:tableName] == nil) {
            NSNumber *override;
            if( (override = [defaultOverrideDictionary objectForKey:tableName]) != nil)
                [tempDictionary setValue:override forKey:tableName];
            else [tempDictionary setValue:[HMDInspector defaultCleanupWeightForTableName:tableName] forKey:tableName];
        }
    }];
    
    return [tempDictionary copy];
}

+ (NSNumber * _Nonnull)defaultCleanupWeightForTableName:(NSString *)tableName {
    return @(DefaultCleanupWeight);
}

+ (NSDictionary<NSString *, NSNumber *> * _Nonnull)defaultTableCleanupWeightOverride {
    static NSDictionary<NSString *, NSNumber *> *defaultOverride;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultOverride = @{
            
            // 史前遗留数据 0.7.0
            @"network_monitor": @(HMDDBInspectMaxWeight),
            @"crash": @(HMDDBInspectMaxWeight),
            @"TTMetricEvent": @(80),
            @"TTServiceEvent": @(60)
        };
    });
    return defaultOverride;
}

//#ifdef DEBUG
//+ (void)load {
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSArray<NSString *> *allTableNames;
//            [[HMDInspector shared] currentDatabaseTable:&allTableNames count:NULL cleanupWeight:NULL];
//            NSDictionary<NSString *, NSNumber *> *defaultOverride = [HMDInspector defaultTableCleanupWeightOverride];
//            NSArray<NSString *> *overrideTableNames = [defaultOverride allKeys];
//            [overrideTableNames enumerateObjectsUsingBlock:^(NSString * _Nonnull overrideName, NSUInteger idx, BOOL * _Nonnull stop) {
//                BOOL have = [allTableNames containsObject:overrideName];
//                // 史前遗留数据 0.7.0
//                NSArray *history = @[@"network_monitor", @"crash"];
//                if(!(have || [history containsObject:overrideName]))
//                    NSLog(@"【需要清理】+[HMDInspector defaultTableCleanupWeightOverride] \n"
//                          " tableName %@ NOT exist anymore", overrideName);
//            }];
//        });
//    });
//}
//#endif

#pragma mark Database Query [Private]

- (NSDictionary<NSString *, NSNumber *> * _Nonnull)recordCountsWithTableNames:(NSArray<NSString *>  * _Nonnull)pairs {
    NSUInteger count = pairs.count;
    NSMutableDictionary<NSString *, NSNumber *> *tempDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
    [pairs enumerateObjectsUsingBlock:^(NSString * _Nonnull tableName, NSUInteger idx, BOOL * _Nonnull stop) {
        [tempDictionary setValue:@([self recordCountForTableName:tableName]) forKey:tableName];
    }];
    return [tempDictionary copy];
}

- (long long)recordCountForTableName:(NSString *)tableName {
    return [[Heimdallr shared].database recordCountForTable:tableName];
}

#pragma mark - Database Size

- (unsigned long long)databaseSize {
    return [[Heimdallr shared].store dbFileSize];
}

+ (NSUInteger)expectedDatabaseSize {
    HMDHeimdallrConfig *config;
    if((config = [Heimdallr shared].config) != nil) {
        HMDCleanupConfig *cleanupConfig;
        if((cleanupConfig = config.cleanupConfig) != nil) {
            NSUInteger expectedDBSize = cleanupConfig.expectedDBSize;
            if(expectedDBSize > kHMDDBExpectedLevel_MAX) expectedDBSize = kHMDDBExpectedLevel_MAX;
            else if(expectedDBSize < kHMDDBExpectedLevel_MIN) expectedDBSize = kHMDDBExpectedLevel_MIN;
            return expectedDBSize;
        }
    }
    return kHMDDBExpectedLevel_DEF;
}

+ (NSUInteger)resolveDevastedSizeByExpectedSize:(NSUInteger)expectedSize {
    if(expectedSize < 500) return expectedSize * 2;
    else return expectedSize + 500;
}

- (BOOL)shouldPerformDevastedCleanup {
    if(_DBDevastedCount++ > HMDDBInspectDevastedTorlerance) return YES;
    return NO;
}

+ (CGFloat)cleanupPercentageWithDatabaseSize:(CGFloat)DBSize
                                expectedSize:(CGFloat)expected
                                devastedSize:(CGFloat)devasted {
    NSAssert(expected != devasted,
             @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.");
    if(expected == devasted) return 0.0;
    
    if(DBSize <= expected) return 0.0;
    else return (DBSize - expected) / DBSize;
}

#pragma mark - Supporting method

+ (NSArray<NSString *> * _Nullable)combineTables:(NSArray<NSString *> * _Nullable)table1
                                       withTable:(NSArray<NSString *> * _Nullable)table2 {
    if(table1 == nil && table2 == nil) return nil;
    
    NSMutableSet *set;
    if(table1 != nil && table2 == nil) set = [NSMutableSet setWithArray:table1];
    else if(table1 == nil && table2 != nil) set = [NSMutableSet setWithArray:table2];
    else {
        set = [NSMutableSet setWithArray:table1];
        [set addObjectsFromArray:table2];
    }
    return set.allObjects;
}

#pragma mark - Don't care

- (instancetype)init {
    NSAssert(NO, @"[FATAL ERROR] Please preserve current environment and contact Heimdallr developer ASAP.");
    return [HMDInspector sharedInstance];
}

+ (instancetype)sharedInstance {
    static __kindof HMDInspector *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMDInspector alloc] initSharedInspector];
    });
    return sharedInstance;
}

- (instancetype)initSharedInspector {
    if (self = [super init]) {
        _isRunning = NO;
        pthread_mutex_init(&_DBInspect_mutex, NULL);
    }
    return self;
}

#pragma mark - No use

+ (id<HeimdallrLocalModule>)getInstance {
    return [HMDInspector sharedInstance];
}

- (NSString *)moduleName {
    return @"inspector";
}

@end
