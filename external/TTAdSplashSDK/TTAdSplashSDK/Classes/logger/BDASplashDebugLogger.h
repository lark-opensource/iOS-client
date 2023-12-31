//
//  BDASplashDebugLogger.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2019/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kSplashAdId;

/// 调试日志类，主要用来进行日志打点，并将日志信息传递给客户端，客户端自行想办法展示。
@interface BDASplashDebugLogger : NSObject

/// 输出调试日志给客户端
/// @param log 调试日志
+ (void)outputLog:(NSString *)log, ...;

@end

NS_ASSUME_NONNULL_END
