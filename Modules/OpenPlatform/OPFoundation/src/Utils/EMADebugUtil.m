//
//  EMADebugUtil.m
//  EEMicroAppSDK
//
//  Created by 殷源 on 2018/10/28.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EMADebugUtil.h"
#import "EMANetworkAPI.h"
#import "NSURLComponents+EMA.h"
#import <ECOInfra/BDPFileSystemHelper.h>
#import "BDPModuleManager.h"
#import "BDPStorageModuleProtocol.h"
#import "BDPUtils.h"
#import "BDPVersionManager.h"
#import "TMACustomHelper.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/BDPLog.h>
#import "EMAConfig.h"
#import "BDPTimorClient.h"
#import "OPResolveDependenceUtil.h"

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

NSString * const kEEMicroAppDebugSwitch = @"kEEMicroAppDebugSwitch";

NSString * const kEMADebugConfigIDClearMicroAppProcesses = @"kEMADebugConfigIDClearMicroAppProcesses";
NSString * const kEMADebugConfigIDClearMicroAppFileCache = @"kEMADebugConfigIDClearMicroAppFileCache";
NSString * const kEMADebugConfigIDClearMicroAppFolders = @"kEMADebugConfigIDClearMicroAppFolders";
NSString * const kEMADebugConfigIDClearH5ApppFolders = @"kEMADebugConfigIDCleaH5AppFolders";
NSString * const kEMADebugConfigIDClearJSSDKFileCache = @"kEMADebugConfigIDClearJSSDKFileCache";
NSString * const kEMADebugConfigIDUseSpecificJSSDKURL = @"kEMADebugConfigIDUseSpecificJSSDKURL";
NSString * const kEMADebugConfigIDSpecificJSSDKURL = @"kEMADebugConfigIDSpecificJSSDKURL";
NSString * const kEMADebugConfigIDDoNotGrayApp = @"kEMADebugConfigIDDoNotGrayApp";
NSString * const kEMADebugConfigIDForceUpdateJSSDK = @"kEMADebugConfigIDForceUpdateJSSDK";
NSString * const kEMADebugConfigIDForceColdStartMicroApp = @"kEMADebugConfigIDForceColdStartMicroApp";
NSString * const kEMADebugConfigIDUseStableJSSDK = @"kEMADebugConfigIDUseStableJSSDK";
NSString * const kEMADebugConfigIDDoNotCompressJS = @"kEMADebugConfigIDDoNotCompressJS";
NSString * const kEMADebugConfigIDOpenAppByID = @"kEMADebugConfigIDOpenAppByID";
NSString * const kEMADebugConfigIDOpenAppByIPPackage = @"kEMADebugConfigIDOpenAppByIPPackage";
NSString * const kEMADebugConfigIDOpenAppBySchemeURL = @"kEMADebugConfigIDOpenAppBySchemeURL";
NSString * const kEMADebugConfigIDOpenAppDemo = @"kEMADebugConfigIDOpenAppDemo";
NSString * const kEMADebugConfigIDUseBuildInJSSDK = @"kEMADebugConfigIDUseBuildInJSSDK";
NSString * const kEMADebugConfigIDShowJSSDKUpdateTips = @"kEMADebugConfigIDShowJSSDKUpdateTips";
NSString * const kEMADebugConfigIDDisableDebugTool = @"kEMADebugConfigIDDisableDebugTool";
NSString * const kEMADebugConfigIDChangeHostSessionID = @"kEMADebugConfigIDChangeHostSessionID";
NSString * const kEMADebugConfigIDGetHostSessionID = @"kEMADebugConfigIDGetHostSessionID";
NSString * const kEMADebugConfigIDUseAmapLocation = @"kEMADebugConfigIDUseAmapLocation";
NSString * const kEMADebugConfigIDDisableAppCharacter = @"kEMADebugConfigIDDisableAppCharacter";
NSString * const kEMADebugConfigIDEnableDebugLog = @"kEMADebugConfigIDEnableDebugLog";
NSString * const kEMADebugConfigIDEnableLaunchTracing = @"kEMADebugConfigIDEnableLaunchTracing";
NSString * const kEMADebugConfigIDForcePrimitiveNetworkChannel = @"kEMADebugConfigIDForcePrimitiveNetworkChannel";
NSString * const kEMADebugConfigIDClearPermission = @"kEMADebugConfigIDClearPermission";
NSString * const kEMADebugConfigIDClearCookies = @"kEMADebugConfigIDClearCookies";
NSString * const kEMADebugConfigIDEnableRemoteDebugger = @"kEMADebugConfigIDEnableRemoteDebugger";
NSString * const kEMADebugConfigIDRemoteDebuggerURL = @"kEMADebugConfigIDRemoteDebuggerURL";
NSString * const kEMADebugConfigIDRecentOpenURL = @"kEMADebugConfigIDRecentOpenURL";
NSString * const kEMADebugConfigUploadEvent = @"kEMADebugConfigUploadEvent";
NSString * const kEMADebugConfigForceOverrideRequestID = @"kEMADebugConfigForceOverrideRequestID";
NSString * const kEMADebugConfigForceOpenAppDebug = @"kEMADebugConfigForceOpenAppDebug";  // 强制开启应用调试（VConsole）
NSString * const kEMADebugConfigDoNotUseAuthDataFromRemote = @"kEMADebugConfigDoNotUseAuthDataFromRemote";  // 不使用远端授权数据
NSString * const kEMADebugConfigIDReloadCurrentGadgetPage = @"kEMADebugConfigIDReloadCurrentGadgetPage"; //强制触发小程序reload
NSString * const kEMADebugConfigIDTriggerMemoryWarning = @"kEMADebugConfigIDTriggerMemoryWarning"; //强制触发小程序memory warning
NSString * const kEMADebugConfigIDWorkerDonotUseNetSetting = @"kEMADebugConfigIDWorkerDonotUseNetSetting";
NSString * const kEMADebugConfigIDUseNewWorker = @"kEMADebugConfigIDUseNewWorker";
NSString * const kEMADebugConfigIDUseVmsdk = @"kEMADebugConfigIDUseVmsdk";
NSString * const kEMADebugConfigIDUseVmsdkQjs = @"kEMADebugConfigIDUseVmsdkQjs";
NSString * const kEMADebugConfigIDShowWorkerTypeTips = @"kEMADebugConfigIDShowWorkerTypeTips";
NSString * const kEMADebugConfigIDShowBlockPreviewUrl = @"kEMADebugConfigIDShowBlockPreviewUrl";

// 删除应用(小程序等)启动信息数据库(OPLaunchInfoTable)中,X天前的数据的配置
NSString * const kEMADebugConfigIDOPAppLaunchDataDeleteOld = @"kEMADebugConfigIDOPAppLaunchDataDeleteOld";

/// 是否开启主窗口的性能数据悬浮窗口
NSString * const kEMADebugConfigShowMainWindowPerformanceDebugView = @"kEMADebugConfigShowMainWindowPerformanceDebugView";

// H5
NSString * const kEMADebugH5ConfigIDAppID = @"kEMADebugH5ConfigIDAppID";
NSString * const kEMADebugH5ConfigIDLocalH5Address = @"kEMADebugH5ConfigIDLocalH5Address";

// Block 
NSString * const kEMADebugBlockTest = @"kEMADebugBlockTest";
NSString * const kEMADebugConfigAppDemoUrl = @"sslocal://microapp?app_id=cli_9cf4d4ab0a7a9103&isdev=1";

NSString * const kEMADebugConfigIDUseSpecificBlockJSSDKURL = @"kEMADebugConfigIDUseSpecificBlockJSSDKURL";
NSString * const kEMADebugConfigIDSpecificBlockJSSDKURL = @"kEMADebugConfigIDSpecificBlockJSSDKURL";

NSString * const kEMADebugBlockDetail = @"kEMADebugBlockDetail";
NSString * const kEMADebugConfigMessageCardDebugTool = @"kEMADebugConfigMessageCardDebugTool";

@interface EMADebugConfig ()

@property (nonatomic, strong) id configValue;

@end

@implementation EMADebugConfig

+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType {
    return [self configWithID:configID name:configName type:configType defaultValue:nil];
}

+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType defaultValue:(id)defaultValue {
    return [self configWithID:configID name:configName type:configType defaultValue:defaultValue noCache:NO];
}

+ (instancetype)configWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType defaultValue:(id)defaultValue noCache:(BOOL)noCache {
    EMADebugConfig * __autoreleasing config = [[self alloc] initWithID:configID name:configName type:configType defaultValue:defaultValue noCache:noCache];
    return config;
}

- (instancetype)initWithID:(NSString *)configID name:(NSString *)configName type:(EMADebugConfigType)configType defaultValue:(id)defaultValue noCache:(BOOL)noCache {
    if (self = [super init]) {
        _configID = configID;
        _configName = configName;
        _configType = configType;
        _noCache = noCache;
        if (!_noCache) _configValue = [NSUserDefaults.standardUserDefaults objectForKey:configID];
        if (defaultValue && _configValue == nil) {
            self.configValue = defaultValue;
        }
    }
    return self;
}

- (BOOL)boolValue {
    if ([_configValue isKindOfClass:NSNumber.class]) {
        NSNumber *value = _configValue;
        return value.boolValue;
    }
    return NO;
}

- (void)setBoolValue:(BOOL)boolValue {
    self.configValue = @(boolValue);
}

- (NSString *)stringValue {
    return _configValue?[NSString stringWithFormat:@"%@", _configValue]:nil;
}

- (void)setStringValue:(NSString *)stringValue {
    self.configValue = stringValue;
}

- (void)setConfigValue:(id)configValue {
    _configValue = configValue;
    if (!_noCache) {
        if (_configValue) {
            [NSUserDefaults.standardUserDefaults setObject:self.configValue forKey:self.configID];
        }else{
            [NSUserDefaults.standardUserDefaults removeObjectForKey:self.configID];
        }
    }
}

@end

@interface EMADebugUtil ()

@end

@implementation EMADebugUtil

@synthesize debugConfigs = _debugConfigs;
@synthesize enable = _enable;

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
        /// 将原对 updateDebug 依赖直接改为对 _enable 的初始化
        /// EMADebugUtil 引用关系复杂,容易引起死锁不建议再在 init 中做外部引用.
        _enable = [NSUserDefaults.standardUserDefaults boolForKey:kEEMicroAppDebugSwitch];
    }
    return self;
}

- (EMAConfig *)engineOnlineConfig {
    EMAConfig *onlineConfig = [OPResolveDependenceUtil currentAppEngineOnlineConfig];
    return onlineConfig;
}

- (void)updateDebug {
    BDPLogInfo(@"updateDebug");
//    BOOL debug = [EMAAppEngine.currentEngine.onlineConfig isDebug];
    BOOL debug = [[self engineOnlineConfig] isDebug];
    if (debug) {
        BDPLogInfo(@"setEnable from config : YES");
        [self setEnable:YES];
        return;
    }
    [self updateDebugLocal];
}

- (void)updateDebugLocal {
    BOOL debugSwitch = [NSUserDefaults.standardUserDefaults boolForKey:kEEMicroAppDebugSwitch];
    if (debugSwitch) {
        BDPLogInfo(@"setEnable from debugSwitch : YES");
        [self setEnable:YES];
        return;
    }
    BDPLogInfo(@"setEnable else : NO");
    [self setEnable:NO];
}

- (void)setEnable:(BOOL)enable {
    if (self.enable != enable) {
        _enable = enable;
        [NSUserDefaults.standardUserDefaults setObject:@(enable) forKey:kEEMicroAppDebugSwitch];    // 持久化
    }
}

- (BOOL)enable {
#ifdef DEBUG
    return YES;
#else
    return _enable;
#endif
}

- (NSDictionary<NSString *,EMADebugConfig *> *)debugConfigs {
    if (!_debugConfigs) {
//        BOOL isSuperDeveloper = EMAAppEngine.currentEngine.onlineConfig.isSuperDeveloper;
        BOOL isSuperDeveloper = [self engineOnlineConfig].isSuperDeveloper;
        NSArray<EMADebugConfig *> *configArray = @[
                                 [EMADebugConfig configWithID:kEMADebugConfigIDForceUpdateJSSDK name:@"强制更新jssdk" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDForceColdStartMicroApp name:@"强制冷启动小程序" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseStableJSSDK name:@"使用稳定jssdk" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDDoNotCompressJS name:@"不压缩jssdk" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDDoNotGrayApp name:@"去掉小程序灰度" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearMicroAppProcesses name:@"清理小程序进程" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearMicroAppFileCache name:@"清理小程序文件缓存" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearMicroAppFolders name:@"清理所有小程序文件" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearH5ApppFolders name:@"清理所有H5离线包文件" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearCookies name:@"清理Cookies" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDReloadCurrentGadgetPage name:@"5秒后强制reload当前小程序页面" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDTriggerMemoryWarning name:@"触发onMemoryWarning API" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearJSSDKFileCache name:@"清理jssdk文件缓存" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseSpecificJSSDKURL name:@"使用指定jssdk" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDSpecificJSSDKURL name:@"jssdk URL" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseSpecificBlockJSSDKURL name:@"使用指定block jssdk（会重启）" type:EMADebugConfigTypeBool],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDSpecificBlockJSSDKURL name:@"block jssdk URL" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDOpenAppByID name:@"用AppID打开小程序" type:EMADebugConfigTypeString defaultValue:@"tt06bd70009997ab3e"],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDOpenAppByIPPackage name:@"访问IP开发包" type:EMADebugConfigTypeString defaultValue:@"http://localhost/__dist__.zip"],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDOpenAppDemo name:@"访问小程序示例" type:EMADebugConfigTypeNone defaultValue:kEMADebugConfigAppDemoUrl],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDOpenAppBySchemeURL name:@"访问Scheme URL" type:EMADebugConfigTypeString defaultValue:@"sslocal://microapp?app_id=tt06bd70009997ab3e"],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseBuildInJSSDK name:@"使用内置jssdk" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDShowJSSDKUpdateTips name:@"显示jssdk更新提示" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDChangeHostSessionID name:@"更换Lark Session" type:EMADebugConfigTypeString defaultValue:nil],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDGetHostSessionID name:@"获取Lark Session" type:EMADebugConfigTypeNone defaultValue:nil],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseAmapLocation name:@"使用高德定位" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDDisableAppCharacter name:@"忽略应用机制弹框" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDEnableDebugLog name:@"启用Debug日志" type:EMADebugConfigTypeBool defaultValue:@(isSuperDeveloper)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDEnableLaunchTracing name:@"启用 Launch Tracing (会改 JSSDK)" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDForcePrimitiveNetworkChannel name:@"强制使用原生网络请求（Lark会重启）" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDDisableDebugTool name:@"禁用调试" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDClearPermission name:@"清理本地用户授权数据" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDEnableRemoteDebugger name:@"连接开发者工具" type:EMADebugConfigTypeBool defaultValue:@(NO) noCache:YES],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDRemoteDebuggerURL name:@"远程调试URL" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugH5ConfigIDAppID name:@"AppID-H5" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugH5ConfigIDLocalH5Address name:@"本地H5地址" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDRecentOpenURL name:@"上次打开" type:EMADebugConfigTypeString],
                                 [EMADebugConfig configWithID:kEMADebugConfigUploadEvent name:@"启用Debug状态Monitor上传" type:EMADebugConfigTypeBool defaultValue:@(NO) noCache:YES],
                                 [EMADebugConfig configWithID:kEMADebugConfigForceOverrideRequestID name:@"强制使用引擎生成RequestID" type:EMADebugConfigTypeBool defaultValue:@(NO) noCache:YES],
                                 [EMADebugConfig configWithID:kEMADebugConfigForceOpenAppDebug name:@"强制开启应用调试(vConsole)" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigDoNotUseAuthDataFromRemote name:@"不使用远端用户授权数据" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugBlockTest name:@"Block测试" type:EMADebugConfigTypeNone],
                                 [EMADebugConfig configWithID:kEMADebugConfigShowMainWindowPerformanceDebugView name:@"是否开启性能数据调试窗口" type:EMADebugConfigTypeBool defaultValue:@(NO) noCache:YES],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDShowWorkerTypeTips name:@"显示worker类型提示" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDWorkerDonotUseNetSetting name:@"不使用远端worker配置（重启生效）" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseNewWorker name:@"是否启用新worker" type:EMADebugConfigTypeBool defaultValue:@(YES)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseVmsdk name:@"Use vmsdk" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDUseVmsdkQjs name:@"Use vmsdk qjs" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDShowBlockPreviewUrl name:@"是否显示Block预览URL" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugBlockDetail name:@"Block详情" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigMessageCardDebugTool name:@"Enable Message Card Debug Tool" type:EMADebugConfigTypeBool defaultValue:@(NO)],
                                 [EMADebugConfig configWithID:kEMADebugConfigIDOPAppLaunchDataDeleteOld name:@"删除OPLaunchInfoTable db旧数据" type:EMADebugConfigTypeString defaultValue:@"180"]
        ];

        NSMutableDictionary *configs = [NSMutableDictionary dictionary];
        [configArray enumerateObjectsUsingBlock:^(EMADebugConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            configs[obj.configID] = obj;
        }];
        _debugConfigs = [configs copy];
    }
    return _debugConfigs;
}

- (nullable EMADebugConfig *)debugConfigForID:(NSString *)configID {
    if (!self.enable) return nil;
    if (!configID) return nil;
    return self.debugConfigs[configID];
}

@end
