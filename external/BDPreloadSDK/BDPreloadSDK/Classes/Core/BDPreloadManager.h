//
//  BDPreloadManager.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import "BDPreloadMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPreloadManager : NSObject

// 普通任务管理
+ (instancetype)sharedInstance;

// 重任务管理，适用于运行时间比较长的任务
+ (instancetype)hardManager;

// 最大并发任务
@property (nonatomic, assign, readonly) NSUInteger maxConcurrentTaskCount;

/**
 *  添加预加载任务
 *  @params task - NSOperation 任务，需要 preloadKey 不为空，内部以 preloadKey 作为任务的唯一标识
 */
- (void)addPreloadTask:(NSOperation *)task;

/**
 *  添加 block 类型的预加载任务
 *  @params preloadKey - 任务唯一标识
 *  @params executionBlock - 任务执行 block, 业务调用执行结束之后需要调用 preloadCompletion 告知任务执行完成
 */
- (void)addPreloadTaskWithKey:(NSString *)preloadKey
           withExecutionBlock:(void(^)(dispatch_block_t preloadCompletion))executionBlock;

/**
 *  添加 block 类型的预加载任务
 *  @params preloadKey - 任务唯一标识
 *  @params onlyWifi - 是否只在 Wifi 下运行
 *  @params executionBlock - 任务执行 block, 业务调用执行结束之后需要调用 preloadCompletion 告知任务执行完成
 */
- (void)addPreloadTaskWithKey:(NSString *)preloadKey
                     onlyWifi:(BOOL)onlyWifi
           withExecutionBlock:(void(^)(dispatch_block_t preloadCompletion))executionBlock;


- (void)addPreloadTaskWithKey:(NSString *)preloadKey
                        scene:(NSString *)scene
                     onlyWifi:(BOOL)onlyWifi
           withExecutionBlock:(void(^)(dispatch_block_t preloadCompletion))executionBlock;

// 取消任务
- (void)cancelPreloadTaskWithKey:(NSString *)key;
// 按场景取消任务，这里用的是 NSOperation 的 bdp_scene
- (void)cancelPreloadTasksWithScene:(NSString *)scene;
- (void)cancelAllPreloadTask;

// 挂起所有任务
- (void)suppendAllTask;

// 恢复所有任务
- (void)resumeAllTask;

@end

NS_ASSUME_NONNULL_END
