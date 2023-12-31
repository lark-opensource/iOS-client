//
//  HMDOOMCrashInfo.h
//  Pods
//
//  Created by yuanzhangjing on 2020/3/1.
//

#import <Foundation/Foundation.h>
#import "HMDAppStateMemoryInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDOOMAppState;

@interface HMDOOMCrashInfo : NSObject

- (nullable instancetype)initWithAppState:(nullable HMDOOMAppState *)appState
                       extraDict:(nullable NSDictionary *)extraDict;

@property (nonatomic, assign) dispatch_source_memorypressure_flags_t memoryPressure;
@property (nonatomic, assign) NSTimeInterval memoryPressureTimestamp;

@property (nonatomic, assign) NSTimeInterval enterForegoundTime;
@property (nonatomic, assign) NSTimeInterval enterBackgoundTime;
@property (nonatomic, assign) NSTimeInterval latestTime;

@property (nonatomic, copy, nullable) NSString *internalSessionID;
@property (nonatomic, assign) NSTimeInterval appStartTime;
@property (nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *buildVersion;
@property (nonatomic, copy, nullable) NSString *sysVersion;

@property (nonatomic, assign) HMDOOMAppStateMemoryInfo memoryInfo;

@property (nonatomic, assign) double updateTime;
@property (nonatomic, copy) NSString *lastScene;
@property (nonatomic, copy) NSDictionary *operationTrace;
@property (nonatomic, assign) double freeDisk;
@property (nonatomic, assign) NSInteger freeDiskBlockSize;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, assign) unsigned long exception_main_address;

@property (nonatomic, copy) NSString *loginfo DEPRECATED_MSG_ATTRIBUTE("Please do not use this property");
@property (nonatomic, assign) BOOL isSlardarMallocInuse;
@property (nonatomic, assign) size_t slardarMallocUsageSize;
@property (nonatomic, assign) BOOL isMemoryDumpInterrupt;

@property (nonatomic, copy, nullable) NSString *detailInfo;

@property (nonatomic, assign) int appContinuousQuitTimes;

@property (nonatomic, copy, nullable) NSString *thermalState;

@property (nonatomic, assign) BOOL isCPUException;

@property (nonatomic, assign) CFTimeInterval inAppTime;

@property (nonatomic, assign) CFTimeInterval inLastSceneTime;

@property (nonatomic, assign) CFTimeInterval restartInterval;

@property (nonatomic, copy) NSString* binaryInfo; // only availiable for OOM

@property (nonatomic, assign) BOOL isAppEnterBackground;

@end

NS_ASSUME_NONNULL_END
