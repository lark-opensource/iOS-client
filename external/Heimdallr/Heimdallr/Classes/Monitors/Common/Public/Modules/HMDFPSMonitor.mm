//
//  HMDFPSMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#include "pthread_extended.h"
#import "HMDFPSMonitor.h"
#import "HMDWeakProxy.h"
#import "HMDMonitor+Private.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDPerformanceReporter.h"
#import "HMDFPSMonitorRecord.h"
#import "HMDFrameDropMonitor.h"
#import "HMDDynamicCall.h"
#import "HMDGCD.h"
#import "hmd_section_data_utility.h"
#import "HMDUITrackerTool.h"
#import "HMDALogProtocol.h"
#import "HMDMacro.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDFluencyDisplayLink.h"

NSString *const kHMDModuleFPSMonitor = @"fps";

HMD_MODULE_CONFIG(HMDFPSMonitorConfig)

@implementation HMDFPSMonitorConfig
+ (NSString *)configKey
{
    return kHMDModuleFPSMonitor;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDFPSMonitor sharedMonitor];
}

@end


@interface HMDFPSMonitor ()

@property (nonatomic, assign) CFTimeInterval lastUpdateTime;
@property (nonatomic, assign) NSUInteger frameCount;
@property (nonatomic, assign) HMDMonitorRecordValue lastFPS;
@property (nonatomic, strong) dispatch_queue_t fpsQueue;
@property (nonatomic, strong) NSMutableArray *customScenes;
@property (nonatomic, copy) NSString *customSceneStr;
@property (nonatomic, strong) NSMutableSet *fpsCallbacks;
@property (nonatomic, strong) NSMutableSet *fpsCallbackObjs;
@property (nonatomic, assign) NSUInteger maximumFramesPerSecond;
@property (nonatomic, assign) CFTimeInterval targetTimestamp;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;

@property (nonatomic, strong) HMDFluencyDisplayLink *fluencyDisplayLink;
@property (nonatomic, strong) HMDFluencyDisplayLinkCallbackObj *callbackObj;

@end

@implementation HMDFPSMonitor

@synthesize refCount;

SHAREDMONITOR(HMDFPSMonitor)

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fpsQueue = dispatch_queue_create("com.heimdallr.fps.monitor", DISPATCH_QUEUE_SERIAL);
        self.customScenes = [NSMutableArray array];
        self.fpsCallbacks = [NSMutableSet set];
        self.fpsCallbackObjs = [NSMutableSet set];
        self.maximumFramesPerSecond = 60;
        self.refCount = 0;
        self.fluencyDisplayLink = [HMDFluencyDisplayLink shared];
    }
    return self;
}

- (Class<HMDRecordStoreObject>)storeClass
{
    return [HMDFPSMonitorRecord class];
}

/// 重写 startWithInterval 方法，在基类 start 方法中会调用
- (void)startWithInterval:(CFTimeInterval)interval {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        [self registerDisplayLink];
    });
}

- (void)stop {
    [super stop];
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        [self unRegisterDisplayLink];
    });
}

- (void)registerDisplayLink {
    // displayLink已经开启或者该模块并没有要启动
    if([self isDisplayLinkStarted] || (!self.isRunning && self.refCount <= 0)) {
        return;
    }
    
    [self.fluencyDisplayLink registerFrameCallback:self.callbackObj
                                        completion:^(CADisplayLink * _Nonnull displayLink) {
        self.lastUpdateTime = displayLink.timestamp;
        self.frameCount = 0;
        if (@available(iOS 10.3, *)) {
              self.maximumFramesPerSecond = [UIScreen mainScreen].maximumFramesPerSecond;
        }
    }];
}

- (void)unRegisterDisplayLink {
    if(![self isDisplayLinkStarted] || (self.isRunning || self.refCount > 0)) {
        return;
    }
    [self.fluencyDisplayLink unregisterFrameCallback:self.callbackObj];
}

- (void)resume {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        self.refCount += 1;
        if(self.refCount == 1) {
            if(hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module resume", [self moduleName]);
            }
            [self registerDisplayLink];
        }
    });
}

- (void)suspend {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        self.refCount -= 1;
        if(self.refCount == 0) {
            if(hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module suspend", [self moduleName]);
            }
            [self unRegisterDisplayLink];
        }
    });
}

- (BOOL)isDisplayLinkStarted {
    return self.callbackObj.isRegistered;
}

- (void)p_updateFrameWithTimestamp:(CFTimeInterval)timestamp
                          duration:(CFTimeInterval)duration
                   targetTimestamp:(CFTimeInterval)targetTimestamp  {
    NSAssert([[NSThread currentThread] isMainThread], @"CADisplayLink should be attached into the runloop of the mainthread.");
    if (self.lastUpdateTime == 0) {
        self.lastUpdateTime = timestamp;
        self.frameCount = 0;
        return;
    }
    
    self.frameCount++;
    _lastTimestamp = timestamp;
    NSTimeInterval interval = timestamp - _lastUpdateTime;
    
    if (interval < 1) {
        return;
    }
    
    self.lastUpdateTime = timestamp;
    self.lastFPS = _frameCount/interval;
    self.frameCount = 0;
    
    [self refresh_async];
}

- (HMDMonitorRecord *)refresh_async
{
    HMDFPSMonitorRecord *record = [HMDFPSMonitorRecord newRecord];
    record.fps = fmin(_lastFPS, self.maximumFramesPerSecond);
    record.refreshRate = self.maximumFramesPerSecond;
    if (UITrackingRunLoopMode == [[NSRunLoop mainRunLoop] currentMode]) {
        record.isScrolling = YES;
    }
    //记录是否正在切换场景
    id<HMDUITrackerManagerSceneProtocol> monitor = hmd_get_uitracker_manager();
    if (monitor) {
        NSNumber *inSwitchNum = [monitor sceneInPushing];
        record.sceneInSwitch = inSwitchNum.boolValue;
    } else{
        record.sceneInSwitch = NO;
    }
    
    record.isLowPowerMode = [[HMDInfo defaultInfo] isLowPowerModeEnabled];
    // 自定义场景
    if (self.customSceneStr && self.customSceneStr.length > 0) {
        record.customScene = self.customSceneStr;
    }
    
    // fps 根据slardar上报配置开启才进行日志落库和上报（业务自行开启只提供回调即可）
    if(self.isRunning) {
        [self.curve pushRecord:record];
    }
    [self callFPSMonitorCallback:record];
    return record;
}

- (void)callFPSMonitorCallback:(HMDFPSMonitorRecord *)record {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        for (HMDMonitorCallback callBack in self.fpsCallbacks) {
            if (callBack) {
                callBack(record);
            }
        }

        for (HMDMonitorCallbackObject *callbackObj in self.fpsCallbackObjs) {
            if ([callbackObj isKindOfClass:[HMDMonitorCallbackObject class]] && callbackObj.callBack) {
                callbackObj.callBack(record);
            }
        }
    });
}

#pragma mark --- fps monitor method ---
- (void)addFPSRecordWithFPSValue:(HMDMonitorRecordValue)fpsValue
                           scene:(NSString *)scene
                     isScrolling:(BOOL)isScrolling
                     extralValue:(NSDictionary<NSString *,NSNumber *> *)extralValue {
    HMDFPSMonitorRecord *record = [HMDFPSMonitorRecord newRecord];
    record.fps = fpsValue;
    record.scene = scene;
    record.isScrolling = isScrolling;
    record.fpsExtralValue = extralValue;
    [self.curve pushRecord:record];
}

- (void)enterCustomScene:(NSString *)scene {
    void(^addCustomScene)(void) = ^{
        if (scene && scene.length > 0) {
            [self.customScenes addObject:scene];
            self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
            [[HMDFrameDropMonitor sharedMonitor] updateFrameDropCustomScene:self.customSceneStr];
        }
    };
    if ([NSThread isMainThread]) {
        addCustomScene();
    } else {
        dispatch_async(dispatch_get_main_queue(), addCustomScene);
    }

}

- (void)enterFluencyCustomSceneWithUniq:(NSString *)scene {
    NSString *lastScene = [self.customScenes lastObject];
    // 去重逻辑 如果传入的 scene 当前 栈顶的一个 scene 是重复的那么不传入;
    if ([lastScene isEqualToString:scene]) { return; }
    [self enterCustomScene:scene];
}

- (void)leaveFluencyCustomSceneWithUniq:(NSString *)scene {
    [self leaveCustomScene:scene];
}

- (void)addFPSMonitorCallback:(HMDMonitorCallback)callback {
    if (callback) {
        hmd_safe_dispatch_async(self.fpsQueue, ^{
            [self.fpsCallbacks addObject:callback];
        });
    }
}

- (void)removeFPSMoitorCallback:(HMDMonitorCallback)callback {
    if (callback) {
        hmd_safe_dispatch_async(self.fpsQueue, ^{
            [self.fpsCallbacks removeObject:callback];
        });
    }
}

- (HMDMonitorCallbackObject *)addFPSMonitorCallbackObject:(HMDMonitorCallback)callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        HMDMonitorCallbackObject *callbackObj = [[HMDMonitorCallbackObject alloc] initWithModuleName:kHMDModuleFPSMonitor callBack:callback];
        hmd_safe_dispatch_async(self.fpsQueue, ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.fpsCallbackObjs addObject:callbackObj];
        });
        return callbackObj;
    }
    return nil;
}

- (void)removeFPSMonitorCallbackObject:(HMDMonitorCallbackObject *)callbackObject {
    if (![callbackObject isKindOfClass:[HMDMonitorCallbackObject class]]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.fpsCallbackObjs removeObject:callbackObject];
    });
}

- (void)leaveCustomScene:(NSString *)scene {
    void(^removeCustomScene)(void) = ^{
       if (scene && scene.length > 0) {
           [self.customScenes removeObject:scene];
           if (self.customScenes.count == 0) {
               self.customSceneStr = nil;
           } else {
               self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
           }
           [[HMDFrameDropMonitor sharedMonitor] updateFrameDropCustomScene:self.customSceneStr];
       }
    };
    if ([NSThread isMainThread]) {
       removeCustomScene();
    } else {
       dispatch_async(dispatch_get_main_queue(), removeCustomScene);
    }

}

- (void)dealloc {
    if ([self isDisplayLinkStarted]) {
        [self.fluencyDisplayLink unregisterFrameCallback:self.callbackObj];
    }
}

#pragma mark - fluency display link getter
- (HMDFluencyDisplayLinkCallbackObj *)callbackObj {
    if (!_callbackObj) {
        _callbackObj = [[HMDFluencyDisplayLinkCallbackObj alloc] init];
        __weak typeof(self) weakSelf = self;
        _callbackObj.callback = ^(CFTimeInterval timestamp, CFTimeInterval duration, CFTimeInterval targetTimestamp) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf p_updateFrameWithTimestamp:timestamp
                                          duration:duration
                                   targetTimestamp:targetTimestamp];
        };
        
        _callbackObj.becomeActiveCallback = ^{
            weakSelf.lastUpdateTime = 0;
            if (@available(iOS 10.3, *)) {
                  weakSelf.maximumFramesPerSecond = [UIScreen mainScreen].maximumFramesPerSecond;
            }
        };
        
    }
    return _callbackObj;
}

#pragma mark HeimdallrModule
- (void)updateConfig:(HMDModuleConfig *)config
{
    [super updateConfig:config];
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityFPSMonitor;
}

- (void)monitorRunWithSpecialScene {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        [self registerDisplayLink];
    });
}

- (void)monitorStopWithSpecialScene {
    hmd_safe_dispatch_async(self.fpsQueue, ^{
        [self unRegisterDisplayLink];
    });
}

@end
