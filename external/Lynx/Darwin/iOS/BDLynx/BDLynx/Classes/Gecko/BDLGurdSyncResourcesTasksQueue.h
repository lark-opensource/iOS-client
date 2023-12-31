//
//  BDLGurdSyncResourcesTasksQueue.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/9.
//

#import <Foundation/Foundation.h>
#import "BDLGurdSyncResourcesTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLGurdSyncResourcesTasksQueue : NSObject

- (BOOL)addTask:(BDLGurdSyncResourcesTask *)task;

- (void)removeTask:(BDLGurdSyncResourcesTask *)task;

- (BOOL)containsTask:(BDLGurdSyncResourcesTask *)task;

- (BDLGurdSyncResourcesTask *)taskForIdentifier:(NSString *)identifier;

- (NSArray<BDLGurdSyncResourcesTask *> *)allTasks;

@end

NS_ASSUME_NONNULL_END
