//
//  EMANetworkMonitor.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 用于监控小程序引擎及小程序的网络请求成功率和耗时
 */
@interface EMANetworkMonitor : NSObject <NSURLSessionTaskDelegate>

+ (instancetype)shared;

+ (NSDictionary *)getRustMetricsForTask:(NSURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
