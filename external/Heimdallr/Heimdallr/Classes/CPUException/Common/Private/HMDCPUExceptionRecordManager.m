//
//  HMDCPUExceptionRecordCache.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/5/19.
//

#import "HMDCPUExceptionRecordManager.h"
#import "HMDGCD.h"
#include "pthread_extended.h"
#import "NSArray+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDInjectedInfo.h"
#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasCounter.h"
// Utility
#import "HMDMacroManager.h"

#define kHMDCPUExceptionMaxCompareCount 20
static pthread_mutex_t mutex_t = PTHREAD_MUTEX_INITIALIZER;

@interface HMDCPUExceptionRecordManager ()

@property (nonatomic, strong) NSMutableArray<HMDCPUExceptionV2Record *> *records;
@property (nonatomic, strong) NSMutableArray<NSString *> *reportedRecordUUIDs;
@property (nonatomic, strong) NSMutableArray *cacheCompareRecords;
@property (nonatomic, strong) dispatch_queue_t storeQueue;

@property (nonatomic, strong) HMInstance *instance;

@end

@implementation HMDCPUExceptionRecordManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.records = [NSMutableArray array];
    self.reportedRecordUUIDs = [NSMutableArray array];
    self.cacheCompareRecords = [NSMutableArray array];
    self.storeQueue = dispatch_queue_create("com.heimdallr.cpu.exception.store", DISPATCH_QUEUE_SERIAL);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMemroyWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

#pragma mark ---  store date ---
- (void)pushRecord:(HMDCPUExceptionV2Record *)record needUploadImmediately:(BOOL)needImmediately {
    if (HMD_IS_DEBUG) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"In Debug Env, Heimdallr CPU exception has been trigged, if you want to get more information, you can debug current record");
        }
        return;
    }
    if (hermas_enabled()) {
        record.sequenceCode = [[HMDHermasCounter shared] generateSequenceCode:@"HMDCPUExceptionV2Record"];
        BOOL recordImmediately = needImmediately;
        HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
        [self.instance recordData:record.reportDictionary priority:priority];
    } else {
        hmd_safe_dispatch_async(self.storeQueue,  ^{
            // 如果开启去重直接去重
            pthread_mutex_lock(&mutex_t);
            [self.records hmd_addObject:record];
            pthread_mutex_unlock(&mutex_t);
            // 如果不立即上报 先入库
            if (needImmediately &&
                [self.delegate respondsToSelector:@selector(shouldReportCPUExceptionRecordNow)]) {
                [self.delegate shouldReportCPUExceptionRecordNow];
            }
            if (!needImmediately) {
                BOOL isSuccess = [self storeRecords];
                if (isSuccess) {
                    pthread_mutex_lock(&mutex_t);
                    [self.records removeAllObjects];
                    pthread_mutex_unlock(&mutex_t);
                }
            }
        });
    }
    
}

- (BOOL)storeRecords {
    BOOL isSuccess = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(storeCPUExceptionRecords:)]) {
        isSuccess = [self.delegate storeCPUExceptionRecords:self.records];
    }
    return isSuccess;
}

- (NSArray *)cpuExceptionReprotDataWithRecords:(NSArray<HMDCPUExceptionV2Record *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    for (HMDCPUExceptionV2Record *record in records) {
        @autoreleasepool {
            NSDictionary *dict = [record reportDictionary];
            if (dict) {
                [dataArray hmd_addObject:dict];
            }
            if (record.uuid) {
                hmd_safe_dispatch_async(self.storeQueue, ^{
                    [self.reportedRecordUUIDs hmd_addObject:[record.uuid copy]];
                });
            }
        }
    }
    return [dataArray copy];
}

- (void)cpuExceptionReportCompletion:(BOOL)success {
    hmd_safe_dispatch_async(self.storeQueue,  ^{
        if (success) {
            if (!self.isRecordFromStore) {
                pthread_mutex_lock(&mutex_t);
                [self.records removeAllObjects];
                pthread_mutex_unlock(&mutex_t);
            } else if ([self.delegate respondsToSelector:@selector(deleteCPUExceptionRecords:)]) {
               [self.delegate deleteCPUExceptionRecords:self.reportedRecordUUIDs];
            }
        }
        [self.reportedRecordUUIDs removeAllObjects];
    });
}

#pragma mark --- upload memory data
- (NSArray *)cpuExceptionReportData {
    pthread_mutex_lock(&mutex_t);
    NSArray *reportData = [self cpuExceptionReprotDataWithRecords:[self.records copy]];
    pthread_mutex_unlock(&mutex_t);
    return  reportData;
}

#pragma mark --- memory warning ---
- (void)receiveMemroyWarning:(NSNotification *)notification {
    hmd_safe_dispatch_async(self.storeQueue, ^{
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Heimdallr CPU Exception Memory warning and clear data");
        }
        [self.cacheCompareRecords removeAllObjects];
        pthread_mutex_lock(&mutex_t);
        [self.records removeAllObjects];
        pthread_mutex_unlock(&mutex_t);
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
