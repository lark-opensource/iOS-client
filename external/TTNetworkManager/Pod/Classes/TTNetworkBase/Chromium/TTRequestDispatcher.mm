//
//  TTRequestDispatcher.m
//  Pods
//
//  Created by changxing on 2020/10/10.
//

#import "TTRequestDispatcher.h"
#import "TTHttpTaskChromium.h"

#ifndef DISABLE_REQ_LEVEL_CTRL
#import "TTNetRequestLevelController.h"
#import "TTNetRequestLevelController+TTNetInner.h"
#endif

@interface TTRequestDispatcher()
@property (atomic, assign) BOOL enableRequestDispatcher;
@property (nonatomic, strong) NSMutableArray *pendingApiQueue;
@property (nonatomic, strong) NSMutableArray *pendingDownloadQueue;
@property (nonatomic, assign) int apiConcurrentCount;
@property (nonatomic, assign) int downloadConcurrentCount;
@property (atomic, assign) BOOL enableRequestDependency;
@property (nonatomic, strong) NSMutableArray *dependencyQueue;
@property (nonatomic, assign) BOOL targetRequestStart;
@property (nonatomic, assign) BOOL hasRunDependencyTask;
@property (nonatomic, assign) NSUInteger delayRequestCount;
@property (nonatomic, strong) dispatch_queue_t timer_queue;
@end

@implementation TTRequestDispatcher

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        self.enableRequestDispatcher = NO;
        self.pendingApiQueue = [NSMutableArray array];
        self.pendingDownloadQueue = [NSMutableArray array];
        self.apiConcurrentCount = 0;
        self.downloadConcurrentCount = 0;
        self.maxApiConcurrentCount = 8;
        self.maxDownloadConcurrentCount = 8;
        
        self.enableRequestDependency = NO;
        self.dependencyQueue = [NSMutableArray array];
        self.targetRequestStart = NO;
        self.hasRunDependencyTask = NO;
        self.dependencyTimeoutToStart = 10;
        self.dependencyExecuteTime = 0;
        self.delayRequestCount = 0;
        
        self.targetUri = nil;
        self.dependencyUri = nil;
        self.timer_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (void)startRequestDispatcher {
    if (self.enableRequestDispatcher) {
        return;
    }
    self.enableRequestDispatcher = YES;
}

- (void)stopRequestDispatcher {
    if (!self.enableRequestDispatcher) {
        return;
    }
    self.enableRequestDispatcher = NO;
    [self runPendingTask];
}

- (void)startRequestDependency {
    if (self.enableRequestDependency) {
        return;
    }
    self.targetRequestStart = NO;
    self.hasRunDependencyTask = NO;
    self.delayRequestCount = 0;
    self.enableRequestDependency = YES;
    if (self.dependencyTimeoutToStart > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     self.dependencyTimeoutToStart * NSEC_PER_SEC),
                       self.timer_queue, ^(void) {
            [[TTRequestDispatcher shareInstance] runDependencyTask];
        });
    }
}

- (void)stopRequestDependency {
    if (!self.enableRequestDependency) {
        return;
    }
    self.enableRequestDependency = NO;
    [self runDependencyTask];
}

- (BOOL)isRequestDispatcherWorking {
    return self.enableRequestDependency || self.enableRequestDispatcher;
}

- (void)runPendingTask {
    @synchronized (self) {
        if (self.pendingApiQueue.count > 0) {
            for (TTHttpTaskChromium *task in self.pendingApiQueue) {
                [task resume];
            }
            [self.pendingApiQueue removeAllObjects];
        }
        
        if (self.pendingDownloadQueue.count > 0) {
            for (TTHttpTaskChromium *task in self.pendingDownloadQueue) {
                [task resume];
            }
            [self.pendingDownloadQueue removeAllObjects];
        }
    }
}

- (void)runDependencyTask {
    @synchronized (self) {
        self.hasRunDependencyTask = YES;
        self.delayRequestCount = self.dependencyQueue.count;
        if (self.dependencyQueue.count > 0) {
            for (TTHttpTaskChromium *task in self.dependencyQueue) {
                [task resume];
            }
            [self.dependencyQueue removeAllObjects];
        }
    }
}

- (BOOL)onHttpTaskResume:(TTHttpTaskChromium *)httpTask {
#ifndef DISABLE_REQ_LEVEL_CTRL
    // YES means task resume() continue, NO means task resume stop going down.
    if ([[TTNetRequestLevelController shareInstance] isRequestLevelControlEnabled]) {
        httpTask.level = [[TTNetRequestLevelController shareInstance] getLevelForRequestPath:httpTask.request.URL.path];
        if (httpTask.level == 1) {
            BOOL rv = [[TTNetRequestLevelController shareInstance] maybeAddP1Task:httpTask];
            if (rv) return NO;
        } else if (httpTask.level == 2) {
            [httpTask cancel];
            return NO;
        }
        return YES;
    }
#endif

    if (httpTask.forceRun) {
        return YES;
    }
    
    if (![self runDependencyStrategy:httpTask]) {
        return NO;
    }
    
    return [self runDispatcherStrategy:httpTask];
}

- (BOOL)runDependencyStrategy:(TTHttpTaskChromium *)httpTask {
    if (!self.enableRequestDependency) {
        return YES;
    }
    
    @synchronized (self) {
        if (self.hasRunDependencyTask) {
            return YES;
        }
        
        for (NSString *uri in self.dependencyUri) {
            if ([httpTask.request.urlString containsString:uri]) {
                [self.dependencyQueue addObject:httpTask];
                return NO;
            }
        }
        return YES;
    }
}

- (BOOL)runDispatcherStrategy:(TTHttpTaskChromium *)httpTask {
    if (!self.enableRequestDispatcher) {
        return YES;
    }
    
    @synchronized (self) {
        if(self.targetUri
           && self.targetRequestStart == NO
           && [httpTask.request.urlString containsString:self.targetUri]) {
            self.targetRequestStart = YES;
            if (self.dependencyExecuteTime > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                             self.dependencyExecuteTime * NSEC_PER_MSEC),
                               self.timer_queue, ^(void) {
                    [[TTRequestDispatcher shareInstance] runDependencyTask];
                });
            }
            return YES;
        }
        
        if (httpTask.taskType == TTNET_TASK_TYPE_API) {
            if (self.apiConcurrentCount < self.maxApiConcurrentCount) {
                ++self.apiConcurrentCount;
                return YES;
            } else {
                [self.pendingApiQueue addObject:httpTask];
                return NO;
            }
        } else if (httpTask.taskType == TTNET_TASK_TYPE_DOWNLOAD) {
            if (self.downloadConcurrentCount < self.maxDownloadConcurrentCount) {
                ++self.downloadConcurrentCount;
                return YES;
            } else {
                [self.pendingDownloadQueue addObject:httpTask];
                return NO;
            }
        } else {
            return YES;
        }
    }
}

- (BOOL)onHttpTaskCancel:(TTHttpTaskChromium *)httpTask {
#ifndef DISABLE_REQ_LEVEL_CTRL
    // YES means task cancel() continue, NO means task cancel() stop going down.
    if ([[TTNetRequestLevelController shareInstance] isRequestLevelControlEnabled]) {
        [[TTNetRequestLevelController shareInstance] notifyTaskCancel:httpTask];
    }
#endif

    if (httpTask.isCancelled) {
        return NO;
    }
    
    if (self.enableRequestDependency && [self runTaskCancel:self.dependencyQueue httpTask:httpTask]) {
        return YES;
    }
    
    if (self.enableRequestDispatcher) {
        if (httpTask.taskType == TTNET_TASK_TYPE_API) {
            [self runTaskCancel:self.pendingApiQueue httpTask:httpTask];
        } else if(httpTask.taskType == TTNET_TASK_TYPE_DOWNLOAD) {
            [self runTaskCancel:self.pendingDownloadQueue httpTask:httpTask];
        }
    }
    return YES;
}

- (BOOL)runTaskCancel:(NSMutableArray *)queue
             httpTask:(TTHttpTaskChromium *)httpTask {
    @synchronized (self) {
        if (queue.count > 0 && [queue containsObject:httpTask]) {
            [queue removeObject:httpTask];
            [httpTask onCancel:@""];
            return YES;
        }
        return NO;
    }
}

- (void)onHttpTaskFinish:(TTHttpTaskChromium *)httpTask {
#ifndef DISABLE_REQ_LEVEL_CTRL
    if ([[TTNetRequestLevelController shareInstance] isRequestLevelControlEnabled]) {
        [[TTNetRequestLevelController shareInstance] notifyTaskFinish:httpTask];
    }
#endif

    if (self.enableRequestDependency) {
        @synchronized (self) {
            if (self.targetUri
                && !self.hasRunDependencyTask
                && [httpTask.request.urlString containsString:self.targetUri]) {
                [self runDependencyTask];
                return;
            }
        }
    }
    
    if (self.enableRequestDispatcher) {
        @synchronized (self) {
            if (httpTask.taskType == TTNET_TASK_TYPE_API) {
                --self.apiConcurrentCount;
                [self runPendingTask:self.pendingApiQueue];
            } else if(httpTask.taskType == TTNET_TASK_TYPE_DOWNLOAD) {
                --self.downloadConcurrentCount;
                [self runPendingTask:self.pendingDownloadQueue];
            }
        }
    }
}

- (void)runPendingTask:(NSMutableArray *)queue {
    if (queue.count > 0) {
        TTHttpTaskChromium *task = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
        task.forceRun = YES;
        [task resume];
    }
}

- (NSUInteger)getDelayRequestCount {
    return self.delayRequestCount;
}
@end
