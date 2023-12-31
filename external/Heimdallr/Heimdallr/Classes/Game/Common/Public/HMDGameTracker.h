//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"

extern NSString * const _Nonnull kEnableGameMonitor;

@interface HMDGameTracker: HMDTracker
/**
 游戏异常埋点接口，异步写入
 
 @param stack 调用栈字符串类型
 @param name 异常名称
 @param reason 异常原因
 */
- (void)recordGameErrorWithTraceStack:(nullable NSString *)stack name:(nullable NSString *)name reason:(nullable NSString *)reason;

/**
 游戏异常埋点接口，支持指定日志是否同步写入

 @param stack 调用栈字符串类型
 @param name 异常名称
 @param reason 异常原因
 @param asyncLogging 是否异步写入日志
 */
- (void)recordGameErrorWithTraceStack:(nullable NSString *)stack name:(nullable NSString *)name reason:(nullable NSString *)reason asyncLogging:(BOOL)asyncLogging;

/**
 游戏异常埋点接口，支持指定日志是否同步写入

 @param stack 调用栈字符串类型
 @param name 异常名称
 @param reason 异常原因
 @param asyncLogging 是否异步写入日志
 @param filters  自定义异常字段
 */
- (void)recordGameErrorWithTraceStack:(nullable NSString *)stack name:(nullable NSString *)name reason:(nullable NSString *)reason asyncLogging:(BOOL)asyncLogging filters:(nullable NSDictionary<NSString *,NSString *> *)filters;

/**
 游戏异常埋点接口，支持指定日志是否同步写入

 @param stack 调用栈字符串类型
 @param name 异常名称
 @param reason 异常原因
 @param asyncLogging 是否异步写入日志
 @param filters  自定义异常字段
 @param context  自定义数据字段
 */
- (void)recordGameErrorWithTraceStack:(nullable NSString *)stack name:(nullable NSString *)name reason:(nullable NSString *)reason asyncLogging:(BOOL)asyncLogging filters:(nullable NSDictionary<NSString *,NSString *> *)filters context:(nullable NSDictionary<NSString *,NSString *> *)context;

@end
