//
//  BDLGurdSyncResourcesTasksQueue.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/9.
//

#import "BDLGurdSyncResourcesTasksQueue.h"

@interface BDLGurdSyncResourcesTasksQueue ()

@property(nonatomic, strong)
    NSMutableDictionary<NSString *, BDLGurdSyncResourcesTask *> *tasksDictionary;
@property(nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation BDLGurdSyncResourcesTasksQueue

- (BOOL)addTask:(BDLGurdSyncResourcesTask *)task {
  NSString *identifier = task.identifier;
  NSArray<NSString *> *channels = task.channelsArray;
  if (identifier.length == 0 || channels.count == 0) {
    return NO;
  }

  BOOL add = NO;
  dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
  if (!self.tasksDictionary[identifier]) {
    self.tasksDictionary[identifier] = task;
    add = YES;
  }
  dispatch_semaphore_signal(self.lock);

  return add;
}

- (void)removeTask:(BDLGurdSyncResourcesTask *)task {
  NSString *identifier = task.identifier;
  if (identifier.length == 0) {
    return;
  }

  dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
  [self.tasksDictionary removeObjectForKey:identifier];
  dispatch_semaphore_signal(self.lock);
}

- (BOOL)containsTask:(BDLGurdSyncResourcesTask *)task {
  NSString *identifier = task.identifier;
  if (identifier.length == 0) {
    return NO;
  }

  BOOL contains = NO;
  dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
  contains = !!self.tasksDictionary[identifier];
  dispatch_semaphore_signal(self.lock);
  return contains;
}

- (BDLGurdSyncResourcesTask *)taskForIdentifier:(NSString *)identifier {
  if (identifier.length == 0) {
    return nil;
  }

  BDLGurdSyncResourcesTask *task = nil;
  dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
  task = self.tasksDictionary[identifier];
  dispatch_semaphore_signal(self.lock);
  return task;
}

- (NSArray<BDLGurdSyncResourcesTask *> *)allTasks {
  NSArray<BDLGurdSyncResourcesTask *> *tasks = nil;
  dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
  tasks = self.tasksDictionary.allValues;
  dispatch_semaphore_signal(self.lock);
  return tasks;
}

- (NSMutableDictionary<NSString *, BDLGurdSyncResourcesTask *> *)tasksDictionary {
  if (!_tasksDictionary) {
    _tasksDictionary = [NSMutableDictionary dictionary];
  }
  return _tasksDictionary;
}

- (dispatch_semaphore_t)lock {
  if (!_lock) {
    _lock = dispatch_semaphore_create(1);
  }
  return _lock;
}

@end
