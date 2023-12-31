//
//  HMDMemoryChecker.m
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/23.
//

#import "HMDMemoryChecker.h"
#import "HMDMemoryUsage.h"
#import "HMDGCD.h"

NSString * const kHMDMemoryWillPeakNotification = @"kHMDMemoryWillPeakNotification";
NSString * const kHMDMemoryHasPeakedNotification = @"kHMDMemoryHasPeakedNotification";
NSString * const kHMDMemorySurgeStr = @"isMemorySurge";
@interface  HMDMemoryChecker()

@property (nonatomic, strong) dispatch_queue_t checkerQueue;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) HMDMemoryCheckerBuilder builder;
@property (nonatomic, assign) uint64_t actualThreshold;
@property (nonatomic, assign) NSTimeInterval notifyTimestamp;
/// timer上一次触发时的内存用量，初始为0
@property (nonatomic, assign) uint64_t lastMemoryUsage;

@end

@implementation HMDMemoryChecker

- (instancetype)init {
    if (self = [super init]) {
        _checkerQueue = dispatch_queue_create("com.heimdallr.checker", DISPATCH_QUEUE_SERIAL);
        _lastMemoryUsage = 0;
    }
    
    return self;
}

- (void)activateByBuilder:(HMDMemoryCheckerBuilder)builder {
    hmd_safe_dispatch_async(self.checkerQueue, ^{
        self.builder = builder;
        self.actualThreshold = builder.dangerThreshold;
        
        if (!self.timer) {
            self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.checkerQueue);
            if (!self.timer) return;
            
            dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, builder.checkInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
            __weak typeof(self) wself = self;
            dispatch_source_set_event_handler(self.timer, ^{
                __strong typeof(wself) sself = wself;
                [sself checkMemoryUsagePeriodly];
            });
            dispatch_resume(self.timer);
        } else {
            dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, builder.checkInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        }
    });
}

- (void)invalidate {
    dispatch_async(self.checkerQueue, ^{
        if (self.timer) {
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        }
    });
}

- (void)checkMemoryUsagePeriodly {
    hmd_MemoryBytes memoryBytes;
    if (self.builder.calculateSlardarMallocMemory) {
        memoryBytes = hmd_getMemoryBytesWithSlardarMallocMemory();
    }else {
        memoryBytes = hmd_getMemoryBytes();
    }

    uint64_t appMemoryUsage = memoryBytes.appMemory;
    
    // exceed 80% of actualThreshold once only trigger one warning
    if (self.builder.manualMemoryWarning && self.lastMemoryUsage <= self.actualThreshold * 0.8 && appMemoryUsage > self.actualThreshold * 0.8) {
        NSData *data = [NSData dataWithBytes:&memoryBytes length:sizeof(memoryBytes)];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDMemoryWillPeakNotification object:data];
    }
    
    BOOL isMemorySurge = NO;
    if (self.builder.memorySurgeThresholdMB > 0 && self.lastMemoryUsage != 0 && appMemoryUsage - self.lastMemoryUsage > self.builder.memorySurgeThresholdMB*(1024*1024)) {
        isMemorySurge = YES;
    }
    self.lastMemoryUsage = appMemoryUsage;
    
    // send peak
    if (appMemoryUsage > self.actualThreshold && [[NSDate date] timeIntervalSince1970] > self.notifyTimestamp + self.builder.minNotifyInterval) {
        self.actualThreshold += self.builder.growingStep;
        self.notifyTimestamp = [[NSDate date] timeIntervalSince1970];
        NSData *data = [NSData dataWithBytes:&memoryBytes length:sizeof(memoryBytes)];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDMemoryHasPeakedNotification object:data userInfo:@{kHMDMemorySurgeStr:@(isMemorySurge)}];
    }
}

@end
