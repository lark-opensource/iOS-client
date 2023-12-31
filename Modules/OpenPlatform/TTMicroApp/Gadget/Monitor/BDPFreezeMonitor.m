//
//  BDPFreezeMonitor.m
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import "BDPFreezeMonitor.h"

@interface BDPFreezeMonitor() {
    CFRunLoopObserverRef _observer;
    CFRunLoopActivity _activity;
    dispatch_semaphore_t _semaphore;
    NSUInteger _timeoutCount;
    BOOL _stop;
}

@property (nonatomic, assign) NSUInteger freezeCount;
@property (nonatomic, assign) NSUInteger totalCount;

@end

@implementation BDPFreezeMonitor

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static BDPFreezeMonitor *monitor;
    dispatch_once(&onceToken, ^{
        monitor = [[BDPFreezeMonitor alloc] _init];
    });
    return monitor;
}

+ (void)start
{
    [[BDPFreezeMonitor sharedInstance] registerObserver];
}

+ (void)stop
{
    [[BDPFreezeMonitor sharedInstance] removeObserver];
}

+ (BDPFreezeMonitorData *)freeze
{
    BDPFreezeMonitorData *data = [[BDPFreezeMonitorData alloc] init];
    data.freezeCount = [[BDPFreezeMonitor sharedInstance] freezeCount];
    data.totalCount = [[BDPFreezeMonitor sharedInstance] totalCount];
    
    // reset data;
    [BDPFreezeMonitor sharedInstance].freezeCount = 0;
    [BDPFreezeMonitor sharedInstance].totalCount = 0;
    
    return data;
}

- (instancetype)_init
{
    self = [super init];
    if (self) {
        self->_stop = YES;
    }
    return self;
}

- (void)registerObserver
{
    if (!_stop) {
        return;
    }
    
    self.totalCount = 0;
    self.freezeCount = 0;
    
    __weak typeof(self) weakSelf = self;
    _observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        __strong typeof(weakSelf) self = weakSelf;
        self->_activity = activity;
        dispatch_semaphore_signal( self->_semaphore);
    });
    
    _stop = NO;
    // 创建信号
    _semaphore = dispatch_semaphore_create(0);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (!self->_stop) {
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
            long st = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
            self.totalCount ++;
            if (st != 0) {
                if (self->_activity==kCFRunLoopBeforeSources || self->_activity==kCFRunLoopAfterWaiting) {
                    if (++self->_timeoutCount < 5) {
                        self.freezeCount ++;
                    }
                    continue;
                    // 检测到卡顿，进行卡顿上报
                }
            }
            self->_timeoutCount = 0;
        }
    });
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
}

- (void)removeObserver
{
    _stop = YES;
    if (_observer) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = nil;
    }
    
}


@end

@implementation BDPFreezeMonitorData

@end
