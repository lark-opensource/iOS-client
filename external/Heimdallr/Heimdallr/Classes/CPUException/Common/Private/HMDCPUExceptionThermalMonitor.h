//
//  HMDCPUExceptionThermalMonitor.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/19.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HMDCPUExceptionTheramlState) {
    HMDCPUExceptionThermalNomal = 0,
    HMDCPUExceptionThermalFair,
    HMDCPUExceptionThermalSerious,
    HMDCPUExceptionThermalCritical
};

NS_ASSUME_NONNULL_BEGIN

@protocol HMDCPUExceptionThermalMonitorDelegate <NSObject>

/// 0: default ; 1: Fair; 2: Serious; 3: Critical
- (void)currentTheramlStateAbormal:(HMDCPUExceptionTheramlState)thermalState;
- (void)currentTheramlStateBecomeNormal:(HMDCPUExceptionTheramlState)thermalState;

@end

@interface HMDCPUExceptionThermalMonitor : NSObject

@property (atomic, assign, readonly) BOOL running;
@property (nonatomic, assign, readonly) BOOL isThermalAbnormal;
@property (nonatomic, assign, readonly) HMDCPUExceptionTheramlState currentThermalState;
@property (nonatomic, weak) id<HMDCPUExceptionThermalMonitorDelegate> delegate;

/// start cpu exception thermal monitor (thread-safe); when the device's temperature is abnormal ,the current montior will call CPUExceptionMonitor to record the APP's thread info , like: thread-back-tree;
- (void)start;

/// stop cpu exception theraml monitor (thread-safe);
- (void)stop;

/// 0: default ; 1: Fair; 2: Serious; 3: Critical
- (void)enterThermalMonitorLevel:(HMDCPUExceptionTheramlState)thermalLevel;

@end

NS_ASSUME_NONNULL_END
