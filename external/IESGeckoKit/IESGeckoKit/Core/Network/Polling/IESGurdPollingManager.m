//
//  IESGurdPollingManager.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/8/31.
//

#import "IESGurdPollingManager.h"

#import <pthread/pthread.h>
#import <objc/runtime.h>

#import "IESGeckoAPI.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdPollingRequest.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdResourceManager+Status.h"
#import "IESGurdResourceManager+MultiAccessKey.h"

static void IESGurdRequestPollingLog(NSString *message, BOOL hasError, BOOL shouldLog)
{
    GurdLog(@"%@", message);
    message = [NSString stringWithFormat:@"【Polling】%@", message];
    [IESGurdEventTraceManager traceEventWithMessage:message hasError:hasError shouldLog:shouldLog];
}

static NSMutableDictionary<NSNumber *, IESGurdPollingRequest *> *kPollingRequests = nil;
static NSDictionary<NSNumber *, NSNumber *> *kPollingIntervals = nil;

static pthread_mutex_t kRequestLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t kIntervalsLock = PTHREAD_MUTEX_INITIALIZER;

static NSString * const kIESGurdPollingTimerRequestKey = @"request";

@interface IESGurdPollingRequest ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation IESGurdPollingManager

#pragma mark - Public

+ (void)addPollingConfigWithParams:(IESGurdFetchResourcesParams *)params
{
    IESGurdPollingPriority priority = params.pollingPriority;
    if (priority == IESGurdPollingPriorityNone) {
        return;
    }
    
    GURD_MUTEX_LOCK(kRequestLock);
    
    if (!kPollingRequests) {
        kPollingRequests = [NSMutableDictionary dictionary];
    }
    
    IESGurdPollingRequest *request = kPollingRequests[@(priority)];
    if (!request) {
        request = [IESGurdPollingRequest requestWithPriority:priority];
        kPollingRequests[@(priority)] = request;
        
        [self createOrUpdateTimerWithRequest:request];
    }
    [request updateConfigWithParams:params];
}

+ (void)updatePollingIntervals:(NSDictionary<NSNumber *, NSNumber *> *)pollingIntervals
{
    if (pollingIntervals.count == 0) {
        return;
    }
    
    BOOL didUpdate = NO;
    pthread_mutex_lock(&kIntervalsLock);
    if (![kPollingIntervals isEqualToDictionary:pollingIntervals]) {
        kPollingIntervals = pollingIntervals;
        
        didUpdate = YES;
        NSString *message = [NSString stringWithFormat:@"Update polling interval : %@", [pollingIntervals description]];
        IESGurdRequestPollingLog(message, NO, YES);
    }
    pthread_mutex_unlock(&kIntervalsLock);
    
    if (!didUpdate) {
        return;
    }
    
    [pollingIntervals enumerateKeysAndObjectsUsingBlock:^(NSNumber *priority, NSNumber *interval, BOOL *stop) {
        pthread_mutex_lock(&kRequestLock);
        IESGurdPollingRequest *request = kPollingRequests[priority];
        if (request) {
            [self createOrUpdateTimerWithRequest:request];
        }
        pthread_mutex_unlock(&kRequestLock);
    }];
}

#pragma mark - Private

+ (void)createOrUpdateTimerWithRequest:(IESGurdPollingRequest *)request
{
    IESGurdPollingPriority priority = request.priority;
    
    NSTimer *timer = request.timer;
    NSInteger interval = [self pollingIntervalWithPriority:priority];
    
    if (interval == 0) {
        if (timer) {
            [timer invalidate];
            request.timer = nil;
            
            IESGurdRequestPollingLog([NSString stringWithFormat:@"Disable timer (priority : %zd)", priority], NO, NO);
        }
        return;
    }
    
    if (timer.timeInterval == interval) {
        return;
    }
    
    if (timer) {
        [timer invalidate];
        IESGurdRequestPollingLog([NSString stringWithFormat:@"Update timer (priority : %zd; interval : %zd)", priority, interval], NO, NO);
    } else {
        IESGurdRequestPollingLog([NSString stringWithFormat:@"Create timer (priority : %zd; interval : %zd)", priority, interval], NO, NO);
    }
    request.timer = [self timerWithRequest:request interval:interval];
}

+ (NSTimer *)timerWithRequest:(IESGurdPollingRequest *)request interval:(NSInteger)interval
{
    __weak IESGurdPollingRequest *weakRequest = request;
    NSMapTable *mapTable = [NSMapTable strongToWeakObjectsMapTable];
    [mapTable setObject:weakRequest forKey:kIESGurdPollingTimerRequestKey];
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval
                                             target:self
                                           selector:@selector(sendPollingRequest:)
                                           userInfo:mapTable
                                            repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSInteger)pollingIntervalWithPriority:(IESGurdPollingPriority)priority
{
    GURD_MUTEX_LOCK(kIntervalsLock);

    if (!kPollingIntervals) {
        kPollingIntervals = @{ @(IESGurdPollingPriorityLevel1) : @(600),
                               @(IESGurdPollingPriorityLevel2) : @(1200),
                               @(IESGurdPollingPriorityLevel3) : @(1800) };
    }
    return [kPollingIntervals[@(priority)] integerValue];
}

+ (void)sendPollingRequest:(NSTimer *)timer
{
    if (![self isPollingEnabled]) {
        return;
    }
    
    IESGurdPollingRequest *request = [timer.userInfo objectForKey:kIESGurdPollingTimerRequestKey];
    if (!request) {
        return;
    }
    
    if ([IESGurdResourceManager checkIfServerAvailable]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [IESGurdResourceManager fetchConfigWithURLString:[IESGurdAPI polling]
                                      multiAccessKeysRequest:request];
        });
    }
}

+ (BOOL)isPollingEnabled
{
    return (IESGurdKit.enable && IESGurdKit.isPollingEnabled && IESGurdResourceManager.isPollingEnabled);
}

@end

@implementation IESGurdPollingRequest (Timer)

- (NSTimer *)timer
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTimer:(NSTimer *)timer
{
    objc_setAssociatedObject(self, @selector(timer), timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)fireDate
{
    GURD_MUTEX_LOCK(kRequestLock);
    return self.timer.fireDate;
}

@end

@implementation IESGurdPollingManager (DebugInfo)

+ (NSDictionary<NSNumber *, IESGurdPollingRequest *> *)pollingRequests
{
    GURD_MUTEX_LOCK(kRequestLock);
    return [kPollingRequests copy];
}

+ (NSDictionary<NSNumber *, NSNumber *> *)pollingIntervals
{
    GURD_MUTEX_LOCK(kIntervalsLock);
    return [kPollingIntervals copy];
}

@end
