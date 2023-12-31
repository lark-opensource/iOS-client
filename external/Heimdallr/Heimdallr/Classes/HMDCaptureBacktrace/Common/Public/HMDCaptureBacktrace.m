//
//  HMDCaptureBacktrace.m
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/21.
//

#import "HMDCaptureBacktrace.h"
#import "HMDCaptureBacktraceManager.h"
#import "HMDGCD.h"
#import "HMDExceptionReporter.h"
#import "HMDThreadBacktrace.h"

#import "HMDHermasHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDCaptureBacktrace() <HMDExceptionReporterDataProvider>

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger maxCaptureTime;
@property (nonatomic, assign) NSInteger maxErrorTime;
@property (nonatomic, strong) dispatch_queue_t exceptionMonitorQueue;
@property (nonatomic, strong) HMDCaptureBacktraceManager *recordManager; // only access on exceptionMonitorQueue
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) BOOL isStop;
@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDCaptureBacktrace

- (instancetype)initCaptureWithType:(NSString *)type maxCaptureTime:(NSInteger)time {
    return [self initCaptureWithType:type maxCaptureTime:time maxErrorTime:0];
}

- (instancetype)initCaptureWithType:(NSString *)type maxCaptureTime:(NSInteger)time maxErrorTime:(NSInteger)errorTime
{
    if (time <= 0) return nil;
    self = [super init];
    if (self) {
        _type = type;
        _maxCaptureTime = time;
        _maxErrorTime = errorTime;
    }
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (void)startCapture {
    [[HMDExceptionReporter sharedInstance] addReportModule:self];
    hmd_safe_dispatch_async(self.exceptionMonitorQueue, ^{
        if (!self.isStart) {
            self.isStart = YES;
            hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(fireSample:)];
                [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:self.maxCaptureTime]];
                
            });
            hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.maxCaptureTime * NSEC_PER_SEC)), self.exceptionMonitorQueue, ^{
                [self stopCapture:NO];
            });
        }
    });
}

- (void)stopCapture:(BOOL)uploadData {
    hmd_safe_dispatch_async(self.exceptionMonitorQueue, ^{
        if (!self.isStop) {
            self.isStop = YES;
            __weak typeof(self) weakSelf = self;
            [self.recordManager finishRecord:uploadData withReportBlock:^{
                [weakSelf shouldReportCaptureBacktraceNow];
            }];
        }
    });
}

- (void)fireSample:(CADisplayLink *)link
{
    hmd_safe_dispatch_async(self.exceptionMonitorQueue, ^{
        HMDThreadBacktrace *backtrack = [HMDThreadBacktrace backtraceOfMainThreadWithSymbolicate:YES skippedDepth:0 suspend:YES];
        [self.recordManager addBacktrace:backtrack];
    });
}

#pragma mark --- exception report ---

- (HMDExceptionType)exceptionType {
    return HMDCaptureBacktraceExceptionType;
}

- (void)shouldReportCaptureBacktraceNow {
    if (hermas_enabled()) {
        if (hermas_drop_data(kModuleExceptionName)) return;
        hmd_safe_dispatch_async(self.exceptionMonitorQueue, ^{
            NSDictionary *dic = [self.recordManager CaptureBacktracesReportData].firstObject;
            if (!dic) return;
            
            BOOL recordImmediately = [HMDHermasHelper recordImmediately];
            HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
            [self.instance recordData:dic priority:priority];
        });
    } else {
        if(hmd_drop_data(HMDReporterException)) return;
        [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDCaptureBacktraceExceptionType)]];
    }
}

- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }
    
    __block NSArray *dataArray = nil;
    dispatch_sync(self.exceptionMonitorQueue, ^{
        dataArray = [self.recordManager CaptureBacktracesReportData];
    });
    return dataArray;
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
}

-(void)dropExceptionData {
}

#pragma mark --- get method ---

- (dispatch_queue_t)exceptionMonitorQueue
{
    if (!_exceptionMonitorQueue) {
        NSString *label = [NSString stringWithFormat:@"com.heimdallr.LaunchAnalyse.monitor.%@", self.type];
        _exceptionMonitorQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
    }
    return _exceptionMonitorQueue;
}

- (HMDCaptureBacktraceManager *)recordManager
{
    if (!_recordManager) {
        _recordManager = [[HMDCaptureBacktraceManager alloc] init];
        _recordManager.backtraceThreshold = self.maxCaptureTime * 60;
#if DEBUG
        _recordManager.errorTime = 10000;
#else
        _recordManager.errorTime = self.maxErrorTime;
#endif
        
        _recordManager.sceneType = self.type;
    }
    return _recordManager;
}

@end
