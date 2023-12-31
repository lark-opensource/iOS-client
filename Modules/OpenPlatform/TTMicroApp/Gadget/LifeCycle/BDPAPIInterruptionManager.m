//
//  BDPAPIInterruptionManager.m
//  Timor
//
//  Created by liuxiangxin on 2019/5/23.
//

#import "BDPAPIInterruptionManager.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPInterruptionManager.h"
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/NSTimer+BDPWeakTarget.h>
#import <OPFoundation/BDPUtils.h>

static const NSTimeInterval kInterruptionDurationSec = 5.f;

@interface BDPAPIInterruptionManager ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSMutableDictionary<BDPUniqueID *, NSTimer *> *appTimers;
@property (nonatomic, strong) NSMutableSet<BDPUniqueID *> *interruptionV2Apps;
@property (nonatomic, strong) NSMutableSet<BDPUniqueID *> *disableInterruptionApps;
@property (nonatomic, copy) NSSet<NSString *> *eventWhiteList;

@end

@implementation BDPAPIInterruptionManager

#pragma mark - Init

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static BDPAPIInterruptionManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[BDPAPIInterruptionManager alloc] initPrivate];
    });
    
    return manager;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1);
        _appTimers = [NSMutableDictionary dictionary];
        _interruptionV2Apps = [NSMutableSet set];
        _disableInterruptionApps = [NSMutableSet set];
        [self addNotificationObserver];
    }
    return self;
}

#pragma mark - Notification Handle

- (void)addNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppEnterBackground:)
                                                 name:kBDPEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppEnterForeground:)
                                                 name:kBDPEnterForegroundNotification
                                               object:nil];
}

- (void)handleAppEnterForeground:(NSNotification *)aNotification
{
    NSNotification *notification = [self transformToInterruptionNotfication:aNotification
                                                         interruptionStatus:BDPInterruptionStatusStop];
    
    [self handleAppInterruption:notification];
}

- (void)handleAppEnterBackground:(NSNotification *)aNotification
{
    NSNotification *notification = [self transformToInterruptionNotfication:aNotification
                                                         interruptionStatus:BDPInterruptionStatusBegin];
    
    [self handleAppInterruption:notification];
}

- (NSNotification *)transformToInterruptionNotfication:(NSNotification *)aNotification
                                    interruptionStatus:(BDPInterruptionStatus)status
{
    NSMutableDictionary *userInfo = [aNotification.userInfo mutableCopy];
    BDPUniqueID *uniqueID = [userInfo bdp_objectForKey:kBDPUniqueIDUserInfoKey ofClass:[BDPUniqueID class]];

    BOOL beginInterruption = (status == BDPInterruptionStatusBegin);
    [userInfo setValue:uniqueID forKey:kBDPUniqueIDUserInfoKey];
    [userInfo setValue:@(beginInterruption) forKey:kBDPInterruptionStatusUserInfoKey];
    
    NSNotification *notification = [NSNotification notificationWithName:aNotification.name
                                                                 object:aNotification.object
                                                               userInfo:userInfo.copy];
    
    return notification;
}

- (void)handleAppInterruption:(NSNotification *)aNotification
{
    BDPExecuteOnMainQueue(^{
        BOOL isBegin = [aNotification.userInfo bdp_boolValueForKey:kBDPInterruptionStatusUserInfoKey];
        BDPUniqueID *uniqueID = [aNotification.userInfo bdp_objectForKey:kBDPUniqueIDUserInfoKey ofClass:[BDPUniqueID class]];
        
        if ([self isPauseInterruptionForUniqueID:uniqueID]) {
            BDPLogWarn(@"uniqueID: %@ isPauseInterruption", uniqueID);
            return;
        }

        NSTimer *timer = [self timerForAppUniqueID:uniqueID];
        if (!timer) {
            BDPLogWarn(@"uniqueID: %@ cannot generate timer", uniqueID);
            return;
        }
        
        if (isBegin) {
            [self postAPIInterruptionV1NotificationWithUniqueID:uniqueID status:BDPInterruptionStatusBegin];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            BDPLogInfo(@"API Interruption add uniqueID: %@, timerCount: %zd", uniqueID, self.appTimers.count);
        } else {
            [self setInterruptionV2Apps:uniqueID status:BDPInterruptionStatusStop];
            [self postAPIInterruptionV1NotificationWithUniqueID:uniqueID status:BDPInterruptionStatusStop];
            [self postAPIInterruptionV2NotificationWithUniqueID:uniqueID status:BDPInterruptionStatusStop];
            [timer invalidate];
            [self.appTimers removeObjectForKey:uniqueID];
            BDPLogInfo(@"API Interruption remove uniqueID: %@, timerCount: %zd", uniqueID, self.appTimers.count);
        }
    });
}

- (void)postAPIInterruptionV1NotificationWithUniqueID:(BDPUniqueID *)uniqueID status:(BDPInterruptionStatus)status
{
    [self postNotification:kBDPAPIInterruptionV1Notification uniqueID:uniqueID status:status];
}

- (void)postAPIInterruptionV2NotificationWithUniqueID:(BDPUniqueID *)uniqueID status:(BDPInterruptionStatus)status
{
    [self postNotification:kBDPAPIInterruptionV2Notification uniqueID:uniqueID status:status];
}

- (void)postNotification:(NSString *)name uniqueID:(BDPUniqueID *)uniqueID status:(BDPInterruptionStatus)status
{
    if (!uniqueID || !name) {
        return;
    }
    
    NSDictionary *userInfo = @{
                               kBDPUniqueIDUserInfoKey: uniqueID,
                               kBDPInterruptionUserInfoStatusKey: @(status)
                               };
    NSNotification *notification = [NSNotification notificationWithName:name
                                                                 object:nil
                                                               userInfo:userInfo];
    BDPExecuteOnMainQueue(^{
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    });
}

#pragma mark - Method

- (void)beginInvokeEvent:(NSString *)event uniqueID:(BDPUniqueID *)uniqueID
{
    if (!event.length || !uniqueID) {
        return;
    }
    
    if (![self.eventWhiteList containsObject:event]) {
        return;
    }
    
    BDPLogInfo(@"%@ is a white list event, begin invoke in app: %@, pause interruption,", event, uniqueID);
    [self pauseInterruptionForUniqueID:uniqueID];
}

- (void)completeInvokeEvent:(NSString *)event uniqueID:(BDPUniqueID *)uniqueID
{
    if (!event.length || !uniqueID) {
        return;
    }
    
    if (![self.eventWhiteList containsObject:event]) {
        return;
    }
    
    BDPLogInfo(@"%@ is a white list event, complete invoke in app: %@, resume interruption", event, uniqueID);
    
    [self resumeInterruptionForUniqueID:uniqueID];
}

- (void)pauseInterruptionForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) {
        return;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.disableInterruptionApps addObject:uniqueID];
    dispatch_semaphore_signal(self.semaphore);
}

- (BOOL)isPauseInterruptionForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) {
        return NO;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    BOOL isPause = [self.disableInterruptionApps containsObject:uniqueID];
    dispatch_semaphore_signal(self.semaphore);
    
    return isPause;
}

- (void)resumeInterruptionForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) {
        return;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.disableInterruptionApps removeObject:uniqueID];
    dispatch_semaphore_signal(self.semaphore);
}

- (BOOL)shouldInterruptionForAppUniqueID:(BDPUniqueID *)uniqueID
{
    BOOL shouldInterruption = NO;
    if (uniqueID) {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        shouldInterruption = [self.appTimers objectForKey:uniqueID] != nil;
        dispatch_semaphore_signal(self.semaphore);
    }
    return shouldInterruption;
}

- (BOOL)shouldInterruptionForEngine:(id<BDPEngineProtocol>)engine {
    if ([engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPUniqueID *uniqueID = ((BDPJSBridgeEngine)engine).uniqueID;
        return [self shouldInterruptionForAppUniqueID:uniqueID];
    }
    return NO;
}

- (BOOL)shouldInterruptionV2ForAppUniqueID:(BDPUniqueID *)uniqueID
{
    BOOL shouldInterruption = NO;
    if (uniqueID) {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        shouldInterruption = [self.interruptionV2Apps containsObject:uniqueID];
        dispatch_semaphore_signal(self.semaphore);
    }
    
    return shouldInterruption;
}

- (BOOL)shouldInterruptionV2ForEngine:(id<BDPEngineProtocol>)engine {
    if ([engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPUniqueID *uniqueID = ((BDPJSBridgeEngine)engine).uniqueID;
        return [self shouldInterruptionV2ForAppUniqueID:uniqueID];
    }
    return NO;
}

- (void)clearInterruptionStatusForApp:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) {
        return;
    }
    
    [self setInterruptionV2Apps:uniqueID status:BDPInterruptionStatusStop];
    BDPExecuteOnMainQueue(^{
        NSTimer *timer = [self timerForAppUniqueID:uniqueID];
        [timer invalidate];
        [self.appTimers removeObjectForKey:uniqueID];
    });
}

- (void)setInterruptionV2Apps:(BDPUniqueID *)uniqueID status:(BDPInterruptionStatus)status
{
    if (!uniqueID) {
        return;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    switch (status) {
        case BDPInterruptionStatusBegin:
            [self.interruptionV2Apps addObject:uniqueID];
            break;
        case BDPInterruptionStatusStop:
            [self.interruptionV2Apps removeObject:uniqueID];
            break;
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (NSTimer *)timerForAppUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) {
        return nil;
    }
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSTimer *timer = [self.appTimers objectForKey:uniqueID];
    if (!timer) {
        WeakSelf;
        timer = [NSTimer bdp_timerWithInterval:kInterruptionDurationSec target:self block:^(NSTimer * _Nonnull timer) {
            BDPLogInfo(@"Timer fired, uniqueID: %@", uniqueID);
            StrongSelfIfNilReturn;
            BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
            if (common.isActive) {
                return;
            }
            [self setInterruptionV2Apps:uniqueID status:BDPInterruptionStatusBegin];
            [self postAPIInterruptionV2NotificationWithUniqueID:uniqueID status:BDPInterruptionStatusBegin];
        }];
        
        [self.appTimers setObject:timer forKey:uniqueID];
    }
    dispatch_semaphore_signal(self.semaphore);
    
    return timer;
}

#pragma mark - getter && setter

- (NSSet<NSString *> *)eventWhiteList
{
    if (!_eventWhiteList) {
        _eventWhiteList = [NSSet setWithArray:@[
                                                @"scanCode",
                                                @"chooseAddress",
                                                @"openSchema",
                                                @"shareVideo",
                                                @"shareAppMessageDirectly",
                                                @"tma_login",
                                                @"login",
                                                @"chooseImage",
                                                @"previewImage",
                                                @"chooseVideo",
                                                @"openSetting",
                                                @"openLocation"
                                                ]];
    }
    
    return _eventWhiteList.copy;
}

@end
