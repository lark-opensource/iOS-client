//
//  HMDReportManager.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/25.
//
#import <Foundation/Foundation.h>
#import "HMDCustomReportConfig.h"

@interface HMDCustomReportManager : NSObject

@property (atomic, strong, readonly, nullable) HMDCustomReportConfig *currentConfig;

+ (nonnull instancetype)defaultManager;

/// 开启自定义上报
/// @param config 自定义上报配置，配置中包括上报模式，上报间隔，上报量限制等，具体参考HMDCustomReportConfig类
- (void)startWithConfig:(HMDCustomReportConfig * _Nullable)config;

/// 停止自定义上报模式
/// 恢复缓存中优先级最高的自定义上报模式，如果没有缓存自定义上报模式，则恢复常规上报
/// @param mode 需停止的自定义模式
- (void)stopWithCustomMode:(HMDCustomReportMode)mode;

/// 开启常规上报，并清空所有自定义上报缓存
- (void)startNormalUpload;

/// 主动触发上报，仅在HMDCustomReportModeActivelyTrigger模式下生效，受限于自定义上报配置中的uploadInterval
- (void)triggerReport;

/// 获取slardar平台配置的性能上报interval
- (NSInteger) getReportIntervalOfSetting;

@end
