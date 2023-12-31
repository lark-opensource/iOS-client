//
//  HMDCPUTimeDetector.m
//  Pods
//
//  Created by bytedance on 2022/12/30.
//

#import "HMDCPUTimeDetector.h"
#import <list>
#import "HMDCPUMonitor.h"

const static int kHMDCPUExceptionCycleLength = 60;
const static int kHMDCPUExceptionThreshold = 48;
const static int kHMDCPUExceptionSampleInterval = 10;

// 通知
NSString *const HMDCPUExceptionHappenNotification = @"HMDCPUExceptionHappenNotification";
NSString *const HMDCPUExceptionRecoverNotification = @"HMDCPUExceptionRecoverNotification";

typedef NS_ENUM(NSUInteger, HMDCPUExceptioNotification) {
    HMDCPUExceptioNotificationHappen,
    HMDCPUExceptioNotificationRecover
};

@interface HMDCPUTimeDetector ()  {
    std::list<double> *_cpuTimeList;
}

@property (nonatomic, strong) dispatch_queue_t cpuSampleQueue;
@property (nonatomic, strong) dispatch_source_t sampleTimer;
@property (nonatomic, assign) BOOL isCPUException;


@end

@implementation HMDCPUTimeDetector

+ (instancetype)sharedDetector {
    static HMDCPUTimeDetector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDCPUTimeDetector alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cpuSampleQueue = dispatch_queue_create("com.heimdallr.cpuexitdetector.monitor", DISPATCH_QUEUE_SERIAL);
        _cpuTimeList = new std::list<double>;
    }
    return self;
}

- (void)start {
    if (self.sampleTimer) {
        dispatch_source_cancel(self.sampleTimer);
        self.sampleTimer = nil;
    }
    // timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.cpuSampleQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, kHMDCPUExceptionSampleInterval * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        [self sampleCPUTime];
    });
    dispatch_resume(timer);
    self.sampleTimer = timer;
}

- (void)stop {
    if (self.sampleTimer) {
        dispatch_source_cancel(self.sampleTimer);
        self.sampleTimer = nil;
    }
    if(_cpuTimeList) {
        delete _cpuTimeList;
        _cpuTimeList = NULL;
    }
    self.isCPUException = false;
}

- (void)sampleCPUTime {
    double cpuTime = ((double)clock())/(CLOCKS_PER_SEC * 1.0);
    if(_cpuTimeList) {
        _cpuTimeList->push_back(cpuTime);
        if(_cpuTimeList->size() == kHMDCPUExceptionCycleLength / kHMDCPUExceptionSampleInterval + 1) {
            double cpuTimeLastCycle = _cpuTimeList->front();
            if(!self.isCPUException && cpuTime - cpuTimeLastCycle > kHMDCPUExceptionThreshold) {
                [self notifyCPUException:HMDCPUExceptioNotificationHappen];
            } else if(self.isCPUException && cpuTime - cpuTimeLastCycle <= kHMDCPUExceptionThreshold) {
                [self notifyCPUException:HMDCPUExceptioNotificationRecover];
            }
            _cpuTimeList->pop_front();
        }
    }
}

#pragma mark --- cpuexception natification ---
- (void)notifyCPUException:(HMDCPUExceptioNotification)type {
    NSString *notificationName = nil;
    if(type == HMDCPUExceptioNotificationHappen && !self.isCPUException) {
        self.isCPUException = true;
        notificationName = HMDCPUExceptionHappenNotification;
    } else if(type == HMDCPUExceptioNotificationRecover && self.isCPUException) {
        self.isCPUException = false;
        notificationName = HMDCPUExceptionRecoverNotification;
    }
    
    if(notificationName) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:nil
                                                          userInfo:nil];
    }
}

@end


