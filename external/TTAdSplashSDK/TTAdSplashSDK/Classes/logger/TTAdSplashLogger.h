//
//  TTAdSplashLogManager.h
//  Pods-TTAdSplashSDK_Example
//
//  Created by yin on 2017/10/25.
//

#import <Foundation/Foundation.h>

@interface TTAdSplashLogger : NSObject

/**
 *  获取单例实例
 *
 *  @return 单例实例
 */
+ (instancetype) sharedInstance;

/**
 *  写入日志
 *
 *  @param module 模块名称
 *  @param logStr 日志信息,动态参数
 */
- (void)logModule:(NSString*)module logStr:(NSString*)logStr, ...;

/**
 *  清空过期的日志
 */
- (void)clearExpiredLog;

/**
  日志路径

 @return 路径
 */
- (NSString *)logPath;
@end
