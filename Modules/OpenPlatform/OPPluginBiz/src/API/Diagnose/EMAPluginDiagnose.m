//
//  EMAPluginDiagnose.m
//  EEMicroAppSDK
//
//  Created by changrong on 2020/8/5.
//

#import "EMAPluginDiagnose.h"
#import <ECOInfra/EMANetworkManager.h>
#import <ECOInfra/EMAFeatureGating.h>
#import <OPFoundation/EMADeviceHelper.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPNetworking.h>
#import <TTMicroApp/BDPMemoryMonitor.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPModuleManager.h>
#import <TTMicroApp/BDPWarmBootManager.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <TTMicroApp/BDPPackageModuleProtocol.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <ECOInfra/OPError.h>
#import <ECOInfra/ECOCookieService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/EMAConfigManager.h>
#import <TTMicroApp/OPAppUniqueId+GadgetCookieIdentifier.h>
#import <ECOInfra/ECOConfig.h>

typedef void(^EMAPluginDiagnoseCallback)(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response);

typedef NS_ENUM(NSUInteger, EMADiagnoseCommand) {
    /// GET
    EMADiagnoseCommandGET_NETWORK_CHANNEL = 1,
    EMADiagnoseCommandGET_DISK_INFO = 6,
    EMADiagnoseCommandGET_MEMORY_INFO = 7,
    EMADiagnoseCommandGET_NETWORK_TYPE = 8,
    EMADiagnoseCommandGET_USER_ID = 9,
    EMADiagnoseCommandGET_TENANT_ID = 10,
    EMADiagnoseCommandGET_MINIAPP_VERSION = 12,
    EMADiagnoseCommandGET_FG_VALUE = 13,
    EMADiagnoseCommandGET_CONFIG_VALUE = 15,
    EMADiagnoseCommandGET_GRANTED_PERMISSIONS = 17,
    EMADiagnoseCommandGET_APP_STRATEGY = 19,
    EMADiagnoseCommandGET_SANDBOX_INFO = 28,

    /// SET
    EMADiagnoseCommand_CLEAR_LOCAL_META = 22,
    EMADiagnoseCommand_CLEAR_LOCAL_PKG = 23,
    EMADiagnoseCommand_CLEAR_LOCAL_JSSDK = 24,
    EMADiagnoseCommand_KILL_GADGET_PROCESS = 25,
    EMADiagnoseCommand_SET_DUMP_ENABLE = 30,

    /// Runner
    EMADiagnoseCommandGET_ALL_ALIVE_APP = 101,
    EMADiagnoseCommandGET_APP_INFO = 102,
    EMADiagnoseCommandEXEC_CLEAR_ACTION = 103,
    EMADiagnoseCommandMANAGE_DEBUG_ABILITY = 104,
    EMADiagnoseCommandMANAGE_JSSDK_ABILITY = 105,
    EMADiagnoseCommandLAUNCH_APP = 106,
    EMADiagnoseCommandEXPORT_FILE_SYSTEM_LOG = 107,
    EMADiagnoseCommandMOCK_FG_SETTING = 108
};


static NSInteger const DIAGNOSE_NETWORK_CHANNEL_DEFAULT = 1; // 原生网络
static NSInteger const DIAGNOSE_NETWORK_CHANNEL_RUST = 2; // rust

static NSString *const DIAGNOSE_NETWORK_TYPE_WIFI = @"wifi";
static NSString *const DIAGNOSE_NETWORK_TYPE_4G = @"4g";
static NSString *const DIAGNOSE_NETWORK_TYPE_3G = @"3g";
static NSString *const DIAGNOSE_NETWORK_TYPE_2G = @"2g";
static NSString *const DIAGNOSE_NETWORK_TYPE_UNKNOWN = @"unknown";

static NSString *const DIAGNOSE_REQUEST_PARAM_APPID = @"app_id";

@interface EMADiagnoseAPIModel : NSObject
@property (nonatomic, assign) EMADiagnoseCommand command;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) SEL commandSelector;
@property (nonatomic, strong) OPDiagnoseBaseRunner *runner;
@end

@implementation EMADiagnoseAPIModel
- (instancetype)initWithItem:(NSDictionary *)item {
    self = [super init];
    if (self) {
        self.command = [item bdp_intValueForKey:@"command"];
        if (self.command == 0) {
            BDPLogWarn(@"command is not number, command=%@", self.command);
            return nil;
        }
        self.params = [item bdp_dictionaryValueForKey:@"params"];
    }
    return self;
}
@end


@implementation EMAPluginDiagnose

- (NSDictionary *)execDiagnoseCommandsSwiftWrapper:(NSArray<NSDictionary *> *)commands controller:(UIViewController * _Nullable)controller {
    OPAPIDummyCallback *apiCallback = [OPAPIDummyCallback new];

    NSArray<EMADiagnoseAPIModel *> *models = [self parseParam:@{@"commands": commands}];
    if (!models) {
        apiCallback.errMsg(@"parse model fail");
        return [apiCallback copyCallbackData];
    }
    if (BDPIsEmptyArray(models)) {
        return [apiCallback copyCallbackData];
    }
    [models enumerateObjectsUsingBlock:^(EMADiagnoseAPIModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        // 判断走selector分发逻辑，还是走runner分发逻辑
        if (model.commandSelector) {
            [self invokeDiagnoseCommandSelectorWithModel:model apiCallback:apiCallback controller:controller];
        } else if (model.runner) {
            [self fireDiagnoseCommandRunnerWithModel:model apiCallback:apiCallback controller:controller];
        } else {
            BDPLogError(@"command-%@ parse failed! can not found commandSelector or runner", @(model.command));
        }
    }];
    return [apiCallback copyCallbackData];
}

/// 处理diagnose的selector分发逻辑
- (void)invokeDiagnoseCommandSelectorWithModel:(EMADiagnoseAPIModel *)model
                                   apiCallback:(OPAPICallback *)apiCallback
                                    controller:(UIViewController *)controller {
    NSMethodSignature *signature = [self methodSignatureForSelector:model.commandSelector];
    if (!signature) { BDPLogError(@"siganture is nil, model=%@", model); return; }

    EMAPluginDiagnoseCallback commandCallback = ^void(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response) {
        if (status != BDPJSBridgeCallBackTypeSuccess) {
            BDPLogWarn(@"response is fail, command=%@, response=%@", @(model.command), response);
            apiCallback.addKeyValue([@(model.command) stringValue], @"fail");
            return;
        }
        if (response) {
            apiCallback.addKeyValue([@(model.command) stringValue], response);
        }
    };
    NSDictionary *params = model.params;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = model.commandSelector;
    [invocation setArgument:&params atIndex:2];
    [invocation setArgument:&commandCallback atIndex:3];
    [invocation setArgument:(void *)&controller atIndex:4];
    [invocation invoke];
}

/// 处理diagnose的runner分发逻辑
- (void)fireDiagnoseCommandRunnerWithModel:(EMADiagnoseAPIModel *)model
                               apiCallback:(OPAPICallback *)apiCallback
                                controller:(UIViewController *)controller  {
    OPDiagnoseRunnerContext * context = [[OPDiagnoseRunnerContext alloc] initWithParams:model.params];

    context.callback = ^(OPError * _Nullable err, NSDictionary<NSString *,id> * _Nonnull response) {
        if (err) {
            BDPLogWarn(@"command runner fail, command=%@", @(model.command));
            apiCallback.addKeyValue([@(model.command) stringValue], @"fail");
            return;
        } else {
            apiCallback.addKeyValue([@(model.command) stringValue], response);
        }
    };

    context.controller = controller;

    [model.runner fireWith:context];
}

- (void)getCurrentNetworkChannelWithParam:(NSDictionary *)param
                                 callback:(EMAPluginDiagnoseCallback)callback
                               controller:(UIViewController *)controller {
    BOOL useRustType = [EMANetworkManager.shared isNetworkTransmitOverRustChannel];
    NSInteger channel = useRustType ? DIAGNOSE_NETWORK_CHANNEL_RUST : DIAGNOSE_NETWORK_CHANNEL_DEFAULT;
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"network_channel" : @(channel)})
}

- (void)getDiskInfoWithParam:(NSDictionary *)param
                    callback:(EMAPluginDiagnoseCallback)callback
                  controller:(UIViewController *)controller {
    long totalSize = [EMADeviceHelper getTotalDiskSpace];
    long freeDiskSpace = [EMADeviceHelper getFreeDiskSpace];
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess,
                             (@{
                                 @"total_disk_space" : @(totalSize),
                                 @"available_disk_space": @(freeDiskSpace)
                              }));
}

- (void)getMemoryInfoWithParam:(NSDictionary *)param
                      callback:(EMAPluginDiagnoseCallback)callback
                    controller:(UIViewController *)controller {
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess,
                             (@{
                                 @"current_memory" : @(BDPMemoryMonitor.currentMemoryUsageInBytes),
                                 @"available_memory": @(BDPMemoryMonitor.avaliableMemory)
                              }));
}

- (void)getNetworkTypeWithParam:(NSDictionary *)param
                       callback:(EMAPluginDiagnoseCallback)callback
                     controller:(UIViewController *)controller {
    BDPNetworkType networkType = [BDPNetworking networkType];
    NSString *result;
    if (networkType & BDPNetworkTypeWifi) {
        result = DIAGNOSE_NETWORK_TYPE_WIFI;
    } else if (networkType & BDPNetworkType4G) {
        result = DIAGNOSE_NETWORK_TYPE_4G;
    } else if (networkType & BDPNetworkType3G) {
        result = DIAGNOSE_NETWORK_TYPE_3G;
    } else if (networkType & BDPNetworkType2G) {
        result = DIAGNOSE_NETWORK_TYPE_2G;
    } else {
        result = DIAGNOSE_NETWORK_TYPE_UNKNOWN;
    }
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess,
                             @{@"network_type" : result})
}

- (void)getUserIdWithParam:(NSDictionary *)param
                  callback:(EMAPluginDiagnoseCallback)callback
                controller:(UIViewController *)controller {
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{
        @"user_id" : [self appEngine].account.encyptedUserID ?: @""
    })
}

- (void)getTenantIdWithParam:(NSDictionary *)param
                    callback:(EMAPluginDiagnoseCallback)callback
                  controller:(UIViewController *)controller {
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{
        @"tenant_id" : [self appEngine].account.encyptedTenantID ?: @""
    })
}

- (void)getFgValueWithParam:(NSDictionary *)param
                   callback:(EMAPluginDiagnoseCallback)callback
                 controller:(UIViewController *)controller {
    NSString *key = [param bdp_stringValueForKey:@"fg_key"];
    if (BDPIsEmptyString(key)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"fg key is not exist")
        return;
    }
    BOOL value = [EMAFeatureGating boolValueForKey:key];
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"fg_value" : @(value)})
}

- (void)getConfigValueWithParam:(NSDictionary *)param
                       callback:(EMAPluginDiagnoseCallback)callback
                     controller:(UIViewController *)controller {
    NSString *key = [param bdp_stringValueForKey:@"config_key"];
    if (BDPIsEmptyString(key)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"config key is not exist")
        return;
    }
    ECOConfig *config = [self appEngine].configManager.minaConfig;
    NSString *serializedString = [config getSerializedStringValueForKey:key];
    if (!serializedString) {
        BDPLogInfo(@"value is not exist, key=%@", key)
        BDP_CALLBACK_SUCCESS
        return;
    }
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"config_value": serializedString})
}

- (void)getGrantedPermissionsWithParam:(NSDictionary *)param
                              callback:(EMAPluginDiagnoseCallback)callback
                            controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId identifier:nil versionType:OPAppVersionTypeCurrent appType:BDPTypeNativeApp];
    NSArray<EMAPermissionData *> *permissions = [[self permissionService] getPermissionDataArrayWithUniqueID:uniqueID];
    if (BDPIsEmptyArray(permissions)) {
        BDPLogInfo(@"permission is empty, appId=%@", appId);
        BDP_CALLBACK_SUCCESS
        return;
    }
    NSMutableDictionary<NSString *, NSNumber *> *authSetting = [NSMutableDictionary dictionary];
    [permissions enumerateObjectsUsingBlock:^(EMAPermissionData *data, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [NSString stringWithFormat:@"%@.%@", data.scope, data.name];
        authSetting[key] = @(data.isGranted);
    }];
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"authSetting": authSetting})
}

- (void)getAppStrategyWithParam:(NSDictionary *)param
                       callback:(EMAPluginDiagnoseCallback)callback
                     controller:(UIViewController *)controller {
    // 暂时不支持获取应用机制
    BDP_CALLBACK_SUCCESS
}

- (void)getMiniAppVersionWithParam:(NSDictionary *)param
                          callback:(EMAPluginDiagnoseCallback)callback
                        controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId
                                                            identifier:nil
                                                           versionType:OPAppVersionTypeCurrent
                                                               appType:BDPTypeNativeApp];
    if (!uniqueID.isValid) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"uniqueID is invalid")
        return;
    }
    MetaContext *context = [[MetaContext alloc] initWithUniqueID:uniqueID
                                                                       token:nil];
    BDPResolveModule(metaModule, MetaInfoModuleProtocol, BDPTypeNativeApp);
    id<AppMetaProtocol> appMeta = [metaModule getLocalMetaWith:context];
    if (!appMeta) {
        BDPLogInfo(@"can noit find app, appID=%@", appId);
        BDP_CALLBACK_SUCCESS;
        return;
    }
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, @{@"gadget_version": appMeta.version})
}

- (void)clearLocalMetaWithParam:(NSDictionary *)param
                       callback:(EMAPluginDiagnoseCallback)callback
                     controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId
                                                            identifier:nil
                                                               versionType:OPAppVersionTypeCurrent
                                                                   appType:BDPTypeNativeApp];
    if (!uniqueID.isValid) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"uniqueID is invalid")
        return;
    }
    MetaContext *context = [[MetaContext alloc] initWithUniqueID:uniqueID
                                                                       token:nil];
    BDPResolveModule(metaModule, MetaInfoModuleProtocol, BDPTypeNativeApp);
    [metaModule removeMetasWith:@[context]];
    BDP_CALLBACK_SUCCESS;
}

- (void)clearLocalPkgWithParam:(NSDictionary *)param
                      callback:(EMAPluginDiagnoseCallback)callback
                    controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    BDPResolveModule(pkgModule, BDPPackageModuleProtocol, BDPTypeNativeApp);
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId identifier:nil versionType:OPAppVersionTypeCurrent appType:BDPTypeNativeApp];
    NSError *error = nil;
    BOOL result = [pkgModule deleteAllLocalPackagesWithUniqueID:uniqueID
                                                                      error:&error];
    if (!result || error) {
        BDPLogWarn(@"delete all local pkg fail, result=%@, error=%@", @(result), error);
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"delete fail");
        return;
    }
    BDP_CALLBACK_SUCCESS;
}

- (void)clearLocalJSSDKWithParam:(NSDictionary *)param
                        callback:(EMAPluginDiagnoseCallback)callback
                      controller:(UIViewController *)controller {
    [BDPVersionManager resetLocalLibCache];
    BDP_CALLBACK_SUCCESS;
}

- (void)killGadgetProcessWithParam:(NSDictionary *)param
                          callback:(EMAPluginDiagnoseCallback)callback
                        controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId identifier:nil versionType:OPAppVersionTypeCurrent appType:BDPTypeNativeApp];
    [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:uniqueID];
    BDP_CALLBACK_SUCCESS;
}

- (void)getSandboxInfoWithParam:(NSDictionary *)param
                       callback:(EMAPluginDiagnoseCallback)callback
                     controller:(UIViewController *)controller {
    NSString *appId = [param bdp_stringValueForKey:DIAGNOSE_REQUEST_PARAM_APPID];
    if (BDPIsEmptyString(appId)) {
        BDP_CALLBACK_WITH_ERRMSG(BDPJSBridgeCallBackTypeFailed, @"app_id is not exist")
        return;
    }
    // 被诊断的应用不一定是当前应用，这一行没有问题。诊断应用目前只支持 current 版本的小程序。
    BDPUniqueID *uniqueID = [BDPUniqueID uniqueIDWithAppID:appId
                                                identifier:nil
                                               versionType:OPAppVersionTypeCurrent
                                                   appType:BDPTypeNativeApp];
    NSArray<NSDictionary<NSString *, NSString *> *> *cookieInfo =
        [[ECOCookie resolveService] getDiagnoseInfoWithGadgetId:uniqueID];
    NSDictionary *resultData = @{
        @"sandbox_info": @{@"mask_cookies": cookieInfo}
    };
    BDP_CALLBACK_WITH_DATA(BDPJSBridgeCallBackTypeSuccess, resultData)
}

- (NSArray<EMADiagnoseAPIModel *> *)parseParam:(NSDictionary *)param {
    NSMutableArray<EMADiagnoseAPIModel *> *result = [NSMutableArray array];
    NSArray<NSDictionary *> *commands = [param bdp_arrayValueForKey:@"commands"];
    if (BDPIsEmptyArray(commands)) {
        BDPLogInfo(@"commands is not exist or commands class is not array, commandsType=%@", [commands class]);
        return result;
    }
    [commands enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            BDPLogWarn(@"item is not dictionary, obj=%@", obj);
            return;
        }
        EMADiagnoseAPIModel *model = [[EMADiagnoseAPIModel alloc] initWithItem:obj];
        if (!model) {
            BDPLogWarn(@"get model fail, item=%@", obj);
            return;
        }
        switch (model.command) {
            /// DiagnoseCommand Selector分发逻辑
            case EMADiagnoseCommandGET_NETWORK_CHANNEL:
                model.commandSelector = @selector(getCurrentNetworkChannelWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_DISK_INFO:
                model.commandSelector = @selector(getDiskInfoWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_MEMORY_INFO:
                model.commandSelector = @selector(getMemoryInfoWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_NETWORK_TYPE:
                model.commandSelector = @selector(getNetworkTypeWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_USER_ID:
                model.commandSelector = @selector(getUserIdWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_TENANT_ID:
                model.commandSelector = @selector(getTenantIdWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_FG_VALUE:
                model.commandSelector = @selector(getFgValueWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_CONFIG_VALUE:
                model.commandSelector = @selector(getConfigValueWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_GRANTED_PERMISSIONS:
                model.commandSelector = @selector(getGrantedPermissionsWithParam:engine:controller:); break;
            case EMADiagnoseCommandGET_APP_STRATEGY:
                model.commandSelector = @selector(getAppStrategyWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_MINIAPP_VERSION:
                model.commandSelector = @selector(getMiniAppVersionWithParam:callback:controller:); break;
            case EMADiagnoseCommandGET_SANDBOX_INFO:
                model.commandSelector = @selector(getSandboxInfoWithParam:callback:controller:); break;
            case EMADiagnoseCommand_CLEAR_LOCAL_META:
                model.commandSelector = @selector(clearLocalMetaWithParam:callback:controller:); break;
            case EMADiagnoseCommand_CLEAR_LOCAL_PKG:
                model.commandSelector = @selector(clearLocalPkgWithParam:callback:controller:); break;
            case EMADiagnoseCommand_CLEAR_LOCAL_JSSDK:
                model.commandSelector = @selector(clearLocalJSSDKWithParam:callback:controller:); break;
            case EMADiagnoseCommand_KILL_GADGET_PROCESS:
                model.commandSelector = @selector(killGadgetProcessWithParam:callback:controller:); break;
            /// DiagnoseCommand Runner分发逻辑
            case EMADiagnoseCommand_SET_DUMP_ENABLE:
            case EMADiagnoseCommandGET_ALL_ALIVE_APP:
            case EMADiagnoseCommandGET_APP_INFO:
            case EMADiagnoseCommandEXEC_CLEAR_ACTION:
            case EMADiagnoseCommandMANAGE_DEBUG_ABILITY:
            case EMADiagnoseCommandMANAGE_JSSDK_ABILITY:
            case EMADiagnoseCommandLAUNCH_APP:
            case EMADiagnoseCommandEXPORT_FILE_SYSTEM_LOG:
            case EMADiagnoseCommandMOCK_FG_SETTING:
                model.runner = [OPRunnerBridge runnerWith: (EMADiagnoseCommandRunnerGroup)model.command];
                break;
        }
        if (!model.commandSelector && !model.runner) {
            BDPLogWarn(@"can not parse selector or runner, command=%@", @(model.command));
            return;
        }
        [result addObject:model];
    }];
    return result;
}

#pragma mark - Private
- (nullable id<EMAAppEnginePluginDelegate>)appEngine {
    BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
    return appEnginePlugin;
}
- (nullable id<EMAPermissionSharedService>)permissionService {
    BDPPlugin(permissionPlugin, EMAPermissionSharedService);
    return permissionPlugin;
}

@end
