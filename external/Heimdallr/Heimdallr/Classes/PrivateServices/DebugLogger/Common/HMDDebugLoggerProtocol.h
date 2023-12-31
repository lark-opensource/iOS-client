//
//  HMDDebugLoggerProtocol.h
//  Pods
//
//  Created by Nickyo on 2023/7/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HMDDebugLoggerBlock)(NSString * _Nullable log);

@protocol HMDDebugLoggerProtocol <NSObject>

/// 启用调试日志
/// - Parameter logger: 日志回调
+ (void)enableDebugLogUsingLogger:(HMDDebugLoggerBlock _Nullable)logger;

/// 输出日志
/// - Parameter log: 日志内容
+ (void)printLog:(NSString * _Nullable)log;

/// 输出错误
/// - Parameter error: 错误内容
+ (void)printError:(NSString * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
