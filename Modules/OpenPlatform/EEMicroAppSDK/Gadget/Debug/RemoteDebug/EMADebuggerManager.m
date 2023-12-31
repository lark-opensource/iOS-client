//
//  EMADebuggerManager.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "EMADebuggerManager.h"
#import <OPFoundation/EMADebugUtil.h>
#import <TTMicroApp/EMADebuggerConnection.h>
#import "EMAI18n.h"
#import "EMALifeCycleManager.h"
#import <OPFoundation/NSURL+EMA.h>
#import <OPFoundation/NSURLComponents+EMA.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSandBoxHelper.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/BDPWarmBootManager.h>
#import <OPFoundation/BDPAppMetaUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@interface EMADebuggerManager() <EMALifeCycleListener>

@property (nonatomic, copy, nullable) NSString *url;    // 连接地址
@property (nonatomic, strong, nullable) NSMutableDictionary<OPAppUniqueID *, EMADebuggerConnection *> *debuggerConnections;    // 当前已建立的连接

@end

@implementation EMADebuggerManager

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _debuggerConnections = NSMutableDictionary.dictionary;
    }
    return self;
}

- (BOOL)serviceEnable {
    return !BDPIsEmptyString(self.url);
}

- (void)handleDebuggerWSURL:(NSString * _Nonnull)wsURL {
    if (BDPIsEmptyString(wsURL)) {
        return;
    }

    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:wsURL];
    if (!urlComponents) {
        return;
    }
    NSDictionary *query = urlComponents.ema_queryItems;
    NSString *allow = query[@"allow"];
    if ([allow isEqualToString:@"true"]) {
        urlComponents.query = nil;  // 删除 query 参数，里面有一些连接无关的参数
        [self enableDebuggerServiceWithURL:urlComponents.string];
    } else if ([allow isEqualToString:@"false"]) {
        [self disableDebuggerService];
    }
}

/// 开启 debugger 服务
- (void)enableDebuggerServiceWithURL:(NSString * _Nonnull)url {
    BDPLogInfo(@"enableDebuggerService, url=%@", url);
    if (BDPIsEmptyString(url)) {
        BDPLogWarn(@"url is empty");
        return;
    }

    if ([self.url isEqualToString:url]) {
        BDPLogInfo(@"same url");
        return;
    }

    // 更新debug配置
    [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableRemoteDebugger].boolValue = YES;
    [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRemoteDebuggerURL].stringValue = url;

    // 监听小程序生命周期
    [EMALifeCycleManager.sharedInstance removeListener:self];
    [EMALifeCycleManager.sharedInstance addListener:self];

    // 断开现有的所有连接
    [self closeAllConnections];

    self.url = url;

    // 对现有小程序全部重新建立连接
    [self connectAllDevApps];

    // 通知所有已打开的小程序，开关立即生效
    [self notifyDebuggerStateChange];
}

/// 关闭 debugger 服务
- (void)disableDebuggerService {
    BDPLogInfo(@"disableDebuggerService");

    // 移除监听小程序生命周期
    [EMALifeCycleManager.sharedInstance removeListener:self];

    self.url = nil;

    // 断开现有的所有连接
    [self closeAllConnections];

    // 通知所有已打开的小程序，开关立即生效
    [self notifyDebuggerStateChange];

    // 更新debug配置
    [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDEnableRemoteDebugger].boolValue = NO;
}

- (void)connectAppDebuggerForUniqueID:(BDPUniqueID * _Nonnull)uniqueID completion:(void (^ _Nullable)(BOOL success))completion {
    BDPLogInfo(@"connectAppDebuggerForUniqueID, uniqueID=%@", uniqueID);
    if (BDPIsEmptyString(self.url)) {
        BDPLogWarn(@"service not available");
        // 服务未开启
        if (completion) {
            completion(YES);
        }
        return;
    }
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID is invalid");
        if (completion) {
            completion(YES);
        }
        return;
    }

    if ([[BDPWarmBootManager sharedManager] hasCacheDataWithUniqueID:uniqueID]) {
        // 热启动: 异步检查连接，如果有必要进行重连
        BDPLogInfo(@"warm launch %@", uniqueID);
        [self startConnectionWithUniqueID:uniqueID completion:nil];

        if (completion) {
            completion(YES);
        }
    } else {
        // 冷启动: 同步建立连接
        BDPLogInfo(@"cold launch %@", uniqueID);
        [self startConnectionWithUniqueID:uniqueID completion:^(BOOL success) {
            if (completion) {
                completion(success);
            }
        }];
    }
}

- (void)pushCmd:(EMADebuggerCommand * _Nonnull)cmd forUniqueID:(BDPUniqueID * _Nonnull)uniqueID {
    BDPLogDebug(@"pushCmd %@", BDPParamStr(cmd.cmd, uniqueID));
    if (!uniqueID.isValid) {
        BDPLogWarn(BDPTag.debugger ,@"pushCmd uniqueID is invalid");
        return;
    }
    EMADebuggerConnection *connection = self.debuggerConnections[uniqueID];
    [connection pushCmd:cmd];
}

/// 关闭所有连接
- (void)closeAllConnections {
    BDPLogInfo(@"closeAllConnections");
    NSDictionary<OPAppUniqueID *, EMADebuggerConnection *> *debuggerConnections = self.debuggerConnections.copy;
    [self.debuggerConnections removeAllObjects];

    [debuggerConnections enumerateKeysAndObjectsUsingBlock:^(OPAppUniqueID * _Nonnull uniqueID, EMADebuggerConnection * _Nonnull connection, BOOL * _Nonnull stop) {
        [connection disconnect];
    }];
}

/// 对现有小程序全部建立连接
- (void)connectAllDevApps {
    BDPLogInfo(@"connectAllDevApps");
    NSSet<BDPUniqueID *> *currentApps = EMALifeCycleManager.sharedInstance.currentApps.copy;
    [currentApps enumerateObjectsUsingBlock:^(BDPUniqueID * _Nonnull uniqueID, BOOL * _Nonnull stop) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if (common && [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType]) {
            [self startConnectionWithUniqueID:uniqueID completion:nil];
        }
    }];
}

/// 与指定小程序建立连接
- (void)startConnectionWithUniqueID:(BDPUniqueID * _Nonnull)uniqueID completion:(void (^ _Nullable)(BOOL success))completion {
    BDPLogInfo(@"startConnection, uniqueID=%@", uniqueID);
    if (BDPIsEmptyString(self.url)) {
        BDPLogWarn(@"service not available");
        // 服务未开启
        if (completion) {
            completion(YES);
        }
        return;
    }
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID is invalid");
        if (completion) {
            completion(YES);
        }
        return;
    }

    EMADebuggerConnection *connection = self.debuggerConnections[uniqueID];

    // connection 已存在当前 url 的连接
    if (connection && [connection.url isEqualToString:self.url] && connection.status == EMADebuggerConnectionStatusConnected) {
        BDPLogInfo(@"connection already exist");
        if (completion) {
            completion(YES);
        }
        return;
    }

    // 先停止当前连接
    [self stopConnectionWithUniqueID:uniqueID];

    // 建立新的连接
    connection = [[EMADebuggerConnection alloc] initWithUrl:self.url uniqueID:uniqueID];
    self.debuggerConnections[uniqueID] = connection;
    [connection connectWithCompletion:^(BOOL success) {
        BDPLogInfo(@"connectWithCompletion %@", BDPParamStr(success));
        if (completion) {
            completion(success);
        }

        if (!success) {
            /// 弹窗提示连接调试器失败
            dispatch_async(dispatch_get_main_queue(), ^{
                [UDToastForOC showFailureWith:EMAI18n.failed_to_connect_ide on:uniqueID.window];
            });
        }
    }];

    // 热启动直接设置meta信息
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    if (common && [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType] && common.model.name) {
        [connection setMetaInfo:common.model.name];
    }
}

/// 与指定小程序断开连接
- (void)stopConnectionWithUniqueID:(BDPUniqueID * _Nonnull)uniqueID {
    BDPLogInfo(@"stopConnection, uniqueID=%@", uniqueID);
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID is invalid");
        return;
    }
    EMADebuggerConnection *connection = self.debuggerConnections[uniqueID];
    self.debuggerConnections[uniqueID] = nil;

    [connection disconnect];
}

/// 通知已打开的小程序状态变化
- (void)notifyDebuggerStateChange {
    BDPLogInfo(@"notifyDebuggerStateChange");
    NSSet<BDPUniqueID *> *currentApps = EMALifeCycleManager.sharedInstance.currentApps.copy;
    [currentApps enumerateObjectsUsingBlock:^(BDPUniqueID * _Nonnull uniqueID, BOOL * _Nonnull stop) {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if (common && [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType]) {
            BDPLogInfo(@"onOpenLogStateChanged %@", BDPParamStr(uniqueID));
            BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
            [appTask.context bdp_fireEvent:@"onOpenLogStateChanged" sourceID:NSNotFound data:@{@"allowLog": @(self.serviceEnable)}];
        }
    }];
}

/// 开关全局JSSDK log配置
- (void)setOpenLog:(BOOL)openLog {
    BDPLogInfo(@"setOpenLog=%@", @(openLog));
    NSMutableDictionary *jssdkEnvConfig = BDPSDKConfig.sharedConfig.jssdkEnvConfig.mutableCopy;
    if (!jssdkEnvConfig) {
        jssdkEnvConfig = NSMutableDictionary.dictionary;
    }
    jssdkEnvConfig[@"openLog"] = @(openLog);
    BDPSDKConfig.sharedConfig.jssdkEnvConfig = jssdkEnvConfig.copy;
}

#pragma mark - EMALifeCycleListener
- (void)onStart:(BDPUniqueID *)uniqueID {
    if (self.debuggerConnections[uniqueID]) {
        [self setOpenLog:YES];  // 在调试应用启动前设置 openLog
    } else {
        [self setOpenLog:NO];   // 非调试应用启动前关闭 openLog
    }
}

- (void)onLaunch:(BDPUniqueID *)uniqueID {
    BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
    if (common && [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType] && self.serviceEnable) {
        BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        EMADebuggerConnection *connection = self.debuggerConnections[uniqueID];
        if (connection) {
            // 冷启动在启动完成后设置meta信息
            if (!BDPIsEmptyString(common.model.name)) {
                [connection setMetaInfo:common.model.name];
            } else {
                // 没有name时用appId
                [connection setMetaInfo:common.model.uniqueID.appID];
            }
        } else {
            // 冷启动完成后主动检查一次是否需要建立连接
            [self connectAppDebuggerForUniqueID:uniqueID completion:^(BOOL success) {
                if (success) {
                    BDPLogInfo(@"onOpenLogStateChanged %@", BDPParamStr(uniqueID));
                    [appTask.context bdp_fireEvent:@"onOpenLogStateChanged" sourceID:NSNotFound data:@{@"allowLog": @(self.serviceEnable)}];
                }
            }];
        }
    }

}

- (void)onDestroy:(BDPUniqueID *)uniqueID {
    [self stopConnectionWithUniqueID:uniqueID];
}

- (void)onFailure:(BDPUniqueID *)uniqueID code:(EMALifeCycleErrorCode)code msg:(NSString *)msg {
    [self stopConnectionWithUniqueID:uniqueID];
}

- (void)onCancel:(BDPUniqueID *)uniqueID {
    [self stopConnectionWithUniqueID:uniqueID];
}

@end
