//
//  HMDReportSizeLimitManager.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2019/12/17.
//

#import "HMDReportSizeLimitManager.h"
#import "HMDCustomReportManager.h"
#import "HMDReportSizeLimitManager+Private.h"
#include "pthread_extended.h"

static BOOL hasStartOnce = NO;

@interface HMDReportSizeLimitManager ()

@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, assign, readwrite) NSUInteger thresholdSize; // byte
@property (nonatomic, strong, readwrite) NSMutableSet *tools;
@property (nonatomic, assign) long long currentDataSize;

@end

@implementation HMDReportSizeLimitManager

+ (instancetype)defaultControlManager {
    static HMDReportSizeLimitManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDReportSizeLimitManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentDataSize = 0;
        self.tools = [NSMutableSet set];
        self.thresholdSize = 20000;
        self.uploadIntervalSec = 5; // 默认 5s;
        hasStartOnce = NO;
    }
    return self;
}

- (void)start {
    HMDCustomReportConfig *config = [[HMDCustomReportConfig alloc] initConfigWithMode:HMDCustomReportModeSizeLimit];
    config.thresholdSize = self.thresholdSize;
    [[HMDCustomReportManager defaultManager] startWithConfig:config];
    hasStartOnce = YES;
}

- (void)stop {
    [[HMDCustomReportManager defaultManager] stopWithCustomMode:HMDCustomReportModeSizeLimit];
}

- (void)dataSizeThreshold:(NSUInteger)thresholdSize {
    if (hasStartOnce) {
        HMDCustomReportConfig *config = [[HMDCustomReportConfig alloc] initConfigWithMode:HMDCustomReportModeSizeLimit];
        config.thresholdSize = thresholdSize;
        [[HMDCustomReportManager defaultManager] startWithConfig:config];
    } else {
        [self setDataSizeThreshold:thresholdSize];
    }
}

@end
