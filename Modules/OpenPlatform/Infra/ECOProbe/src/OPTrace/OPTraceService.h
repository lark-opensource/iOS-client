//
//  OPTraceService.h
//  LarkOPInterface
//
//  Created by changrong on 2020/9/14.
//

#import <Foundation/Foundation.h>
#import "OPTrace.h"
#import "OPTraceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPTraceService : NSObject

#pragma mark - Public API

/// 获取全局默认 service
+ (instancetype)defaultService;

/// 生成一个trace
- (OPTrace *)generateTrace;

/// 根据parent，生成一个trace
- (OPTrace *)generateTraceWithParent:(nullable OPTrace *)parent;

/// 根据 traceID 和 bizName 生成一个 trace，会根据 bizName 决策 trace 的 batchEnabled 开关状态
- (OPTrace *)generateTraceWithTraceID:(nonnull NSString *)traceID bizName:(nonnull NSString *)bizName;

/// 根据 parent 和 bizName 生成一个 trace，会根据 bizName 决策 trace 的 batchEnabled 开关状态
- (OPTrace *)generateTraceWithParent:(nullable OPTrace *)parent bizName:(nonnull NSString *)bizName;

#pragma mark - For Tracing Lifecycle
/// 注入trace config
- (void)setup:(OPTraceConfig *)config;

@end

NS_ASSUME_NONNULL_END
