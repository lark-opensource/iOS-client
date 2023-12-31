//
//  HTSBootLoader.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootLoader.h"
#import "HTSBootNodeGroup.h"
#import "HTSBootConfiguration.h"
#import "HTSAppContext.h"
#import "HTSBootLoader.h"

#define HTS_BOOT_ASSERT_MAIN NSAssert([NSThread isMainThread],@"Method should invoke on main thread");

/// 暂时拷贝一份，因为迁移过后基类会被删除
static inline void dispatch_async_safe(dispatch_queue_t queue, void (^block)(void)){
    if (!block) {
        return;
    }
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {
        block();
    } else {
        dispatch_async(queue, block);
    }
};

@interface _HTSBootBlockNode: NSObject<HTSBootNode>

@property (copy, nonatomic) void(^block)(void);
@property (assign, nonatomic) BOOL isMainThread;
@end

@implementation _HTSBootBlockNode

- (instancetype)initWithBlock:(void (^)(void))block mainThread:(BOOL)isMainThread{
    if (self = [super init]) {
        _block = block;
        _isMainThread = isMainThread;
    }
    return self;
}

- (void)run{
    if (!self.block) {
        return;
    }
    self.block();
}

@end

@interface _HTSBootDelayQueue<ObjectType> : NSObject

@property (strong, nonatomic) NSMutableArray<ObjectType> * mainTasks;
@property (strong, nonatomic) NSMutableArray<ObjectType> * backgroundTasks;

@end

@implementation _HTSBootDelayQueue

- (instancetype)init{
    if (self = [super init]) {
        _mainTasks = [[NSMutableArray alloc] init];
        _backgroundTasks = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

typedef NS_ENUM(NSInteger,HTSBootDelayStage){
    HTSBootDelayStageEnterFourground,
    HTSBootDelayStageFeedReady,
    HTSBootDelayStageLaunchCompletion,
};

static void HTSRunNode(id<HTSBootNode> node, NSOperationQueue* bgQueue){
    if (node.isMainThread) {
        [node run];
    }else{
        [bgQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [node run];
        }]];
    }
}

static void HTSRunNodeGroup(HTSBootNodeList* group, NSOperationQueue* bgQueue){
    for (id<HTSBootNode>node in group) {
        HTSRunNode(node, bgQueue);
    }
}

static void HTSRunNodeGroupAlwaysWithQueue(HTSBootNodeList* group, NSOperationQueue* bgQueue){
    for (id<HTSBootNode>node in group) {
        NSOperationQueue *queue = node.isMainThread ? NSOperationQueue.mainQueue: bgQueue;
        [queue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [node run];
        }]];
    }
}

@interface HTSBootLoader()

@property (assign, nonatomic) BOOL isSuspend;
@property (assign, nonatomic) BOOL canSuspend;
@property (strong, nonatomic) NSOperationQueue * lowQosQueue;
@property (strong, nonatomic) NSOperationQueue * highQosQueue;
@property (strong, nonatomic) HTSBootConfiguration * configuration;
@property (strong, nonatomic) _HTSBootDelayQueue<_HTSBootBlockNode *> * feedReadyDelayQueue;
@property (strong, nonatomic) _HTSBootDelayQueue<_HTSBootBlockNode *> * launchCompletionQueue;
@property (strong, nonatomic) _HTSBootDelayQueue<_HTSBootBlockNode *> * fourgroundDelayQueue;

@end

@implementation HTSBootLoader

+ (instancetype)sharedLoader{
    static dispatch_once_t onceToken;
    static HTSBootLoader * _instance;
    dispatch_once(&onceToken, ^{
        _instance = [[HTSBootLoader alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _canSuspend = YES;
        NSUInteger coreCount = [NSProcessInfo processInfo].activeProcessorCount;
        NSInteger maxConcurrent = MIN(coreCount, 4);
        _lowQosQueue = [[NSOperationQueue alloc] init];
        _lowQosQueue.qualityOfService = NSQualityOfServiceBackground;
        _lowQosQueue.maxConcurrentOperationCount = maxConcurrent;
        _highQosQueue = [[NSOperationQueue alloc] init];
        _highQosQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        _highQosQueue.maxConcurrentOperationCount = maxConcurrent;
        _feedReadyDelayQueue = [[_HTSBootDelayQueue alloc] init];
        _launchCompletionQueue = [[_HTSBootDelayQueue alloc] init];
        _fourgroundDelayQueue = [[_HTSBootDelayQueue alloc] init];
    }
    return self;
}

- (void)bootWithConfig:(NSDictionary *)config{
    HTS_BOOT_ASSERT_MAIN;
    if (!config.allKeys.count) {
        return;
    }
    self.configuration = [[HTSBootConfiguration alloc] initWithConfiguration:config];
    [self boot];
}

- (void)boot{
    HTS_BOOT_ASSERT_MAIN;
    for (id<HTSBootNode> node in self.configuration.foundationList) {
        HTSRunNode(node,self.highQosQueue);
        if (self.isSuspend) {
            return;
        }
    }
    self.canSuspend = NO;
    if (HTSCurrentContext().backgroundLaunch) {
        //只有后台启动执行的任务
        HTSRunNodeGroup(self.configuration.backgroundList, self.highQosQueue);
    }
}

- (void)resume{
    HTS_BOOT_ASSERT_MAIN;
    if (!self.isSuspend) {
        return;
    }
    self.isSuspend = NO;
    //重新启动，node层面保证只会执行一次
    [self boot];
}

- (BOOL)suspend{
    HTS_BOOT_ASSERT_MAIN;
    if (self.isSuspend) {
        return YES;
    }
    if (!self.canSuspend) {
        return NO;
    }
    self.isSuspend = YES;
    return YES;
}

#pragma mark - Private

static CFIndex const kCARunLoopObserverOrder = 2000000;

- (void)_observerRunloopFree:(void(^)(void))block{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFStringRef runLoopMode = kCFRunLoopDefaultMode;
    __block CFRunLoopObserverRef observer;
    observer = CFRunLoopObserverCreateWithHandler
    (kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, kCARunLoopObserverOrder, ^(CFRunLoopObserverRef ob, CFRunLoopActivity _) {
        block();
        CFRunLoopRemoveObserver(runLoop, ob, runLoopMode);
        CFRelease(observer);
    });
    CFRunLoopAddObserver(runLoop, observer, runLoopMode);
}

- (void)_runFirstEnterFourground{
    HTS_BOOT_ASSERT_MAIN;
    _HTSBootDelayQueue * queue;
    @synchronized (self) {
        queue = self.fourgroundDelayQueue;
        self.fourgroundDelayQueue = nil;
    }
    HTSRunNodeGroup(queue.backgroundTasks, self.highQosQueue);
    HTSRunNodeGroup(self.configuration.firstFourgroundList, self.highQosQueue);
    HTSRunNodeGroup(queue.mainTasks, self.highQosQueue);
}

- (void)_runLaunchCompletion{
    HTS_BOOT_ASSERT_MAIN;
    _HTSBootDelayQueue * queue;
    @synchronized (self) {
        queue = self.launchCompletionQueue;
        self.launchCompletionQueue = nil;
    }
    HTSRunNodeGroup(self.configuration.afterLaunchNowList, self.lowQosQueue);
    HTSRunNodeGroup(queue.mainTasks, self.lowQosQueue);
    [self _observerRunloopFree:^{
        BOOL oneTaskPerRunloop = [HTSCurrentContext().appDelegate runOneBootTaskPerRunloop];
        if (oneTaskPerRunloop) {
            HTSRunNodeGroupAlwaysWithQueue(self.configuration.afterLaunchIdleList, self.lowQosQueue);
            HTSRunNodeGroupAlwaysWithQueue(queue.backgroundTasks, self.lowQosQueue);
            return;;
        }
        HTSRunNodeGroup(self.configuration.afterLaunchIdleList, self.lowQosQueue);
        HTSRunNodeGroup(queue.backgroundTasks, self.lowQosQueue);
    }];
}

- (void)_runFeedReady{
    HTS_BOOT_ASSERT_MAIN;
    _HTSBootDelayQueue * queue;
    @synchronized (self) {
        queue = self.feedReadyDelayQueue;
        self.feedReadyDelayQueue = nil;
    }
    HTSRunNodeGroup(self.configuration.feedReadyNowList, self.lowQosQueue);
    HTSRunNodeGroup(queue.mainTasks, self.lowQosQueue);
    [self _observerRunloopFree:^{
        BOOL oneTaskPerRunloop = [HTSCurrentContext().appDelegate runOneBootTaskPerRunloop];
        if (oneTaskPerRunloop) {
            HTSRunNodeGroupAlwaysWithQueue(self.configuration.feedReadyIdleList, self.lowQosQueue);
            HTSRunNodeGroupAlwaysWithQueue(queue.backgroundTasks, self.lowQosQueue);
            return;
        }
        HTSRunNodeGroup(self.configuration.feedReadyIdleList, self.lowQosQueue);
        HTSRunNodeGroup(queue.backgroundTasks, self.lowQosQueue);
    }];
}

- (void)_runOrDelayTaskOfStage:(HTSBootDelayStage)stage thread:(HTSBootThread)thread block:(void(^)(void))block{
    if (!block) {
        return;
    }
    @synchronized (self) {
        _HTSBootDelayQueue * queue;
        if (stage == HTSBootDelayStageFeedReady) {
            queue = self.feedReadyDelayQueue;
        }else if(stage == HTSBootDelayStageEnterFourground){
            queue = self.fourgroundDelayQueue;
        }else{
            queue = self.launchCompletionQueue;
        }
        if (queue) {
            BOOL isMainThread = (thread == HTSBootThreadMain);
            _HTSBootBlockNode * node = [[_HTSBootBlockNode alloc] initWithBlock:block mainThread:isMainThread];
            if (isMainThread) {
                [queue.mainTasks addObject:node];
            }else{
                [queue.backgroundTasks addObject:node];
            }
            return;
        }
    }
    if (thread == HTSBootThreadMain) {
        dispatch_async_safe(dispatch_get_main_queue(),block);
    }else{
        block();
    }
}

@end

FOUNDATION_EXPORT void _HTSBootNotifyFirstEnterFourground(){
    [[HTSBootLoader sharedLoader] _runFirstEnterFourground];
}

static BOOL _shouldDelayLaunchCompletionTask(){
    static BOOL _shouldDelay;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shouldDelay = HTSCurrentContext().appDelegate.delayLaunchCompletionTaskUntilFeedReady;
    });
    return _shouldDelay;
}

FOUNDATION_EXPORT void HTSBootMarkFeedReady(void){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_shouldDelayLaunchCompletionTask()) {
            [[HTSBootLoader sharedLoader] _runLaunchCompletion];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[HTSBootLoader sharedLoader] _runFeedReady];
            });
        }else{
            [[HTSBootLoader sharedLoader] _runFeedReady];
        }
    });
}

FOUNDATION_EXPORT void HTSBootMarkLaunchCompletion(void){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_shouldDelayLaunchCompletionTask()) {
            return;
        }
        [[HTSBootLoader sharedLoader] _runLaunchCompletion];
    });
}

FOUNDATION_EXPORT void HTSBootRunFeedReady(HTSBootThread thread, void(^block)(void)){
    [[HTSBootLoader sharedLoader] _runOrDelayTaskOfStage:HTSBootDelayStageFeedReady thread:thread block:block];
}

FOUNDATION_EXPORT void HTSBootRunLaunchCompletion(HTSBootThread thread,void(^block)(void)){
    [[HTSBootLoader sharedLoader] _runOrDelayTaskOfStage:HTSBootDelayStageLaunchCompletion thread:thread block:block];
}
FOUNDATION_EXPORT void HTSBootRunNowOrEnterForground(HTSBootThread thread,void(^block)(void)){
    [[HTSBootLoader sharedLoader] _runOrDelayTaskOfStage:HTSBootDelayStageEnterFourground thread:thread block:block];
}
