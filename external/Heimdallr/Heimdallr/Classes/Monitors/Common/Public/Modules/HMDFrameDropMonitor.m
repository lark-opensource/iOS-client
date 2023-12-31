//
//  HMDFrameDropMonitor.m
//  Heimdallr
//
//  Created by 王佳乐 on 2019/3/5.
//

#import "HMDFrameDropMonitor.h"
#import "HMDFrameDropRecord.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDMonitor+Private.h"
#import "HMDPerformanceReporter.h"
#import "HMDGCD.h"
#import "hmd_section_data_utility.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "NSObject+HMDAttributes.h"
#import "HeimdallrUtilities.h"
#import "HMDMacro.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDServiceContext.h"
#import "HMDEvilMethodServiceProtocol.h"
#import "HMDFrameDropServiceProtocol.h"
#import "HMDFluencyDisplayLink.h"

NSString *const kHMDModuleFrameDropMonitor = @"fps_drop";
static NSString *const kHMDFrameDropHardCodeANRNotificaton = @"HMDANROverNotification";

/// 16.67  60 Hz 屏幕的刷新频率
const static NSTimeInterval oneFrameInterval = 1.0 / 60 * 1000;
const static NSTimeInterval hitchThreshold = 1.0 / 120 * 1000;
const static NSTimeInterval evilMethodThreshold = 50;

HMD_MODULE_CONFIG(HMDFrameDropMonitorConfig)

@implementation HMDFrameDropMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableUploadStaticRecord, enable_upload_static_record, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleFrameDropMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDFrameDropMonitor sharedMonitor];
}

@end

@interface HMDFrameDropMonitor () <HMDFrameDropServiceProtocol>
@property (atomic, assign) BOOL isFrameDropActive;
@property (nonatomic, assign) CFTimeInterval lastUpdateTime;
@property (nonatomic, assign) CFTimeInterval startScrollingTime;
@property (nonatomic, assign) BOOL lastScrolling;
@property (nonatomic, strong) NSMutableArray *frameDrops;
@property (nonatomic, strong) NSMutableArray *hitchDurArray;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@property (nonatomic, assign) NSTimeInterval lastTargetTimestamp;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval hitchDuration;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, assign) CGPoint touchReleaseVelocity;
@property (nonatomic, assign) CGPoint scrollTargetDistance;
@property (nonatomic, copy) NSString *customScene;
@property (nonatomic, assign) NSUInteger refreshRate;
@property (nonatomic, strong) NSMutableDictionary *customExtra;

@property (nonatomic, strong) NSMutableSet *frameDropCallbacks;
@property (nonatomic, strong) NSMutableSet *frameDropcallBackObjs;
// 是否是静止采样状态 默认静止状态下不采样
@property (nonatomic, assign, readwrite) BOOL isStaticStateSample;
@property (nonatomic, assign, readwrite) BOOL isStaticEnableUpload;
@property (nonatomic, assign) BOOL isRecordStaticState;
@property (nonatomic, strong) NSOperationQueue *osNineSerialQueue;
@property (nonatomic, assign) double blockDuration;
@property (nonatomic, assign) NSInteger blockCount;
@property (nonatomic, assign) NSInteger callbackInterval;
@property (nonatomic, assign) CFTimeInterval staticLastRecordTime;
@property (nonatomic, strong) id<HMDEvilMethodServiceProtocol> emService;
@property (nonatomic, assign) BOOL enableService;

@property (nonatomic, strong) HMDFluencyDisplayLink *fluencyDisplayLink;
@property (nonatomic, strong) HMDFluencyDisplayLinkCallbackObj *callbackObj;

@end

@implementation HMDFrameDropMonitor

@synthesize refCount;

SHAREDMONITOR(HMDFrameDropMonitor)

- (instancetype)init {
    if (self = [super init]) {
        self.isFrameDropActive = NO;
        self.frameDrops = [NSMutableArray array];
        self.hitchDurArray = [NSMutableArray array];
        self.serialQueue = dispatch_queue_create("hmd.drop.monitor.serial.queue", DISPATCH_QUEUE_SERIAL);
        self.frameDropCallbacks = [NSMutableSet set];
        self.frameDropcallBackObjs = [NSMutableSet set];
        self.customExtra = [NSMutableDictionary dictionary];
        self.refreshRate = 60;
        self.refCount = 0;
        self.fluencyDisplayLink = [HMDFluencyDisplayLink shared];
    }
    return self;
}

- (void)dealloc {
    if(self.isFrameDropActive) {
        [self tryToStopFrameDrop];
    }
}

- (void)tryToStartFrameDrop {
    if(self.isFrameDropActive || (!self.isRunning && self.refCount <= 0)) {
        return ;
    }
    [self registerFluencyDisplayLink];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveANROverNotification:) name:kHMDFrameDropHardCodeANRNotificaton object:nil];
    self.isFrameDropActive = YES;
}

- (void)tryToStopFrameDrop {
    if(!self.isFrameDropActive || (self.isRunning || self.refCount > 0)) {
        return ;
    }
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self unRegisterFluencyDisplayLink];
        self.isFrameDropActive = NO;
    } @catch (NSException *exception) {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDFrameDropMMonitor remove notification exception: %@", exception.description);
        }
    }
}

- (void)resume {
    hmd_safe_dispatch_async(self.serialQueue, ^{
        self.refCount += 1;
        if(self.refCount == 1) {
            self.lastTimestamp = 0;
            if(hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module resume", [self moduleName]);
            }
            [self tryToStartFrameDrop];
        }
    });
}

- (void)suspend {
    hmd_safe_dispatch_async(self.serialQueue, ^{
        self.refCount -= 1;
        if(self.refCount == 0) {
            if(hmd_log_enable()) {
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@ module suspend", [self moduleName]);
            }
            [self tryToStopFrameDrop];
        }
    });
}

- (void)start {
    [super start];
    self.lastTimestamp = 0;
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self tryToStartFrameDrop];
        self.emService = hmd_get_evilmethod_tracer();
        self.enableService = self.config.enableOpen && self.config.enableUpload;
        self.isStaticEnableUpload = ((HMDFrameDropMonitorConfig *)self.config).enableUploadStaticRecord;
    });
}

- (void)stop {
    [super stop];
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self tryToStopFrameDrop];
        self.emService = nil;
        self.enableService = NO;
    });
}

- (void)monitorRunWithSpecialScene {
    self.lastTimestamp = 0;
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self tryToStartFrameDrop];
        self.emService = hmd_get_evilmethod_tracer();
        self.enableService = self.config.enableOpen && self.config.enableUpload;
        self.isStaticEnableUpload = ((HMDFrameDropMonitorConfig *)self.config).enableUploadStaticRecord;
    });
}

- (void)monitorStopWithSpecialScene {
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self tryToStopFrameDrop];
        self.emService = nil;
        self.enableService = NO;
    });
}

- (void)registerFluencyDisplayLink {
    [self.fluencyDisplayLink registerFrameCallback:self.callbackObj completion:^(CADisplayLink * _Nonnull dissplayLink) {
        [self setLastTimestampToZero];
        NSUInteger framesPerSec = 60;
        if (@available(iOS 10.3, *)) {
            framesPerSec = [UIScreen mainScreen].maximumFramesPerSecond;
        }
        [self refreshRateInfo:framesPerSec];
    }];
}

- (void)unRegisterFluencyDisplayLink {
    [self.fluencyDisplayLink unregisterFrameCallback:self.callbackObj];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDFrameDropRecord class];
}

- (void)applicationDidReceiveFrameNotification:(CFTimeInterval)timeInterval frameDuration:(CFTimeInterval)frameDuration {
    if (!self.isRunning && self.refCount <= 0) { return; }
    // 时间出现意外，不统计
    if (timeInterval - self.lastUpdateTime < 0) {return;}
    // 首次调用这个方法时，self.lastUpdateTime 为 0，数据不应该被统计
    BOOL lastUpdateTimeValid = self.lastUpdateTime >= 0.01;

    BOOL isScrolling = NO;
    if (UITrackingRunLoopMode == [[NSRunLoop mainRunLoop] currentMode]) {
        isScrolling = YES;
    }

    // 现在没有在滑动，并且上一帧也不在滑动，也不在静止时对丢帧统计 则不统计;
    if (!isScrolling && !self.lastScrolling && !self.isStaticStateSample) {
        return;
    }

    // 现在没有在滑动，并且上一帧也不在滑动 => 静止时
    if (!isScrolling && !self.lastScrolling) {
        self.isRecordStaticState = YES;
        if (self.staticLastRecordTime == 0) {
            self.staticLastRecordTime = timeInterval;
        }
        NSInteger dropFrames = (timeInterval - self.lastUpdateTime) / frameDuration;
        self.lastUpdateTime = timeInterval;
        if (lastUpdateTimeValid) {
            [self.frameDrops addObject:@(dropFrames)];
            if (self.callbackInterval > 0 &&
                (timeInterval - self.staticLastRecordTime > (self.callbackInterval * 1000))) {
                [self staticSampleRecordWithScene:nil];
            }
        }
    } else if (isScrolling && frameDuration > 0) {
        if (!self.lastScrolling) { // 静止 -> 滑动
            self.startScrollingTime = timeInterval;
            self.lastUpdateTime = timeInterval;
            if (self.isRecordStaticState) {
                self.isRecordStaticState = NO;
                [self staticSampleRecordWithScene:nil];
            }
            [self resetBlockDuration];
        }
        NSInteger dropFrames = (timeInterval - self.lastUpdateTime) / frameDuration;
        self.lastUpdateTime = timeInterval;
        self.lastScrolling = isScrolling;
        if (lastUpdateTimeValid) {
            [self.frameDrops addObject:@(dropFrames)];
        }

    } else if (!isScrolling && self.lastScrolling) {
        // 滑动 => 静止 (滑动结束)
        self.lastScrolling = NO;
        self.isRecordStaticState = NO;
        NSTimeInterval slidingTime = timeInterval - self.startScrollingTime;
        [self scrollSampleRecordWithSlidingTime:slidingTime];
    }
}

- (void)applicationDidReceiveFrameNotification:(CFTimeInterval)timeInterval
                                         frameDuration:(CFTimeInterval)frameDuration
                               targetTimestamp:(CFTimeInterval)targetTimestamp {
    NSAssert(NO, @"This interface is not available!!! Do not call this method!!! it will cause an error in frame drop data");
    [self p_didUpdateFramesWithTimeInterval:timeInterval frameDuration:frameDuration targetTimestamp:targetTimestamp];
}

- (void)p_didUpdateFramesWithTimeInterval:(CFTimeInterval)timeInterval
                            frameDuration:(CFTimeInterval)frameDuration
                          targetTimestamp:(CFTimeInterval)targetTimestamp {
    if (!self.isRunning && self.refCount <= 0) { return; }
    // 时间出现意外，不统计
    if (timeInterval - self.lastTimestamp < 0) {return;}
    
    // 首次调用这个方法时，self.lastTimestamp 为 0，数据不应该被统计
    if(self.lastTimestamp >= 0.01) {
        CFTimeInterval hitch = timeInterval - self.lastTargetTimestamp;
        hitch = hitch > hitchThreshold ? hitch : 0;
        CFTimeInterval duration = timeInterval - self.lastTimestamp;
        
        BOOL isScrolling = UITrackingRunLoopMode == [[NSRunLoop mainRunLoop] currentMode];
        // 现在没有在滑动，并且上一帧也不在滑动 => 静止时
        if (!isScrolling && !self.lastScrolling  && self.isStaticStateSample) {
            self.isRecordStaticState = YES;
            if (self.staticLastRecordTime == 0) {
                self.staticLastRecordTime = timeInterval;
            }
            NSInteger dropFrames = duration / frameDuration;
            [self.frameDrops addObject:@(dropFrames)];
            if(hitch > 0)
                [self.hitchDurArray addObject:@(hitch)];
            self.hitchDuration += hitch;
            self.duration += duration;
            if(hitch > evilMethodThreshold && [self.emService enableCollectFrameDrop] && self.isStaticEnableUpload) {
                [self.emService endCollectFrameDropWithHitch:hitch isScrolling:NO];
            }
            // 到达静止采样的时间，生成一条日志
            if (self.callbackInterval > 0 &&
                (timeInterval - self.staticLastRecordTime > (self.callbackInterval * 1000))) {
                [self staticSampleRecordWithScene:nil];
            }
        } else if (isScrolling && frameDuration > 0) {
            if (!self.lastScrolling) { // 静止 -> 滑动
                // 这里把静止到滑动的那一帧算为滑动帧，所以滑动开始时间应该是上一帧的刷新时间
                self.startScrollingTime = self.lastTimestamp;
                // 开始滑动时，立刻生成一条静止采样的日志
                if (self.isRecordStaticState) {
                    self.isRecordStaticState = NO;
                    [self staticSampleRecordWithScene:nil];
                }
                
                self.duration = 0;
                self.hitchDuration = 0;
                [self.hitchDurArray removeAllObjects];
                [self.frameDrops removeAllObjects];
                [self resetBlockDuration];
            }
            // 处于滑动状态
            if(hitch > evilMethodThreshold && [self.emService enableCollectFrameDrop]) {
                [self.emService endCollectFrameDropWithHitch:hitch isScrolling:YES];
            }
            
            NSInteger dropFrames = 0;
            if(self.isFixedFrameDropStandardDuration) {
                dropFrames = duration / oneFrameInterval;
            } else {
                dropFrames = duration / (frameDuration ?: 16.67);
            }
            self.lastScrolling = isScrolling;
            [self.frameDrops addObject:@(dropFrames)];
            if(hitch > 0)
                [self.hitchDurArray addObject:@(hitch)];
            self.hitchDuration += hitch;
            self.duration += duration;
        } else if (!isScrolling && self.lastScrolling) {
            // 滑动 => 静止 (滑动结束) 的这一帧不采集
            self.lastScrolling = NO;
            self.isRecordStaticState = NO;
            // 这一帧没有被算作滑动帧，所以滑动停止时间应该是上一帧刷新时间
            NSTimeInterval slidingTime = self.lastTimestamp - self.startScrollingTime;
            [self scrollSampleRecordWithSlidingTime:slidingTime];
        }
    }
    
    if([self.emService enableCollectFrameDrop]) {
        [self.emService startCollectFrameDrop];
    }
    self.lastTimestamp = timeInterval;
    self.lastTargetTimestamp = targetTimestamp;
}

// 关闭 CADisplayLink 时，lastTimestamp 清 0
- (void)setLastTimestampToZero {
    self.lastTimestamp = 0;
}

- (NSInteger)getFrameDropLevel:(NSInteger)dropFrames {
    if (59 < dropFrames) {
        return 59;
    }
    return dropFrames;
}

#pragma mark --- record anr duration
- (void)recieveANROverNotification:(NSNotification *)notification {
    id anrInfo = notification.object;
    id durationNum = DC_OB(anrInfo, duration);
    if (durationNum && [durationNum isKindOfClass:[NSNumber class]]) {
        double duration = [((NSNumber *)durationNum) doubleValue];
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.blockDuration += duration;
            strongSelf.blockCount ++;
        }];
    }
}

- (void)resetBlockDuration {
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.blockDuration = 0;
        strongSelf.blockCount = 0;
    }];
}

- (NSDictionary *)getFrameInfoFromArray:(NSArray *)dropInfoArray {
    NSMutableDictionary *frameInfoDictionary = [NSMutableDictionary dictionary];
    for (NSNumber *infoNumber in dropInfoArray) {
        NSInteger level = [self getFrameDropLevel:infoNumber.integerValue];
        NSString *levelString = [NSString stringWithFormat:@"%ld", (long) level];
        if ([frameInfoDictionary objectForKey:levelString]) {
            NSInteger value = [[frameInfoDictionary objectForKey:levelString] integerValue] + 1;
            [frameInfoDictionary setObject:@(value) forKey:levelString];
        } else {
            [frameInfoDictionary setObject:@(1) forKey:levelString];
        }
    }
    return [frameInfoDictionary copy];
}

- (NSDictionary *)getHitchInfoFromArray:(NSArray *)hitchInfoArray {
    NSMutableDictionary *hitchInfoDictionary = [NSMutableDictionary dictionary];
    for (NSNumber *hitchInfo in hitchInfoArray) {
        NSTimeInterval hitch = [hitchInfo doubleValue];
        NSInteger level = hitch / oneFrameInterval;
        level = level >= 60 ? 60 : level;
        NSString *levelString = [NSString stringWithFormat:@"%ld", (long) level];
        if ([hitchInfoDictionary objectForKey:levelString]) {
            NSTimeInterval value = [[hitchInfoDictionary objectForKey:levelString] doubleValue] + hitch;
            [hitchInfoDictionary setObject:@(value) forKey:levelString];
        } else {
            [hitchInfoDictionary setObject:@(hitch) forKey:levelString];
        }
    }
    return [hitchInfoDictionary copy];
}

#pragma mark --- utility method ---
- (void)frameDropRecordWithDropInfoArray:(NSArray *)dropInfoArray
                          hitchInfoArray:(NSArray *)hitchInfoArray
                           hitchDuration:(NSTimeInterval)hitchDuration
                                duration:(NSTimeInterval)duration
                             slidingTime:(NSTimeInterval)slidingTime
                                   scene:(NSString *)scene
                                isScroll:(BOOL)isScroll {
    
    HMDFrameDropRecord *record = [HMDFrameDropRecord newRecord];
    record.slidingTime = slidingTime;
    record.frameDropInfo = [self getFrameInfoFromArray:dropInfoArray];
    record.originDropArray = dropInfoArray;
    record.touchReleasedVelocity = self.touchReleaseVelocity;
    record.targetScrollDistance = self.scrollTargetDistance;
    record.refreshRate = self.refreshRate;
    record.isScrolling = isScroll;
    record.isLowPowerMode = [[HMDInfo defaultInfo] isLowPowerModeEnabled];
    record.blockDuration = self.blockDuration;
    record.blockCount = self.blockCount;
    record.duration = duration;
    record.hitchDuration = hitchDuration;
    record.hitchDurDic = [self getHitchInfoFromArray:hitchInfoArray];
    record.isEvilMethod = self.emService ? YES:NO;

    if (self.customScene && self.customScene.length > 0) {
        record.customScene = self.customScene;
    }
    if (scene && scene.length > 0) {
        record.scene = scene;
    }
    if (self.customExtra && self.customExtra.count > 0) {
        record.customExtra = self.customExtra;
    }
    
    // isRunning为真才代表fps_drop是由slardar上报配置开启，非业务自定义开启
    if (self.isRunning && (isScroll || self.isStaticEnableUpload)) {
        if(record.duration >= record.hitchDuration) {
            [self.curve pushRecord:record];
        }
    }
    if(record.duration >= record.hitchDuration) {
        [self callFrameDropCallback:record];
    }
    self.touchReleaseVelocity = CGPointZero;
    self.scrollTargetDistance = CGPointZero;
    self.blockDuration = 0;
    self.blockCount = 0;
}

// 场景切换时 如果对静止时的数据进行统计, 为了避免当前场景的数据对其他场景的数据污染
- (void)willLeaveScene:(NSString *)scene {
    hmd_dispatch_main_async_safe(^{
        if (self.isStaticStateSample) {
            [self staticSampleRecordWithScene:scene];
        }
    });
}

- (void)staticSampleRecordWithScene:(NSString *)scene {
    NSArray *frameDropInfoCopy = [self.frameDrops copy];
    NSArray *hitchInfoCopy = [self.hitchDurArray copy];
    NSTimeInterval hitchDuration = self.hitchDuration;
    NSTimeInterval duration = self.duration;
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf frameDropRecordWithDropInfoArray:frameDropInfoCopy hitchInfoArray:hitchInfoCopy hitchDuration:hitchDuration duration:duration slidingTime:0 scene:scene isScroll:NO];
    }];
    self.staticLastRecordTime = 0;
    self.hitchDuration = 0;
    self.duration = 0;
    [self.hitchDurArray removeAllObjects];
    [self.frameDrops removeAllObjects];
}

- (void)scrollSampleRecordWithSlidingTime:(NSTimeInterval)slidingTime {
    NSArray *frameDropCopy = [self.frameDrops copy];
    NSArray *hitchInfoCopy = [self.hitchDurArray copy];
    NSTimeInterval hitchDuration = self.hitchDuration;
    NSTimeInterval duration = self.duration;
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf frameDropRecordWithDropInfoArray:frameDropCopy hitchInfoArray:hitchInfoCopy hitchDuration:hitchDuration duration:duration slidingTime:slidingTime scene:nil isScroll:YES];
    }];
    self.hitchDuration = 0;
    self.duration = 0;
    [self.frameDrops removeAllObjects];
    [self.hitchDurArray removeAllObjects];
}

- (void)callFrameDropCallback:(HMDFrameDropRecord *)record {
    for (HMDMonitorCallback callback in self.frameDropCallbacks) {
        if (callback) {
            callback(record);
        }
    }

    for (HMDMonitorCallbackObject *callbackObj in self.frameDropcallBackObjs) {
        if ([callbackObj isKindOfClass:[HMDMonitorCallbackObject class]] && callbackObj.callBack) {
            callbackObj.callBack(record);
        }
    }
}

#pragma mark --- public method ---
- (void)updateCurrentTouchReleasedVelocity:(CGPoint)velocity targetContentDistance:(CGPoint)targetDistance {
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.touchReleaseVelocity = velocity;
        strongSelf.scrollTargetDistance = targetDistance;
    }];
}

- (void)updateFrameDropCustomScene:(NSString *)customScene {
    // 更新scene
    void(^changeScene)(void) = ^ {
        [self willLeaveScene:nil];

    };
    if ([NSThread isMainThread]) {
        changeScene();
    } else {
        dispatch_async(dispatch_get_main_queue(), changeScene);
    }

    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.customScene = customScene;
    }];
}

- (void)addFrameDropMonitorCallback:(HMDMonitorCallback)callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.frameDropCallbacks addObject:callback];
        }];
    }
}

- (void)removeFrameDropMonitorCallback:(HMDMonitorCallback)callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.frameDropCallbacks removeObject:callback];
        }];
    }
}


- (HMDMonitorCallbackObject *)addFrameDropMonitorCallbackObject:(HMDMonitorCallback)callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        HMDMonitorCallbackObject *callbackObj = [[HMDMonitorCallbackObject alloc] initWithModuleName:kHMDModuleFrameDropMonitor callBack:callback];
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.frameDropcallBackObjs addObject:callbackObj];
        }];
        return callbackObj;
    }
    return nil;
}

- (void)removeFrameDropMonitorCallbackObject:(HMDMonitorCallbackObject *)callbackObject {
    if (![callbackObject isKindOfClass:[HMDMonitorCallbackObject class]]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.frameDropcallBackObjs removeObject:callbackObject];
    }];
}

- (void)addFrameDropCustomExtra:(NSDictionary *_Nonnull)extra {
    if (extra && extra.count > 0) {
        NSDictionary *extraCopy = [extra copy];
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.customExtra addEntriesFromDictionary:extraCopy?:@{}];
        }];
    }
}

- (void)removeFrameDropCustomExtra:(NSDictionary *_Nonnull)extra {
    if (extra && extra.count > 0) {
        NSDictionary *extraCopy = [extra copy];
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [extraCopy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                id extraObj = [strongSelf.customExtra valueForKey:key];
                if ([extraObj isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
                    if ([((NSString *)extraObj) isEqualToString:((NSString *) obj)]) {
                        [strongSelf.customExtra removeObjectForKey:key];
                    }
                    return;
                }

                if ([extraObj isKindOfClass:[NSNumber class]] && [obj isKindOfClass:[NSNumber class]]) {
                    if ([((NSNumber *)extraObj) isEqualToNumber:((NSNumber *) obj)]) {
                        [strongSelf.customExtra removeObjectForKey:key];
                    }
                    return;
                }
            }];
        }];
    }
}

- (void)removeFrameDropCustomExtraWithKeys:(NSArray<NSString *> *)keys {
    if (keys && [keys isKindOfClass:[NSArray class]] && keys.count > 0) {
        NSArray *keysCopy = [keys copy];
        __weak typeof(self) weakSelf = self;
        [self excuteBlockOnFrameDropSerialQueue:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.customExtra removeObjectsForKeys:keysCopy];
        }];
    }
}

- (void)refreshRateInfo:(NSUInteger)refreshRate {
    __weak typeof(self) weakSelf = self;
    [self excuteBlockOnFrameDropSerialQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.refreshRate = refreshRate;
    }];
}

- (void)allowedNormalStateSample:(BOOL)isAllowed {
    [self allowedNormalStateSample:isAllowed callbackInterval:self.callbackInterval];
}

- (void)allowedNormalStateSample:(BOOL)isAllowed callbackInterval:(NSInteger)callbackInterval {
    void(^changSampleModleBlock)(void) = ^ {
        if (self.isRecordStaticState && !isAllowed) {
            [self staticSampleRecordWithScene:nil];
        }
        self.isStaticStateSample = isAllowed;
        self.callbackInterval = callbackInterval;

    };
    if ([NSThread isMainThread]) {
        changSampleModleBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), changSampleModleBlock);
    }
}

- (void)excuteBlockOnFrameDropSerialQueue:(void(^)(void))frameDropBlock {
    if (@available(iOS 10.0, *)) {
        hmd_safe_dispatch_async(self.serialQueue, frameDropBlock);
    } else {
        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:frameDropBlock];
        [self.osNineSerialQueue addOperation:blockOperation];
    }
}
#pragma mark - overrides
- (NSOperationQueue *)osNineSerialQueue {
    if (!_osNineSerialQueue) {
        _osNineSerialQueue = [[NSOperationQueue alloc] init];
        _osNineSerialQueue.maxConcurrentOperationCount = 1;
        _osNineSerialQueue.name = @"com.heimdallr.fpsdrop.operation.queuqe";
    }
    return _osNineSerialQueue;
}

#pragma mark - fluency display link getter
- (HMDFluencyDisplayLinkCallbackObj *)callbackObj {
    if (!_callbackObj) {
        _callbackObj = [[HMDFluencyDisplayLinkCallbackObj alloc] init];
        __weak typeof(self) weakSelf = self;
        _callbackObj.callback = ^(CFTimeInterval timestamp, CFTimeInterval duration, CFTimeInterval targetTimestamp) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf p_didUpdateFramesWithTimeInterval:timestamp * 1000
                                            frameDuration:duration * 1000
                                          targetTimestamp:targetTimestamp * 1000];
        };
         
        _callbackObj.becomeActiveCallback = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf setLastTimestampToZero];
            NSUInteger framesPerSec = 60;
            if (@available(iOS 10.3, *)) {
                framesPerSec = [UIScreen mainScreen].maximumFramesPerSecond;
            }
            [strongSelf refreshRateInfo:framesPerSec];
        };
        
    }
    return _callbackObj;
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityFrameDropMonitor;
}


- (nullable NSDictionary *)getCustomFilterTag {
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    [filters hmd_setObject:self.customScene forKey:@"custom_scene"];
    return [filters copy];
}

- (BOOL)enableFrameDropService {
    return self.enableService;
}

@end
