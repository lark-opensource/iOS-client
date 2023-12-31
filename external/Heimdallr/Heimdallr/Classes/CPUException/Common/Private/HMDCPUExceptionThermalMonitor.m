//
//  HMDCPUExceptionThermalMonitor.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/19.
//

#import "HMDCPUExceptionThermalMonitor.h"
#import "HMDALogProtocol.h"

@interface HMDCPUExceptionThermalMonitor ()

@property (atomic, assign, readwrite) BOOL running;
@property (nonatomic, assign, readwrite) BOOL isThermalAbnormal;
@property (nonatomic, assign, readwrite) HMDCPUExceptionTheramlState currentThermalState;
@property (nonatomic, assign) HMDCPUExceptionTheramlState abnormalThermalState;

@end

@implementation HMDCPUExceptionThermalMonitor

- (instancetype)init
{
    self = [super init];
    if (self) {
       _abnormalThermalState = HMDCPUExceptionThermalSerious;
    }
    return self;
}

- (void)dealloc {
    if (self.running) {
        [self unRegistThermalNotification];
    }
}

- (void)start {
    if (!self.running) {
        self.running = YES;
        [self registThermalNotification];
    }
}

- (void)stop {
    if (self.running) {
        self.running = NO;
        [self unRegistThermalNotification];
    }
}

- (void)enterThermalMonitorLevel:(HMDCPUExceptionTheramlState)thermalLevel {
    self.abnormalThermalState = thermalLevel;
}

#pragma mark - thermal notification
- (void)registThermalNotification {
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hmdDeviceTheramlStateDidChange:) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    }
}

- (void)unRegistThermalNotification {
    if (@available(iOS 11.0, *)) {
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSProcessInfoThermalStateDidChangeNotification object:nil];
        } @catch (NSException *exception) {
            if (hmd_log_enable()) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr CPUException thermal state remove notification throws exception");
            }
        }
    }
}

- (void)hmdDeviceTheramlStateDidChange:(NSNotification *)notification {
    if (@available(iOS 11.0, *)) {
        NSProcessInfoThermalState thermalState = [NSProcessInfo processInfo].thermalState;
        HMDCPUExceptionTheramlState hmdThermalSate = 0;
        switch (thermalState) {
            case NSProcessInfoThermalStateNominal:
                hmdThermalSate = HMDCPUExceptionThermalNomal;
                break;
            case NSProcessInfoThermalStateFair:
                hmdThermalSate = HMDCPUExceptionThermalFair;
                break;
            case NSProcessInfoThermalStateSerious:
                hmdThermalSate = HMDCPUExceptionThermalSerious;
                break;
            case NSProcessInfoThermalStateCritical:
                hmdThermalSate = HMDCPUExceptionThermalCritical;
            default:
                break;
        }
        self.currentThermalState = hmdThermalSate;
        
        if (!self.isThermalAbnormal && (hmdThermalSate >= self.abnormalThermalState)) {
            self.isThermalAbnormal = YES;
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(currentTheramlStateAbormal:)]) {
                [self.delegate currentTheramlStateAbormal:hmdThermalSate];
            }
            return;
        }

        if (self.isThermalAbnormal && (hmdThermalSate < self.abnormalThermalState)) {
            self.isThermalAbnormal = NO;
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(currentTheramlStateBecomeNormal:)]) {
                [self.delegate currentTheramlStateBecomeNormal:hmdThermalSate];
            }
        }
    }
}

@end
