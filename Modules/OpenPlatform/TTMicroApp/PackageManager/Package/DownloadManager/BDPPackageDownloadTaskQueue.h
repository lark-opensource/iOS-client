//
//  BDPPackageDownloadTaskQueue.h
//  Timor
//
//  Created by houjihu on 2020/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPPackageDownloadMergedTask;

/**
 控制下载并发数，管理优先级。具体的下载任务执行在外部，这里只处理任务并发和协调优先级
 - 一任务进队或优先级调整时，排序所有等待和执行中的任务集合，暂停正在执行的低优先级任务，优先执行或恢复高优先级任务（判断是否正在执行）
 - 一任务出队时，即执行结束后，优先执行或恢复执行高优先级任务（判断是否正在执行）
 */
@interface BDPPackageDownloadTaskQueue : NSObject

/// 根据当前执行任务个数，开始任务或将任务插入等待队列
- (void)startOrEnqueueMergedTask:(BDPPackageDownloadMergedTask *)mergedTask;

/// 用于合并任务时，通知提高优先级
- (void)notifyToRaisePriorityForMergedTask:(BDPPackageDownloadMergedTask *)mergedTask;

/// 正常结束或中止任务
- (nullable BDPPackageDownloadMergedTask *)finishMergedTaskWithTaskID:(NSString *)taskID;

/// 中止所有任务
- (void)finishAllMergedTasks;

/// 获取队列中的任务
- (nullable BDPPackageDownloadMergedTask *)mergedTaskWithTaskID:(NSString *)taskID;

/// 任务是否正在下载中
- (BOOL)isMergedTaskExecutingForTaskID:(NSString *)taskID;

@end

NS_ASSUME_NONNULL_END
