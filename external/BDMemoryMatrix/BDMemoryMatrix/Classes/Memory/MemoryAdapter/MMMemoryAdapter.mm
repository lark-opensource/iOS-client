//
//  WCMemoryAdapter.m
//  Pods-MatrixDemo
//
//  Created by zhufeng on 2021/8/24.
//

#import "MMMemoryAdapter.h"
#import "MMMemoryStatConfig.h"
#import "MMMemoryRecordManager.h"
#import "MMMemoryLog.h"
#import "MMMatrixDeviceInfo.h"
#import "memory_logging.h"
#import "logger_internal.h"
#import "dyld_image_info.h"
#import "MMMemoryIssue.h"
#import "MMMemoryRecordLaunchTime.h"

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <objc/runtime.h>

extern void set_current_vc_name(const char * vc_name);
extern void get_event_time_stamp(bool event_time);

// ============================================================================
#pragma mark - Memory dump callback
// ============================================================================

static void (^s_callback)(NSData *) = nil;

void memory_dump_callback(const char *data, size_t len) {
    @autoreleasepool {
        NSData *reportData = [NSData dataWithBytes:(void *)data length:len];
        s_callback(reportData);
        s_callback = nil;
    }
}

// ============================================================================
#pragma mark - Memory adapter
// ============================================================================

@interface MMMemoryAdapter () {
    MMMemoryRecordManager *m_recordManager;

    MMMemoryRecordInfo *m_lastRecord;
    MMMemoryRecordInfo *m_currRecord;
    
    uint64_t m_app_launch_time;
}

@property (nonatomic, strong) dispatch_queue_t pluginReportQueue;

@end

@implementation MMMemoryAdapter

+ (instancetype)shared {
    static MMMemoryAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[MMMemoryAdapter alloc] init];
    });
    return adapter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[MMMemoryRecordLaunchTime shared] onAppLaunch];
        
        m_recordManager = [[MMMemoryRecordManager alloc] init];
        
        uint64_t lastLaunchTime = [MMMemoryRecordLaunchTime shared].lastSessionLaunchTime;
        if (lastLaunchTime > 0) {
            m_lastRecord = [m_recordManager getRecordByLaunchTime:lastLaunchTime];
        }
        
        self.pluginReportQueue = dispatch_queue_create("matrix.memorystat", DISPATCH_QUEUE_SERIAL);

    }
    return self;
}

- (void)onAppLaunch {
    // nothing to do , just a stub
}

- (BOOL)start {
    if ([MMMatrixDeviceInfo isBeingDebugged]) {
        return NO;
    }

    if (m_currRecord != nil) {
        return NO;
    }

    int ret = MS_ERRC_SUCCESS;

    MMMemoryStatConfig *config = [MMMemoryStatConfig defaultConfiguration];
    skip_max_stack_depth = config.skipMaxStackDepth;
    skip_min_malloc_size = config.skipMinMallocSize;
    dump_call_stacks = config.dumpCallStacks;

    m_currRecord = [[MMMemoryRecordInfo alloc] init];
    m_currRecord.launchTime = [MMMemoryRecordLaunchTime shared].currentSessionLaunchTime;
    m_currRecord.systemVersion = [MMMatrixDeviceInfo systemVersion];
    m_currRecord.appUUID = @(app_uuid());

    NSString *dataPath = [m_currRecord recordDataPath];
    [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];

    memory_event_enable_vmalloc(true);
    if ((ret = enable_memory_logging(dataPath.UTF8String)) == MS_ERRC_SUCCESS) {
        [m_recordManager insertNewRecord:m_currRecord];
        return YES;
    } else {
        MatrixError(@"MemStatPlugin start error: %d", ret);
        heimdallr_disable_memory_logging("Matrix start eror");
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onMemoryAdapterError:type:)]) {
            [self.delegate onMemoryAdapterError:ret type:@"start"];
        }
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
        m_currRecord = nil;
        return NO;
    }
}

- (void)stop {
    if (m_currRecord == nil) {
        return;
    }
    [self deleteRecord:m_currRecord];
    m_currRecord = nil;
}

- (void)getEventTime:(BOOL)eventTime {
    get_event_time_stamp(eventTime);
}

// ============================================================================
#pragma mark - Record
// ============================================================================

- (NSArray *)recordList {
    return [m_recordManager recordList];
}

- (MMMemoryRecordInfo *)recordOfLastRun {
    return m_lastRecord;
}

- (MMMemoryRecordInfo *)recordByLaunchTime:(uint64_t)launchTime {
    return [m_recordManager getRecordByLaunchTime:launchTime];
}

- (void)deleteRecord:(MMMemoryRecordInfo *)record {
    [m_recordManager deleteRecord:record];
}

- (void)deleteAllRecords {
    [m_recordManager deleteAllRecords];
}

- (void)deleteOldRecords {
    [m_recordManager deleteOldRecord];
}

// ============================================================================
#pragma mark - Private
// ============================================================================

- (void)setCurrentRecordInvalid {
    if (m_currRecord == nil) {
        return;
    }
    [m_recordManager deleteRecord:m_currRecord];
    m_currRecord = nil;
}

- (void)reportError:(int)errorCode {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onMemoryAdapterError:type:)]) {
        [self.delegate onMemoryAdapterError:errorCode type:@"internal"];
    }
}

- (void)reportReason:(NSString *)reasonString {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onMemoryAdapterReason:type:)]) {
        [self.delegate onMemoryAdapterReason:reasonString type:@"heimdallrAlog"];
    }
}

// ============================================================================
#pragma mark - Report
// ============================================================================

- (void)report {
    NSDictionary *customInfo = nil;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(onMemoryAdapterGetCustomInfo)]) {
        customInfo = [self.delegate onMemoryAdapterGetCustomInfo];
    }
    
    dispatch_async(self.pluginReportQueue, ^{
        MMMemoryRecordInfo *lastInfo = [self recordOfLastRun];
        if (lastInfo == nil) {
            [self.delegate onMemoryIssueNotFound:@"last launch memory data not found"];
            return;
        }
        
        NSData *reportData = [lastInfo generateReportDataWithCustomInfo:customInfo];
        [self deleteOldRecords];
        
        if (reportData == nil) {
            [self.delegate onMemoryIssueNotFound:@"memory report generate failed"];
            return;
        }
        
        MMMemoryIssue *issue = [[MMMemoryIssue alloc] init];
        issue.issueID = [lastInfo recordID];
        issue.issueData = reportData;
        
        MatrixInfo(@"report memory record: %@", issue);
        [self.delegate onMemoryIssueReport:issue];
    });
}

- (void)setVCName:(char *)name{
    if (m_currRecord && name) {
        set_current_vc_name(name);
    }
}

@end
