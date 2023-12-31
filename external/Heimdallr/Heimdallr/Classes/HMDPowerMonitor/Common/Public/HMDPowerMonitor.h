//
//  BDPowerLogManager.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/25.
//

#import "HMDMonitor.h"
#import "HMDPowerMonitorConfig.h"
#import "HMDPowerMonitorSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDPowerMonitor : HMDMonitor

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

//event

+ (void)beginEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

+ (void)endEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

+ (void)addEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

//session

+ (HMDPowerMonitorSession *)beginSession:(NSString *)name;

+ (HMDPowerMonitorSession *)beginSession:(NSString *)name config:(HMDPowerMonitorSessionConfig *)config;

+ (void)endSession:(HMDPowerMonitorSession *)session;

+ (void)dropSession:(HMDPowerMonitorSession *)session;

@end

NS_ASSUME_NONNULL_END
