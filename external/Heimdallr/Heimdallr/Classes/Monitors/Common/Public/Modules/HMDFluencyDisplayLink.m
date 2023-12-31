//
//  HMDFluencyDisplayLink.m
//  Heimdallr_NewsInHouse_3A238829
//
//  Created by ByteDance on 2023/5/12.
//

#import "HMDFluencyDisplayLink.h"
#import <pthread/pthread.h>

#import "NSArray+HMDSafe.h"
#import "HMDWeakProxy.h"

@interface HMDFluencyDisplayLinkCallbackObj ()

@property (nonatomic, assign, readwrite) BOOL isRegistered;

@end

@implementation HMDFluencyDisplayLinkCallbackObj

@end

#pragma mark - HMDFluencyDisplayLink

@interface HMDFluencyDisplayLink ()

@property (nonatomic, strong) dispatch_queue_t displayLinkQueue;
@property (nonatomic, strong) NSMutableArray *callbackObjs;
@property (nonatomic, assign) CFTimeInterval lastVSyncInterval;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, strong, readwrite) CADisplayLink *displayLink;
@property (nonatomic, assign, readwrite) BOOL isRunning;

@end

@implementation HMDFluencyDisplayLink {
    pthread_rwlock_t _rwLock;
}

+ (instancetype)shared {
    static HMDFluencyDisplayLink *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDFluencyDisplayLink alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbackObjs = [NSMutableArray array];
        _displayLinkQueue = dispatch_queue_create("com.hmd.monitor.displaylink.operation", DISPATCH_QUEUE_SERIAL);
        pthread_rwlock_init(&_rwLock, NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification:)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification:)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
        
    }
}

#pragma mark - public
- (void)registerFrameCallback:(HMDFluencyDisplayLinkCallbackObj *)callbackObj completion:(nullable void (^)(CADisplayLink * _Nonnull))completionInMainThread {
    if(!callbackObj) { return; }
    void (^operationBlock)(void) = ^{
        if(callbackObj.isRegistered) { return; }
        if(self.callbackObjs.count == 0) {
            dispatch_async(self.displayLinkQueue, ^{
                [self p_tryToStartDisplayLink];
                self.isRunning = YES;
                if(completionInMainThread) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionInMainThread(self.displayLink);
                    });
                }
                
            });
        } else if (completionInMainThread) {
            completionInMainThread(self.displayLink);
        }
        [self.callbackObjs hmd_addObject:callbackObj];
        callbackObj.isRegistered = YES;
    };
    
    if(pthread_main_np() != 0) {
        operationBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), operationBlock);
    }
}

- (void)unregisterFrameCallback:(HMDFluencyDisplayLinkCallbackObj *)callbackObj {
    if(!callbackObj) {
        return;
    }
    void (^operationBlock)(void) = ^{
        if(!callbackObj.isRegistered) { return; }
        callbackObj.isRegistered = NO;
        [self.callbackObjs removeObject:callbackObj];
        if(self.callbackObjs.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self p_tryToStopDisplayLink];
            });
            dispatch_async(self.displayLinkQueue, ^{
                self.isRunning = NO;
            });
        }
    };
    
    if(pthread_main_np() != 0) {
        operationBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), operationBlock);
    }
}

- (NSInteger)screenMaximumFramesPerSecond {
    NSInteger frames = 60;
    if (@available(iOS 10.3, *)) {
        frames = [UIScreen mainScreen].maximumFramesPerSecond;
    }
    
    return frames;
}

#pragma mark - action
- (BOOL)p_tryToStartDisplayLink {
    if(self.displayLink) return NO;
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:[HMDWeakProxy proxyWithTarget:self]
                                                       selector:@selector(frameUpdate:)];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    });
    
    return YES;
}

- (BOOL)p_tryToStopDisplayLink {
    if(!self.displayLink) { return NO; }
    
    [self.displayLink invalidate];   // thread-safe
    self.displayLink = nil;
    
    return YES;
}

- (void)frameUpdate:(CADisplayLink *)displayLink {
    NSAssert([[NSThread currentThread] isMainThread], @"CADisplayLink should be attached into the runloop of the mainthread.");
    _lastTimestamp = _displayLink.timestamp;
    
    for (HMDFluencyDisplayLinkCallbackObj *callbackObj in self.callbackObjs) {
        if(callbackObj.callback) {
            CFTimeInterval targetTimestamp = 0;
            if(@available(iOS 10.0, *)) {
                targetTimestamp = _displayLink.targetTimestamp;
            }
            else {
                targetTimestamp = _lastTimestamp + _displayLink.duration;
            }
            callbackObj.callback(displayLink.timestamp, displayLink.duration, targetTimestamp);
        }
    }
    
    // match CADisplayLink 的回调频率和当前屏幕刷新率尽可能保持一致
    if (@available(iOS 15.0, *)) {
        if (CAFrameRateRangeMake) {
            // Below code only runs on >= iOS 15
            NSTimeInterval vsyncInterval = displayLink.duration;
            if (_lastVSyncInterval != vsyncInterval) {
                NSInteger lastFPS = (NSInteger)ceil(1.0 / _lastVSyncInterval);
                NSInteger currentFPS = (NSInteger)ceil(1.0 / vsyncInterval);
                if (lastFPS != currentFPS) {
                    _lastVSyncInterval = vsyncInterval;
                    displayLink.preferredFrameRateRange = CAFrameRateRangeMake(10.0, currentFPS, 0.0);
                }
            }
        }
    }
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification {
    if (!self.isRunning) {
        return;
    }
    if (self.displayLink.isPaused) {
        [self.displayLink setPaused:NO];      // it is safe to setPaused: outside
    }
    for (HMDFluencyDisplayLinkCallbackObj *callbackObj in self.callbackObjs) {
        if(callbackObj.becomeActiveCallback) {
            callbackObj.becomeActiveCallback();
        }
    }
}

- (void)applicationWillResignActiveNotification:(NSNotification *)notification {
    if(!self.isRunning) {
        return;
    }
    if (!self.displayLink.isPaused) {
        [self.displayLink setPaused:YES];     // it is safe to setPaused: outside
    }
    for (HMDFluencyDisplayLinkCallbackObj *callbackObj in self.callbackObjs) {
        if(callbackObj.resignActiveCallback) {
            callbackObj.resignActiveCallback();
        }
    }
}

@end

