//
//  BDQuaterbackSDK.h
//  Pods
//
//  Created by hopo on 2019/11/17.
//

#import <Foundation/Foundation.h>
#import "BDQBDelegate.h"
#import "BDDYCMonitor.h"

//



NS_ASSUME_NONNULL_BEGIN

@interface AweQuaterbackConfiguration : NSObject
/**
 是否打开 debug 调试信息，默认为NO
 */
@property (nonatomic, assign) BOOL debug;

#pragma mark - parameters

/**
 [Required]
 App在公司内部唯一标识，又名`SSAppID`, or read info.plist key `SSAppID`
 */
@property (nonatomic, copy, nonnull) NSString *aid;

/**
 [Required]
 设备id
 */
@property (nonatomic, copy,  nonnull) NSString* (^getDeviceIdBlock)(void);

/**
 [Optional]
 install id
 */
@property (nonatomic, copy, nullable) NSString* (^getInstallIdBlock)(void);

/**
 App渠道；默认读取 info.plist 的 `CHANNEL_NAME` 字段
 */
@property (nonatomic, copy, nonnull) NSString *channel;

/**
 [Optional]
 App三位主版本号；默认读取`CFBundleShortVersionString`
 */
@property (nonatomic, copy, nonnull) NSString *appVersion;

/**
 [Optional]
 App编译版本号，头条内部通常是四位版本号；默认读取`CFBundleVersion`
 */
@property (nonatomic, copy, nonnull) NSString *appBuildVersion;


#pragma mark - network parameters

// `distArea` 和 `domainName` 决定请求接口的域名。
// 如果手动设置了 domainName ，将使用 domainName 作为接口域名，否则将使用 distArea 配置的默认域名
/**
 [Required]
 产品发布地区；Default is `kBDDYCDeployAreaCN`
 */
@property (nonatomic, assign) BDDYCDeployArea distArea;

/**
 [Optional]
 Domain name, Default is from `distArea` field.
 根据产品实际需求可动态配置部署域名
 */
@property (nonatomic, copy, nonnull) NSString *domainName;

/**
 Common network parameters
 */
@property (nonatomic, copy, nonnull) NSDictionary* (^commonNetworkParamsBlock)(void);

/**
 判断当前网络是否为WIFI
 */
@property (nonatomic, copy, nullable) BOOL (^isWifiNetworkBlock)(void);

/// 是否支持切换前台是请求xxx包;默认：YES
@property (nonatomic, assign) BOOL enableEnterForegroundRequest;

@end



/**
 日志输出相关配置，默认都是NO
 */

@interface AweQuaterbackLogConfiguration : NSObject
/**
 是否输出 Module (load + hook) 日志
 */
@property (nonatomic, assign) bool enableModInitLog;

/**
 是否在控制台显示 NSLog 日志
 */
@property (nonatomic, assign) bool enablePrintLog;

/**
 是否在控制台显示 Instruction 执行日志
 */
@property (nonatomic, assign) bool enableInstExecLog;

/**
 是否在控制台显示 Instruction 执行调用堆栈日志
 */
@property (nonatomic, assign) bool enableInstCallFrameLog;

@end


@interface AweQuaterbackSDK : NSObject

/**
 运行主程序

 @param conf     配置
 @param delegate 回调代理，被strong持有
 */
+ (void)startWithConfiguration:(AweQuaterbackConfiguration *)conf
                       logConf:(AweQuaterbackLogConfiguration *)logConf
                      delegate:(id<BDQBDelegate> _Nullable)delegate;

/**
 主动拉取patch list
 */
+ (void)fetchQuaterbacks;

/**
 清理本地补丁包
 */
+ (void)clearAllLocalQuaterback;

/**
  懒加载动态库patch包加载
 */
+ (void)loadLazyModuleWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
