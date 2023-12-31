//
//  BDLGurdSyncResourcesManager.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/9.
//

#import "BDLGurdSyncResourcesManager.h"
#import "BDLGeckoProtocol.h"
#import "BDLGurdSyncResourcesTasksQueue.h"
#import "BDLHostProtocol.h"
#import "BDLSDKManager.h"
#import "BDLSDKProtocol.h"

static BOOL kBDLGurdSyncResourcesDidCreateBootTask = NO;
static BOOL kBDLGurdSyncResourcesDidExecuteBootTask = NO;
static BOOL kBDLGurdSyncHighPriorityResourcesIfNeeded = NO;

@interface BDLGurdSyncResourcesTask ()

@property(nonatomic, readwrite, assign, getter=isExecuting) BOOL executing;

@end

@interface BDLGurdSyncResourcesManager ()

@property(nonatomic, strong) BDLGurdSyncResourcesTasksQueue *waitingTasksQueue;

@property(nonatomic, strong) BDLGurdSyncResourcesTasksQueue *executedTasksQueue;

@end

@implementation BDLGurdSyncResourcesManager

+ (BDLGurdSyncResourcesManager *)sharedManager {
  static BDLGurdSyncResourcesManager *manager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    manager = [[self alloc] init];
    [self enableGurd];
  });
  return manager;
}

#pragma mark - Public
+ (void)enqueueSyncResourcesTask:(BDLGurdSyncResourcesTask *)task {
  if (![[self sharedManager] _shouldExecuteWithTask:task]) {  // 已经执行过了
    return;
  }

  BOOL forceRequest = [task forceRequest];
  if (forceRequest) {
    BDLGurdSyncResourcesTask *waitingTask =
        [[self sharedManager] _waitingTaskForIdentifier:task.identifier];
    if ([waitingTask forceRequest]) {  // 已经添加强制执行的任务
      return;
    }
    if (waitingTask.isExecuting) {  // 非强制执行任务已经在执行了
      return;
    }
    if (waitingTask) {  // 删除非强制执行的任务
      [[self sharedManager] _cancelWaitingTask:waitingTask];
    }
  }

  if (![[self sharedManager] _enqueueSyncResourcesTask:task]) {
    return;
  }

  NSString *accessKey = [BDL_SERVICE(BDLGeckoProtocol) accessKey];
  [BDL_SERVICE(BDLGeckoProtocol) registerChannels:task.channelsArray
                                     forAccessKey:task.accessKey ?: accessKey];

  if (forceRequest) {
    [[self sharedManager] _syncResourcesWithTask:task];
    return;
  }
  [self syncResourcesIfNeeded];
}

static BOOL kBDLGurdSyncResourcesEnabled = NO;
+ (void)enableGurd {
  kBDLGurdSyncResourcesEnabled = YES;
}

+ (void)syncResourcesIfNeeded {
  if (!kBDLGurdSyncResourcesEnabled) {
    return;
  }

  if ([BDL_SERVICE_WITH_SELECTOR(BDLSDKProtocol, @selector(disableDownloadTemplate))
          disableDownloadTemplate]) {
    return;
  }
  if (!kBDLGurdSyncHighPriorityResourcesIfNeeded) {
    kBDLGurdSyncHighPriorityResourcesIfNeeded = YES;
  }

  BOOL isStartUpFirstTime = [BDL_SERVICE(BDLSDKProtocol) isStartUpFirstTime];
  if (!isStartUpFirstTime) {
    kBDLGurdSyncResourcesDidCreateBootTask = YES;
    NSUInteger delaySyncTime = 10 * 1000;  // 默认10s
    delaySyncTime = [BDL_SERVICE(BDLGeckoProtocol) normalPolicyDelaySyncTime] ?: delaySyncTime;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)((delaySyncTime / 1000) * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          kBDLGurdSyncResourcesDidExecuteBootTask = YES;
          [[self sharedManager] _syncResourcesIfNeeded];
        });
  } else {
    [[self sharedManager] _syncResourcesIfNeeded];
  }
}

#pragma mark - Private - Queue

- (BDLGurdSyncResourcesTask *)_waitingTaskForIdentifier:(NSString *)identifier {
  return [self.waitingTasksQueue taskForIdentifier:identifier];
}

- (BOOL)_enqueueSyncResourcesTask:(BDLGurdSyncResourcesTask *)task {
  return [self.waitingTasksQueue addTask:task];
}

- (void)_cancelWaitingTask:(BDLGurdSyncResourcesTask *)task {
  [self.waitingTasksQueue removeTask:task];
}

- (BOOL)_shouldExecuteWithTask:(BDLGurdSyncResourcesTask *)task {
  return ![self.executedTasksQueue containsTask:task];
}

#pragma mark - Private - Sync Resources

static BOOL kAWEGurdCanSyncResources = YES;
- (void)_syncResourcesIfNeeded {
  // 防止 _syncResources 频繁调用
  if (!kAWEGurdCanSyncResources) {
    return;
  }
  [self _syncResources];
  kAWEGurdCanSyncResources = YES;
}

- (void)_syncResources {
  NSArray<BDLGurdSyncResourcesTask *> *waitingTasks = [self.waitingTasksQueue allTasks];
  [waitingTasks
      enumerateObjectsUsingBlock:^(BDLGurdSyncResourcesTask *task, NSUInteger idx, BOOL *stop) {
        if (task.isExecuting) {
          return;
        }
        BOOL isHighPriorityTask = task.options & BDLGurdSyncResourcesOptionsHighPriority;
        if (kBDLGurdSyncHighPriorityResourcesIfNeeded && isHighPriorityTask) {
          // 高优任务
          [self _syncResourcesWithTask:task];
          return;
        }

        BOOL delayRequest =
            (kBDLGurdSyncResourcesDidCreateBootTask && !kBDLGurdSyncResourcesDidExecuteBootTask);
        BOOL isUrgentTask = task.options & BDLGurdSyncResourcesOptionsUrgent;
        if (!isUrgentTask && delayRequest) {
          return;
        }
        [self _syncResourcesWithTask:task];
      }];
}

- (void)_syncResourcesWithTask:(BDLGurdSyncResourcesTask *)task {
  task.executing = YES;

  BDLGurdSyncStatusDictionaryBlock completion =
      ^(BOOL succeed, NSDictionary<NSString *, NSNumber *> *dict) {
        task.executing = NO;
        if (task.completion) {
          task.completion(succeed, dict);
        }
        [self.waitingTasksQueue removeTask:task];

        if (!succeed) {
          return;
        }

        BOOL disableThrottle = task.options & BDLGurdSyncResourcesOptionsDisableThrottle;
        if (!disableThrottle) {
          [self.executedTasksQueue addTask:task];
          // 十分钟后再移除
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(600 * NSEC_PER_SEC)),
                         dispatch_get_main_queue(), ^{
                           [self.executedTasksQueue removeTask:task];
                         });
        }
      };

  NSString *accessKey = [BDL_SERVICE(BDLGeckoProtocol) accessKey];
  if ([BDL_SERVICE(BDLGeckoProtocol)
          respondsToSelector:@selector
          (syncResourcesWithAccessKey:
                             channels:resourceVersion:businessDomain:forceSync:completion:)]) {
    [BDL_SERVICE(BDLGeckoProtocol)
        syncResourcesWithAccessKey:task.accessKey ?: accessKey
                          channels:task.channelsArray
                   resourceVersion:task.resourceVersion
                    businessDomain:task.businessDomain
                         forceSync:(task.options & BDLGurdSyncResourcesOptionsForceRequest)
                        completion:completion];
  } else if ([BDL_SERVICE(BDLGeckoProtocol)
                 respondsToSelector:@selector
                 (syncResourcesWithAccessKey:
                                    channels:resourceVersion:businessDomain:completion:)]) {
    [BDL_SERVICE(BDLGeckoProtocol) syncResourcesWithAccessKey:task.accessKey ?: accessKey
                                                     channels:task.channelsArray
                                              resourceVersion:task.resourceVersion
                                               businessDomain:task.businessDomain
                                                   completion:completion];
  }
}

#pragma mark - Getter

- (BDLGurdSyncResourcesTasksQueue *)waitingTasksQueue {
  if (!_waitingTasksQueue) {
    _waitingTasksQueue = [[BDLGurdSyncResourcesTasksQueue alloc] init];
  }
  return _waitingTasksQueue;
}

- (BDLGurdSyncResourcesTasksQueue *)executedTasksQueue {
  if (!_executedTasksQueue) {
    _executedTasksQueue = [[BDLGurdSyncResourcesTasksQueue alloc] init];
  }
  return _executedTasksQueue;
}

@end
