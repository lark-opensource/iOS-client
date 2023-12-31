//
//  BDPLLogMonitorManager.m
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import "BDPLLogMonitorManager.h"
#import "NSDictionary+BDPL.h"
#import "BDPowerLogManager.h"
#import <objc/runtime.h>

#define upload_interval 3600
#define flush_interval 60
#define log_count_metrics_extension @"log_count_metrics"
#define top_n_log 10
#define flush_timestamp_key "flush_timestamp"
#define upload_timestamp_key "powerlog_log_count_metrics_upload_timestamp"

@interface BDPLLogMonitorManager()<BDPLLogMonitorDelegate>
@property (nonatomic, strong) NSHashTable *table;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *basePath;
@property (nonatomic, assign) BOOL hasUpload;
@end

@implementation BDPLLogMonitorManager

+ (instancetype)sharedManager {
    static BDPLLogMonitorManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[BDPLLogMonitorManager alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.table = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        self.lock = [[NSLock alloc] init];
        self.uuid = [[NSUUID UUID] UUIDString];
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *logmonitorPath = [libraryPath stringByAppendingPathComponent:@"PowerLog/LogMonitor"];
        self.basePath = [logmonitorPath stringByAppendingPathComponent:self.uuid];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.basePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (void)_addLogMonitor:(BDPLLogMonitor *)monitor {
    [self.lock lock];
    
    [self.table addObject:monitor];
    
    [self.lock unlock];
}

- (NSArray<BDPLLogMonitor *> *)allLogMonitors {
    [self.lock lock];
    
    NSArray *objects = [self.table allObjects];
    
    [self.lock unlock];
    
    return objects;
}

+ (NSArray<BDPLLogMonitor *> *)allLogMonitors {
    return [[BDPLLogMonitorManager sharedManager] allLogMonitors];
}

+ (BDPLLogMonitor *)monitorWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config {
    BDPLLogMonitor *logMonitor = [BDPLLogMonitor monitorWithType:type config:config];
    logMonitor.delegate = [BDPLLogMonitorManager sharedManager];
    [[BDPLLogMonitorManager sharedManager] _addLogMonitor:logMonitor];
    return logMonitor;
}

- (void)onHighFrequentEvents:(BDPLLogMonitor *)monitor deltaTime:(long long)deltaTime count:(long long)count counterDict:(NSDictionary *)counterDict {
    if ([self.delegate respondsToSelector:@selector(onHighFrequentEvents:deltaTime:count:counterDict:)]) {
        [self.delegate onHighFrequentEvents:monitor deltaTime:deltaTime count:count counterDict:counterDict];
    }
}

- (void)dataChanged:(NSString *)dataType data:(NSDictionary *)data init:(BOOL)init {
    if (init)
        return;
    if ([dataType isEqualToString:BDPowerLogDataType_app_state]) {
        if(!data.isForeground) {
            [[self allLogMonitors] enumerateObjectsUsingBlock:^(BDPLLogMonitor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.enable && obj.config.enableLogCountMetrics) {
                    [self flushLogCountMetricsForMonitor:obj];
                 }
            }];
            [self uploadLogCountMetrics];
        }
    }
}

- (NSString *)diskCachePathForMonitor:(BDPLLogMonitor *)monitor {
    return [self.basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.log_count_metrics",monitor.type]];
}

- (void)flushLogCountMetricsForMonitor:(BDPLLogMonitor *)monitor{
    NSNumber *number = objc_getAssociatedObject(monitor, flush_timestamp_key);
    double ts = [number doubleValue];
    double cur_ts = CACurrentMediaTime();
    if (cur_ts - ts < flush_interval) {
        return;
    }
    NSDictionary *counterDict = [monitor totalCounterDict];
    if (counterDict.count == 0) {
        return;
    }
    if ([NSJSONSerialization isValidJSONObject:counterDict]) {
        @try {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:counterDict options:0 error:nil];
            NSString *path = [self diskCachePathForMonitor:monitor];
            if ([jsonData writeToFile:path atomically:YES]) {
                objc_setAssociatedObject(monitor, flush_timestamp_key, @(cur_ts), OBJC_ASSOCIATION_RETAIN);
            }
        } @catch (NSException *exception) {
            [BDPowerLogManager.delegate printErrorLog:exception.description];
        } @finally {
            
        }
    }
}

- (void)uploadLogCountMetrics {
    if (self.hasUpload) {
        return;
    }
    double cur_ts = CACurrentMediaTime();
    double upload_ts = [[NSUserDefaults standardUserDefaults] doubleForKey:@upload_timestamp_key];
    if (cur_ts - upload_ts < upload_interval) {
        return;
    }
    
    
    [[NSUserDefaults standardUserDefaults] setDouble:cur_ts forKey:@upload_timestamp_key];

    self.hasUpload = YES;
    
    NSString *logmonitorPath = [self.basePath stringByDeletingLastPathComponent];
    NSArray<NSString *> *uuids = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logmonitorPath error:nil];
    NSMutableSet<NSString *> *logTypes = [NSMutableSet set];
    [uuids enumerateObjectsUsingBlock:^(NSString * _Nonnull uuid, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![uuid isEqualToString:self.uuid]) {
            NSString *dirPath = [logmonitorPath stringByAppendingPathComponent:uuid];
            NSArray<NSString *> *names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
            [names enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
                if([name hasSuffix:log_count_metrics_extension]) {
                    NSString *logType = [name stringByDeletingPathExtension];
                    [logTypes addObject:logType];
                }
            }];
        }
    }];
    
    //merge with logtype
    [logTypes enumerateObjectsUsingBlock:^(NSString * _Nonnull logType, BOOL * _Nonnull stop) {
        NSMutableDictionary *mergedDict = [NSMutableDictionary dictionary];
        [uuids enumerateObjectsUsingBlock:^(NSString * _Nonnull uuid, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![uuid isEqualToString:self.uuid]) {
                NSString *filePath = [logmonitorPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.%@",uuid,logType,log_count_metrics_extension]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    @autoreleasepool {
                        @try {
                            NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
                            NSDictionary *counterDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                            if ([counterDict isKindOfClass:NSDictionary.class]) {
                                [self mergeDict:counterDict target:mergedDict];
                            }
                        } @catch (NSException *exception) {
                            [BDPowerLogManager.delegate printErrorLog:exception.description];
                        } @finally {
                            
                        }
                    }
                }
            }
        }];
        [self uploadLogCountMetricsForDict:mergedDict logType:logType];
    }];
    
    [uuids enumerateObjectsUsingBlock:^(NSString * _Nonnull uuid, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![uuid isEqualToString:self.uuid]) {
            NSString *dirPath = [logmonitorPath stringByAppendingPathComponent:uuid];
            [[NSFileManager defaultManager] removeItemAtPath:dirPath error:nil];
        }
    }];
}

- (void)mergeDict:(NSDictionary *)source target:(NSMutableDictionary *)target {
    [source enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL * _Nonnull stop) {
        long long val = [[target bdpl_objectForKey:key cls:NSNumber.class] longLongValue];
        [target setValue:@(val + obj.longLongValue) forKey:key];
    }];
}

- (void)uploadLogCountMetricsForDict:(NSDictionary *)dict logType:(NSString *)logType {
    if (dict.count == 0) {
        return;
    }
    NSArray *sortedKeys = [dict keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    [sortedKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *val = [dict bdpl_objectForKey:key cls:NSNumber.class];
        if (val) {
            NSMutableDictionary *logInfo = [NSMutableDictionary dictionary];
            [logInfo bdpl_setObject:val forKey:@"log_count"];
            [logInfo bdpl_setObject:key forKey:@"log_category"];
            [logInfo bdpl_setObject:logType forKey:@"log_type"];
            [self uploadLog:logInfo];
        }
        if (idx >= top_n_log) {
            *stop = YES;
        }
    }];
}

- (void)uploadLog:(NSDictionary *)log {
    if ([BDPowerLogManager.delegate respondsToSelector:@selector(uploadEvent:logInfo:extra:)]) {
        [BDPowerLogManager.delegate uploadEvent:@"powerlog_log_count_metrics_dev" logInfo:log extra:nil];
    }
}

@end
