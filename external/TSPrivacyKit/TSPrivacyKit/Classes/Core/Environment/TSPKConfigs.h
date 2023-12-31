//
//  TSPKConfigs.h
//  Aweme
//
//  Created by admin on 2021/11/13.
//

#import <Foundation/Foundation.h>

@interface TSPKConfigs : NSObject

@property (nonatomic, copy, nullable) NSDictionary *defaultDetectedPlanConfigs;
@property (nonatomic, copy, nullable) NSDictionary *monitorConfig;

+ (nonnull instancetype)sharedConfig;

- (NSArray *__nullable)ruleConfigs;
- (NSDictionary *__nullable)detectorConfigs;
- (NSString *__nullable)settingVersion;
- (BOOL)isRelativeTimeEnable;
- (NSDictionary *__nullable)customAnchorConfigs;
- (NSArray * __nullable)dynamicAspectConfigs;
- (NSArray *__nullable)apiStatisticsConfigs;
- (NSDictionary *__nullable)performanceStatisticsConfigs;
- (NSDictionary *__nullable)crossPlatformConfigs;
- (NSDictionary *__nullable)callFilterConfigs;
- (NSDictionary *__nullable)signalConfigs;
- (NSArray *__nullable)pageStatusConfigs;
- (NSArray*__nullable)cacheConfigs;

- (BOOL)isEnableUploadAPICostTimeStatistics;

- (BOOL)enableMergeCustomAndSystemBacktraces;
- (BOOL)enable;
- (BOOL)enableNetworkInit;
- (BOOL)enableUploadAlog;
- (BOOL)enablePermissionChecker;
- (BOOL)enableViewControllerPreload;
- (BOOL)enableRemoveLastStartBacktrace;
- (BOOL)enableSetupAppLifeCycleObserver;
- (BOOL)enableSetupMediaNotificationObserver;
- (BOOL)enableBizInfoUpload;
- (BOOL)enableReceiveExternalLog;
- (BOOL)enableLocationDelegate;
- (BOOL)enableCalendarRequestCompletion;
- (BOOL)enableUseAppLifeCycleCurrentTopView;
- (BOOL)enableGuardUserInput;
- (NSNumber *_Nullable)isDataTypeEnable:(NSString *__nullable)dataTypes;
- (NSNumber *_Nullable)isPipelineEnable:(NSString *__nullable)pipelineName;
- (NSNumber *_Nullable)isApiEnable:(NSString *__nullable)api;
- (NSNumber *_Nullable)isRuleEngineDataTypeEnable:(NSString *__nullable)dataTypes;
- (NSNumber *_Nullable)isRuleEnginePipelineEnable:(NSString *__nullable)pipelineName;
- (NSNumber *_Nullable)isRuleEngineApiEnable:(NSString *__nullable)api;
- (NSTimeInterval)timeDelayToUploadAlog;
- (NSTimeInterval)timeRangeToUploadAlog;
- (NSInteger)maxUploadCount;
- (NSInteger)maxURLCacheSize;
- (NSArray *__nullable)frequencyConfigs;
- (BOOL)enableUploadStack;
- (BOOL)isEnableUploadStackWithApiId:(NSNumber *_Nullable)apiId;


- (void)updateRuleAndDetectorPartOfMonitorConfig:(nullable NSDictionary *)monitorConfig;

@end
