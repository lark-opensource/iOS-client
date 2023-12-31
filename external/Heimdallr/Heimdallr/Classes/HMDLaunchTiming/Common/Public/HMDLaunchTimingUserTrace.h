//
//  HMDLaunchTiming+Trace.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/19.
//

#import "HMDLaunchTiming.h"
#import "HMDLaunchTimingDefine.h"


extern NSString * _Nonnull const kHMDLaunchTimingTraceUserDefaultModule;
extern NSString * _Nonnull const kHMDLaunchTimingTraceUserDefauleModule __attribute__((deprecated("please use kHMDLaunchTimingTraceUserDefaultModule")));

@interface HMDLaunchTimingUserTrace : NSObject

+ (void)startTrace;
+ (void)startTraceUseProcExec;
+ (void)startTraceWithDate:(NSDate * _Nullable)date;


+ (void)endTraceWithLaunchModel:(HMDAPPLaunchModel)launchModel
                   endSceneName:(NSString * _Nullable)sceneName
                    maxDuration:(long long)maxDuration
                        endDate:(NSDate * _Nullable)endDate;
+ (void)endTraceWithLaunchModel:(HMDAPPLaunchModel)launchModel
                   endSceneName:(NSString * _Nullable)sceneName;


+ (void)endTraceWithCustomLaunchModel:(NSString * _Nullable)customLaunchModel
                         endSceneName:(NSString * _Nullable)sceneName
                          maxDuration:(long long)maxDuration
                              endDate:(NSDate * _Nullable)endDate;
+ (void)endTraceWithCustomLaunchModel:(NSString * _Nullable)customLaunchModel
                         endSceneName:(NSString * _Nullable)sceneName;

+ (void)cancelTrace;
+ (long long)getTraceStartTimestamp;


#pragma mark --- span
+ (void)startSpanWithModuleName:(NSString * _Nullable)moduleName
                       taskName:(NSString * _Nullable)taskName
                      startDate:(NSDate * _Nullable)startDate
                   forceRefresh:(BOOL)forceRefresh;
+ (void)startSpanWithModuleName:(NSString * _Nullable)moduleName
                       taskName:(NSString * _Nullable)taskName;
+ (void)startSpanWithTaskName:(NSString * _Nullable)taskName;


+ (void)endSpanWithModuleName:(NSString * _Nullable)moduleName
                     taskName:(NSString * _Nullable)taskName
                      endDate:(NSDate * _Nullable)date;
+ (void)endSpanWithModuleName:(NSString * _Nullable)moduleName
                     taskName:(NSString * _Nullable)taskName;
+ (void)endSpanWithTaskName:(NSString * _Nullable)taskName;

+ (void)recordSpanWithModule:(NSString * _Nullable)moduleName
                        task:(NSString * _Nullable)taskName
                       start:(NSDate * _Nullable)startDate
                         end:(NSDate * _Nullable)endDate;

@end

