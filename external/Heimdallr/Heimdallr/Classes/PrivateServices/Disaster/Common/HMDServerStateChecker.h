//
//  HMDServerStateChecker.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/10.
//

#import <Foundation/Foundation.h>
#import "HMDServerStateDefinition.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const HMDMaxNextAvailableTimeInterval;

@interface HMDServerStateChecker : NSObject

+ (instancetype)stateCheckerWithReporter:(HMDReporter)reporter;

/// 存在SDK上报场景时使用
+ (instancetype)stateCheckerWithReporter:(HMDReporter)reporter forApp:(NSString * _Nullable)aid;

/// 给异常上报使用的容灾策略，对齐develop分支策略
- (void)checkIfDegradedwithResponse:(id _Nullable)maybeDictionary;

/// 检查端监控是否需要进入容灾模式
/// - Parameters:
///   - result: 服务端返回的请求结果
///   - statusCode: 上报接口返回的状态码
- (HMDServerState)updateStateWithResult:(NSDictionary * _Nullable)result
                             statusCode:(NSInteger)statusCode;

/// 判断当前是否处于退避期间（客户端在退避期间不上报数据）
- (BOOL)isServerAvailable;

/// 重定向的域名，优先级最高，上报时需先使用此域名
/// 返回nil，表示不需重定向
- (NSString * _Nullable)redirectHost;

/// 是否需要丢弃新产生数据
- (BOOL)dropData;

/// 是否需要删除本地已有数据
- (BOOL)dropAllData;

@end

NS_ASSUME_NONNULL_END
