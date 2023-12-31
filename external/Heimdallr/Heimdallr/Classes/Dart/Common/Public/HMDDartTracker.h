//
//  HMDDartTracker.h
//  Heimdallr
//
//  Created by joy on 2018/10/24.
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"

extern NSString *const _Nonnull kEnableDartMonitor;

@interface HMDDartTracker: HMDTracker

/**
 Dart异常埋点接口，异步写入

 @param stack 调用栈字符串
*/
- (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack;

/**
 Dart异常埋点接口，异步写入

 @param stack 调用栈字符串
 @param customData 用户自定义环境数据
 @param customLog 用户自定义日志
*/
- (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack customData:(nullable NSDictionary *)customData customLog:(nullable NSString *)customLog;

/**
 Dart异常埋点接口，异步写入

 @param stack 调用栈字符串
 @param customData 用户自定义环境数据
 @param customLog 用户自定义日志
 @param filters 用户自定义筛选项
*/
- (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack customData:(nullable NSDictionary *)customData customLog:(nullable NSString *)customLog filters:(nullable NSDictionary *)filters;

@end
