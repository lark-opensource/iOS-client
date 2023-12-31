//
//  HMDMonitorServiceProtocol.h
//  Heimdallr
//
//  Created by Nickyo on 2023/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDMonitorServiceProtocol <NSObject>

/// 事件埋点
/// - Parameters:
///   - serviceName: 事件名称
///   - metrics: 指标(线聚合 - 数字)
///   - dimension: 维度(点聚合 - 字符串)
///   - extra: 额外信息
+ (void)trackService:(NSString *)serviceName
             metrics:(NSDictionary<NSString *, NSNumber *> * _Nullable)metrics
           dimension:(NSDictionary<NSString *, NSString *> * _Nullable)dimension
               extra:(NSDictionary * _Nullable)extra;

/// 事件埋点
/// - Parameters:
///   - serviceName: 事件名称
///   - metrics: 指标(线聚合 - 数字)
///   - dimension: 维度(点聚合 - 字符串)
///   - extra: 额外信息
///   - sync: 是否同步记录
+ (void)trackService:(NSString *)serviceName
             metrics:(NSDictionary<NSString *, NSNumber *> * _Nullable)metrics
           dimension:(NSDictionary<NSString *, NSString *> * _Nullable)dimension
               extra:(NSDictionary * _Nullable)extra
           syncWrite:(BOOL)sync;

@end

NS_ASSUME_NONNULL_END
