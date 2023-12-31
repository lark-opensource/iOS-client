//
//  EMAAppEngine.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/18.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/EMAPreloadManager.h>
#import "EMAAppUpdateManagerV2.h"
#import <OPFoundation/EMAAppEngineAccount.h>
#import <OPFoundation/EMAAppEngineConfig.h>
#import "EMALibVersionManager.h"
#import "EMAComponentsVersionManager.h"
#import <OPFoundation/EMAConfig.h>
#import <OPFoundation/EMAAppEnginePluginDelegate.h>

@class EMAConfigManager, OpenPluginCommnentJSManager, CommonComponentResourceManager, OPPackageSilenceUpdateManager;

NS_ASSUME_NONNULL_BEGIN

/**
 *  其生命周期与当前账户的生命周期一致，账户退出则销毁，账户登录则创建（租户切换等同与账户切换）。
 *  所有与账户生命周期一致的全局对象，可以放在这里统一管理。
 *  减少全局单例的使用有利于账户切换时的内存管理。
 */
@interface EMAAppEngine : NSObject<EMAAppEnginePluginDelegate>

/// 当前账户引擎对象，注意是可空对象（账户登出后为空）
+ (instancetype _Nullable)currentEngine;

/// 登录
+ (void)loginWithAccount:(EMAAppEngineAccount * _Nonnull)account config:(EMAAppEngineConfig * _Nonnull)config;

/// 引擎启动
- (void)startup;

/// 登出
+ (void)logout;

/// 小程序更新管理器
@property (nonatomic, strong, nullable) EMAAppUpdateManagerV2 *updateManager;

/// 预加载manager
@property (nonatomic, strong, nullable) id<EMAPreloadManager> preloadManager;

/// 引擎账户
@property (nonatomic, strong, nullable, readonly) EMAAppEngineAccount *account;

/// 引擎配置
@property (nonatomic, strong, nullable, readonly) EMAAppEngineConfig *config;

/// 配置中心远程配置 Mina
@property (nonatomic, strong, nullable, readonly) EMAConfig *onlineConfig DEPRECATED_MSG_ATTRIBUTE("use EMAAppEngine.current.configManager.minaConfig");

/// 配置中心
@property (nonatomic, strong, nullable, readonly) EMAConfigManager *configManager;

/// JSSDK 管理器
@property (nonatomic, strong, nullable, readonly) EMALibVersionManager *libVersionManager;

/// 大组件管理器
@property (nonatomic, strong, nullable, readonly) EMAComponentsVersionManager *componentsVersionManager;

/// 评论组件管理器
@property (nonatomic, strong, nullable, readonly) OpenPluginCommnentJSManager *commnentVersionManager;

/// ajaxHookJS管理器
@property (nonatomic, strong, nullable, readonly) CommonComponentResourceManager *componentResourceManager;

/// 止血pull&push管理器
@property (nonatomic, strong, nullable, readonly) OPPackageSilenceUpdateManager *silenceUpdateManager;
@end

NS_ASSUME_NONNULL_END
