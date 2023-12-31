//
//  EMALifeCycleManager.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/4/22.
//

#import "EMALifeCycleManager.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPLifeCyclePluginDelegate.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <objc/runtime.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <ECOInfra/EMAFeatureGating.h>
#import <ECOProbe/ECOProbe-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <ECOProbe/ECOProbe-Swift.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/OPNoticeManager.h>
#import "EMAAppEngine.h"

static const char * OP_APP_UNIUQE_ID_KEY = "life_cycle_uniqueid";

@interface EMALifeCycleBlockCallback ()

@property (nonatomic, copy) void (^continueCallback)();
@property (nonatomic, copy) void (^cancelCallback)();

@end

@implementation EMALifeCycleBlockCallback

- (void)continueLoading {
    BDPExecuteOnMainQueue(^{
        if (self.continueCallback) {
            self.continueCallback();

            self.continueCallback = nil;
            self.cancelCallback = nil;
        }
    });
}

- (void)cancelLoading {
    BDPExecuteOnMainQueue(^{
        if (self.cancelCallback) {
            self.cancelCallback();

            self.continueCallback = nil;
            self.cancelCallback = nil;
        }
    });
}

@end

@interface EMALifeCycleManager () <BDPLifeCyclePluginDelegate, OPHeartBeatMonitorBizProvider>

@property (nonatomic, strong) NSMutableArray<id<EMALifeCycleListener> > *listeners;
@property (nonatomic, copy, readwrite, nullable) NSMutableSet<BDPUniqueID *> *mCurrentApps;
@property (nonatomic, copy, readwrite, nullable) BDPUniqueID *currentUniqueID;
@property (nonatomic, copy, readwrite, nullable) NSString *currentAppVersion;
@property (nonatomic, copy, readwrite, nullable) NSString *currentAppSceneCode;
@property (nonatomic, copy, readwrite, nullable) NSString *currentAppSubSceneCode;
@property (nonatomic, copy, readwrite, nullable) NSString *currentContextID;
@property (nonatomic, copy, readwrite, nullable) NSMutableSet<BDPUniqueID *> *currenForegroundApps;
@end

@implementation EMALifeCycleManager

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (id<BDPLifeCyclePluginDelegate>)sharedPlugin {
    return self.sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _listeners = NSMutableArray.array;
        _mCurrentApps = NSMutableSet.set;
        _currenForegroundApps = NSMutableSet.set;
    }
    return self;
}

- (NSSet<BDPUniqueID *> *)currentApps {
    return self.mCurrentApps.copy;
}

- (NSString *)generateNewContextID {
    static NSInteger gContextIndex = 0;
    NSInteger timeMS = (NSInteger)(NSDate.date.timeIntervalSince1970 * 1000);
    NSString *uniqueID = self.currentUniqueID.fullString;
    NSInteger contextIndex = (++gContextIndex);
    NSString *uuid = [NSUUID UUID].UUIDString;
    return [NSString stringWithFormat:@"%llu_%@_%llu_%@", timeMS, uniqueID, contextIndex, uuid];
}

- (void)setCurrentUniqueID:(BDPUniqueID *)currentUniqueID {
    if (_currentUniqueID != currentUniqueID) {
        _currentUniqueID = currentUniqueID;

        _currentAppVersion = nil;
        _currentAppSceneCode = nil;
        _currentAppSubSceneCode = nil;

        self.currentContextID = [self generateNewContextID];
    }

    // 更新appVersion
    if (currentUniqueID && !_currentAppVersion) {
    	BDPCommon *common = BDPCommonFromUniqueID(currentUniqueID);
        _currentAppVersion = common.model.version;
        _currentAppSceneCode = common.schema.scene;
        _currentAppSubSceneCode = common.schema.subScene;
    }
}

- (void)addListener:(id<EMALifeCycleListener> _Nonnull)listener forUniqueID:(BDPUniqueID * _Nonnull)uniqueID {
    BDPLogInfo(@"addListener, uniqueID=%@, listener=%@", uniqueID, NSStringFromClass(listener.class));
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDisableAppCharacter].boolValue) {
        return;
    }
    if (!listener) {
        BDPLogWarn(@"!listener");
        return;
    }
    @synchronized (self.listeners) {
        if ([self.listeners containsObject:listener]) {
            BDPLogWarn(@"listener has been added");
            return;
        }
        objc_setAssociatedObject(listener, OP_APP_UNIUQE_ID_KEY, uniqueID, OBJC_ASSOCIATION_RETAIN);
        [self.listeners addObject:listener];
    }
}

- (void)addListener:(id<EMALifeCycleListener> _Nonnull)listener {
    BDPLogInfo(@"addListener, listener=%@", NSStringFromClass(listener.class));
    @synchronized (self.listeners) {
        [self addListener:listener forUniqueID:nil];
    }
}

- (void)removeListener:(id<EMALifeCycleListener> _Nonnull)listener {
    BDPLogInfo(@"removeListener, listener=%@", NSStringFromClass(listener.class));
    @synchronized (self.listeners) {
        [self.listeners removeObject:listener];
    }
}

/**
 通过uniqueID彻底杀掉小程序

 @param uniqueID uniqueID
 */
- (void)closeMicroAppWithUniqueID:(BDPUniqueID *)uniqueID {
    
    // 主动关闭页面需要尝试关闭标签(内部判断是否在标签打开)
    [[OPApplicationService.current getContainerWithUniuqeID:uniqueID] removeTemporaryTab];
    // 这里需要完全退出
    [[OPApplicationService.current getContainerWithUniuqeID:uniqueID] destroyWithMonitorCode:GDMonitorCode.life_cycle_dismiss];

    // 全部close完成后清理tracing
    [[BDPTracingManager sharedInstance] clearTracingByUniqueID:uniqueID];
}

- (void)enumerateInstanceListener:(void(^)(id<EMALifeCycleListener> listener))enumerateBlock forUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID || !enumerateBlock) {
        return;
    }
    NSArray *listeners = nil;
    @synchronized (self.listeners) {
        listeners = self.listeners.copy;
    }
    for (id<EMALifeCycleListener> listener in listeners) {
        OPAppUniqueID *listenerUniqueID = objc_getAssociatedObject(listener, OP_APP_UNIUQE_ID_KEY);
        if ((listenerUniqueID && [uniqueID isEqual:listenerUniqueID]) || (!listenerUniqueID)) {
            enumerateBlock(listener);
        }
    }
}

- (void)bdp_onContainerLoaded:(BDPUniqueID *)uniqueID container:(UIViewController *)container {
    BDPLogInfo(@"bdp_onContainerLoaded, app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onContainerLoaded:container:)]) {
            [instanceListener onContainerLoaded:uniqueID container:container];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onStart:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_onStart, app=%@", uniqueID);
    self.currentUniqueID = uniqueID;
    //preload
    [[EMAAppEngine currentEngine].preloadManager preloadWithUniqueID:uniqueID];
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onStart:)]) {
            [instanceListener onStart:uniqueID];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_beforeLaunch:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_beforeLaunch, app=%@", uniqueID);
    self.currentUniqueID = uniqueID;
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(beforeLaunch:)]) {
            [instanceListener beforeLaunch:uniqueID];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onLaunch:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_onLaunch, app=%@", uniqueID);
    self.currentUniqueID = uniqueID;
    [self.mCurrentApps addObject:uniqueID];
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onLaunch:)]) {
            [instanceListener onLaunch:uniqueID];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onCancel:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_onCancel, app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onCancel:)]) {
            [instanceListener onCancel:uniqueID];
        }
    } forUniqueID:uniqueID];
    if ([self.currentUniqueID isEqual:uniqueID]) {
        self.currentUniqueID = nil;
    }
}

- (void)bdp_onPageDomReady:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId {
    BDPLogInfo(@"bdp_onPageDomReady, app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onPageDomReady:page:)]) {
            [instanceListener onPageDomReady:uniqueID page:appPageId];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_beforeLoadAppServiceJS:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_beforeLoadAppServiceJS, app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(beforeLoadAppServiceJS:)]) {
            [instanceListener beforeLoadAppServiceJS:uniqueID];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_beforeLoadPageFrameJS:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId {
    BDPLogInfo(@"bdp_beforeLoadPageFrameJS, app=%@, page=%@", uniqueID, @(appPageId));
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(beforeLoadPageFrameJS:page:)]) {
            [instanceListener beforeLoadPageFrameJS:uniqueID page:appPageId];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_beforeLoadPageJS:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId{
    BDPLogInfo(@"bdp_beforeLoadPageJS, app=%@, page=%@", uniqueID, @(appPageId));
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(beforeLoadPageJS:page:)]) {
            [instanceListener beforeLoadPageJS:uniqueID page:appPageId];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onPageCrashed:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId visible:(BOOL)visible {
    BDPLogError(@"bdp_beforeLoadPageFrameJS, app=%@, page=%@, visible=%@", uniqueID, @(appPageId), @(visible));
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onPageCrashed:page:visible:)]) {
            [instanceListener onPageCrashed:uniqueID page:appPageId visible:visible];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onFirstFrameRender:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_beforeLoadPageFrameJS, app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onFirstFrameRender:)]) {
            [instanceListener onFirstFrameRender:uniqueID];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onModelFetchedForUniqueID:(BDPUniqueID *)uniqueID isSilenceFetched:(BOOL)isSilenceFetched isModelCached:(BOOL)isModelCached appModel:(BDPModel *)appModel error:(NSError *)error {
    if (error) {
        BDPLogError(@"bdp_onModelFetched, app=%@, isSilenceFetched=%@, isModelCached=%@, appModel=%@, error=%@", uniqueID, @(isSilenceFetched), @(isModelCached), appModel, error);
    } else {
        BDPLogInfo(@"bdp_onModelFetched, app=%@, isSilenceFetched=%@, isModelCached=%@, appModel=%@", uniqueID, @(isSilenceFetched), @(isModelCached), appModel);
    }
    if (!isSilenceFetched) {
        self.currentUniqueID = uniqueID;
    }
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onModelFetchedForUniqueID:isSilenceFetched:isModelCached:appModel:error:)]) {
            [instanceListener onModelFetchedForUniqueID:uniqueID isSilenceFetched:isSilenceFetched isModelCached:isModelCached appModel:appModel error:error];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onPkgFetched:(BDPUniqueID *)uniqueID error:(NSError *)error {
    if (error) {
        BDPLogError(@"bdp_onPkgFetched, app=%@, error=%@", uniqueID, error);
    } else {
        BDPLogInfo(@"bdp_onPkgFetched, app=%@", uniqueID);
    }
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onPkgFetched:error:)]) {
            [instanceListener onPkgFetched:uniqueID error:error];
        }
    } forUniqueID:uniqueID];
}

- (void)bdp_onShow:(BDPUniqueID *)uniqueID startPage:(nullable NSString *)startPage {
    BDPLogInfo(@"bdp_onShow, app=%@", uniqueID);
    BDPMonitorWithCode(GDMonitorCodeLifecycle.gadget_foreground, uniqueID)
    .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
    .flush();
    self.currentUniqueID = uniqueID;
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onShow:startPage:)]) {
            [instanceListener onShow:uniqueID startPage:startPage];
        }
    } forUniqueID:uniqueID];
    // 小程序应用时长统计接入心跳埋点
    [_currenForegroundApps addObject:uniqueID];
    OPMonitorEvent *event = BDPMonitorWithCode(EPMClientOpenPlatformGadgetLifecycleCode.gadget_heartbeat, uniqueID);
    OPHeartBeatMonitorBizSource *source = [[OPHeartBeatMonitorBizSource alloc] initWithHeartBeatID:uniqueID.fullString monitorData:event];
    [[OPHeartBeatMonitorService default] registerHeartBeatWith:source provider:self];
}

- (void)bdp_onHide:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_onHide, app=%@", uniqueID);
    BDPMonitorWithCode(GDMonitorCodeLifecycle.gadget_background, uniqueID)
    .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
    .flush();
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onHide:)]) {
            [instanceListener onHide:uniqueID];
        }
    } forUniqueID:uniqueID];
    [_currenForegroundApps removeObject:uniqueID];
    [[OPHeartBeatMonitorService default] endHeartBeatFor:uniqueID.fullString];
}

- (void)bdp_onDestroy:(BDPUniqueID *)uniqueID {
    BDPLogInfo(@"bdp_onDestroy, app=%@", uniqueID);
    [self.mCurrentApps removeObject:uniqueID];
    [_currenForegroundApps removeObject:uniqueID];
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onDestroy:)]) {
            [instanceListener onDestroy:uniqueID];
        }
    } forUniqueID:uniqueID];
    if ([self.currentUniqueID isEqual:uniqueID]) {
        self.currentUniqueID = nil;
    }
}

- (void)bdp_onFailure:(BDPUniqueID *)uniqueID code:(OPMonitorCode *)code msg:(NSString *)msg {
    BDPLogError(@"bdp_onFailure, app=%@, code=%@, msg=%@", uniqueID, code, msg);
    EMALifeCycleErrorCode errCode = code;
    // 内部错误 -> 对外统一错误(iOS & Android 保持一致)
    if (code == GDMonitorCodeLaunch.meta_info_fail) {
        errCode = EMALifeCycleErrorCodeMetaInfoFail;
    } else if (code == GDMonitorCodeLaunch.download_fail) {
        errCode = EMALifeCycleErrorCodeAppDownloadFail;
    } else if (code == GDMonitorCodeLaunch.offline) {
        errCode = EMALifeCycleErrorCodeOffline;
    } else if (code == GDMonitorCodeLaunch.jssdk_old) {
        errCode = EMALifeCycleErrorCodeJSSDKOld;
    } else if (code == GDMonitorCodeLaunch.service_disabled) {
        errCode = EMALifeCycleErrorCodeServiceDisabled;
    } else if (code == GDMonitorCodeLaunch.environment_invalid) {
        errCode = EMALifeCycleErrorCodeEnvironmentInvalid;
    } else if (code == GDMonitorCodeLaunch.lark_version_old) {
        // 这边需要对错误映射一下, 否则数据类型对不上
        // Note: EMALifeCycleErrorCode这个应该已经不使用了,这边暂时对枚举不做新增.
        errCode = EMALifeCycleErrorCodeJSSDKOld;
    }

    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onFailure:code:msg:)]) {
            [instanceListener onFailure:uniqueID code:errCode msg:msg];
        }
    } forUniqueID:uniqueID];
    if ([self.currentUniqueID isEqual:uniqueID]) {
        self.currentUniqueID = nil;
    }
}

- (void)bdp_blockLoading:(BDPUniqueID *)uniqueID  startPage:(nullable NSString *)startPage continueCallback:(void (^)())continueCallback cancelCallback:(void (^)(OPMonitorCode * reason))cancelCallback {
    BDPLogInfo(@"bdp_blockLoading, app=%@", uniqueID);
    if (!continueCallback || !cancelCallback) {
        BDPLogWarn(@"!continueCallback || !cancelCallback");
        return;
    }
    //Main Thread
    NSMutableArray *instanceListeners = NSMutableArray.array;
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(blockLoading:startPage:callback:)]) {
            [instanceListeners addObject:instanceListener];
        }
    } forUniqueID:uniqueID];

    NSUInteger totalCount = instanceListeners.count;
    if (totalCount == 0) {
        continueCallback();
        BDPLogInfo(@"continueCallback final");
        return;
    }

    __block NSUInteger continueCount = 0;
    __block NSUInteger cancelCount = 0;

    for (id<EMALifeCycleListener>  listener in instanceListeners) {
        NSInteger listenerHash = listener.hash;
        EMALifeCycleBlockCallback *callback = EMALifeCycleBlockCallback.new;
        callback.continueCallback = ^{
            //Main Thread
            continueCount++;
            BDPLogInfo(@"continue %@", BDPParamStr(uniqueID, listenerHash, continueCount, cancelCount, totalCount));
            if (continueCount + cancelCount == totalCount) {
                if (cancelCount == 0) {
                    continueCallback();
                    BDPLogInfo(@"continueCallback final");
                } else {
                    cancelCallback(nil);    // TODO: 需要应用机制接入异常原因 callback
                    BDPLogInfo(@"cancelCallback final");
                }
            }
        };
        callback.cancelCallback = ^{
            //Main Thread
            cancelCount++;
            BDPLogInfo(@"cancel %@", BDPParamStr(uniqueID, listenerHash, continueCount, cancelCount, totalCount));
            if (continueCount + cancelCount == totalCount) {
                if (cancelCount == 0) {
                    continueCallback();
                    BDPLogInfo(@"continueCallback final");
                } else {
                    cancelCallback(nil);    // TODO: 需要应用机制接入异常原因 callback
                    BDPLogInfo(@"cancelCallback final");
                }
            }
        };
        BDPLogInfo(@"blockLoading %@", BDPParamStr(uniqueID, listenerHash));
        [listener blockLoading:uniqueID startPage:startPage callback:callback];
    }
}

- (void)bdp_onFirstAppear:(OPAppUniqueID *)uniqueID {
    BDPLogInfo(@"app=%@", uniqueID);
    [self enumerateInstanceListener:^(id<EMALifeCycleListener> instanceListener) {
        if ([instanceListener respondsToSelector:@selector(onFirstAppear:)]) {
            [instanceListener onFirstAppear:uniqueID];
        }
    } forUniqueID:uniqueID];
}

// 小程序应用时长统计接入心跳埋点,定时轮询状态
- (enum OPHeartBeatMonitorSourceStatus)getCurrentStatusOf:(NSString *)heartBeatID {
    __block OPHeartBeatMonitorSourceStatus status = OPHeartBeatMonitorSourceStatusUnknown;
    [_currenForegroundApps enumerateObjectsUsingBlock:^(OPAppUniqueID * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.fullString isEqualToString:heartBeatID]) {
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:obj];
            if (common && !common.isDestroyed) {
                status = OPHeartBeatMonitorSourceStatusActive;
            }
            *stop = YES;
        }
    }];
    return status;
}
@end
