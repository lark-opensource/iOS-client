//
//  LKCExceptionContinounslyCrash.m
//  LarkMonitor
//
//  Created by sniperj on 2020/1/2.
//

#import "LKCExceptionContinounslyCrash.h"
#import "LKCExceptionContinounslyCrashConfig.h"
#import <Heimdallr/HMDBootingProtection.h>
#import <Heimdallr/HMDUserExceptionTracker.h>

double LCKEXCContinounsCrashLaunchTimeThreshold = 10.0;
int LCKEXCContinounsCrashCount = 3;

@implementation LKCExceptionContinounslyCrash

+ (instancetype)sharedInstance {
    static LKCExceptionContinounslyCrash *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LKCExceptionContinounslyCrash alloc] init];
    });
    return monitor;
}

-(void)updateConfig:(LKCExceptionContinounslyCrashConfig *)config {
    [super updateConfig:config];
    self.crashCount = config.crashCount;
    self.launchTimeThreshold = config.launchTimeThreshold;
}

- (void)start {
    if (!self.isRunning) {
        [super start];
        __weak LKCExceptionContinounslyCrash *weakSelf = self;
        [HMDBootingProtection startProtectWithLaunchTimeThreshold:self.launchTimeThreshold handleCrashBlock:^(NSInteger successiveCrashCount) {
            if (successiveCrashCount >= weakSelf.crashCount) {
                [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithExceptionType:@"Continouns_crash" title:@"" subTitle:@"" customParams:nil filters:nil callback:^(NSError * _Nullable error) {}];
            }
        }];
    }
}

- (void)end {
    if (self.isRunning) {
        [super end];
    }
}

@end
