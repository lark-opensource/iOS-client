#import "TTQueue.h"
#import "TTDownloadLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTQueue()
@property (atomic, strong) NSMutableArray *array;
@property (atomic, assign) NSInteger queueSizeMax;
@end

@implementation TTQueue

- (id)initWhithSize:(NSInteger)queueSizeMax {
    self = [super init];
    if (self) {
        if (queueSizeMax <= 2) {
            NSException *exception = [NSException exceptionWithName: @"queueSizeMaxException"
                                                             reason: @"queueSizeMax must greater than 2"
                                                           userInfo: nil];
            @throw exception;
        }
        self.array = [[NSMutableArray alloc] init];
        self.queueSizeMax = queueSizeMax;
    }
    return self;
}

- (BOOL)enqueue:(id)task insertType:(InsertType)insertType {
    if (!task) {
        return NO;
    }

    @synchronized (self.array) {
        if (self.array.count >= self.queueSizeMax) {
            return NO;
        }
        DLLOGD(@"insertObject");
        if (QUEUE_HEAD == insertType) {
            [self.array insertObject:task atIndex:0];
        } else {
            [self.array addObject:task];
        }
        DLLOGD(@"dispatcher:debug:enqueueTask count=%ld", self.array.count);
    }
    return YES;
}

- (id)dequeue {
    @synchronized (self.array) {
        if (self.array.count == 0) {
            DLLOGD(@"queue is null");
            return nil;
        }
        id task = [self.array firstObject];
        if (task) {
            [self.array removeObjectAtIndex:0];
            DLLOGD(@"dispatcher:debug:waitTask count=%ld", self.array.count);
        }
        return task;
    }
}

- (NSInteger)getQueueTaskCount {
    @synchronized (self.array) {
        return self.array.count;
    }
}

- (NSInteger)getQueueSizeMax {
    return self.queueSizeMax;
}

- (BOOL)isQueueFull {
    @synchronized (self.array) {
        return self.array.count == self.queueSizeMax;
    }
}
@end

NS_ASSUME_NONNULL_END
