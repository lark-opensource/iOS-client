//
//  BDPPackageDownloadTaskQueue.m
//  Timor
//
//  Created by houjihu on 2020/7/8.
//

#import "BDPPackageDownloadTaskQueue.h"
#import "BDPPackageDownloadMergedTask.h"
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

@interface BDPPackageDownloadTaskQueue ()

/// 保证进出队同步的串行队列
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;

/// 最大并发下载任务数
@property (nonatomic, assign) NSUInteger maximumActiveDownloadCount;
/// 当前正在下载的任务数
@property (nonatomic, assign) NSUInteger activeDownloadCount;

/// 存储除了正在执行中的其他任务，按照优先级从高到低排序
@property (nonatomic, strong) NSMutableArray<BDPPackageDownloadMergedTask *> *queuedMergedTasks;
/// 存储正在执行中的任务，按照优先级从高到低排序
@property (nonatomic, strong) NSMutableArray<BDPPackageDownloadMergedTask *> *executingMergedTasks;
/// 所有还没完成的任务
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPPackageDownloadMergedTask *> *allMergedTaskDict;

@end

@implementation BDPPackageDownloadTaskQueue

- (instancetype)init {
    if (self = [super init]) {
        /// 限制下载最大并发数
        NSUInteger maximumActiveDownloads = 5;
        self.maximumActiveDownloadCount = maximumActiveDownloads;

        self.queuedMergedTasks = [[NSMutableArray alloc] init];
        self.executingMergedTasks = [[NSMutableArray alloc] init];
        self.allMergedTaskDict = [[NSMutableDictionary alloc] init];
        self.activeDownloadCount = 0;

        NSString *name = [NSString stringWithFormat:@"com.timor.packageDownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.synchronizationQueue, (__bridge void *)self, (__bridge void *)self.synchronizationQueue, NULL);
    }
    return self;
}

#pragma mark - Public

- (void)startOrEnqueueMergedTask:(BDPPackageDownloadMergedTask *)mergedTask {
    BDPLogTagInfo(BDPTag.packageManager, @"startOrEnqueueMergedTask: id(%@)", mergedTask.taskID);
    [self synchronizeInQueueWithBlock:^{
        NSString *taskID = mergedTask.taskID;
        // 1) 判断是重复请求，则合并请求，添加回调，并直接返回。在前置调用代码中已处理
        // 2) 判断缓存中已下载过，则执行回调，并直接返回。在前置调用代码中已处理
        // 3) 进队
        self.allMergedTaskDict[taskID] = mergedTask;

        // 4) 根据当前正在执行的任务个数，决定是否开始任务或者将任务先进队
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            [self startMergedTask:mergedTask];
        } else {
            [self enqueueMergedTask:mergedTask];
        }
    }];
}

- (void)notifyToRaisePriorityForMergedTask:(BDPPackageDownloadMergedTask *)mergedTask {
    BDPLogTagInfo(BDPTag.packageManager, @"notifyToRaisePriorityForMergedTask: id(%@)", mergedTask.taskID);
    [self synchronizeInQueueWithBlock:^{
        NSString *taskID = mergedTask.taskID;
        BOOL contains = [self isMergedTaskExecutingForTaskID:taskID];
        // 1) 如果指定的任务正在执行，则不需要处理
        if (contains) {
            return;
        }

        BDPPackageDownloadMergedTask *lowestPriorityExecutingMergedTask = self.executingMergedTasks.lastObject;
        // 2) 如果正在执行的最低优先级任务不低于指定的任务，则只需重新排序等待中的任务，不需要额外处理
        if (lowestPriorityExecutingMergedTask.priority >= mergedTask.priority) {
            // 重新排序等待中的任务集合
            [self sortMergedTasks:self.queuedMergedTasks];
            return;
        }

        // 3) 暂停正在执行的低优先级任务，移到等待队列
        [lowestPriorityExecutingMergedTask stopTask];
        [self.executingMergedTasks removeObject:lowestPriorityExecutingMergedTask];
        [self enqueueMergedTask:lowestPriorityExecutingMergedTask];

        // 4) 优先执行或恢复高优先级任务，移到执行队列
        [self startNextTaskIfNecessary];
    }];
}

- (BDPPackageDownloadMergedTask *)finishMergedTaskWithTaskID:(NSString *)taskID {
    BDPLogTagInfo(BDPTag.packageManager, @"finishMergedTask: id(%@)", taskID);
    __block BDPPackageDownloadMergedTask *mergedTask;
    [self synchronizeInQueueWithBlock:^{
        if ([self isMergedTaskExecutingForTaskID:taskID]) {
            // 1) 正常结束任务
            mergedTask = [self removeMergedTaskWithTaskID:taskID];
            [self decrementActiveTaskCount];
            [self startNextTaskIfNecessary];
        } else {
            // 2) 清理任务
            mergedTask = [self removeMergedTaskWithTaskID:taskID];
            [mergedTask clearTask];
        }
    }];
    return mergedTask;
}

- (void)finishAllMergedTasks {
    BDPLogTagInfo(BDPTag.packageManager, @"finishAllMergedTasks");
    [self synchronizeInQueueWithBlock:^{
        for (BDPPackageDownloadMergedTask *mergedTask in [self.executingMergedTasks arrayByAddingObjectsFromArray:self.queuedMergedTasks]) {
            [mergedTask clearTask];
        }
        [self.allMergedTaskDict removeAllObjects];
        [self.executingMergedTasks removeAllObjects];
        [self.queuedMergedTasks removeAllObjects];
        self.activeDownloadCount = 0;
    }];
}

- (BDPPackageDownloadMergedTask *)mergedTaskWithTaskID:(NSString *)taskID {
    __block BDPPackageDownloadMergedTask *mergedTask;
    [self synchronizeInQueueWithBlock:^{
        mergedTask = self.allMergedTaskDict[taskID];
    }];
    return mergedTask;
}

#pragma mark - Private

#pragma mark Unsafely Task Management

- (void)startNextTaskIfNecessary {
    if ([self isActiveRequestCountBelowMaximumLimit] && self.queuedMergedTasks.count > 0) {
        BDPPackageDownloadMergedTask *mergedTask = [self dequeueMergedTask];
        [self startMergedTask:mergedTask];
    }
}

- (void)startMergedTask:(BDPPackageDownloadMergedTask *)mergedTask {
    BDPLogTagInfo(BDPTag.packageManager, @"startMergedTask: id(%@)", mergedTask.taskID);
    [mergedTask startTask];
    [self.executingMergedTasks addObject:mergedTask];
    [self sortMergedTasks:self.executingMergedTasks];
    ++self.activeDownloadCount;
}

- (void)enqueueMergedTask:(BDPPackageDownloadMergedTask *)mergedTask {
    // 按照先入先出方式管理队列
    BDPLogTagInfo(BDPTag.packageManager, @"enqueueMergedTask: id(%@)", mergedTask.taskID);
    [self.queuedMergedTasks addObject:mergedTask];
    [self sortMergedTasks:self.queuedMergedTasks];
}

- (void)sortMergedTasks:(NSMutableArray<BDPPackageDownloadMergedTask *> *)mergedTasks {
    // 按照优先级进行从高到低排序
    [mergedTasks sortUsingComparator:^NSComparisonResult(BDPPackageDownloadMergedTask * _Nonnull task1, BDPPackageDownloadMergedTask * _Nonnull task2) {
        if (task1.priority > task2.priority) {
            return NSOrderedAscending;
        } else if (task1.priority < task2.priority) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (BDPPackageDownloadMergedTask *)dequeueMergedTask {
    BDPPackageDownloadMergedTask *mergedTask = [self.queuedMergedTasks firstObject];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

/// 任务是否正在执行
- (BOOL)isMergedTaskExecutingForTaskID:(NSString *)taskID {
    BOOL contains = [self mergedTaskForTaskID:taskID inMergedTasks:self.executingMergedTasks] != nil;
    return contains;
}

- (BDPPackageDownloadMergedTask *)mergedTaskForTaskID:(NSString *)taskID inMergedTasks:(NSMutableArray<BDPPackageDownloadMergedTask *> *)mergedTasks {
    __block BDPPackageDownloadMergedTask *task;
    [mergedTasks enumerateObjectsUsingBlock:^(BDPPackageDownloadMergedTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskID isEqualToString:taskID]) {
            task = obj;
            *stop = YES;
        }
    }];
    return task;
}

- (void)decrementActiveTaskCount {
    if (self.activeDownloadCount > 0) {
        self.activeDownloadCount -= 1;
    }
}

- (BDPPackageDownloadMergedTask *)removeMergedTaskWithTaskID:(NSString *)taskID {
    BDPLogTagInfo(BDPTag.packageManager, @"removeMergedTask: id(%@)", taskID);
    BDPPackageDownloadMergedTask *mergedTask = self.allMergedTaskDict[taskID];
    [self.allMergedTaskDict removeObjectForKey:taskID];
    [self.executingMergedTasks removeObject:mergedTask];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeDownloadCount < self.maximumActiveDownloadCount;
}

#pragma mark Helper

/// 同步执行回调。通过检测代码执行队列来避免死锁
- (void)synchronizeInQueueWithBlock:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if (dispatch_get_specific((__bridge void *)self)) {
        block();
    } else {
        dispatch_sync(self.synchronizationQueue, block);
    }
}

@end
