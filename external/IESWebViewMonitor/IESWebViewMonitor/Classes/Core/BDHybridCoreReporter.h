//
//  BDHybridCoreReporter.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MonitorReporterInstance [BDHybridCoreReporter shareInstance]

typedef void(^BDMonitorReportBlock)(NSString *service,NSDictionary *reportDic);

@interface BDHybridCoreReporter : NSObject

+ (instancetype)shareInstance;

// 注意，如果是要处理的话，此处上报会拦截所有smonitor的上报，service是包含webview、lynx、RN，如果是有需求要分隔service，那么可以根据service去拆容器。
- (void)addGlobalReportBlock:(BDMonitorReportBlock)reportBlock;

// 过滤指定虚拟aid的上报，如果需要过滤当前宿主的某个monitor上报，此处传"default"字符串，servicList传递需要过滤的上报service。
- (void)filterReportWithAid:(NSString *)aid serviceList:(NSArray *)serviceList;
// 过滤当前aid下所有上报
- (void)filterReportWithAid:(NSString *)aid;
// 过滤所有上报
- (void)filterAllReport;

- (void)setHMDReportSwitch:(BOOL)isOn;

// 上报单条
- (void)reportSingleDic:(NSDictionary *)dic forService:(NSString *)service;

@end

NS_ASSUME_NONNULL_END
