//
//  HMDUIFrozenManager.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import "HMDUIFrozenManager.h"
#import "HMDUIFrozenDetectProtocol.h"
#import "HMDSwizzle.h"
#import <UIKit/UIKit.h>
#import "HMDALogProtocol.h"
#import "HMDTimeSepc.h"
#import "HMDUIFrozenDefine.h"
#import "HMDSessionTracker.h"
#import "HMDNetworkHelper.h"
#import "HMDMemoryUsage.h"
#import "HMDDiskUsage.h"
#import "HeimdallrUtilities.h"
#import "HMDUITrackerManager.h"
#import "HMDInjectedInfo.h"
#import "HMDUIViewHierarchy.h"
#import "HMDUITrackerTool.h"
#import "HMDSimpleBackgroundTask.h"
#import "HMDMacro.h"
// 监控数据
NSString * const kHMDUIFrozenKeyType = @"frozen_type";
NSString * const kHMDUIFrozenKeyTargetView = @"target_view";
NSString * const kHMDUIFrozenKeyTargetWindow = @"target_window";
NSString * const kHMDUIFrozenKeyViewHierarchy = @"view_hierarchy";
NSString * const kHMDUIFrozenKeyResponseChain = @"response_chain";
NSString * const kHMDUIFrozenKeyViewControllerHierarchy = @"view_controller_hierarchy";
NSString * const kHMDUIFrozenKeySnapshot = @"snapshot";
NSString * const kHMDUIFrozenKeyOperationCount = @"operationCount";
NSString * const kHMDUIFrozenKeyIsLaunchCrash = @"is_launch_crash";
NSString * const kHMDUIFrozenKeyStartTimestamp = @"startTimestamp";
NSString * const kHMDUIFrozenKeyTimestamp = @"timestamp";
NSString * const kHMDUIFrozenKeyinAppTime = @"inapp_time";
NSString * const kHMDUIFrozenKeySettings = @"settings";
NSString * const kHMDUIFrozenKeyNearViewController = @"near_view_controller";
NSString * const kHMDUIFrozenKeyNearViewControllerDesc = @"near_view_controller_desc";

// 性能数据
NSString * const kHMDUIFrozenKeyNetwork = @"access";
NSString * const kHMDUIFrozenKeyMemoryUsage = @"memory_usage";
NSString * const kHMDUIFrozenKeyFreeMemoryUsage = @"free_memory_usage";
NSString * const kHMDUIFrozenKeyFreeDiskBlockSize = @"d_zoom_free";

// 业务数据
NSString * const kHMDUIFrozenKeyBusiness = @"business";
NSString * const kHMDUIFrozenKeySessionID = @"session_id";
NSString * const kHMDUIFrozenKeyInternalSessionID = @"internal_session_id";
NSString * const kHMDUIFrozenKeylastScene = @"last_scene";
NSString * const kHMDUIFrozenKeyOperationTrace = @"operation_trace";
NSString * const kHMDUIFrozenKeyNetQuality = @"network_quality";
NSString * const kHMDUIFrozenKeyCustom = @"custom";
NSString * const kHMDUIFrozenKeyFilters = @"filters";

// Default:
NSUInteger HMDUIFrozenDefaultOperationCountThreshold = 5;
NSTimeInterval HMDUIFrozenDefaultLaunchCrashThreshold = 10.f;
BOOL HMDUIFrozenDefaultUploadAlog = NO;
NSUInteger HMDUIFrozenDefaultGestureCountThreshold = 10;
BOOL HMDUIFrozenDefaultEnableGestureMonitor = NO;

// Notification
NSNotificationName const HMDUIFrozenNotificationDidEnterBackground = @"HMDUIFrozenNotificationDidEnterBackground";

// 文件
static NSString * const kHMDUIFrozenDirectoryName = @"UIFrozen"; // 文件夹名
static NSString *kHMDUIFrozenFileName = @"UIFrozenInfo.plist"; // 文件名

// 记录
// hitTest相关
static BOOL hitTestIncreaseTag = NO;
static NSUInteger invalidHitTestCount = 0;
static NSTimeInterval hitTestEventTS = 0.0;
static NSTimeInterval hitTestLastTS = 0.0;
static __weak UIView *hitTestFirstResponder = nil;

// sendEvent
static BOOL invalidOperationFlag = NO;
static BOOL isNeedCallOriginTouchendMethod = YES;
static NSUInteger invalidSendEventCount = 0;
static NSTimeInterval sendEventTS = 0;
static __weak UIView *sendEventFirstResponder = nil;

#pragma mark - AppDelegate

@protocol HMDUIFrozenApplicationDelegate<UIApplicationDelegate>
- (void)HMDUIFrozenTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
@end

static void HMDUIFrozenIMP_touchesEnded_withEvent(id<HMDUIFrozenApplicationDelegate> thisSelf, SEL selector, NSSet<UITouch *> *touches, UIEvent *event) {
    invalidOperationFlag = true;
    if (isNeedCallOriginTouchendMethod) {
        [thisSelf HMDUIFrozenTouchesEnded:touches withEvent:event];
    }
}

#pragma mark - UIApplication

static __weak UIView *firstResponder = nil;

@implementation UIApplication (HMDUIFrozen)

- (void)HMDUIFrozenSendEvent:(UIEvent *)event {
    [self HMDUIFrozenSendEvent:event];
    invalidHitTestCount = 0;
    if (event.type == UIEventTypeTouches) {
        for (UITouch *touch in event.allTouches) {
            if (touch.phase == UITouchPhaseEnded) {
                // 发生冻屏
                if (invalidOperationFlag) {
                    invalidOperationFlag = NO;
                    if (sendEventFirstResponder == touch.view) {
                        invalidSendEventCount++;
                    }
                    else {
                        sendEventFirstResponder = touch.view;
                        invalidSendEventCount = 1;
                        sendEventTS = HMD_XNUSystemCall_timeSince1970();
                    }
                    DEBUG_LOG("[UIFrozen] Invalid operation count:%lu view:%s",
                              (unsigned long)invalidSendEventCount, touch.view.description.UTF8String);
                }
                // 冻屏恢复
                else if (invalidSendEventCount > 0) {
                    invalidSendEventCount = 0;
                    sendEventTS = 0;
                    DEBUG_LOG("[UIFrozen] recovery");
                    break;
                }
                // 正常
                else {
                    break;
                }
            }
        }
    }
}

@end

#pragma mark - UIWindow

@implementation UIWindow (HMDUIFrozen)

- (UIView *)HMDUIFrozenHitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 一次手势开始时会对每个window分别调用该方法，通过时间戳判断是否为同一Event事件
    // invalidHitTestCount对无效的hitTest进行计数，若后续调用了-[UIApplication sendEvent:]，则清0
    if (fabs(event.timestamp-hitTestLastTS)<0.001) {
        if (!hitTestIncreaseTag) {
            invalidHitTestCount++;
        }

        hitTestIncreaseTag = YES;
    }
    else {
        hitTestIncreaseTag = NO;
//        hitTestEventTS = event.timestamp; event中的timestamp不是时间戳，而是系统启动至现在的秒数
        hitTestLastTS = event.timestamp;
        hitTestEventTS = HMD_XNUSystemCall_timeSince1970();
    }

    UIView *view = [self HMDUIFrozenHitTest:point withEvent:event];
    hitTestFirstResponder = view;
    return view;
}

@end

#pragma mark - HMDUIFrozenManager

@interface HMDUIFrozenManager()
{
    dispatch_queue_t _serailQueue;
    BOOL _initFlag;
    NSString *_rootDirPath;
}
@end

@implementation HMDUIFrozenManager

#pragma mark - Init

+ (instancetype)sharedInstance {
    static HMDUIFrozenManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HMDUIFrozenManager alloc] init];
    });

    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enable = NO;
        _operationCountThreshold = HMDUIFrozenDefaultOperationCountThreshold;
        _launchCrashThreshold = HMDUIFrozenDefaultLaunchCrashThreshold;
        _uploadAlog = HMDUIFrozenDefaultUploadAlog;
        _gestureCountThreshold = HMDUIFrozenDefaultGestureCountThreshold;
        _serailQueue = dispatch_queue_create("com.heimdallr.uifrozen", DISPATCH_QUEUE_SERIAL);
        _initFlag = NO;
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)start {
    dispatch_async(_serailQueue, ^{
        if (!self->_enable) {
            [self initUIFrozen];
            self->_enable = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminate:) name:UIApplicationWillTerminateNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
    });
}

- (void)stop {
    dispatch_async(_serailQueue, ^{
        if (self->_enable) {
            self->_enable = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
        }
    });
}

#pragma mark - Private

- (void)initUIFrozen {
    // 初始化方法只执行一次
    if (_initFlag) {
        return;
    }

    _initFlag = YES;
    if([self initDirectory]) {
        [self checkExceptionLastTime];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self swizzleMonitorMethod];
    });
    
    
}

- (BOOL)initDirectory {
    _rootDirPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMDUIFrozenDirectoryName];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isEst = [manager fileExistsAtPath:_rootDirPath isDirectory:&isDir];
    if(isEst && isDir) {
        return YES;
    }

    NSError *error = nil;
    BOOL rst = [manager createDirectoryAtPath:_rootDirPath
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error];
    if (error) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init directory failed with error %@", error);
    }

    return rst;
}

// 检查上次启动是否存在冻屏异常
- (void)checkExceptionLastTime {
    NSDictionary *data = nil;
    NSString *filePath = [_rootDirPath stringByAppendingPathComponent:kHMDUIFrozenFileName];
    if (@available(iOS 11.0, *)) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        data = [NSDictionary dictionaryWithContentsOfURL:fileURL error:nil];
    }
    else {
        data = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }

    if (data && self.delegate && [self.delegate respondsToSelector:@selector(didDetectUIFrozenWithData:)]) {
        [self.delegate didDetectUIFrozenWithData:[data copy]];
    }

    [self clearLocalFile];
}

- (BOOL)clearLocalFile {
    NSString *filePath = [_rootDirPath stringByAppendingPathComponent:kHMDUIFrozenFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] remove file failed with error %@", error);
            return NO;
        }
    }

    return YES;
}

bool frozen_swizzle_touchesEnd_method_with_imp(Class appdelegate, SEL touchesEndSEL, SEL frozenTouchesEndSEL, IMP frozenTouchesEndIMP)
{
    Method originMethod = class_getInstanceMethod(appdelegate, touchesEndSEL);
    Method uiresponderMethod = class_getInstanceMethod([UIResponder class], touchesEndSEL);
    const char *methodType = method_getTypeEncoding(originMethod);
    if (originMethod == uiresponderMethod) {
        // appdelegate no overwrite touchesEnded:withEvent:
        isNeedCallOriginTouchendMethod = NO;
        if (frozenTouchesEndIMP && class_addMethod(appdelegate, touchesEndSEL, frozenTouchesEndIMP, methodType)) {
            return true;
        }
    }
    else
    {
        // appdelegate overwrite touchesEnded:withEvent:
        IMP originIMP = method_getImplementation(originMethod);
        isNeedCallOriginTouchendMethod = YES;
        if (originIMP && frozenTouchesEndIMP && originIMP != frozenTouchesEndIMP) {
            if(class_addMethod(appdelegate, frozenTouchesEndSEL, originIMP, methodType)) {
                class_replaceMethod(appdelegate, touchesEndSEL, frozenTouchesEndIMP, methodType);
                return true;
            } DEBUG_ELSE
        } DEBUG_ELSE
    }
    return false;
}


- (void)swizzleMonitorMethod {
    UIApplication *appApplication = UIApplication.sharedApplication;
    if(appApplication) {
        if(![appApplication isKindOfClass:UIResponder.class]) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init failed because of Not currently supported UIApplication not inherit UIResponder");
            return;
        }
        if(frozen_swizzle_touchesEnd_method_with_imp([appApplication class],
                                                      @selector(touchesEnded:withEvent:),
                                                      @selector(HMDUIFrozenTouchesEnded:withEvent:),
                                                      (IMP) HMDUIFrozenIMP_touchesEnded_withEvent)) {
            if(!hmd_swizzle_instance_method([UIApplication class], @selector(sendEvent:), @selector(HMDUIFrozenSendEvent:))) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init failed because of exchange UIApplication sendEvent:");
            }

            if(!hmd_swizzle_instance_method([UIWindow class], @selector(hitTest:withEvent:), @selector(HMDUIFrozenHitTest:withEvent:))) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init failed because of exchange UIWindow hitTest:withEvent:");
            }
        }
        else {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init failed because of exchange UIApplication touchedEned:withEvent:");
        }

    }
    else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] init failed because of nil UIApplication");
    }
}

- (void)didEnterBackground:(NSNotification *)notification
{
    NSTimeInterval eventTS = 0;
    NSUInteger count = 0;
    NSString *frozenType = nil;
    __strong UIView *targetView = nil;
    if (invalidHitTestCount >= _operationCountThreshold) {
        eventTS = hitTestEventTS;
        count = invalidHitTestCount;
        frozenType = @"HitTest";
        targetView = hitTestFirstResponder;
    }
    else if (invalidSendEventCount >= _operationCountThreshold) {
        eventTS = sendEventTS;
        count = invalidSendEventCount;
        frozenType = @"SendEvent";
        targetView = sendEventFirstResponder;
    }
    else {
        return;
    }

    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:frozenType forKey:kHMDUIFrozenKeyType];
    [data setValue:@(eventTS) forKey:kHMDUIFrozenKeyStartTimestamp];
    [data setValue:targetView forKey:kHMDUIFrozenKeyTargetView];
    [data setValue:@(count) forKey:kHMDUIFrozenKeyOperationCount];
    NSDictionary *notificationObject = [data copy];

    if (targetView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:HMDUIFrozenNotificationDidEnterBackground object:notificationObject];
        });
    }
}

- (void)terminate:(NSNotification *)notification {
    NSTimeInterval eventTS = 0;
    NSUInteger count = 0;
    NSString *frozenType = nil;
    __strong UIView *targetView = nil;
    if (invalidHitTestCount >= _operationCountThreshold) {
        eventTS = hitTestEventTS;
        count = invalidHitTestCount;
        frozenType = @"HitTest";
        targetView = hitTestFirstResponder;
    }
    else if (invalidSendEventCount >= _operationCountThreshold) {
        eventTS = sendEventTS;
        count = invalidSendEventCount;
        frozenType = @"SendEvent";
        targetView = sendEventFirstResponder;
    }
    else {
        return;
    }

    if (!targetView) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] capture failed because of nil firstResponder");
        return;
    }

    UIWindow *targetWindow = targetView.window;
    if (!targetWindow){
        //当某些hittest类冻屏，targetView.window
        targetWindow = HMDUITrackerTool.keyWindow;
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] capture failed because of nil window");
        if (!targetWindow){
            //未找到可以key window时返回
            return;
        }
    }

    NSTimeInterval timestamp = HMD_XNUSystemCall_timeSince1970();
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:frozenType forKey:kHMDUIFrozenKeyType];
    [data setValue:[HMDUIViewHierarchy getDescriptionForUI:targetView] forKey:kHMDUIFrozenKeyTargetView];
    [data setValue:[HMDUIViewHierarchy getDescriptionForUI:targetWindow] forKey:kHMDUIFrozenKeyTargetWindow];
    [data setValue:[self viewHierarchy:targetWindow targetView:targetView] forKey:kHMDUIFrozenKeyViewHierarchy];
    [data setValue:[self responseChain:targetView] forKey:kHMDUIFrozenKeyResponseChain];
    [data setValue:@(eventTS) forKey:kHMDUIFrozenKeyStartTimestamp];
    [data setValue:@(timestamp) forKey:kHMDUIFrozenKeyTimestamp];
    [data setValue:@(count) forKey:kHMDUIFrozenKeyOperationCount];
    NSTimeInterval launchTS = [HMDSessionTracker currentSession].timestamp;
    [data setValue:@(timestamp-launchTS) forKey:kHMDUIFrozenKeyinAppTime];
    [data setValue:((eventTS-launchTS)<=_launchCrashThreshold) ? @(YES) : @(NO) forKey:kHMDUIFrozenKeyIsLaunchCrash];
    NSDictionary *settings = @{
        @"operation_count_threshold" : @(_operationCountThreshold),
        @"launch_crash_threshold" : @(_launchCrashThreshold),
        @"upload_alog" : @(_uploadAlog),
    };
    [data setValue:settings forKey:kHMDUIFrozenKeySettings];
    [data setValue:[self nearViewController:targetView] forKey:kHMDUIFrozenKeyNearViewController];
    [data setValue:[self nearViewControllerDesc:targetView] forKey:kHMDUIFrozenKeyNearViewControllerDesc];

    // 性能数据
    [data setValue:[HMDNetworkHelper connectTypeName]?:@"" forKey:kHMDUIFrozenKeyNetwork];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double memoryUsage = memoryBytes.appMemory / (double)HMD_MEMORY_MB;
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
    [data setValue:injectedInfo.customContext forKey:kHMDUIFrozenKeyCustom];
    [data setValue:injectedInfo.filters forKey:kHMDUIFrozenKeyFilters];
    NSString *filePath = [_rootDirPath stringByAppendingPathComponent:kHMDUIFrozenFileName];
    
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:@"com.heimdallr.UIFrozen.saveFile" task:^(void (^ _Nonnull completeHandle)(void)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (@available(iOS 11.0, *)) {
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                NSError *error = nil;
                [data writeToURL:fileURL error:&error];
                if (error) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] write file failed with error %@", error);
                }
            }
            else {
                if(![data writeToFile:filePath atomically:YES]) {
                    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[UIFrozen] write file failed");
                }
            }
            completeHandle();
        });
    }];
}


-(NSDictionary *)viewHierarchy:(UIWindow *)window targetView:(UIView *)view {
    return [[HMDUIViewHierarchy shared] getViewHierarchy:window superView:nil superVC:nil withDetail:YES
                                                      targetView:view];
}

- (NSString *)responseChain:(UIView *)targetView {
    NSMutableString *log = [NSMutableString stringWithFormat:@"<%@: %p>", targetView.class, targetView];
    UIResponder *nextResponder = [targetView nextResponder];
    while (nextResponder) {
        [log appendString:@" - "];
        [log appendFormat:@"<%@: %p>", nextResponder.class, nextResponder];
        nextResponder = nextResponder.nextResponder;
    }
    return [log copy];
}

- (NSString *)nearViewController:(UIView *)targetView{
    UIResponder *nextResponder = [targetView nextResponder];
    while (nextResponder){
        if ([nextResponder isKindOfClass:[UIViewController class]]){
            return [NSString stringWithFormat:@"%@", [nextResponder class]];
        }
        nextResponder = nextResponder.nextResponder;
    }
    return @"unknown";
}

- (NSString *)nearViewControllerDesc:(UIView *)targetView{
    UIResponder *nextResponder = [targetView nextResponder];
    while (nextResponder){
        if ([nextResponder isKindOfClass:[UIViewController class]]){
            return [HMDUIViewHierarchy getDescriptionForUI:nextResponder];
        }
        nextResponder = nextResponder.nextResponder;
    }
    return @"unknown";
}

@end
