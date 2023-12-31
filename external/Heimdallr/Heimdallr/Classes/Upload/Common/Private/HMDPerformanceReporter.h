//
//  HMDPerformanceReporter.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/29.
//

#import <Foundation/Foundation.h>
#import "HMDNetworkProvider.h"

@class HMDDebugRealConfig;
@class HMDHeimdallrConfig;
@class HMDPerformanceReportDataInfo;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDReporterPriority) {
    HMDReporterPriorityDefault = 0,
    HMDReporterPriorityControllerTimeManager,
    HMDReporterPriorityUITrackerManager,
    HMDReporterPriorityBatteryMonitor,
    HMDReporterPrioritySmartNetTrafficMonitor,
    HMDReporterPriorityNetTrafficMonitor,
    HMDReporterPriorityGPUMonitor,
    HMDReporterPriorityCPUMonitor,
    HMDReporterPriorityMemoryMonitor,
    HMDReporterPriorityFPSMonitor,
    HMDReporterPriorityTTMonitorTracker,
    HMDReporterPriorityDiskMonitor,
    HMDReporterPriorityFrameDropMonitor,
    HMDReporterPriorityStartDetector,
    HMDReporterPriorityHTTPRequestTracker,
};

@protocol HMDPerformanceReporterDataSource <NSObject>
@required

#if RANGERSAPM
@property (nonatomic, assign, readwrite)BOOL dropData;  // 判断是否允许接受新数据
#endif

/// 服务端下发容灾策略，清除本地和内存中的所有数据
- (void)dropAllDataForServerState;

@optional

// 监控模块实现，来返回采集的数据；Memory,CPU,FPS等模块需要实现格式示范:
//{
//    "sessionID":5E4FCBD9-87AF-4689-BE6F-2958257041AC,//用户一次使用周期的标示
//    "timestamp": 1519816183351,//事件的时间戳
//    "inapp_time":61.05,//标示用户打开app多久
//    "service": "cpu",//性能指标类别
//    "log_type": "performance_monitor",//大类
//    "extra_values": {//数值，可运算分析
//        "app_usage":0.80
//        "total_usage":0.90
//        "user_usage":0.50,
//        "idle":0.30
//    },
//    "extra_status": {//状态 可枚举
//    }
//}
- (NSUInteger)reporterPriority;
- (NSUInteger)properLimitCount;
- (NSArray * _Nullable)performanceDataWithCountLimit:(NSInteger)limitCount;
- (NSArray *)metricCountPerformanceData;
- (NSArray *)metricTimerPerformanceData;
- (NSArray * _Nullable)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config;
- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config;
- (void)performanceDataDidReportSuccess:(BOOL)isSuccess;
- (NSArray *)performanceSDKDataWitLimitCount:(NSInteger)limitCount sdkAid:(NSString *)sdkAid;
- (NSArray * _Nullable)performanceCacheDataImmediatelyUpload;
- (NSArray * _Nullable)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize;
- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess;
- (CGFloat)properLimitSizeWeight;
- (void)saveEventDataToDiskWhenEnterBackground;
//用于SDK事件监控
- (void)dropAllDataForServerStateWithAid:(NSString *)aid;

@end

@interface HMDPerformanceReporter : NSObject
@property (nonatomic, assign) NSInteger reportMaxLogCount;
@property (nonatomic, assign) NSTimeInterval reportPollingInterval;
@property (nonatomic, assign) NSTimeInterval enableTimeStamp;

@property (nonatomic, strong, readonly) id<HMDNetworkProvider> provider;
@property (nonatomic, readonly, strong) NSArray *allReportingModules;/**所有上报模块**/
/// sdk performance 上报的 sdk's appId
@property (nonatomic, copy) NSString *sdkAid;
/// 是否只上报 sdk 的信息
@property (nonatomic, assign) BOOL isSDKReporter;

- (instancetype)initWithProvider:(id<HMDNetworkProvider>)provider;
- (void)updateConfig:(HMDHeimdallrConfig *)config;
- (BOOL)ifNeedReportAfterUpdatingRecordCount:(NSInteger)count;
- (void)clearRecordCountAfterReportingSuccessfully;

- (void)updateEnableTimeStampAfterReporting;

- (void)addReportModuleSafe:(id<HMDPerformanceReporterDataSource>)module;
- (void)removeReportModuleSafe:(id<HMDPerformanceReporterDataSource>)module;

- (void)cleanupWithConfigUnsafe:(HMDDebugRealConfig *)config;

@end

NS_ASSUME_NONNULL_END
