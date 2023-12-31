//
//  HTSBootGroup.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/15.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootNodeGroup.h"

static inline void _runTaskList(HTSBootNodeList * list){
    for (HTSBootNode * task in list) {
        [task run];
    }
};

@interface HTSBootNodeGroup()

@property (strong, nonatomic) HTSBootNodeList * syncList;
@property (strong, nonatomic) HTSBootNodeList * asyncList;
@property (assign, nonatomic) BOOL canRunned;

@end

@implementation HTSBootNodeGroup

- (instancetype)initWithSyncList:(HTSBootNodeList *)syncList
                       asyncList:(HTSBootNodeList *)asnycList{
    if (self = [super init]) {
        _syncList = syncList;
        _asyncList = asnycList;
        _canRunned = NO;
    }
    return self;
}

- (BOOL)isMainThread{
    return YES;
}

- (void)run{
    @synchronized (self) {
        if (self.canRunned) {
            return;
        }
        self.canRunned = YES;
    }
    //高优队列，优先保证启动
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.servicekit.group.queue", attr);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(backgroundQueue, ^{
        _runTaskList(self.asyncList);
        dispatch_semaphore_signal(semaphore);
    });
    _runTaskList(self.syncList);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

@end
