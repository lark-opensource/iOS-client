//
//  HMDBackgroundMonitor.m
//  Pods
//
//  Created by 白昆仑 on 2020/4/10.
//

#import "HMDBackgroundMonitor.h"
#import <atomic>
#import "HMDInfo+AppInfo.h"
#import "UIApplication+HMDUtility.h"
#import "pthread_extended.h"

static std::atomic<BOOL> HMDSessionBackgroundStatus;

FOUNDATION_EXPORT BOOL HMDApplicationSession_backgroundState(void) {
    return std::atomic_load_explicit(&HMDSessionBackgroundStatus, std::memory_order_acquire);
}

@interface HMDBackgroundMonitor()

@property (nonatomic, strong) NSHashTable<id<HMDApplicationStatusChangeDelegate>> *delegateTable;
@property (nonatomic, assign) pthread_mutex_t delegate_mutex;
@end

@implementation HMDBackgroundMonitor

+ (instancetype)sharedInstance {
    static HMDBackgroundMonitor *monitor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[HMDBackgroundMonitor alloc] init];
    });
    
    return monitor;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegateTable = [[NSHashTable alloc]initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
        mutex_init_normal(_delegate_mutex);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(foregroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(foregroundNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isBackground {
    return HMDApplicationSession_backgroundState();
}

- (void)updateBackgroundState {

    NSAssert([NSThread isMainThread], @"[Heimdallr][updateBackgroundState] must be on the main thread!");
    UIApplicationState state = [UIApplication hmdSharedApplication].applicationState;
    BOOL isBackground = (state == UIApplicationStateBackground);
    std::atomic_store_explicit(&HMDSessionBackgroundStatus, isBackground, std::memory_order_release);
}

- (void)foregroundNotification:(NSNotification *)notification {
    std::atomic_store_explicit(&HMDSessionBackgroundStatus, NO, std::memory_order_release);
    mutex_lock(_delegate_mutex);
    for (id<HMDApplicationStatusChangeDelegate> obj in _delegateTable) {
        [obj applicationChangeToForeground];
    }
    mutex_unlock(_delegate_mutex);
}

- (void)backgroundNotification:(NSNotification *)notification {
    std::atomic_store_explicit(&HMDSessionBackgroundStatus, YES, std::memory_order_release);
    mutex_lock(_delegate_mutex);
    for (id<HMDApplicationStatusChangeDelegate> obj in _delegateTable) {
        [obj applicationChangeToBackground];
    }
    mutex_unlock(_delegate_mutex);
}

- (void)addStatusChangeDelegate:(id<HMDApplicationStatusChangeDelegate>)delegate {
    if ([delegate conformsToProtocol:@protocol(HMDApplicationStatusChangeDelegate)]) {
        mutex_lock(_delegate_mutex);
        [_delegateTable addObject:delegate];
        mutex_unlock(_delegate_mutex);
    }
}

- (void)removeStatusChangeDelegate:(id<HMDApplicationStatusChangeDelegate>)delegate {
    mutex_lock(_delegate_mutex);
    [_delegateTable removeObject:delegate];
    mutex_unlock(_delegate_mutex);
}

@end
