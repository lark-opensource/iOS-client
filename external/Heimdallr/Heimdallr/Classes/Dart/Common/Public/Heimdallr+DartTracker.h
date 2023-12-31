//
//  Heimdallr+DartTracker.h
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/28.
//

#import "Heimdallr.h"

@interface Heimdallr (DartTracker)
/**
 Dart异常埋点接口，异步写入
 
 @param stack 调用栈字符串
 */
+ (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack;

/**
 Dart异常埋点接口，异步写入
 
 @param stack 调用栈字符串
 @param dictionary 用户自定义环境数据
 @param customLog 用户自定义日志
 */
+ (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack customData:(nullable NSDictionary *)dictionary customLog:(nullable NSString *)customLog;

/**
 Dart异常埋点接口，异步写入

 @param stack 调用栈字符串
 @param dictionary 用户自定义环境数据
 @param customLog 用户自定义日志
 @param filters 用户自定义筛选项
*/
+ (void)recordDartErrorWithTraceStack:(nonnull NSString *)stack customData:(nullable NSDictionary *)dictionary customLog:(nullable NSString *)customLog filters:(nullable NSDictionary *)filters;
@end
