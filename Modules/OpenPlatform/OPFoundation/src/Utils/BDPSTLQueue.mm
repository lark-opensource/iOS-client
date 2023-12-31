//
//  BDPSTLQueue.mm
//  Timor
//
//  Created by 王浩宇 on 2018/12/23.
//

#import "BDPSTLQueue.h"
#import <iostream>
#import <queue>

@interface BDPSTLQueue ()
{
    std::queue<id> *_queue;
    NSRecursiveLock *_lock;
}
@end

@implementation BDPSTLQueue

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)init
{
    self = [super init];
    if (self) {
        self->_queue = new std::queue<id>;
        self->_lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self->_lock lock];
    if (self->_queue != nullptr) {
        delete self->_queue;
        self->_queue = nullptr;
    }
    [self->_lock unlock];
}

#pragma mark - Queue Operate
/*-----------------------------------------------*/
//            Queue Operate - 队列操作
/*-----------------------------------------------*/
- (void)enqueue:(id)object
{
    if (self->_queue != nullptr && object) {
        [self->_lock lock];
        self->_queue->push(object);
        [self->_lock unlock];
    }
}

- (id)dequeue
{
    id object = nil;
    if (self->_queue != nullptr) {
        [self->_lock lock];
        if (!self->_queue->empty()) {
            object = self->_queue->front();
            self->_queue->pop();
        }
        [self->_lock unlock];
    }
    return object;
}

- (void)clear
{
    if (self->_queue != nullptr) {
        [self->_lock lock];
        if (!self->_queue->empty()) {
            std::queue<id> empty;
            std::swap(empty, *self->_queue);
        }
        [self->_lock unlock];
    }
}

- (BOOL)empty
{
    BOOL isEmpty = YES;
    if (self->_queue != nullptr) {
        [self->_lock lock];
        isEmpty = self->_queue->empty();
        [self->_lock unlock];
    }
    return isEmpty;
}

- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(id object, BOOL *stop))block
{
    if (self->_queue != nullptr && block) {
        BOOL stop = NO;
        [self->_lock lock];
        while (!self->_queue->empty()) {
            @autoreleasepool {
                block(self->_queue->front(), &stop);
                self->_queue->pop();
                if (stop) {
                    break;
                }
            }
        }
        [self->_lock unlock];
    }
}

@end
