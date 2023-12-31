//
//  BDPTracingManager.h
//  Timor
//
//  Created by changrong on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import "BDPTracing.h"
#import "BDPUniqueID.h"


NS_ASSUME_NONNULL_BEGIN

/**
 * 小程序 tracing
 * https://bytedance.feishu.cn/docs/doccnMwAGehp2sR3s1C5X5knE9c
 */

typedef NSString *(^GenerateNewTracing)(NSString *parentTraceId);

/// 仅用于小程序获取tracing使用
@interface BDPTracingManager : NSObject

/**
 * 获取最顶层tracing
 */
@property (nonatomic, readonly) BDPTracing *containerTrace;


+ (instancetype)sharedInstance;

/**
 * 生成一个tracing，不做存储
 */
- (BDPTracing *)generateTracing;
/**
 * 根据parent，生成一个tracing，不做存储
 */
- (BDPTracing *)generateTracingWithParent:(BDPTracing * _Nullable)parent;


/**
 * 绑定一个新的tracing到appId
 * iOS 由于小程序没有独立进程和适合的容器，这里虚拟『appId』为一个进程中的容器。
 * 做了如下假设：
 * 1. 一个进程中AppId仅可能存在一个小程序
 * 2. AppId的所有销毁需要通知 (clearTracingByAppID:)
 * 3. 支持Gadget, H5Gadget, Block，三个类型分桶
 */
- (BDPTracing *)generateTracingByUniqueID:(BDPUniqueID *)uniqueID;

/**
 * 杀掉小程序时调用，清理本地缓存的traceId
 */
- (void)clearTracingByUniqueID:(BDPUniqueID *)uniqueID;

/**
 * 清理所有tracing与AppId绑定
 * 建议用于注销、切换租户等场景
 */
- (void)clearAllTracing;

/**
 * get a traceId from container
 */
- (nullable BDPTracing *)getTracingByUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark - For Tracing Lifecycle
/**
 * 注入traceId生成算法
 */
- (void)registerTracing:(NSString *)prefix
           generateFunc:(nonnull GenerateNewTracing)func;

#pragma mark - For Safety
- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

#pragma mark - Tracing For Thread
@interface BDPTracingManager (ThreadTracing)

/// 包装tracing的block。获取当前线程的tracing，并传递到block内部，block执行完成的时候，替换为之前的tracing。
/// @param block block
+ (dispatch_block_t)convertTracingBlock:(dispatch_block_t)block;

/// 获取当前线程的traceId
+ (BDPTracing * _Nullable )getThreadTracing;

/// 绑定一个tracing到当前线程
/// @param tracing tracing
+ (void)bindCurrentThreadTracing:(BDPTracing *)tracing;


/// 使用一个linkTracing执行block, 同步执行block，执行完成后移除线程被link的tracing
/// @param block 需要执行的block
/// @param tracing 被链接的tracing
+ (void)doBlock:(dispatch_block_t)block withLinkTracing:(BDPTracing * _Nullable)tracing;
@end

NS_ASSUME_NONNULL_END
