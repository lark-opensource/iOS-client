//
//  HMDAppExitReasonDetector.h
//  Heimdallr-a8835012
//
//  Created by zhouyang11 on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import "HMDAPPExitReasonDetectorProtocol.h"

@interface HMDAppExitReasonDetector : NSObject

@property(class, assign) NSTimeInterval systemStateUpdateInterval;

// To monitor the exit before Heimdall starts, it needs to be called manually
+ (void)setAppExitFlagBefroHeimdallr;

+ (void)registerDelegate:(id<HMDAPPExitReasonDetectorProtocol> _Nonnull)delegate;

+ (void)deregisterDelegate:(id<HMDAPPExitReasonDetectorProtocol> _Nonnull)delegate;

+ (void)updateTimeInterval:(NSTimeInterval)timeInterval;

+ (void)uploadMemoryInfo;

// 业务方可以调用该方法立即记录当前状态,该方法异步执行(不会承担IO读写重担, 如果HMDOOMCrashDetector在开启状态的话)
+ (void)triggerCurrentEnvironmentInformationSaving;

+ (void)triggerCurrentEnvironmentInformationSavingWithAction:(NSString* _Nullable)action;

+ (BOOL)findOrCreateDirectoryInPath:(NSString * _Nullable)path;

+ (NSString * _Nonnull const)logFileDictionary;

@end
