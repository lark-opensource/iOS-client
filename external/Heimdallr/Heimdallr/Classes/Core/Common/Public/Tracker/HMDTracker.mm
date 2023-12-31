//
//  HMDTracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDTracker.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "Heimdallr+Cleanup.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDGCD.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDHermasCounter.h"
#import "HMDInjectedInfo+LegacyDBOptimize.h"

#define kRecordMinCacheCount 100

static void *tracker_queue_key = &tracker_queue_key;
static void *tracker_queue_context = &tracker_queue_context;

dispatch_queue_t hmd_get_tracker_queue(void) {
    static dispatch_queue_t tracker_queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker_queue = dispatch_queue_create("com.heimdallr.tracker", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(tracker_queue, tracker_queue_key, tracker_queue_context, 0);
    });
    return tracker_queue;
}

void dispatch_on_tracker_queue(bool async, dispatch_block_t block) {
    if (block == NULL) {
        return;
    }
    if (dispatch_get_specific(tracker_queue_key) == tracker_queue_context) {
        block();
    } else {
        if (async) {
            hmd_safe_dispatch_async(hmd_get_tracker_queue(), block);
        } else {
            dispatch_sync(hmd_get_tracker_queue(), block);
        }
    }
}

@interface HMDTracker () {
    dispatch_source_t _timer;
    CFTimeInterval _startTimestamp;
}
@end

@implementation HMDTracker


+ (instancetype)sharedTracker {
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
        
        self.lock = [[NSLock alloc] init];
        self.insertIndex = 0;
        self.hasNewData = YES;
        
        if (!_startTimestamp) {
            _startTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        _records = [NSMutableArray array];
    }

    return self;
}

- (void)didCollectOneRecord:(HMDTrackerRecord *)record {
    [self didCollectOneRecord:record async:YES];
}

- (void)didCollectOneRecord:(HMDTrackerRecord *)record trackerBlock:(TrackerDataToDBBlock)block {
    [self didCollectOneRecord:record async:YES trackerBlock:block];
}

- (void)didCollectOneRecord:(HMDTrackerRecord *)record async:(BOOL)async {
    [self didCollectOneRecord:record async:async trackerBlock:NULL];
}

- (void)didCollectOneRecord:(HMDTrackerRecord *)record async:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block {
    if (!record) {
        return;
    }
    
    [self updateRecordWithConfig:record];
    
    if ([HMDInjectedInfo defaultInfo].stopWriteToDiskWhenUnhit && !record.enableUpload) {
        if (block) {
            block(NO);
        }
        return;
    }

    dispatch_on_tracker_queue(async,^{
        [self flushRecord:record async:async trackerBlock:block];
    });
}

- (void)dropAllRecordFromMemoryCacheOrDatabase {
    dispatch_on_tracker_queue(YES, ^{
        [self.records removeAllObjects];
        [self.heimdallr.database deleteAllObjectsFromTable:[self.storeClass tableName]];
    });
}

- (void)flushRecord:(HMDTrackerRecord *)record async:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block{
    [self.records addObject:record];
    if (self.records.count >= ((HMDTrackerConfig *)self.config).flushCount) {
        [self flush:async trackerBlock:block];
    } else {
        if (block) {
            block(NO);
        }
    }
}

- (void)updateRecordWithConfig:(HMDTrackerRecord *)record
{
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    if (hermas_enabled()) {
        record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:NSStringFromClass([record class])] : -1;
    }
}

- (void)performanceDataSaveImmediately {
    dispatch_on_tracker_queue(YES,^{
        [self flush:YES trackerBlock:nil];
    });
}

- (void)setRefreshInterval:(double)refreshInterval {
    if (_refreshInterval != refreshInterval) {
        if (_timer) {
            [self scheduleTimerWithInterval:refreshInterval];
        }
        _refreshInterval = refreshInterval;
    }
}

- (void)scheduleTimerWithInterval:(double)interval {
    if (interval == 0) {
        interval = 10;
    }
    if (!_timer) {
        _refreshInterval = interval;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, hmd_get_tracker_queue());
        
        srand((unsigned)time(NULL));
#if RAND_MAX <= 0           // 一般是 RAND_MAX 未定义导致的
#error RAND_MAX <= 0
#endif
        double percentage = rand() / (double)RAND_MAX;
        double differTime = interval * percentage;
        
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW + differTime * NSEC_PER_SEC, interval * NSEC_PER_SEC, interval * NSEC_PER_SEC);
        __weak __typeof(self) wself = self;
        dispatch_source_set_event_handler(_timer, ^{
            __strong __typeof(wself) sself = wself;
            [sself flushWithTrackerBlock:nil];
        });
        dispatch_resume(_timer);
    } else {
        if (_refreshInterval != interval) {
            _refreshInterval = interval;
            dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, interval * NSEC_PER_SEC);
        }
    }
}

- (void)flush:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block {
    dispatch_on_tracker_queue(async, ^{
        [self flushWithTrackerBlock:block];
    });
}

- (void)flushWithTrackerBlock:(TrackerDataToDBBlock)block {
    
    if(self.records.count == 0) {
        if (block) {
            block(NO);
        }
        return;
    }
    
    NSArray *records = [self.records copy];
    
    BOOL flag = [self.heimdallr.database insertObjects:records into:[self.storeClass tableName]];
    
    if (block) {
        block(flag);
    }
    
    if (flag) {
        
        if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
            __block BOOL hasUploadRecord = NO;
            [records enumerateObjectsUsingBlock:^(HMDTrackerRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.enableUpload) {
                    hasUploadRecord = YES;
                    *stop = YES;
                }
            }];
            if (hasUploadRecord) {
                [self.lock lock];
                self.insertIndex += 1;
                self.hasNewData = YES;
                [self.lock unlock];
            }
        }
        
        if (self.sizeLimitTool && [self.sizeLimitTool shouldSizeLimit]) {
            [self.sizeLimitTool estimateSizeWithStoreObjectRecord:records recordClass:self.storeClass module:self];
        }
        [self.heimdallr updateRecordCount:self.records.count];
        [self.records removeAllObjects];
    }
    
    // avoid oom
    NSUInteger flushCount = (NSUInteger)((HMDTrackerConfig *)self.config).flushCount;
    NSInteger limit = MAX((flushCount * 2), (kRecordMinCacheCount));
    if (self.records.count > limit) {
        [self.records removeObjectsInRange:NSMakeRange(0, flushCount)];
        HMDALOG_PROTOCOL_WARN_TAG(@"HMDTracker", @"Drop record for avoiding oom, count : %ld", limit);
    }
}

#pragma mark - HeimdallrModule

- (void)start {
    [super start];
    
    if (!hermas_enabled()) {
        [self scheduleTimerWithInterval:((HMDTrackerConfig *)self.config).flushInterval];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(flushAsync)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
}

- (void)stop {
    [super stop];
    
    if (!hermas_enabled()) {
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
}


- (void)setupWithHeimdallr:(Heimdallr *)heimdallr {
    [super setupWithHeimdallr:heimdallr];
}

- (void)updateConfig:(HMDTrackerConfig *)config {
    [super updateConfig:config];
    self.refreshInterval = config.flushInterval;
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig
{
    [self.heimdallr cleanupDatabaseWithConfig:cleanConfig tableName:[self.storeClass tableName]];
    [self.heimdallr cleanupDatabase:[self.storeClass tableName] limitSize:[self dbMaxSize]];
}

- (BOOL)needSyncStart {
    return NO;
}

#pragma mark - SyncFlush

- (void)flushAsync {
    [self flush:YES trackerBlock:nil];
}

- (void)performanceActionOnTrackerAsyncQueue:(dispatch_block_t)block {
    if (block) {
        dispatch_on_tracker_queue(YES, block);
    }
}

#pragma mark - Helper
- (long long)dbMaxSize {
    return 10000;
}

+ (NSString *)getLastSceneIfAvailable {
    NSString *scene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    if(scene == nil) scene = @"unknown";
    return scene;
}

+ (NSDictionary *)getOperationTraceIfAvailable {
    NSDictionary *operationTrace = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), sharedOperationTrace), NSDictionary);
    return operationTrace;
}

+ (void)asyncActionOnTrackerQueue:(dispatch_block_t)action {
    dispatch_on_tracker_queue(YES, action);
}


@end
