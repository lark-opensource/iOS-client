//
//  OPTrace.h
//  LarkOPInterface
//
//  Created by changrong on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import "OPTraceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPTracingCoreSpan : NSObject<OPTraceProtocol>

/// 每个 Trace object 的 traceId 不发生变化
@property (nonatomic, readonly) NSString *traceId;
@property (nonatomic, readonly) NSTimeInterval createTime;
/// 外部使用生成好的traceIdy初始化Trace
- (instancetype)initWithTraceId:(NSString *)traceId NS_DESIGNATED_INITIALIZER;

/**
 *使用 JSON 字典反序列化生成 TracingSpan
 * @param json JSON 字典，格式：{"traceId": "1-xxx-yyy", "createTime": 1234.5678}
 */
- (nullable instancetype)initWithJSONDict:(NSDictionary *)json;

/// 禁用默认初始化方法
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
