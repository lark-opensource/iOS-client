//
//  HMDOOMCrashDetector.h
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"
#import "HMDOOMCrashConfig.h"
#import "HMDOOMCrashDetectorDelegate.h"

@interface HMDOOMCrashDetector : NSObject

@property(class, assign) NSTimeInterval systemStateUpdateInterval;

+ (void)startWithDelegate:(id<HMDOOMCrashDetectorDelegate> _Nullable)delegate DEPRECATED_MSG_ATTRIBUTE("invalid");

+ (void)stop DEPRECATED_MSG_ATTRIBUTE("invalid");

+ (void)updateConfig:(HMDOOMCrashConfig * _Nullable)config DEPRECATED_MSG_ATTRIBUTE("invalid");

// 业务方可以调用该方法立即记录当前状态,该方法异步执行(不会承担IO读写重担, 如果HMDOOMCrashDetector在开启状态的话)
+ (void)triggerCurrentEnvironmentInfomationSaving DEPRECATED_MSG_ATTRIBUTE("use triggerCurrentEnvironmentInformationSaving instead");
+ (void)triggerCurrentEnvironmentInfomationSavingWithAction:(NSString*  _Nullable)action DEPRECATED_MSG_ATTRIBUTE("use triggerCurrentEnvironmentInformationSavingWithAction instead");
+ (void)triggerCurrentEnvironmentInformationSaving DEPRECATED_MSG_ATTRIBUTE("use HMDAPPExitReasonDetector instead");
+ (void)triggerCurrentEnvironmentInformationSavingWithAction:(NSString* _Nullable)action DEPRECATED_MSG_ATTRIBUTE("use HMDAPPExitReasonDetector instead");

+ (BOOL)findOrCreateDirectoryInPath:(NSString * _Nullable)path DEPRECATED_MSG_ATTRIBUTE("use HMDAPPExitReasonDetector instead");
+ (NSString *const _Nullable)logFileDictionary DEPRECATED_MSG_ATTRIBUTE("use HMDAPPExitReasonDetector instead");

@end
