//
//  BDXGurdSyncManager.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXGurdSyncManager.h"
#import "BDXGurdService.h"
#import "BDXGurdSyncTask.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <pthread/pthread.h>
#import <IESGeckoKit/IESGeckoKit.h>

#ifndef BDXRES_MUTEX_LOCK
#define BDXRES_MUTEX_LOCK(lock)  \
    pthread_mutex_lock(&(lock)); \
    @onExit { pthread_mutex_unlock(&(lock)); };
#endif

static BOOL kBDXGurdSyncResourcesDidCreateBootTask = NO;
static BOOL kBDXGurdSyncResourcesDidExecuteBootTask = NO;
static BOOL kBDXGurdSyncHighPriorityResourcesIfNeeded = NO;

@interface BDXGurdSyncTask ()

@property(atomic, readwrite, assign) BDXGurdSyncTaskState state;

@end

@interface BDXGurdSyncManager ()

@property(nonatomic, strong) NSMutableArray<BDXGurdSyncTask *> *waitingTasksQueue;

@end

@implementation BDXGurdSyncManager

static pthread_mutex_t kTasksLock = PTHREAD_MUTEX_INITIALIZER;

+ (BDXGurdSyncManager *)sharedManager
{
    static BDXGurdSyncManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.waitingTasksQueue = [NSMutableArray array];
    });
    return manager;
}

#pragma mark - Public

static BOOL kBDXGurdSyncResourcesEnabled = YES;
+ (void)enableGurd
{
    kBDXGurdSyncResourcesEnabled = YES;
}

+ (void)enableHighPrioritySync
{
    kBDXGurdSyncHighPriorityResourcesIfNeeded = YES;
}

+ (void)disableGurd
{
    kBDXGurdSyncResourcesEnabled = NO;
}

+ (void)enqueueSyncResourcesTask:(BDXGurdSyncTask *)task
{
    BDXGurdSyncTask *waitingTask = [[self sharedManager] _waitingTaskForTask:task];
    BOOL forceRequest = task.forceRequest;
    if (forceRequest) {
        if (waitingTask.forceRequest) { //已经添加强制执行的任务
            return;
        }
        if (waitingTask.isExecuting) { //非强制执行任务已经在执行了
            return;
        }
        if (waitingTask) { //删除非强制执行的任务
            [[self sharedManager] _cancelWaitingTask:waitingTask];
            [task addCompletionOfTask:waitingTask];
            waitingTask = nil;
        }
    }

    if (waitingTask) {
        [waitingTask addCompletionOfTask:task];
        return;
    }
    [[self sharedManager] _enqueueSyncResourcesTask:task];

    NSAssert(task.accessKey, @"BDXGurdSyncTask should set accessKey.");

    [BDXGurdService registerAccessKey:task.accessKey];

    if (forceRequest) {
        NSString *deviceID = [IESGeckoKit deviceID];
        if (!BTD_isEmptyString(deviceID)) {
            [[self sharedManager] _syncResourcesWithTask:task];
        }
        return;
    }
    [self syncResourcesIfNeeded];
}

+ (void)syncResourcesIfNeeded
{
    if (!kBDXGurdSyncResourcesEnabled) {
        return;
    }

    [[self sharedManager] _syncResourcesIfNeeded];
}

#pragma mark - Private - Queue

- (BDXGurdSyncTask *)_waitingTaskForTask:(BDXGurdSyncTask *)task
{
    BDXRES_MUTEX_LOCK(kTasksLock);
    NSInteger index = [self.waitingTasksQueue indexOfObject:task];
    return (index == NSNotFound) ? nil : self.waitingTasksQueue[index];
}

- (BOOL)_enqueueSyncResourcesTask:(BDXGurdSyncTask *)task
{
    BDXRES_MUTEX_LOCK(kTasksLock);
    if ([self.waitingTasksQueue containsObject:task]) {
        return NO;
    }
    [self.waitingTasksQueue btd_addObject:task];
    return YES;
}

- (void)_cancelWaitingTask:(BDXGurdSyncTask *)task
{
    BDXRES_MUTEX_LOCK(kTasksLock);
    [self.waitingTasksQueue removeObject:task];
}

#pragma mark - Private - Sync Resources

static BOOL kBDXGurdCanSyncResources = YES;
- (void)_syncResourcesIfNeeded
{
    //防止 _syncResources 频繁调用
    if (!kBDXGurdCanSyncResources) {
        return;
    }
    kBDXGurdCanSyncResources = NO;
    NSString *deviceID = [IESGeckoKit deviceID];

    if (!BTD_isEmptyString(deviceID)) {
        [self _syncResources];
        kBDXGurdCanSyncResources = YES;
    }
}

- (void)_syncResources
{
    pthread_mutex_lock(&kTasksLock);
    NSArray<BDXGurdSyncTask *> *waitingTasks = [self.waitingTasksQueue copy];
    pthread_mutex_unlock(&kTasksLock);

    [waitingTasks enumerateObjectsUsingBlock:^(BDXGurdSyncTask *task, NSUInteger idx, BOOL *stop) {
        if (task.state != BDXGurdSyncTaskStateWaiting) {
            return;
        }
        BOOL isHighPriorityTask = task.options & BDXGurdSyncResourcesOptionsHighPriority;
        if (kBDXGurdSyncHighPriorityResourcesIfNeeded && isHighPriorityTask) {
            //高优任务
            [self _syncResourcesWithTask:task];
            return;
        }

        BOOL delayRequest = (kBDXGurdSyncResourcesDidCreateBootTask && !kBDXGurdSyncResourcesDidExecuteBootTask);
        BOOL isUrgentTask = task.options & BDXGurdSyncResourcesOptionsUrgent;
        if (delayRequest && !isUrgentTask) {
            return;
        }
        [self _syncResourcesWithTask:task];
    }];
}

- (void)_syncResourcesWithTask:(BDXGurdSyncTask *)task
{
    task.state = BDXGurdSyncTaskStateExecuting;
    IESGurdSyncStatusDictionaryBlock completion = ^(BOOL succeed, IESGurdSyncStatusDict _Nonnull dict) {
        pthread_mutex_lock(&kTasksLock);
        task.state = BDXGurdSyncTaskStateFinished;
        [self.waitingTasksQueue removeObject:task];
        pthread_mutex_unlock(&kTasksLock);
        BOOL disableThrottle = task.options && BDXGurdSyncResourcesOptionsDisableThrottle;
        task.disableThrottle = disableThrottle;

        BDXGurdSyncResourcesResult *result = [[BDXGurdSyncResourcesResult alloc] init];
        result.successfully = succeed;
        result.info = dict;
        result.throttled = [BDXGurdService isRequestThrottledWithStatusDictionary:dict];
        [task callCompletionsWithResult:result];
    };
    [BDXGurdService syncResourcesWithTask:task completion:completion];
}

@end
