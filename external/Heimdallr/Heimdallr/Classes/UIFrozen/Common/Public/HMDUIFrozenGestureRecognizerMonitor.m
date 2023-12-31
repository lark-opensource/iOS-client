//
//  HMDUIFrozenGestureRecognizerMonitor.m
//  Heimdallr-8bda3036
//
//  Created by wangyinhui on 2022/4/26.
//
#include <pthread.h>

#import "HMDUIFrozenGestureRecognizerMonitor.h"
#import "HMDUITrackerManager.h"
#import "HMDUIViewHierarchy.h"
#import "HMDUIFrozenDefine.h"
#include "HMDTimeSepc.h"
#import "HMDSessionTracker.h"
#import "HMDUIFrozenManager.h"
#import "HMDNetworkHelper.h"
#import "HMDMemoryUsage.h"
#import "HMDDiskUsage.h"
#import "HMDInjectedInfo.h"
#import "HMDMacro.h"
#import "HMDUIFrozenDetectProtocol.h"
#import "HMDUITrackerTool.h"

static pthread_mutex_t recordLock = PTHREAD_MUTEX_INITIALIZER;

NSNotificationName const HMDUIFrozenNotificationGestureUnresponsive = @"HMDUIFrozenGestureUnresponsive";

@implementation HMDUIFrozenGestureRecord


@end

@interface HMDUIFrozenGestureRecognizerMonitor() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIWindow* targetWindow;

@property (nonatomic, strong) NSMutableArray* gestures;

@property (nonatomic, strong) dispatch_queue_t storeQueue;

@property (nonatomic, strong) dispatch_queue_t consumeQueue;

@property(nonatomic, strong) UISwipeGestureRecognizer *up;

@property(nonatomic, strong) UISwipeGestureRecognizer *down;

@property(nonatomic, strong) UISwipeGestureRecognizer *left;

@property(nonatomic, strong) UISwipeGestureRecognizer *right;

@end

@implementation HMDUIFrozenGestureRecognizerMonitor

+ (instancetype)shared
{
    static dispatch_once_t once_token;
    static HMDUIFrozenGestureRecognizerMonitor *monitor;
    dispatch_once(&once_token, ^{
        monitor = [[HMDUIFrozenGestureRecognizerMonitor alloc] init];
    });
    return monitor;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _storeQueue = dispatch_queue_create("com.hmd.heimdallr.ui-frozen-gr-store", DISPATCH_QUEUE_SERIAL);
        _consumeQueue = dispatch_queue_create("com.hmd.heimdallr.ui-frozen-gr-consume", DISPATCH_QUEUE_SERIAL);
        _gestures = [NSMutableArray new];
        _up = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handSwipeUP:)];
        if (@available(iOS 11.0, *)) {
            _up.name = @"com.bytedance.heimdallr.global-swipe-gr-up";
        }
        _up.cancelsTouchesInView = NO;
        _up.delaysTouchesEnded = NO;
        _up.delaysTouchesBegan = NO;
        _up.direction = UISwipeGestureRecognizerDirectionUp;
        _up.delegate = self;
        
        _down = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handSwipeDown:)];
        if (@available(iOS 11.0, *)) {
            _down.name = @"com.bytedance.heimdallr.global-swipe-gr-down";
        }
        _down.cancelsTouchesInView = NO;
        _down.delaysTouchesEnded = NO;
        _down.delaysTouchesBegan = NO;
        _down.direction = UISwipeGestureRecognizerDirectionDown;
        _down.delegate = self;
        
        _left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handSwipeLeft:)];
        if (@available(iOS 11.0, *)) {
            _left.name = @"com.bytedance.heimdallr.global-swipe-gr-left";
        }
        _left.cancelsTouchesInView = NO;
        _left.delaysTouchesEnded = NO;
        _left.delaysTouchesBegan = NO;
        _left.direction = UISwipeGestureRecognizerDirectionLeft;
        _left.delegate = self;
        
        _right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handSwipeRight:)];
        if (@available(iOS 11.0, *)) {
            _right.name = @"com.bytedance.heimdallr.global-swipe-gr-right";
        }
        _right.cancelsTouchesInView = NO;
        _right.delaysTouchesEnded = NO;
        _right.delaysTouchesBegan = NO;
        _right.direction = UISwipeGestureRecognizerDirectionRight;
        _right.delegate = self;
        
    }
    return self;
}

#pragma mark - addGestureRecognizers

- (void)addUIFrozenGestureRecognizersForWindow:(UIWindow *)window
{
    if (!window) {
        return;
    }
    
    if (![HMDUIFrozenManager sharedInstance].enableGestureMonitor) {
        return;
    }
    
    if (_targetWindow == window) {
        return;
    }else {
        [self removeUIFrozenGestureRecognizers];
    }
    
    [window addGestureRecognizer:_up];
    [window addGestureRecognizer:_down];
    [window addGestureRecognizer:_left];
    [window addGestureRecognizer:_right];
    _targetWindow = window;
    [self startRecord];
}

- (void)addUIFrozenGestureRecognizersForKeyWindow
{
    if (![HMDUIFrozenManager sharedInstance].enableGestureMonitor) {
        return;
    }
    
    UIWindow* keyWindow = [HMDUITrackerTool keyWindow];
    
    if (_targetWindow == keyWindow) {
        return;
    }else {
        [self removeUIFrozenGestureRecognizers];
    }
    
    [keyWindow addGestureRecognizer:_up];
    [keyWindow addGestureRecognizer:_down];
    [keyWindow addGestureRecognizer:_left];
    [keyWindow addGestureRecognizer:_right];
    _targetWindow = keyWindow;
    [self startRecord];
}

-(void)removeUIFrozenGestureRecognizers
{
    if (!_targetWindow) {
        return;
    }
    if (![HMDUIFrozenManager sharedInstance].enableGestureMonitor) {
        return;
    }
    [_targetWindow removeGestureRecognizer:_up];
    [_targetWindow removeGestureRecognizer:_down];
    [_targetWindow removeGestureRecognizer:_left];
    [_targetWindow removeGestureRecognizer:_right];
    [_gestures removeAllObjects];
    _targetWindow = nil;
    [self stopRecord];
}

#pragma mark - GestureRecognizers action

- (void)handSwipeUP:(UISwipeGestureRecognizer *)recognizer
{
    HMDUIFrozenGestureRecord *record = [[HMDUIFrozenGestureRecord alloc] init];
    record.type = HMDUIFrozenGestureSwipeUp;
    DEBUG_LOG("SwipeUP👆");
    [self asyncStoreGestureRecord:record];
}

- (void)handSwipeDown:(UISwipeGestureRecognizer *)recognizer
{
    HMDUIFrozenGestureRecord *record = [[HMDUIFrozenGestureRecord alloc] init];
    record.type = HMDUIFrozenGestureSwipeDown;
    DEBUG_LOG("SwipeDown👇");
    [self asyncStoreGestureRecord:record];
}

- (void)handSwipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    HMDUIFrozenGestureRecord *record = [[HMDUIFrozenGestureRecord alloc] init];
    record.type = HMDUIFrozenGestureSwipeLeft;
    DEBUG_LOG("SwipeLeft👈");
    [self asyncStoreGestureRecord:record];
}

- (void)handSwipeRight:(UISwipeGestureRecognizer *)recognizer
{
    HMDUIFrozenGestureRecord *record = [[HMDUIFrozenGestureRecord alloc] init];
    record.type = HMDUIFrozenGestureSwipeRight;
    DEBUG_LOG("SwipeRight👉");
    [self asyncStoreGestureRecord:record];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

#pragma mark - record

-(void)startRecord
{
    pthread_mutex_lock(&recordLock);
    _isRecording = YES;
    _isUnresponsive = NO;
    pthread_mutex_unlock(&recordLock);
}

-(void)stopRecord
{
    pthread_mutex_lock(&recordLock);
    _isRecording = NO;
    _isUnresponsive = NO;
    pthread_mutex_unlock(&recordLock);
}

-(void)resetRecord
{
    pthread_mutex_lock(&recordLock);
    _isRecording = YES;
    _isUnresponsive = NO;
    [_gestures removeAllObjects];
    pthread_mutex_unlock(&recordLock);
}

-(void)asyncStoreGestureRecord:(HMDUIFrozenGestureRecord *)record
{
    if (!record) {
        return;
    }
    dispatch_async(_storeQueue, ^{
        pthread_mutex_lock(&recordLock);
        if (!self->_isRecording || self->_isUnresponsive) {
            pthread_mutex_unlock(&recordLock);
            return;
        }
        [self->_gestures addObject:record];
        if (self->_gestures.count >= [HMDUIFrozenManager sharedInstance].gestureCountThreshold && !self->_isUnresponsive && self.targetWindow) {
            DEBUG_LOG("🙅Too many gestures are not responding");
            self->_isUnresponsive = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.delegate && [self.delegate respondsToSelector:@selector(shouldUploadUIFrozenException)]) {
                    NSDictionary *vh = [[HMDUIViewHierarchy shared] getViewHierarchy:self->_targetWindow
                                                                           superView:nil
                                                                             superVC:nil
                                                                          withDetail:YES
                                                                          targetView:self->_targetWindow];
                    NSMutableDictionary *notificationObject = [NSMutableDictionary new];
                    [notificationObject setObject:vh forKey:@"view_hierarchy"];
                    [notificationObject setObject:[self->_gestures copy] forKey:@"gesture"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:HMDUIFrozenNotificationGestureUnresponsive object:[notificationObject copy]];
                    //upload uifrozen exception
                    BOOL shouleUpload = [self.delegate shouldUploadUIFrozenException];
                    if (shouleUpload) {
                        [self uploadGestureUnresponsiveExceptionWithViewHierarchy:vh];
                    } else {
                        [self resetRecord];
                    }
                }
            });
        }
        pthread_mutex_unlock(&recordLock);
    });
}


- (NSData *)snapShotOfView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapShotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImageJPEGRepresentation(snapShotImage, 0.6);
    return data;
}

-(void)consumeStoreGestureRecordWithBlock:(HMDUIFrozenGestureRecordBlock)block
{
    dispatch_async(_consumeQueue, ^{
        pthread_mutex_lock(&recordLock);
        if (!self->_isRecording) {
            pthread_mutex_unlock(&recordLock);
            return;
        }
        if (self->_gestures.count > 0) {
            if (block) {
                block([self->_gestures firstObject]);
            }
            if (self->_isUnresponsive) {
                //清除手势记录
//                self->_isUnresponsive = NO;
                [self->_gestures removeAllObjects];
            }else{
                [self->_gestures removeObjectAtIndex:0];
            }
        }
        pthread_mutex_unlock(&recordLock);
    });
}

#pragma mark - upload

-(void)uploadGestureUnresponsiveExceptionWithViewHierarchy:(NSDictionary *)vh {
    
    NSTimeInterval timestamp = HMD_XNUSystemCall_timeSince1970();
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:@"GestureUnresponsive" forKey:kHMDUIFrozenKeyType];
    [data setValue:[HMDUIViewHierarchy getDescriptionForUI:self->_targetWindow] forKey:kHMDUIFrozenKeyTargetView];
    [data setValue:[HMDUIViewHierarchy getDescriptionForUI:self->_targetWindow] forKey:kHMDUIFrozenKeyTargetWindow];
    [data setValue:vh forKey:kHMDUIFrozenKeyViewHierarchy];
    [data setValue:[HMDUIViewHierarchy getDescriptionForUI:self->_targetWindow.rootViewController] forKey:kHMDUIFrozenKeyViewControllerHierarchy];
    [data setValue:@(timestamp) forKey:kHMDUIFrozenKeyTimestamp];
    [data setValue:@(self->_gestures.count) forKey:kHMDUIFrozenKeyOperationCount];
    NSTimeInterval launchTS = [HMDSessionTracker currentSession].timestamp;
    [data setValue:@(timestamp-launchTS) forKey:kHMDUIFrozenKeyinAppTime];
    [data setValue:((timestamp-launchTS)<=[HMDUIFrozenManager sharedInstance].launchCrashThreshold) ? @(YES) : @(NO) forKey:kHMDUIFrozenKeyIsLaunchCrash];
    NSDictionary *settings = @{
        @"operation_count_threshold" : @([HMDUIFrozenManager sharedInstance].operationCountThreshold),
        @"launch_crash_threshold" : @([HMDUIFrozenManager sharedInstance].launchCrashThreshold),
        @"upload_alog" : @([HMDUIFrozenManager sharedInstance].uploadAlog),
    };
    [data setValue:settings forKey:kHMDUIFrozenKeySettings];
//                [data setValue:[self nearViewController:targetView] forKey:kHMDUIFrozenKeyNearViewController];
//                [data setValue:[self nearViewControllerDesc:targetView] forKey:kHMDUIFrozenKeyNearViewControllerDesc];

    // 性能数据
    [data setValue:[HMDNetworkHelper connectTypeName]?:@"" forKey:kHMDUIFrozenKeyNetwork];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double memoryUsage = memoryBytes.appMemory / (double)HMD_MB;
    [data setValue:@(memoryUsage) forKey:kHMDUIFrozenKeyMemoryUsage];
    [data setValue:@(memoryBytes.availabelMemory) forKey:HMD_Free_Memory_Key];
    NSInteger freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
    [data setValue:@(freeDiskBlockSize) forKey:kHMDUIFrozenKeyFreeDiskBlockSize];

    // 业务数据
    [data setValue:[HMDSessionTracker currentSession].sessionID
            forKey:kHMDUIFrozenKeySessionID];
    [data setValue:[HMDSessionTracker sharedInstance].eternalSessionID
            forKey:kHMDUIFrozenKeyInternalSessionID];
    [data setValue:[HMDUITrackerManager sharedManager].scene ?: @"unknown"
            forKey:kHMDUIFrozenKeylastScene];
    [data setValue:[HMDUITrackerManager sharedManager].sharedOperationTrace
            forKey:kHMDUIFrozenKeyOperationTrace];
    [data setValue:@([HMDNetworkHelper currentNetQuality]) forKey:kHMDUIFrozenKeyNetQuality];
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    [data setValue:injectedInfo.business ?: @"unknown" forKey:kHMDUIFrozenKeyBusiness];
    if ( self.delegate && [self.delegate respondsToSelector:@selector(getCustomExceptionData)]) {
        NSDictionary *custom = [self.delegate getCustomExceptionData];
        if (custom) {
            [data setValue:custom forKey:kHMDUIFrozenKeyCustom];
        }
    }
    [data setValue:injectedInfo.filters forKey:kHMDUIFrozenKeyFilters];
    
    HMDUIFrozenManager *manager = [HMDUIFrozenManager sharedInstance];
    if (data && manager.delegate && [manager.delegate respondsToSelector:@selector(didDetectUIFrozenWithData:)]) {
        [manager.delegate didDetectUIFrozenWithData:[data copy]];
    }

}

@end
