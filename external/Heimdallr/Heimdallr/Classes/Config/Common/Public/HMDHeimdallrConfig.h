//
//  HMDHeimdallrConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"
#import "HMDCleanupConfig.h"

@class HMDGeneralAPISettings;
@class HMDCustomEventSetting;
@class HMDCloudCommandConfig;



extern NSString *_Nonnull const kEnablePerformanceMonitor;

@interface HMDHeimdallrConfig : NSObject

//general settings include cleanup and api settings
@property (nonatomic, strong, readonly, nullable) HMDCleanupConfig *cleanupConfig;
@property (nonatomic, strong, readonly, nullable) HMDGeneralAPISettings *apiSettings;
@property (nonatomic, strong, nullable) NSDictionary *commonInfo;
//custom_event_settings
@property (nonatomic, strong, nullable) HMDCustomEventSetting *customEventSetting;

//modules
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *,HMDModuleConfig *> *activeModulesMap;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, HMDModuleConfig *> *allModulesMap;

@property (nonatomic, assign, readonly) BOOL needHookTTMonitor; //接管TTMonitor开关
@property (nonatomic, assign, readonly) BOOL enableEventTrace;

@property (nonatomic, assign) BOOL configurationAvailable;
@property (nonatomic, assign) BOOL enableNetQualityReport;

- (nullable instancetype)initWithDictionary:(NSDictionary * _Nullable)data;
- (nullable instancetype)initWithJSONData:(NSData *_Nonnull)jsonData;

- (BOOL)logTypeEnabled:(NSString *_Nonnull)logtype;
- (BOOL)metricTypeEnabled:(NSString *_Nonnull)metricType;
- (BOOL)serviceTypeEnabled:(NSString *_Nonnull)serviceType;
- (BOOL)logTypeHighPriorityEnable:(NSString *_Nonnull)logType;
- (BOOL)serviceHighPriorityEnable:(NSString *_Nonnull)serviceType;

@end


