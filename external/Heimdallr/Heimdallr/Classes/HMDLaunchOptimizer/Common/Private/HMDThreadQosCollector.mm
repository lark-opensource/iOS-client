//
//  HMDThreadQosCollector.cpp
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/5/11.
//

#import "HMDThreadQosCollector.h"
#import <Foundation/Foundation.h>
#import <atomic>
#import "HMDDispatchNode.hpp"
#import <BDFishhook/BDFishhook.h>
#import "HMDQoSMockerConfig.hpp"
#import "HMDALogProtocol.h"
#import <memory>
#import "pthread_extended.h"
#import "HMDDynamicCall.h"
#import "NSArray+HMDSafe.h"
#import "HMDServiceContext.h"

// key queue 采集有效次数
static const NSInteger kHMDKeyQueueCollectCount = 3;

#pragma mark - Hooked functions

#pragma mark dispatch_xx


static dispatch_block_t dispatch_is_calling(dispatch_queue_t queue, dispatch_block_t block) {
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
        return block;
    }
    std::shared_ptr<HMDDispatchNode> node = current_thread_dispatch_node();
    dispatch_block_t new_block = ^{
        update_current_thread_dispatch_node_list_by_copy(node, dispatch_queue_get_label(queue));
        block();
        remove_current_thread_dispatch_node_list_last();
    };
    return new_block;
}

static void (*orig_dispatch_async)(dispatch_queue_t queue, dispatch_block_t block);
static void hooked_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
    @autoreleasepool {
        orig_dispatch_async(queue, dispatch_is_calling(queue, block));
    }
}

static void
(*orig_dispatch_group_async)(dispatch_group_t group,
                     dispatch_queue_t queue,
                             dispatch_block_t block);
static void
hooked_dispatch_group_async(dispatch_group_t group,
                     dispatch_queue_t queue,
                     dispatch_block_t block) {
    @autoreleasepool {
        orig_dispatch_group_async(group, queue, dispatch_is_calling(queue, block));
    }
}

static void
(*orig_dispatch_barrier_async)(dispatch_queue_t queue, dispatch_block_t block);
static void
hooked_dispatch_barrier_async(dispatch_queue_t queue, dispatch_block_t block) {
    @autoreleasepool {
        orig_dispatch_barrier_async(queue, dispatch_is_calling(queue, block));
    }
}

static void
(*orig_dispatch_after)(dispatch_time_t when, dispatch_queue_t queue,
                       dispatch_block_t block);
static void
hooked_dispatch_after(dispatch_time_t when, dispatch_queue_t queue,
               dispatch_block_t block) {
    @autoreleasepool {
        orig_dispatch_after(when, queue, dispatch_is_calling(queue, block));
    }
}

#pragma mark dispatch_xx_f

struct HMDWorkContext {
    void *function = nullptr;
    void *context = nullptr;
    std::shared_ptr<HMDDispatchNode> node = nullptr;
    dispatch_queue_t queue = 0;
};

struct HMDWorkContext *dispatch_node_context(void *function, void *context, dispatch_queue_t queue) {
    HMDWorkContext *workContext = new HMDWorkContext();
    workContext->function = function;
    workContext->context = context;
    workContext->node = current_thread_dispatch_node();
    workContext->queue = queue;
    return workContext;
}

static void dispatch_calling_work(HMDWorkContext *context) {
    dispatch_function_t function = (dispatch_function_t)context->function;
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
        function(context->context);
        delete context;
        return;
    }
    const char *queueLabel = context->queue ? dispatch_queue_get_label(context->queue) : NULL;
    update_current_thread_dispatch_node_list_by_copy(context->node, queueLabel);
    function(context->context);
    remove_current_thread_dispatch_node_list_last();
    delete context;
}

static void
(*orig_dispatch_async_f)(dispatch_queue_t queue,
                         void *_Nullable context, dispatch_function_t work);
static void
hooked_dispatch_async_f(dispatch_queue_t queue,
                        void *_Nullable context, dispatch_function_t work) {
    @autoreleasepool {
        if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
            orig_dispatch_async_f(queue, context, work);
            return;
        }
        orig_dispatch_async_f(queue, dispatch_node_context((void *)work, context, queue), (dispatch_function_t)dispatch_calling_work);
    }
}


static void
(*orig_dispatch_group_async_f)(dispatch_group_t group,
                               dispatch_queue_t queue,
                               void *_Nullable context,
                               dispatch_function_t work);
static void
hooked_dispatch_group_async_f(dispatch_group_t group,
    dispatch_queue_t queue,
    void *_Nullable context,
                       dispatch_function_t work) {
    @autoreleasepool {
        if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
            orig_dispatch_group_async_f(group, queue, context, work);
            return;
        }
        orig_dispatch_group_async_f(group, queue, dispatch_node_context((void *)work, context, queue), (dispatch_function_t)dispatch_calling_work);
    }
}

static void
(*orig_dispatch_barrier_async_f)(dispatch_queue_t queue,
                                 void *_Nullable context, dispatch_function_t work);
static void
hooked_dispatch_barrier_async_f(dispatch_queue_t queue,
                                void *_Nullable context, dispatch_function_t work) {
    @autoreleasepool {
        if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
            orig_dispatch_barrier_async_f(queue, context, work);
            return;
        }
        orig_dispatch_barrier_async_f(queue, dispatch_node_context((void *)work, context, queue), (dispatch_function_t)dispatch_calling_work);
    }
}

static void
(*orig_dispatch_after_f)(dispatch_time_t when, dispatch_queue_t queue,
                         void *_Nullable context, dispatch_function_t work);
static void
hooked_dispatch_after_f(dispatch_time_t when, dispatch_queue_t queue,
                        void *_Nullable context, dispatch_function_t work) {
    @autoreleasepool {
        if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
            orig_dispatch_after_f(when, queue, context, work);
            return;
        }
        orig_dispatch_after_f(when, queue, dispatch_node_context((void *)work, context, queue), (dispatch_function_t)dispatch_calling_work);
    }
}

#pragma mark pthread_create

static void *pthread_create_callback(void * const context) {
    HMDWorkContext *params = (HMDWorkContext *)context;
    update_current_thread_dispatch_node_list_by_copy(params->node, NULL);
    void * _Nullable (* _Nonnull function)(void * _Nullable) = (void * _Nullable (* _Nonnull)(void * _Nullable))params->function;
    void* pres = function(params->context);
    remove_current_thread_dispatch_node_list_last();
    delete params;
    return pres;
}

static int (*orig_pthread_create)(pthread_t _Nullable * _Nonnull __restrict thread,
        const pthread_attr_t * _Nullable __restrict attr,
        void * _Nullable (* _Nonnull start_routine)(void * _Nullable),
                           void * _Nullable __restrict arg);
static int hooked_pthread_create(pthread_t _Nullable * _Nonnull __restrict thread,
        const pthread_attr_t * _Nullable __restrict attr,
        void * _Nullable (* _Nonnull start_routine)(void * _Nullable),
                          void * _Nullable __restrict arg) {
    
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
        int res = orig_pthread_create(thread, attr, start_routine, arg);
        return res;
    }
    
    HMDWorkContext *params = new HMDWorkContext();
    params->function = (void *)start_routine;
    params->context = arg;
    params->node = current_thread_dispatch_node();
    int pres = orig_pthread_create(thread, attr, &pthread_create_callback, params);
    return pres;
}

@interface HMDThreadQosCollector()
{
    pthread_mutex_t _collectedKeyQueueNamesMutex;
}

@property (nonatomic, strong) NSMutableArray<NSString *>* collectedKeyQueueNames;

@end

@implementation HMDThreadQosCollector

#define HOOKED(func) hooked_##func
#define ORIG(func) orig_##func
#define REBINDING(func) \
    {#func, (void *)&HOOKED(func), (void **)&ORIG(func)}

+ (instancetype)sharedInstance {
    static HMDThreadQosCollector* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        init_dispatch_node();
        self.collectedKeyQueueNames = [NSMutableArray new];
        pthread_mutex_init(&_collectedKeyQueueNamesMutex, NULL);
    }
    return self;
}

- (void)fishhookWithRebingBlock:(void (^)(struct bd_rebinding *rebindings, size_t rebindings_nel))rebindingBlock {
    struct bd_rebinding r[] = {
        REBINDING(dispatch_async),
        REBINDING(dispatch_group_async),
        REBINDING(dispatch_barrier_async),
        REBINDING(dispatch_after),
        REBINDING(dispatch_async_f),
        REBINDING(dispatch_group_async_f),
        REBINDING(dispatch_barrier_async_f),
        REBINDING(dispatch_after_f),
        REBINDING(pthread_create)
    };
    if (rebindingBlock) {
        rebindingBlock(r, sizeof(r)/sizeof(struct bd_rebinding));
    }
}

- (NSArray<NSString *>*)markKeyPoint:(NSString *)label {
    std::shared_ptr<HMDDispatchNode> node = current_thread_dispatch_node();
    NSMutableArray *currentKeyPointQueueNames = [NSMutableArray new];
    for (std::string &queueString : node->queueList) {
        NSString *queueName = [NSString stringWithCString:queueString.c_str() encoding:NSUTF8StringEncoding];
        [currentKeyPointQueueNames addObject:[[HMDQoSMockerConfig sharedConfig] updatedWhiteListQueueName:queueName]];
    }
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[LaunchOptimizer] HMDThreadQoSCollector Key Point: %@, Detected Key Queues %@", label, currentKeyPointQueueNames);
    pthread_mutex_lock(&_collectedKeyQueueNamesMutex);
    [self.collectedKeyQueueNames addObjectsFromArray:currentKeyPointQueueNames];
    pthread_mutex_unlock(&_collectedKeyQueueNamesMutex);
    return [currentKeyPointQueueNames copy];
}

- (void)launchDidFinished {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSMutableArray *keyQueueNamesArray = [[HMDQoSMockerConfig sharedConfig].keyQueueNamesArray mutableCopy];
        pthread_mutex_lock(&self->_collectedKeyQueueNamesMutex);
        NSArray<NSString *>* collectedKeyQueueNames = [self.collectedKeyQueueNames copy];
        pthread_mutex_unlock(&self->_collectedKeyQueueNamesMutex);
        if ([collectedKeyQueueNames count] > 0) {
            [keyQueueNamesArray addObject:collectedKeyQueueNames];
        }
        if ([keyQueueNamesArray count] > kHMDKeyQueueCollectCount) {
            NSRange rangeToRemove = NSMakeRange(0, [keyQueueNamesArray count] - kHMDKeyQueueCollectCount);
            [keyQueueNamesArray removeObjectsInRange:rangeToRemove];
        }
        [HMDQoSMockerConfig sharedConfig].keyQueueNamesArray = keyQueueNamesArray;
        [[HMDQoSMockerConfig sharedConfig] flush];
        [self reportKeyQueueNamesRecursively:collectedKeyQueueNames atIndex:0];
    });
}

- (void)reportKeyQueueNamesRecursively:(NSArray<NSString *> *)keyQueueNames atIndex:(NSInteger)index {
    if (index >= [keyQueueNames count]) {
        return;
    }
    NSString *queueName = [keyQueueNames hmd_objectAtIndex:index class:[NSString class]];
    if (!queueName) {
        return;
    }
    NSDictionary *category = @{
        @"queue": queueName
    };
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hmdTrackService:@"slardar_key_queue_collector" metric:nil category:category extra:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self reportKeyQueueNamesRecursively:keyQueueNames atIndex:index+1];
    });
}

@end
