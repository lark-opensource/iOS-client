//
//	HMDPerformanceReporterManager.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/8/27. 
//

#import <Foundation/Foundation.h>

@class HMDPerformanceReporter, HMDHeimdallrConfig, HMDDebugRealConfig;
@protocol HMDPerformanceReporterDataSource;

NS_ASSUME_NONNULL_BEGIN

typedef void (^PerformanceReporterBlock)(BOOL success);

extern NSString *const HMDPerformanceReportSuccessNotification;

@protocol HMDPerformanceReporterCheckPointProtocol <NSObject>
@optional

- (void)dataReportingCheckPointWithReporter:(NSString *)reporter;
- (void)dataReportSuccessedCheckPointWithReporter:(NSString *)reporter;
- (void)dataReportFailedCheckPointWithReporter:(NSString *)reporter error:(NSError *)error response:(NSDictionary *)response;

@end


/// 性能上报的类型
typedef NS_ENUM(NSUInteger, HMDPerformanceReporterType) {
    HMDPerformanceReporterNormal = 0,       // 只上报指定的appID的组件数据
    HMDPerformanceReporterSizeLimited,
    HMDPerformanceReporterImmediatelyData,
    HMDPerformanceReporterTimer,            // 计时器触发上报
    HMDPerformanceReporterInitialize,       // 初始化reporter触发上报
    HMDPerformanceReporterBackground,       // 进入后台上报
    HMDPerformanceReporterOpenTrace,        // 只OpenTrace数据上报使用
};


@interface HMDPerformanceReporterManager : NSObject

#if !RANGERSAPM
@property (atomic, assign, readonly) BOOL isUploading;
#else
@property (atomic, assign, readonly) NSInteger isUploading;
#endif
@property (nonatomic, assign) BOOL needEncrypt;
@property (nonatomic, assign) NSUInteger maxRetryTimes;
@property (nonatomic, assign) NSUInteger reportFailBaseInterval;

+ (instancetype)sharedInstance;
- (instancetype)init __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));
+ (instancetype)new __attribute__((unavailable("Use +sharedInstance to retrieve the shared instance.")));

/**
 初始化指定appID的上报类，内部维护全局映射表，每次生命周期每个appid仅有唯一的一个实例负责上报

 @param reporter 上报实例
 @param appID appID或sdk的aid
*/
- (void)addReporter:(HMDPerformanceReporter *)reporter withAppID:(NSString *)appID;

/**
 上报性能数据，根据appID指定上报某个组件或APP的数据

 @param appID appID或sdk的aid
 @param block 完成回调
 */
- (void)reportPerformanceDataAsyncWithAppID:(NSString *)appID
                                      block:(PerformanceReporterBlock _Nullable)block;

/**
 上报,在内存缓存中 需要立即上报的数据，根据appID指定上报某个组件或APP的数据

 @param appID appID或sdk的aid
 @param block 完成回调
 */
-(void)reportImmediatelyPerformanceCacheDataWithAppID:(NSString *)appID
                                                block:(PerformanceReporterBlock)block;

/**
 初始化reporter后触发的上报，需要与其他reporter的数据合并上报，总数据量<50条则不上报
 
 @param appID appID或sdk的aid
 @param block 完成回调
 */
- (void)reportPerformanceDataAfterInitializeWithAppID:(NSString *)appID
                                                block:(PerformanceReporterBlock _Nullable)block;

/**
 只使用上报功能，手动调用才会上报，无需将reporter添加至manager管理

 @param reporter reporter实例
 @param block 完成回调
*/
- (void)reportDataWithReporter:(HMDPerformanceReporter *)reporter
                         block:(PerformanceReporterBlock _Nullable)block;

/**
 ⚠️只OpenTrace模块上报使用

 @param reporter reporter实例
 @param block 完成回调
*/
- (void)reportOTDataWithReporter:(HMDPerformanceReporter *)reporter
                           block:(PerformanceReporterBlock _Nullable)block;

/**
 上报debugreal的性能数据，只宿主App使用

 @param config 每一次的回捞指定对应的数据模型
 */
- (void)reportDebugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config;
- (NSArray *)allDebugRealPeformanceDataWithConfig:(HMDDebugRealConfig *)config;

/**
 指定配置清理各模块缓存，只宿主App使用

 @param config 指定的配置
 */
- (void)cleanupWithConfig:(HMDDebugRealConfig *)config;

/**
 增加上报模块

 @param module 实现了HMDPerformanceReporterDataSource协议就可以被注册到上报模块中
 @param appID 宿主App或组件的aid
 */
- (void)addReportModule:(id<HMDPerformanceReporterDataSource>)module withAppID:(NSString *)appID;
- (void)removeReportModule:(id<HMDPerformanceReporterDataSource>)module withAppID:(NSString *)appID;

- (void)updateConfig:(HMDHeimdallrConfig *)config withAppID:(NSString *)appID;
- (void)updateRecordCount:(NSInteger)count withAppID:(NSString *)appID;

- (void)triggerAllReporterUpload;

@end

NS_ASSUME_NONNULL_END
