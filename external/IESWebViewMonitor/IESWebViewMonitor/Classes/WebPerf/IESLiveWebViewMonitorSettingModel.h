//
//  IESLiveWebViewMonitorSettingModel.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveWebViewMonitorSettingModel : NSObject

/** fps, cpu, mem 等上报配置
 @{
    @"FPSMonitor": @{
        @"interval": 10000 // 间隔上报周期，单位ms
    },
    @"MemoryMonitor": @{
        @"interval": 10000 // 间隔上报周期，单位ms
    },
 }
 */

@property (nonatomic, copy, readonly) NSDictionary *apmReportConfig;

/** navigation timing 等信息*/
@property (nonatomic, copy, readonly) NSDictionary *performanceReportConfig;

/** js error， resource error 等信息配置*/
@property (nonatomic, copy, readonly) NSDictionary *errorMsgReportConfig;

/** resourceTiming 等信息配置*/
@property (nonatomic, copy, readonly) NSDictionary *resourceTimingReportConfig;

/** 通用配置*/
@property (nonatomic, copy, readonly) NSDictionary *commonSettings;

/** 上报黑名单*/
@property (nonatomic, copy, readonly) NSArray *blockList;

@property (nonatomic, copy) NSString *bid;

@property (nonatomic, copy) NSString *pid;

+ (IESLiveWebViewMonitorSettingModel*)settingModelForWebView:(Class)webViewCls;

+ (NSDictionary *)settingMapForWebView:(Class)webViewCls;

+ (void)setConfig:(NSDictionary *)config forClasses:(NSSet<Class>*)classes;

// 根据指定的webview的类判断
+ (BOOL)switchStatusForKey:(NSString *)key webViewClass:(Class)webViewCls;

+ (NSSet *)filterStartedClass:(NSSet<Class>*)classes;

- (NSString *)jsonDescription;

@end

NS_ASSUME_NONNULL_END
