//
//  BDPreloadManager.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/4/15.
//

#import "BDPreloadManager.h"
#import "NSOperation+BDPreloadTask.h"
#import "BDPreloadConfig.h"
#import "BDPreloadUtil.h"
#import "BDPreloadMonitor.h"
#import "BDPreloadDebugView.h"

#import <pthread.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

static NSString * const TAG = @"BDPreload";

@interface BDPreloadManager()

@property (nonatomic, strong) NSMutableArray <NSOperation *>*pendingTasks;
@property (nonatomic, strong) NSMutableArray <NSOperation *>*tempTasks;
@property (nonatomic, strong) NSOperationQueue *preloadQueue;
@property (nonatomic, assign) BDPreloadType type;
@property (nonatomic, assign) NSUInteger finishCount;

- (void)_startPendingTaskIfNeed;

@end


@implementation BDPreloadManager

+ (instancetype)sharedInstance {
    static BDPreloadManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BDPreloadManager alloc] init];
    });
    return sharedManager;
}

+ (instancetype)hardManager {
    static BDPreloadManager *sharedHardManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHardManager = [[BDPreloadManager alloc] init];
        sharedHardManager.type = BDPreloadTypeHard;
    });
    return sharedHardManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tempTasks = [NSMutableArray array];
        _pendingTasks = [NSMutableArray array];
        _preloadQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (NSUInteger)maxConcurrentTaskCount {
    NSInteger count = 0;
    if (self.type == BDPreloadTypeHard) {
        if ([BDPreloadUtil isWifiConnected]) {
            count = [BDPreloadConfig sharedConfig].maxConcurrentHardTaskCountInWiFi;
        } else {
            count = [BDPreloadConfig sharedConfig].maxConcurrentHardTaskCount;
        }
    } else if ([BDPreloadUtil isWifiConnected]) {
        count = [BDPreloadConfig sharedConfig].maxConcurrentTaskCountInWiFi;
    } else {
        count = [BDPreloadConfig sharedConfig].maxConcurrentTaskCount;
    }
    if (count <= 0) {
        count = 5;
    }
    return count;
}

- (NSUInteger)maxRuningTime {
    return [BDPreloadConfig sharedConfig].maxRunningTime;
}

#pragma mark - 预加载队列管理

- (void)addPreloadTask:(NSOperation *)task {
    if (task.bdp_preloadType == BDPreloadTypeHard && self.type != BDPreloadTypeHard) {
        [[BDPreloadManager hardManager] addPreloadTask:task];
        return ;
    }
    
    if (task.bdp_preloadType == BDPreloadTypeNormal && self.type != BDPreloadTypeNormal) {
        [[BDPreloadManager sharedInstance] addPreloadTask:task];
        return ;
    }
    
    if (task.bdp_preloadKey.length <= 0) {
        return ;
    }
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        
        if ([self _taskIsLoading:task]) {
            return;
        }
        
        if (![task isKindOfClass:[NSBlockOperation class]]) {
            dispatch_block_t taskCompletionBlock = [task.completionBlock copy];
            __weak typeof(task) wTask = task;
            __weak typeof(self) wself = self;
            dispatch_block_t completionBlock = ^{
                [wself increaseFinish];
                [BDPreloadMonitor pop:wTask.bdp_preloadKey];
                wTask.bdp_finishTime = [[NSDate date] timeIntervalSince1970];
                [wself _startPendingTaskIfNeed];
                taskCompletionBlock ? taskCompletionBlock() : nil;
            };
            
            task.completionBlock = completionBlock;
        }
        task.bdp_initTime = [[NSDate date] timeIntervalSince1970];
        
        [self _removePendingTaskWithKey:task.bdp_preloadKey];
        [self resumeAllTask];
        __strong typeof(wself) self = wself;
        if ((self.pendingTasks.count == 0 &&
             self.preloadQueue.operationCount < self.maxConcurrentTaskCount) &&
            (!task.bdp_onlyWifi || [BDPreloadUtil isWifiConnected])) {
            
            [BDPreloadMonitor push:task];
            task.bdp_startTime = [[NSDate date] timeIntervalSince1970];
            [self _addOperation:task];
        } else {
            [self throttleInsertTask:task];
        }
    }];
}

- (void)addPreloadTaskWithKey:(NSString *)preloadKey withExecutionBlock:(void(^)(dispatch_block_t))executionBlock {
    [self addPreloadTaskWithKey:preloadKey onlyWifi:NO withExecutionBlock:executionBlock];
}
    
- (void)addPreloadTaskWithKey:(NSString *)preloadKey
                     onlyWifi:(BOOL)onlyWifi
           withExecutionBlock:(void(^)(dispatch_block_t))executionBlock {
    [self addPreloadTaskWithKey:preloadKey scene:nil preloadType:self.type onlyWifi:onlyWifi withExecutionBlock:executionBlock];
}

- (void)addPreloadTaskWithKey:(NSString *)preloadKey
                        scene:(NSString *)scene
                     onlyWifi:(BOOL)onlyWifi
           withExecutionBlock:(void(^)(dispatch_block_t preloadCompletion))executionBlock {
    [self addPreloadTaskWithKey:preloadKey scene:scene preloadType:self.type onlyWifi:onlyWifi withExecutionBlock:executionBlock];
}

- (void)addPreloadTaskWithKey:(NSString *)preloadKey
                        scene:(NSString *)scene
                  preloadType:(BDPreloadType)preloadType
                     onlyWifi:(BOOL)onlyWifi
           withExecutionBlock:(void(^)(dispatch_block_t))executionBlock {
    if (preloadType == BDPreloadTypeHard && self.type != BDPreloadTypeHard) {
        [[BDPreloadManager hardManager] addPreloadTaskWithKey:preloadKey scene:scene preloadType:preloadType onlyWifi:onlyWifi withExecutionBlock:executionBlock];
        return ;
    }
    
    if (preloadType == BDPreloadTypeNormal && self.type != BDPreloadTypeNormal) {
        [[BDPreloadManager sharedInstance] addPreloadTaskWithKey:preloadKey scene:scene preloadType:preloadType onlyWifi:onlyWifi withExecutionBlock:executionBlock];
        return ;
    }
    
    NSBlockOperation *operaion = [[NSBlockOperation alloc] init];
    operaion.bdp_onlyWifi = onlyWifi;
    operaion.bdp_preloadType = preloadType;
    operaion.bdp_scene = scene;
    
    __weak NSBlockOperation *wOperaion = operaion;
    __weak typeof(self) wself = self;
    [operaion addExecutionBlock:^{
        if (wOperaion.isCancelled) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            executionBlock ? executionBlock(^{
                [wself increaseFinish];
                [BDPreloadMonitor pop:preloadKey];
                wOperaion.bdp_finishTime = [[NSDate date] timeIntervalSince1970];
                [wself _startPendingTaskIfNeed];
            }) : NULL;
        });
    }];
    operaion.bdp_preloadKey = preloadKey;
    [self addPreloadTask:operaion];
}

- (void)throttleInsertTask:(NSOperation *)task {
    if (!task) {
        return ;
    }
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        [self.tempTasks addObject:task];
        [self refreshDebugView];
        static int throttle = 0;
        throttle++;
        int throttleNow = throttle;
        // 限流，保证短时内同一批次内的请求先入先出，不同批次的请求后入先出
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (throttleNow == throttle) {
                [self _tryInsertTempTasks:YES];
                [self _startPendingTaskIfNeed];
            }
        });
    }];
}

- (void)cancelAllPreloadTask {
    if (self.type == BDPreloadTypeNormal) {
        [[BDPreloadManager hardManager] cancelAllPreloadTask];
    }
    BDALOG_PROTOCOL_INFO_TAG(TAG, @"cancelAllPreloadTask");
    [BDPreloadMonitor popAll];
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        [self.pendingTasks removeAllObjects];
        [self.tempTasks removeAllObjects];
        [self.preloadQueue cancelAllOperations];
        [self refreshDebugView];
    }];
}

- (void)suppendAllTask {
    if (self.type == BDPreloadTypeNormal) {
        [[BDPreloadManager hardManager] suppendAllTask];
    }
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        if (!self.preloadQueue.isSuspended) {
            BDALOG_PROTOCOL_INFO_TAG(TAG, @"suppendAllTask");
            [self.preloadQueue setSuspended:YES];
        }
    }];
}

- (void)resumeAllTask {
    if (self.type == BDPreloadTypeNormal) {
        [[BDPreloadManager hardManager] resumeAllTask];
    }
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        if (self.preloadQueue.isSuspended) {
            BDALOG_PROTOCOL_INFO_TAG(TAG, @"resumeAllTask");
            [self.preloadQueue setSuspended:NO];
        }
    }];
}

/**
 如果指定URLString的task 处于pending则取消
 */
- (void)cancelPreloadTaskWithKey:(NSString *)preloadKey {
    // _removePendingTask 可以将相同proloadKey的task移除
    [BDPreloadMonitor pop:preloadKey];
    [self _removePendingTaskWithKey:preloadKey];
    [self _cancelOperationWithKey:preloadKey];
}

- (void)cancelPreloadTasksWithScene:(NSString *)scene {
    [self _removePendingTaskWithScene:scene];
    [self _cancelOperationWithScene:scene];
}

#pragma mark - Private

- (void)_addOperation:(NSOperation *)task {
    NSOperation __weak *wTask = task;
    [self.preloadQueue addOperation:task];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.maxRuningTime * NSEC_PER_SEC)), BDPreloadUtil.preloadTaskQueue, ^{
        NSOperation *task = wTask;
        if (task && ![task isFinished]) {
            BDALOG_PROTOCOL_INFO_TAG(TAG, @"%@ preload run time out", task.bdp_preloadKey);
            [BDPreloadMonitor trackPreloadWithKey:task.bdp_preloadKey scene:wTask.bdp_scene ?: @"cancel" error:[NSError errorWithDomain:@"kBDPreloadError" code:-9999 userInfo:nil]];
            if (task.bdp_timeoutBlock) {
                task.bdp_timeoutBlock();
            }
            [task cancel];
            [BDPreloadMonitor pop:task.bdp_preloadKey];
            [self _startPendingTaskIfNeed];
        }
    });
}

- (void)_tryInsertTempTasks:(BOOL)force {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        if ((force || self.pendingTasks.count == 0) && self.tempTasks.count > 0) {
            self.pendingTasks = [[self.tempTasks arrayByAddingObjectsFromArray:self.pendingTasks ? : @[]] mutableCopy];
            [self.tempTasks removeAllObjects];
        }
        [self refreshDebugView];
    }];
}

- (void)_startPendingTaskIfNeed
{
    [self _tryInsertTempTasks:NO];

    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        NSMutableArray <NSOperation *>*preloadTasks = [NSMutableArray array];
        [self.pendingTasks enumerateObjectsUsingBlock:^(NSOperation * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(wself) self = wself;
            if (self.preloadQueue.operationCount >= self.maxConcurrentTaskCount) {
                *stop = YES;
            } else if (task.bdp_waitTime > [BDPreloadConfig sharedConfig].maxWaitTime) {
                BDALOG_PROTOCOL_INFO_TAG(TAG, @"%@ preload wait time out", task.bdp_preloadKey);
                [BDPreloadMonitor trackPreloadWithKey:task.bdp_preloadKey scene:task.bdp_scene ?: @"cancel" error:[NSError errorWithDomain:@"kBDPreloadError" code:-19999 userInfo:nil]];
                if (task.bdp_timeoutBlock) {
                    task.bdp_timeoutBlock();
                }
                [BDPreloadMonitor pop:task.bdp_preloadKey];
                [preloadTasks addObject:task];
            } else if (!task.bdp_onlyWifi || [BDPreloadUtil isWifiConnected]) {
                [BDPreloadMonitor push:task];
                task.bdp_startTime = [[NSDate date] timeIntervalSince1970];
                [self _addOperation:task];
                [preloadTasks addObject:task];
                *stop = YES;
            }
        }];
        
        if (preloadTasks.count > 0) {
            [self.pendingTasks removeObjectsInArray:preloadTasks];
        }
        [self refreshDebugView];
    }];
    
}

- (void)_removePendingTaskWithScene:(NSString *)scene {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        NSMutableIndexSet *pIndexs = [NSMutableIndexSet new];
        [self.pendingTasks enumerateObjectsUsingBlock:^(NSOperation *t, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([t.bdp_scene isEqualToString:scene]) {
                [BDPreloadMonitor pop:t.bdp_preloadKey];
                [pIndexs addIndex:idx];
            }
        }];
        [self.pendingTasks removeObjectsAtIndexes:pIndexs];
        
        NSMutableIndexSet *tIndexs = [NSMutableIndexSet new];
        [self.tempTasks enumerateObjectsUsingBlock:^(NSOperation *t, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([t.bdp_scene isEqualToString:scene]) {
                [BDPreloadMonitor pop:t.bdp_preloadKey];
                [tIndexs addIndex:idx];
            }
        }];
        
        [self.tempTasks removeObjectsAtIndexes:tIndexs];
        [self refreshDebugView];
    }];
}

- (void)_removePendingTaskWithKey:(NSString *)preloadKey {
    
    __weak typeof(self) wself = self;
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        __strong typeof(wself) self = wself;
        __block NSUInteger index = NSNotFound;
        [self.pendingTasks enumerateObjectsUsingBlock:^(NSOperation *t, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([t.bdp_preloadKey isEqualToString:preloadKey]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        if (index != NSNotFound) {
            [self.pendingTasks removeObjectAtIndex:index];
        } else {
            [self.tempTasks enumerateObjectsUsingBlock:^(NSOperation *t, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([t.bdp_preloadKey isEqualToString:preloadKey]) {
                    index = idx;
                    *stop = YES;
                }
            }];
            if (index != NSNotFound) {
                [self.tempTasks removeObjectAtIndex:index];
            }
        }
        [self refreshDebugView];
    }];
}

- (void)_cancelOperationWithKey:(NSString *)preloadKey {
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        [self.preloadQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.bdp_preloadKey isEqualToString:preloadKey] && [obj isKindOfClass:NSOperation.class]) {
                [(NSOperation *)obj cancel];
                *stop = YES;
            }
        }];
    }];
}

- (void)_cancelOperationWithScene:(NSString *)scene {
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        [self.preloadQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.bdp_scene isEqualToString:scene] && [obj isKindOfClass:NSOperation.class]) {
                [BDPreloadMonitor pop:obj.bdp_preloadKey];
                [(NSOperation *)obj cancel];
            }
        }];
    }];
}

- (BOOL)_taskIsLoading:(NSOperation *)task {
    __auto_type operations = self.preloadQueue.operations;
    __block BOOL preloading = NO;
    [operations enumerateObjectsUsingBlock:^(NSOperation *t, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([t.bdp_preloadKey isEqualToString:task.bdp_preloadKey]) {
            preloading = YES;
            *stop = YES;
        }
    }];
    return preloading;
}

- (void)refreshDebugView {
    [BDPreloadUtil taskAsyncInPreloadQueue:^{
        NSInteger waitingCount = [BDPreloadManager sharedInstance].tempTasks.count;
        NSInteger runningCount = [BDPreloadManager sharedInstance].preloadQueue.operationCount;
        NSInteger pendingCount = [BDPreloadManager sharedInstance].pendingTasks.count;
        
        NSInteger hardWaitingCount = [BDPreloadManager hardManager].tempTasks.count;
        NSInteger hardRunningCount = [BDPreloadManager hardManager].preloadQueue.operationCount;
        NSInteger hardPendingCount = [BDPreloadManager hardManager].pendingTasks.count;
        dispatch_async(dispatch_get_main_queue(), ^{
            [BDPreloadDebugView sharedInstance].runningLabel.text = [NSString stringWithFormat:@"%@ + %@",@(runningCount), @(hardRunningCount)];
            [BDPreloadDebugView sharedInstance].pendingLabel.text = [NSString stringWithFormat:@"%@ + %@",@(pendingCount), @(hardPendingCount)];
            [BDPreloadDebugView sharedInstance].waitingLabel.text = [NSString stringWithFormat:@"%@ + %@",@(waitingCount), @(hardWaitingCount)];
        });
    }];
}

- (void)increaseFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        ++self.finishCount;
        [BDPreloadDebugView sharedInstance].finishLabel.text = [NSString stringWithFormat:@"%@ + %@",@([BDPreloadManager sharedInstance].finishCount), @([BDPreloadManager hardManager].finishCount)];
    });
}

@end
