//
//  BDPLogHelper.h
//  Timor
//
//  Created by houjihu on 2018/9/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPLogHelper : NSObject

/// 开始请求打点
+ (void)logRequestBeginWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString;
+ (void)logRequestBeginWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString withTrace:(NSString *)traceId;

/// 请求结束打点（记录http错误码）
+ (void)logRequestEndWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString URLResponse:(NSURLResponse * _Nullable)URLResponse;

/// 请求结束打点（记录错误信息）
+ (void)logRequestEndWithEventName:(NSString * _Nullable)eventName URLString:(NSString * _Nullable)URLString error:(NSError * _Nullable)error;

/// 做URL日志打印的安全截断
+ (nullable NSString *)safeURLString:(NSString  * _Nullable)url;
+ (nullable NSString *)safeURL:(NSURL * _Nullable)URL;
@end

NS_ASSUME_NONNULL_END
