//
//  BDPTracing.h
//  Timor
//
//  Created by Chang Rong on 2020/2/17.
//

#import <Foundation/Foundation.h>
#import <ECOProbe/OPTrace.h>


NS_ASSUME_NONNULL_BEGIN

/**
 * tracing 实体类
 * 包含获取traceId、初始化方法
 */
@interface BDPTracing : OPTrace

/// BDPTracing 创建时间
@property (nonatomic, readonly) NSInteger createTime;

/// 外部使用生成好的traceIdy初始化BDPTracing
- (instancetype)initWithTraceId:(NSString *)traceId;

@end


/// extension 的通用扩展方法
@interface BDPTracing(Extension)

/// 其他tracing被link到当前tracing时，调用该方法，同时埋点: "mp_app_event_link"
- (void)linkTracing:(BDPTracing *)linkedTracing;

@end

/// client duration 的扩展方法
@interface BDPTracing(ClientDurationExtension)

/// 支持记录某个开始点
- (void)clientDurationTagStart:(NSString *)key;

/// 支持记录开始点到当前的事件（ms）
- (NSInteger)clientDurationTagEnd:(NSString *)startKey;

///纯计算方法：支持记录开始点到当前的事件的时间（ms），与'clientDurationTagEnd'区别在于不标记finish
- (NSInteger)clientDurationFor:(NSString *)startKey;

- (NSInteger)endDuration:(NSString *)startKey timestamp:(NSInteger)timestamp;

@end

NS_ASSUME_NONNULL_END
