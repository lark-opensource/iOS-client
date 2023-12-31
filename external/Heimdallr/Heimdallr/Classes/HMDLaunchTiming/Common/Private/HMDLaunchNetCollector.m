//
//  HMDLaunchNetCollector.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/5.
//

#import "HMDLaunchNetCollector.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "HMDHTTPDetailRecord+Private.h"
#import "HMDSessionTracker.h"
#import "HMDAppLaunchTool.h"

@interface HMDLaunchNetCollector ()<HMDHTTPRequestTrackerRecordDelegate>

@end

@implementation HMDLaunchNetCollector

- (void)dealloc {
    if (self.isRunning) {
        [self unregisterRecordCollector];
    }
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        [self registerRecordCollector];
    }
}

- (void)stop {
    if (self.isRunning) {
        self.isRunning = NO;
        [self unregisterRecordCollector];
    }
}

- (void)registerRecordCollector {
    [[HMDHTTPRequestTracker sharedTracker] addRecordVisitor:self];
}

- (void)unregisterRecordCollector {
    [[HMDHTTPRequestTracker sharedTracker] removeRecordVisitor:self];
}

- (void)asyncHMDHTTPRequestTackerWillCollectedRecord:(HMDHTTPDetailRecord *)record {
    if (self.launchEndTS == 0 || record.startTime < self.launchEndTS) {
        static long long launchTS = 0;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            launchTS = hmdTimeWithProcessExec();
        });
        NSDictionary *traceData = @{@"trace_base": @(launchTS)};
        record.sid = [self getLaunchNetSid];
        [record addCustomExtraValueWithKey:@"relate_start_trace" value:traceData];
    }
}

- (NSInteger)getLaunchNetSid {
    static NSInteger sid = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sid = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    });
    return sid;
}

@end
