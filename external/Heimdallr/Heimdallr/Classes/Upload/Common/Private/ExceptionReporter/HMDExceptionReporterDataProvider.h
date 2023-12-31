//
//  HMDExceptionReporterDataProvider.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#ifndef HMDExceptionReporterDataProvider_h
#define HMDExceptionReporterDataProvider_h

@class HMDDebugRealConfig;

typedef enum : NSUInteger {
    HMDDefaultExceptionType = 0,
#if RANGERSAPM
    HMDWatchDogExceptionType,
#endif
    HMDUserExceptionType,
    HMDCPUExceptionType,
    HMDCaptureBacktraceExceptionType,
    HMDMetricKitExceptionType,
    HMDUIFrozenExceptionType,
    HMDFDExceptionType,
    HMDExceptionTypeCount,
} HMDExceptionType;

@protocol HMDExceptionReporterDataProvider<NSObject>
@optional
- (HMDExceptionType)exceptionType;

- (NSArray *)pendingExceptionData;
// 监控模块实现，来返回采集的数据；ANR、OOM 需要实现
- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config;
- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config;
// Response 之后数据清除等工作
- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess;
- (void)dropExceptionData;
// 即使Hermas启动，也会清除数据库的数据
- (void)dropExceptionDataIgnoreHermas;

#if RANGERSAPM
- (NSArray *)exceptionDataForAppID:(NSString *)appID;
#endif

@end

#endif /* HMDExceptionReporterDataProvider_h */
