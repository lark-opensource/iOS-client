//
//  TMAPluginCustomImplRegister.m
//  Article
//
//  Created by zhangkun on 07/08/2018.
//

#import "TMAPluginCustomImplRegister.h"
#import "BDPLocationPluginCustomImpl.h"
#import "BDPPluginApplicationImpl.h"
#import "BDPPluginNetworkCustomImpl.h"
#import "BDPPluginPickerCustomImpl.h"
#import "BDPPluginRouterCustomImpl.h"
#import "BDPPluginShareBoardCustomImpl.h"
#import "BDPPluginTrackerCustomImpl.h"
#import "BDPUserPluginCustomImpl.h"
#import "BDPUserPluginCustomImpl.h"
#import "EMAPluginAPICustomImpl.h"
#import "EMALifeCycleManager.h"
#import "EMAPluginAuthorizationCustomImpl.h"
#import "EMAPluginMonitorCustomImpl.h"
#import "TMAPluginFileSystemCustomImpl.h"
#import "TMAPluginUIWidgetCustomImpl.h"
#import "BDPPluginXScreenCustomImpl.h"
#import <KVOController/KVOController.h>
#import <OPFoundation/BDPBootstrapHeader.h>
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>
#import <OPFoundation/BDPTimorClient.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LKLoadable/Loadable.h>
#import <TTMicroApp/BDPVersionManagerV2.h>
#import <TTMicroApp/BDPPermissionViewController.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "OPGadgetPluginImpl.h"
#import "EMAAppEngine.h"
#import "EMAPermissionManager.h"

@interface EMAJSBridgeMethodSignature : NSObject

@property (nonatomic, copy) NSString *method;
@property (nonatomic, assign) BOOL isSynchronize;
@property (nonatomic, assign) BOOL isOnMainThread;
@property (nonatomic, strong) Class implClass;
@property (nonatomic, assign) BDPJSBridgeMethodType type;

@end

@implementation EMAJSBridgeMethodSignature

@end

@interface TMAPluginCustomImplRegister ()

@property (nonatomic, strong) NSMutableArray<EMAJSBridgeMethodSignature *> *methodSignatureList;

@end

LoadableMainFuncBegin(TMAPluginCustomImplRegisterTimorClientPlugin)
BDPTimorClient *client = [BDPTimorClient sharedClient];
client.alertPlugin = [TMAPluginUIWidgetCustomImpl class];
client.applicationPlugin = [BDPPluginApplicationImpl class];
client.authorizationPlugin = [EMAPluginAuthorizationCustomImpl class];
client.customResponderPlugin = [TMAPluginUIWidgetCustomImpl class];
client.fileSystemPlugin = [TMAPluginFileSystemCustomImpl class];
client.lifeCyclePlugin = [EMALifeCycleManager class];
client.locationPlugin = [BDPLocationPluginCustomImpl class];
client.modalPlugin = [TMAPluginUIWidgetCustomImpl class];
client.monitorPlugin = [EMAPluginMonitorCustomImpl class];
client.navigationPlugin = [TMAPluginUIWidgetCustomImpl class];
client.networkPlugin = [BDPPluginNetworkCustomImpl class];
client.pickerPlugin = [BDPPluginPickerCustomImpl class];
client.routerPlugin = [BDPPluginRouterCustomImpl class];
client.sharePlugin = [BDPPluginShareBoardCustomImpl class];
client.toastPlugin = [TMAPluginUIWidgetCustomImpl class];
client.trackerPlugin = [BDPPluginTrackerCustomImpl class];
client.userPlugin = [BDPUserPluginCustomImpl class];
client.webviewPlugin = [TMAPluginUIWidgetCustomImpl class];
client.apiPlugin = [EMAPluginAPICustomImpl class];
client.gadgetUniversalRoutePlugin = [GadgetUniversalRouteCustomImpl class];
client.XScreenPlugin = [BDPPluginXScreenCustomImpl class];
client.versionManagerPlugin = [BDPVersionManagerV2 class];
client.permissionVCPlugin = [BDPPermissionViewController class];
client.opGadgetPlugin = [OPGadgetPluginImpl class];
client.appEnginePlugin = [EMAAppEngine class];
client.permissionPlugin = [EMAPermissionManager class];
client.disasterRecoverPlugin = [OPGadgetDRManager class];
LoadableMainFuncEnd(TMAPluginCustomImplRegisterTimorClientPlugin)

@implementation TMAPluginCustomImplRegister
@BDPBootstrapLaunch(TMAPluginCustomImplRegister, {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 注册自定义Plugin实现
        [TMAPluginCustomImplRegister.sharedInstance applyAllCustomPlugin];
    });
});

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)registerInstanceMethod:(NSString *)method isSynchronize:(BOOL)isSynchronize isOnMainThread:(BOOL)isOnMainThread class:(Class)class type:(BDPJSBridgeMethodType)type {
    if (!self.methodSignatureList) {
        self.methodSignatureList = NSMutableArray.array;
    }
    EMAJSBridgeMethodSignature *methodSignature = [EMAJSBridgeMethodSignature new];
    methodSignature.method = method;
    methodSignature.isSynchronize = isSynchronize;
    methodSignature.isOnMainThread = isOnMainThread;
    methodSignature.implClass = class;
    methodSignature.type = type;
    [self.methodSignatureList addObject:methodSignature];
}

- (void)applyAllCustomPlugin {
    // 将覆盖已注册Plugin
    [self.KVOController unobserveAll];
    [self.KVOController observe:[BDPTimorClient sharedClient] keyPath:@"networkPlugin" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        Class<BDPNetworkPluginDelegate> cls = change[NSKeyValueChangeNewKey];
        if (![NSStringFromClass(cls) isEqualToString:NSStringFromClass([BDPPluginNetworkCustomImpl class])]) {
            [self replaceCustomPluginDelegates];
        }
    }];
    [self replaceCustomPluginDelegates];

    // 将覆盖已注册Plugin的Method实现
    [self.methodSignatureList enumerateObjectsUsingBlock:^(EMAJSBridgeMethodSignature * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [BDPJSBridgeCenter registerInstanceMethod:obj.method isSynchronize:obj.isSynchronize isOnMainThread:obj.isOnMainThread class:obj.implClass type:obj.type];
    }];
}

/// 覆盖Timor基础库设置的plugin delegate
- (void)replaceCustomPluginDelegates {
    [BDPTimorClient sharedClient].networkPlugin = [BDPPluginNetworkCustomImpl class];
}

@end
