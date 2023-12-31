//
//  HMDTTNetTraffic.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/25.
//

#import "HMDNetworkTrafficCollector.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "HMDHTTPDetailRecord.h"
#import "HMDDynamicCall.h"

@interface HMDNetworkTrafficCollector ()<HMDHTTPRequestTrackerRecordDelegate>

@property (atomic, assign, readwrite) BOOL isRunning;

@end

@implementation HMDNetworkTrafficCollector

+ (instancetype)sharedInstance {
    static HMDNetworkTrafficCollector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDNetworkTrafficCollector alloc] init];
    });
    return instance;
}

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

- (void)asyncHMDHTTPRequestTackerDidCollectedRecord:(HMDHTTPDetailRecord *)record {
    if ([record.logType isEqualToString:@"api_error"]) { return; } // api_error 在 wukong_release 是一条重复的记录 这里过滤掉

    NSString *url = [record.absoluteURL copy];
    NSString *clientType = [record.clientType copy]?:@"";
    NSString *mimeType = [record.MIMEType copy]?:@"";
    if (record.requestLog) {
        NSString *requestLog = [record.requestLog copy];
        DC_OB(DC_CL(HMDNetTrafficMonitor, sharedMonitor), networkTrafficUsageWithURL:requestLog:clientType:MIMEType:, url, requestLog, clientType, mimeType);
    } else {
        unsigned long long sendBytes = record.upStreamBytes;
        unsigned long long recvBytes = record.downStreamBytes;
        DC_OB(DC_CL(HMDNetTrafficMonitor, sharedMonitor), networkTrafficUsageWithURL:sendBytes:recvBytes:clientType:MIMEType:, url, sendBytes, recvBytes, clientType, mimeType);
    }
}


@end
