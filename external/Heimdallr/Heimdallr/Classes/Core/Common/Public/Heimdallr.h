//
//  Heimdallr.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDInjectedInfo.h"

@interface Heimdallr : NSObject

@property (nonatomic, strong, readonly, nullable) HMDInjectedInfo *userInfo;
@property (nonatomic, copy, readonly, nullable) NSString *sessionID;
@property (nonatomic, assign) BOOL showDebugAlert;
@property (nonatomic, assign) BOOL enablePriorityInversionProtection; // 优先级反转保护(目前只针对HMDConfigManager)
@property (atomic, assign, readonly) BOOL enableWorking; // Heimdallr各个功能模块是否允许启动

/// Hermas重构开关，由宿主设置是否开启，并且其优先级高于slardar settings开关。当次设置不生效，第二次启动后生效，应该在[Heimdallr shared]之后调用
@property (nonatomic, assign, class) BOOL enableHermasRefactor;

// the weight of max upload size in refactor version
// to optimize the usage of vitual memory in Hermas
@property (nonatomic, copy, nullable, class) NSDictionary *refactorMaxUploadSizeWeight;


/**
 单例方法

 @return 返回Heimdallr的单例
 */
+ (instancetype _Nonnull)shared;

/**
 初始化APM SDK

 @param info 一些APM SDK工作必须的信息，如device_id,app_id等

 注意：⚠️这个接口请在device_id确保有效之后调用
 */
- (void)setupWithInjectedInfo:(HMDInjectedInfo * _Nullable)info;

/**
 当宿主APP没有接入Heimdallr时，需要调用此方法开启SDKMonitor或TTMonitor的配置拉取

 注意：⚠️这个接口在宿主app没有接入Heimdallr SDK的情况下，作为获取服务端配置的入口
*/
+ (void)setupAllSDKMonitors;

/**
 返回某个功能模块是否在工作 [已废弃]
 - addObserverForName:usingBlock: 代替
 
 @param moduleName 功能模块的名字，定义见HMDConstants.h文件
 @return 该模块是否在工作
 */
- (BOOL)isModuleWorkingForName:(NSString * _Nullable)moduleName __attribute__((deprecated("deprecated. Use new API Heimdallr+ModuleCallback.h")));

- (id _Nullable)init __attribute__((unavailable("Use +shared to retrieve the shared instance.")));
+ (instancetype _Nullable)new __attribute__((unavailable("Use +shared to retrieve the shared instance.")));

@end
