//
//  EMAAppEnginePluginDelegate.h
//  OPFoundation
//
//  Created by justin on 2022/12/23.
//

#import <Foundation/Foundation.h>
#import "BDPBasePluginDelegate.h"
#import "EMAAppEngineConfig.h"
#import "EMAAppEngineAccount.h"
#import "EMAConfig.h"
#import "EMAPreloadManager.h"
#import <ECOInfra/EMAConfigManager.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EMAAppEnginePluginDelegate <BDPBasePluginDelegate>

@required

// == EMAAppEngine.currentEngine
//+ (id<EMAAppEnginePluginDelegate>)sharedPlugin;

/// 引擎配置
@property (nonatomic, strong, nullable, readonly) EMAAppEngineConfig *config;

/// 引擎账户
@property (nonatomic, strong, nullable, readonly) EMAAppEngineAccount *account;


/// 配置中心远程配置 Mina
@property (nonatomic, strong, nullable, readonly) EMAConfig *onlineConfig DEPRECATED_MSG_ATTRIBUTE("use EMAAppEngine.current.configManager.minaConfig");

/// 配置中心
@property (nonatomic, strong, nullable, readonly) EMAConfigManager *configManager;

/// 预加载manager
@property (nonatomic, strong, nullable) id<EMAPreloadManager> preloadManager;

//暴露接口给 TTMicroApp，可以通过内部触发 JSSDK 更新逻辑
- (void)updateLibIfNeedWithConfig:(NSDictionary *)config;
@end

NS_ASSUME_NONNULL_END
