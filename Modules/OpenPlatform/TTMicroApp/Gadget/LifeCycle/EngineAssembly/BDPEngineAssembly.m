//
//  BDPEngineAssembly.m
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#import "BDPEngineAssembly.h"
#import "BDPAuthModule.h"
#import "BDPCommunicationModule.h"
#import "BDPContainerModule.h"
#import "BDPLogicLayerModule.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPPackageModule.h"
#import "BDPRenderLayerModule.h"
#import "BDPStorageModule.h"
#import <TTMicroApp/BDPMetaInfoAccessorProtocol.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LKLoadable/Loadable.h>

/// 注册模块：native小程序+H5小程序
static void registerModulesForNativeAndH5App() {
    void (^registerBlock)(BDPModuleManager *module) = ^(BDPModuleManager *module){
    @autoreleasepool {
        [module registerModuleWithProtocol:@protocol(CommonAppLoadProtocol) class:CommonAppLoader.class];
        [module registerModuleWithProtocol:@protocol(BDPCommunicationModuleProtocol) class:[BDPCommunicationModule class]];
        [module registerModuleWithProtocol:@protocol(BDPContainerModuleProtocol) class:[BDPContainerModule class]];
        [module registerModuleWithProtocol:@protocol(BDPLogicLayerModuleProtocol) class:[BDPLogicLayerModule class]];
        [module registerModuleWithProtocol:@protocol(MetaInfoModuleProtocol) class:MetaInfoModule.class handler:^id<MetaInfoModuleProtocol> _Nonnull(BDPModuleManager * _Nonnull manager) {
            return [[MetaInfoModule alloc] initWithProvider:[[GadgetMetaProvider alloc] initWithType:manager.type] appType:manager.type];
        }];
        [module registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:[BDPPackageModule class]];
        [module registerModuleWithProtocol:@protocol(BDPRenderLayerModuleProtocol) class:[BDPRenderLayerModule class]];
        [module registerModuleWithProtocol:@protocol(BDPAuthModuleProtocol) class:[BDPAuthModule class]];
        [module registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:[BDPStorageModule class]];
    }
    };
    BDPModuleManager *moduleManagerOfNativeApp = [BDPModuleManager moduleManagerOfType:BDPTypeNativeApp];
    registerBlock(moduleManagerOfNativeApp);
}

/// 注册模块：Web应用
static void registerModulesForWebApp() {
    @autoreleasepool {
    BDPModuleManager *moduleManagerOfWebApp = [BDPModuleManager moduleManagerOfType:BDPTypeWebApp];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(CommonAppLoadProtocol) class:CommonAppLoader.class];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPCommunicationModuleProtocol) class:[BDPCommunicationModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPContainerModuleProtocol) class:[BDPContainerModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPLogicLayerModuleProtocol) class:[BDPLogicLayerModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:[BDPPackageModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPRenderLayerModuleProtocol) class:[BDPRenderLayerModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPAuthModuleProtocol) class:[BDPAuthModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:[BDPStorageModule class]];
    [moduleManagerOfWebApp registerModuleWithProtocol:@protocol(MetaInfoModuleProtocol) class:MetaInfoModule.class handler:^id<MetaInfoModuleProtocol> _Nonnull(BDPModuleManager * _Nonnull manager) {
        return [[MetaInfoModule alloc] initWithProvider:nil appType:manager.type];
    }];
    }
}

/// 注册模块：端集成
static void registerModulesForThirdNativeApp() {
    BDPModuleManager *moduleManager = [BDPModuleManager moduleManagerOfType:BDPTypeThirdNativeApp];
    [moduleManager registerModuleWithProtocol:@protocol(BDPAuthModuleProtocol) class:[BDPAuthModule class]];
    [moduleManager registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:[BDPStorageModule class]];
}

/// 注册模块：动态组件
static void registerModulesForDynamicComponent() {
    @autoreleasepool {
    BDPModuleManager *moduleManagerOfDyComponent = [BDPModuleManager moduleManagerOfType:BDPTypeDynamicComponent];
    [moduleManagerOfDyComponent registerModuleWithProtocol:@protocol(CommonAppLoadProtocol) class:CommonAppLoader.class];
    [moduleManagerOfDyComponent registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:[BDPPackageModule class]];
    [moduleManagerOfDyComponent registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:[BDPStorageModule class]];
    [moduleManagerOfDyComponent registerModuleWithProtocol:@protocol(MetaInfoModuleProtocol) class:MetaInfoModule.class handler:^id<MetaInfoModuleProtocol> _Nonnull(BDPModuleManager * _Nonnull manager) {
        return [[MetaInfoModule alloc] initWithProvider:nil appType:manager.type];
    }];
    }
}

/// 注册模块：卡片
static void registerModulesForCard() {
    @autoreleasepool {
    BDPModuleManager *moduleManagerOfCard = [BDPModuleManager moduleManagerOfType:BDPTypeNativeCard];
    [moduleManagerOfCard registerModuleWithProtocol:@protocol(CommonAppLoadProtocol) class:CommonAppLoader.class];
    [moduleManagerOfCard registerModuleWithProtocol:@protocol(MetaInfoModuleProtocol) class:MetaInfoModule.class handler:^id<MetaInfoModuleProtocol> _Nonnull(BDPModuleManager * _Nonnull manager) {
        return [[MetaInfoModule alloc] initWithProvider:CardMetaProvider.new appType:manager.type];
    }];
    [moduleManagerOfCard registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:[BDPStorageModule class]];
    [moduleManagerOfCard registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:BDPPackageModule.class];
    [moduleManagerOfCard registerModuleWithProtocol:@protocol(BDPAuthModuleProtocol) class:BDPAuthModule.class];
    }
}

/// 注册模块：Block
static void registerModulesForBlock() {
    @autoreleasepool {
    BDPModuleManager *moduleManager = [BDPModuleManager moduleManagerOfType:BDPTypeBlock];
    [moduleManager registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:BDPStorageModule.class];
    [moduleManager registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:BDPPackageModule.class];
    [moduleManager registerModuleWithProtocol:@protocol(BDPAuthModuleProtocol) class:BDPAuthModule.class];
    [moduleManager registerModuleWithProtocol:@protocol(MetaInfoModuleProtocol) class:MetaInfoModule.class handler:^id<MetaInfoModuleProtocol> _Nonnull(BDPModuleManager * _Nonnull manager) {
        return [[MetaInfoModule alloc] initWithProvider:nil appType:BDPTypeBlock];
    }];
    }
}

/// 注册模块：SDKMsgCard
static void registerModulesForSDKMsgCard() {
    BDPModuleManager *moduleManager = [BDPModuleManager moduleManagerOfType:BDPTypeSDKMsgCard];
    [moduleManager registerModuleWithProtocol:@protocol(BDPStorageModuleProtocol) class:BDPStorageModule.class];
    [moduleManager registerModuleWithProtocol:@protocol(BDPPackageModuleProtocol) class:BDPPackageModule.class];
}

LoadableMainFuncBegin(registerSeveralModules)
registerModulesForNativeAndH5App();
registerModulesForWebApp();
registerModulesForThirdNativeApp();
registerModulesForCard();
registerModulesForBlock();
registerModulesForDynamicComponent();
registerModulesForSDKMsgCard();
LoadableMainFuncEnd(registerSeveralModules)

@implementation BDPEngineAssembly

#pragma mark - Unregister

/// 用于退出登陆时，清理跟所有应用类型文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearAllSharedLocalFileManagers {
    NSArray<NSNumber *> *types = @[@(BDPTypeNativeApp), @(BDPTypeNativeCard),@(BDPTypeBlock)];
    for (NSNumber *typeNumber in types) {
        BDPType appType = (BDPType)[typeNumber integerValue];
        [BDPGetResolvedModule(MetaInfoModuleProtocol, appType) closeDBQueue];
        [BDPGetResolvedModule(BDPPackageModuleProtocol, appType) closeDBQueue];
    }
    [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) clearAllSharedLocalFileManagers];
    [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeBlock) clearAllSharedLocalFileManagers];
    
    [LaunchInfoAccessorFactory clearAllLuancInfoAccessor];
}

@end


