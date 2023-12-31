//
//  BDPJSRunningThreadAsyncDispatchQueue.m
//  Timor
//
//  Created by dingruoshan on 2019/6/14.
//

#import <pthread.h>
#import "BDPJSRunningThreadAsyncDispatchQueue.h"
//#import "BDPUtils.h"
//#import "BDPTracingManager.h"
#import "OPJSEngineMacroUtils.h"
#import <OPJSEngine/OPJSEngine-Swift.h>
#import <ECOInfra/OPMacroUtils.h>

// 如果代码执行在当前的dispatch queue，则不再dispatch_async，直接执行，否则async一次
@interface BDPJSRunningThreadAsyncDispatchQueue ()
@property (nonatomic, strong, readwrite) BDPJSRunningThread* thread;
@property (nonatomic, assign) pthread_key_t key;
@property (nonatomic, assign) BOOL* pIsInsideQueue;

@property (nonatomic, strong) NSRecursiveLock* lock;
@property (nonatomic, strong) NSMutableArray* blkArr;

@property (nonatomic, assign) NSInteger asyncCallCount;


@end

@implementation BDPJSRunningThreadAsyncDispatchQueue
- (instancetype)initWithThread:(BDPJSRunningThread*)thread
{
    self = [super init];
    if (self) {
        _enableAcceptAsyncCall = YES;
        _thread = thread;
        _pIsInsideQueue = malloc(sizeof(BOOL));
        *_pIsInsideQueue = NO;
        pthread_key_create(&_key, nil);
        
        _lock = [[NSRecursiveLock alloc] init];
        _blkArr = [NSMutableArray array];
        
        OPDebugNSLog(@"[JSAsync Debug] BDPAsyncMergedDispatchQueue init %@",@([self hash]));
    }
    return self;
}

- (void)dealloc
{
    pthread_key_delete(_key);
    if (_pIsInsideQueue) {
        free(_pIsInsideQueue);
        _pIsInsideQueue = nil;
    }
    
    OPDebugNSLog(@"[JSAsync Debug] BDPAsyncMergedDispatchQueue dealloc %@",@([self hash]));
}

- (void)dispatchASync:(dispatch_block_t)blk
{
    dispatch_block_t tracingBlock = [[[OPJSEngineService shared] utils] convertTracingBlock:blk];

    BOOL* pIsRunning = pthread_getspecific(_key);
    if(pIsRunning != nil && (*pIsRunning))
    {
        // js线程中的递归调用
        tracingBlock();
    }
    else if(self.enableAcceptAsyncCall)
    {
        // 这里不能直接使用performSelector的方式传递blk，会有未知的强引用解除不掉，造成内存泄漏，因此使用数组取消息执行的方式实现，防止内存泄漏。
        [_lock lock];
        [_blkArr addObject:tracingBlock];
        [_lock unlock];
        if (!self.thread.forceStopped) {
            [self performSelector:@selector(_innerDispatchedBlockConsumeQueue) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)removeAllAsyncDispatch
{
    [_lock lock];
    [_blkArr removeAllObjects];
    [_lock unlock];
}

- (void)startThread:(BOOL)waitUntilStarted
{
    if (self.thread) {
        [self.thread startThread:waitUntilStarted];
    }
}

- (void)stopThread:(BOOL)waitUntilDone
{
    if (self.thread) {
        if (waitUntilDone) {
            while([_blkArr count] > 0) {
                usleep(1000);
            }
            [self.thread stopThread:waitUntilDone];
        }
        else {
            // 这里抛到队列里执行stop，防止队列中还有未执行完的调用调不到，引起内存泄漏。
            BDPJSRunningThread* thread = self.thread;
            [self dispatchASync:^{
                [[[OPJSEngineService shared] utils] executeOnMainQueue:^{
                    [thread stopThread:waitUntilDone];
                }];
            }];
            // 这里做一个10秒后强制stop的兜底，防止万一没有回收的情况出现。
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [thread stopThread:waitUntilDone];
            });
        }
    }
}

- (void)_innerDispatchedBlockConsumeQueue
{
    *(self.pIsInsideQueue) = YES;
    pthread_setspecific(self.key, self.pIsInsideQueue);
    @autoreleasepool {
        if (!self.thread.forceStopped) {
            dispatch_block_t blk = nil;
            [_lock lock];
            if ([_blkArr count] > 0) {
                blk = [_blkArr firstObject];
                [_blkArr removeObjectAtIndex:0];
            }
            [_lock unlock];
            if (blk) {
                blk();
            }
            _asyncCallCount++;
        }
    }
    *(self.pIsInsideQueue) = NO;
    pthread_setspecific(self.key, self.pIsInsideQueue);
}

@end
