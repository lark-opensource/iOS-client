//
//  HMDCrashConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//
#if !SIMPLIFYEXTENSION
#import "HMDTrackerConfig.h"
#endif

@class HMDCommonAPISetting;
extern NSString *const kHMDModuleCrashTracker;//Crash监控

#if SIMPLIFYEXTENSION
@interface HMDCrashConfig : NSObject
#else
@interface HMDCrashConfig : HMDTrackerConfig
#endif

@property (nonatomic, assign) double launchThreshold;
@property (nonatomic, assign) BOOL useBackgroundSession;
@property (nonatomic, assign) BOOL useCompactUnwind;
#if !SIMPLIFYEXTENSION
@property (nonatomic, strong, nullable) HMDCommonAPISetting *crashUploadSetting;
@property (nonatomic, strong, nullable) HMDCommonAPISetting *allAPISetting;
#endif
@property (nonatomic, assign) BOOL enableAsyncStackTrace;
@property (nonatomic, assign) BOOL enableMultipleAsyncStackTrace;
@property (nonatomic, assign) BOOL enableRegisterAnalysis;
@property (nonatomic, assign) BOOL enableStackAnalysis;
@property (nonatomic, assign) BOOL enableVMMap;
@property (nonatomic, assign) int maxVmmapCount;
@property (nonatomic, assign) BOOL enableCPPBacktrace;
@property (nonatomic, assign) BOOL enableContentAnalysis;
@property (nonatomic, assign) BOOL enableExtensionDetect;
@property (nonatomic, assign) BOOL enableIgnoreExitByUser;
@property (nonatomic, assign) BOOL writeImageOnCrash;  //default NO
//default NO；如果设置为YES，那么当在子线程操作UI时候，会发生崩溃
@property (nonatomic, assign) BOOL setAssertMainThreadTransactions;
@property (nonatomic, assign) BOOL extendFD;
@property (nonatomic, assign) NSUInteger maxStackTraceCount;

- (NSDictionary * _Nullable)configDictionary;
@end

