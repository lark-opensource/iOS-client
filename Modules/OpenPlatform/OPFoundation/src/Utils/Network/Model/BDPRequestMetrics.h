//
//  BDPRequestMetric.h
//  Timor
//
//  Created by 傅翔 on 2019/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 请求链路各阶段耗时度量. iOS10及以上
 */
@interface BDPRequestMetrics : NSObject 

/** DNS查询解析耗时, 单位ms */
@property (nonatomic, readonly, assign) NSInteger dns;
/** TCP握手耗时, 单位ms */
@property (nonatomic, readonly, assign) NSInteger tcp;
/** SSL握手耗时, 单位ms */
@property (nonatomic, readonly, assign) NSInteger ssl;
/** 从连接建立完成, 到请求数据发送完毕, 单位ms */
@property (nonatomic, readonly, assign) NSInteger send;
/** 首包耗时, 从发送完成到接受到首位数据, 单位ms */
@property (nonatomic, readonly, assign) NSInteger wait;
/** 响应(header+body)完全接收耗时, 单位ms */
@property (nonatomic, readonly, assign) NSInteger receive;
/** 是否复用连接 */
@property (nonatomic, readonly, assign) BOOL reuseConnect;
/// 请求时间【作为 duration来使用，计算逻辑是responseEndTime、requestStartTime之间的差值】
@property (nonatomic, readonly, assign) NSInteger requestTime;

+ (nullable instancetype)metricsFromTransactionMetrics:(NSURLSessionTaskTransactionMetrics * _Nullable)metrics;

- (void)updateWithMetrics:(NSURLSessionTaskTransactionMetrics *)metrics;

@end

NS_ASSUME_NONNULL_END
