#include "TTDownloadDispatcher.h"
#import "TTDownloadManager.h"
#include "TTQueue.h"

NS_ASSUME_NONNULL_BEGIN

static const int kQueueSizeMaxDefault = 10000; //every queue‘s max size is 10000
static const int kDownloadingTaskMaxDefault = 16; //Running task's max count default.
static const int kDownloadingTaskValidValueMax = 20; //Running task's max count that allowed callers to set.

@interface TTDownloadDispatcher()
@property (atomic, strong) TTQueue *queueHigh;
@property (atomic, strong) TTQueue *queueMid;
@property (atomic, strong) TTQueue *queueLow;
@property (atomic, strong) NSMutableDictionary<NSString *, TTDispatcherTask *> *downloadingDic;
@property (atomic, strong) NSMutableDictionary<NSString *, TTDispatcherTask *> *allTaskDic;
@property (atomic, assign) int8_t downloadingTaskMax;
@end

@implementation TTDownloadDispatcher

- (id)init {
    self = [super init];
    if (self) {
        self.queueLow       = [[TTQueue alloc] initWhithSize:kQueueSizeMaxDefault];
        self.queueMid       = [[TTQueue alloc] initWhithSize:kQueueSizeMaxDefault];
        self.queueHigh      = [[TTQueue alloc] initWhithSize:kQueueSizeMaxDefault];
        self.downloadingDic = [NSMutableDictionary dictionary];
        self.allTaskDic     = [NSMutableDictionary dictionary];
        self.downloadingTaskMax = kDownloadingTaskMaxDefault;
        [TTDownloadManager shareInstance].onCompletionHandler = ^(DownloadResultNotification *notification) {
            DLLOGD(@"dispatcher:debug:completionHandler run,downloadingDic.size=%lu,allTaskDic=%lu", self.downloadingDic.count, self.allTaskDic.count);
            [self deleteTaskDownloadingDic:notification.urlKey];
            [self runSameResultBlockAndRemove:notification];
            [self dequeue];
        };
    }
    return self;
}

- (void)runSameResultBlockAndRemove:(DownloadResultNotification *)notification {
    if (!notification) {
        return;
    }
    @synchronized (self.allTaskDic) {
        TTDispatcherTask * task = [self.allTaskDic objectForKey:notification.urlKey];
        [task executeAllResultBlock:notification];
        if (task) {
            task.isDeleted = YES;
        }
        [self.allTaskDic removeObjectForKey:notification.urlKey];
    }
}

- (BOOL)deleteTaskToAllTaskDic:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    @synchronized (self.allTaskDic) {
        TTDispatcherTask * task = [self.allTaskDic objectForKey:urlKey];
        if (task) {
            task.isDeleted = YES;
        }
        [self.allTaskDic removeObjectForKey:urlKey];
    }
    return YES;
}

- (BOOL)isTaskExist:(TTDispatcherTask *)task {
    if (!task) {
        return NO;
    }
    @synchronized (self.allTaskDic) {
        id ret = [self.allTaskDic objectForKey:task.urlKey];
        DLLOGD(@"dispatcher:debug:allTaskDic count=%ld", self.allTaskDic.count);
        return ret ? YES : NO;
    }
}

- (size_t)getAllTaskCount {
    @synchronized (self.allTaskDic) {
        return self.allTaskDic.count;
    }
}

- (BOOL)addDTaskToDownloadingDic:(TTDispatcherTask *)task {
    if (!task) {
        return NO;
    }
    @synchronized (self.downloadingDic) {
        DLLOGD(@"addDTaskToDownloadingDic");
        [self.downloadingDic setObject:task forKey:task.urlKey];
    }
    return YES;
}

- (BOOL)deleteTaskDownloadingDic:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    @synchronized (self.downloadingDic) {
        DLLOGD(@"deleteTaskDownloadingDic");
        [self.downloadingDic removeObjectForKey:urlKey];
        DLLOGD(@"dispatcher:debug:self.downloadingDic=%ld", self.downloadingDic.count);
    }
    return YES;
}

- (BOOL)findDTaskDownloadingDic:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    @synchronized (self.downloadingDic) {
        DLLOGD(@"deleteTaskDownloadingDic");
        id ret = [self.downloadingDic objectForKey:urlKey];
        DLLOGD(@"dispatcher:debug:self.downloadingDic=%ld", self.downloadingDic.count);
        return ret ? YES : NO;
    }
}

- (BOOL)isDownloadingDicFull {
    @synchronized (self.downloadingDic) {
        DLLOGD(@"dispatcher:debug:self.downloadingDic.count=%lu,self.downloadingTaskMax=%hhd", (unsigned long)self.downloadingDic.count, self.downloadingTaskMax);
        return self.downloadingDic.count >= self.downloadingTaskMax;
    }
}

- (BOOL)isTaskWaitInQueue:(TTDispatcherTask *)task {
    if (!task) {
        return NO;
    }
    return (![self findDTaskDownloadingDic:task.urlKey] && [self isTaskExist:task]);
}

- (BOOL)mergeSameRequestResultBlock:(TTDispatcherTask *)newTask {
    if (!newTask) {
        return NO;
    }
    @synchronized (self.allTaskDic) {
        TTDispatcherTask *oldTask = [self.allTaskDic objectForKey:newTask.urlKey];
        DLLOGD(@"dispatcher:debug:allTaskDic count=%ld", self.allTaskDic.count);
        if (oldTask) {
            [oldTask addResultBlock:newTask];
        }
        return oldTask ? YES : NO;
    }
}

- (BOOL)enqueue:(TTDispatcherTask *)task {
    DLLOGD(@"enqueue:task.urlKey=%@,priority=%ld", task.urlKey, (long)task.userParameters.queuePriority);
    
    if ([self mergeSameRequestResultBlock:task]) {
        return YES;
    }
    
    BOOL ret = NO;
    @synchronized (self.allTaskDic) {
        switch (task.userParameters.queuePriority) {
            case QUEUE_PRIORITY_HIGH:
                ret = [self.queueHigh enqueue:task insertType:task.userParameters.insertType];
                break;
            case QUEUE_PRIORITY_MID:
                ret = [self.queueMid enqueue:task insertType:task.userParameters.insertType];
                break;
            default:
                ret = [self.queueLow enqueue:task insertType:task.userParameters.insertType];
                break;
        }
        if (ret) {
            [self.allTaskDic setObject:task forKey:task.urlKey];
        }
    }
    /**
     * trigger dequeue
     */
    [self dequeue];
    return ret;
}

- (void)dequeue {
    DLLOGD(@"+++++++dispatcher:dequeue+++++++");
    if ([self isDownloadingDicFull]) {
        DLLOGD(@"+++++++downloading dic full+++++++");
        return;
    }
    TTDispatcherTask *task = nil;
    @synchronized (self.allTaskDic) {
        while (YES) {
            if (nil != (task = [self.queueHigh dequeue])) {
                DLLOGD(@"queueHigh dequeue");
            } else if (nil != (task = [self.queueMid dequeue])) {
                DLLOGD(@"queueMid dequeue");
            } else if (nil != (task = [self.queueLow dequeue])) {
                DLLOGD(@"queueLow dequeue");
            }
            if (!task || ([self.allTaskDic objectForKey:task.urlKey] && !task.isDeleted)) {
                DLLOGD(@"dispatcher:dequeue task.urlKey=%@", task.urlKey);
                break;
            }
        }
    }
    
    if (task) {
        [self addDTaskToDownloadingDic:task];
        if (![self isTaskExist:task]) {
            [self deleteTaskDownloadingDic:task.urlKey];
            return;
        }
        task.onRealTask(task.userParameters);
    }
    DLLOGD(@"dispatcher:debug:1:downloadingDic=%lu,allTaskDic=%lu,queueWait=%lu", (unsigned long)self.downloadingDic.count, self.allTaskDic.count, ([self.queueHigh getQueueTaskCount] + [self.queueMid getQueueTaskCount] + [self.queueLow getQueueTaskCount]));
}

- (void)cancelTask:(TTDispatcherTask *)task {
    if (!task) {
        return;
    }

    [self deleteTaskToAllTaskDic:task.urlKey];
    [self deleteTaskDownloadingDic:task.urlKey];
    task.onRealTask(nil);
}

- (void)deleteTask:(TTDispatcherTask *)task {
    if (!task) {
        return;
    }
    [self deleteTaskDownloadingDic:task.urlKey];
    [self deleteTaskToAllTaskDic:task.urlKey];
    task.onRealTask(nil);
}

- (void)queryTask:(TTDispatcherTask *)task {
    if (!task) {
        return;
    }
    if ([self findDTaskDownloadingDic:task.urlKey]) {
        task.onRealQueryTask(DOWNLOADING);
    } else if ([self isTaskExist:task]) {
        task.onRealQueryTask(QUEUE_WAIT);
    } else {
        task.onRealQueryTask(INIT);
    }
}

- (BOOL)setDownlodingTaskCountMax:(int8_t)taskCount {
    if (taskCount <= 0 || taskCount > kDownloadingTaskValidValueMax) {
        return NO;
    }
    @synchronized (self) {
        int8_t previousTaskMax = self.downloadingTaskMax;
        self.downloadingTaskMax = taskCount;
        
        if (taskCount > previousTaskMax) {
            for (int i = 0; i < (taskCount - previousTaskMax); ++i) {
                [self dequeue];
            }
        }
    }
    
    return YES;
}

- (int8_t)getDownlodingTaskCountMax {
    return self.downloadingTaskMax;
}

- (size_t)getQueueWaitTaskCount {
    return [self.queueLow getQueueTaskCount] + [self.queueMid getQueueTaskCount] + [self.queueHigh getQueueTaskCount];
}

- (BOOL)isResourceDownloading:(NSString *)urlKey {
    if (!urlKey) {
        return NO;
    }
    @synchronized (self.allTaskDic) {
        id ret = [self.allTaskDic objectForKey:urlKey];
        DLLOGD(@"dispatcher:debug2:allTaskDic count=%ld", self.allTaskDic.count);
        return ret ? YES : NO;
    }
}

- (BOOL)setWifiOnlyWithUrlKey:(const NSString *)urlKey isWifiOnly:(const BOOL)isWifiOnly {
    TTDispatcherTask *task = nil;
    @synchronized (self.allTaskDic) {
        task = [self.allTaskDic objectForKey:urlKey];
    }
    if ([self isTaskWaitInQueue:task]) {
        //update memory status
        task.userParameters.isDownloadWifiOnly = isWifiOnly;
            
        //update db status
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[TTDownloadManager shareInstance] setWifiOnlyWithUrlKey:urlKey isWifiOnly:isWifiOnly];
        });
            
        return YES;
    }
    
    //if task is downloading or not exist, we handle it in TTDownloadManager
    return NO;
}

@end

NS_ASSUME_NONNULL_END
