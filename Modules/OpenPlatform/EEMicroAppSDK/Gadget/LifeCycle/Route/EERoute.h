//
//  EERoute.h
//  EEMicroAppSDK
//
//  Created by fanlv on 2018/4/14.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <OPFoundation/EMAConfig.h>
#import <OPFoundation/EMAPermissionData.h>
#import <OPFoundation/EMAProtocol.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OPFoundation/OPEnvTypeHelper.h>
#import <ECOProbe/OPTrace.h>
#import <OPGadget/OPGadget-Swift.h>

@class MicroAppDomainConfig;

#define kTimorRootDir [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Timor"]

/// 引擎和Lark交互使用的类，目前已经很臃肿，类名也不合理，需要重构
@interface EERoute : NSObject

/*----------------------------------------------------------*/
#pragma mark             核心接口
/*----------------------------------------------------------*/

+ (instancetype _Nonnull)sharedRoute;

/**
 更新小程序引擎配置

 @param delegate        需要Lark提供对应能力的代理
 @param accountToken    用于唯一标识一个 账户 的 token，用于隔离多账户的小程序数据
 @param userID Lark     用户ID，该数据属于隐私数据，不允许对外直接提供
 @param userSession     Lark 用户session，该数据属于隐私数据，不允许对外直接提供
 @param envType         环境
 @param domainConfig         私有部署域名
 @param channel
 @param tenantID         租户ID
 */
- (void)loginWithDelegate:(id<EMAProtocol> _Nullable)delegate
              accoutToken:(NSString * _Nonnull)accountToken
                   userID:(NSString * _Nonnull)userID
              userSession:(NSString * _Nonnull)userSession
                  envType:(OPEnvType)envType
             domainConfig:(MicroAppDomainConfig * _Nonnull)domainConfig
                  channel:(NSString * _Nonnull)channel
                 tenantID:(NSString * _Nonnull)tenantID;

/// 用户ID
@property (nonatomic, copy) NSString *userID;

/**
 主端调用小程序登录接口时机可能会早于loginWithDelegate时机, 进而导致loginURL还没来得及同步导致网络请求异常;
 这边使用这个状态进行控制;(这个逻辑作为临时解决方案; 后续有其他完整解决方案进行替换)
 */
@property (nonatomic, assign, readonly) BOOL isFinishLogin;

/**
 主端调用小程序登录接口时机可能会早于loginWithDelegate时机, 进而导致loginURL还没来得及同步导致网络请求异常;
 这边使用这个block进行控制;(这个逻辑作为临时解决方案; 后续有其他完整解决方案进行替换)
 */
@property (nonatomic, copy) void (^loginFinishCallback)(void);

- (void)logout;

/**
 打开小程序。场景值默认为1000，代表未定义

 @param url 小程序链接，如：sslocal://microapp?app_id=xxxx
 @return 是否打开
 */
- (BOOL)openURLByPushViewController:(NSURL *)url window:(UIWindow *_Nullable)window;

- (BOOL)openURLByPushViewController:(NSURL *)url scene:(NSInteger)scene window:(UIWindow *_Nullable)window;

- (BOOL)openURLByPushViewController:(NSURL *)url scene:(NSInteger)scene window:(UIWindow *)window channel:(NSString *)channel applinkTraceId:(NSString *)applinkTraceId;

- (BOOL)openURLByPushViewController:(NSURL *)url
                              scene:(NSInteger)scene
                             window:(UIWindow *)window
                            channel:(NSString *)channel
                     applinkTraceId:(NSString *)applinkTraceId
                              extra:(MiniProgramExtraParam *)extra;



/// 真机调试打开小程序
/// @param url schema url
- (void)realMatchineDebugOpenURL:(NSURL * _Nonnull)url window:(UIWindow *_Nullable)window;


/**
 打开小程序，不自动push，由调用方负责push

 @param url 小程序链接，如：sslocal://microapp?app_id=xxxx
 @param scene 打开小程序的场景值
 @param window 打开小程序的window( iPad 多 Scene 模式需要 )
 @return vc
 */
- (UIViewController *)getViewControllerByURL:(NSURL *)url scene:(NSInteger)scene window:(UIWindow *_Nullable)window;


/*----------------------------------------------------------*/
#pragma mark                 属性
/*----------------------------------------------------------*/

/**
 需要Lark提供对应能力的代理
 */
/// 不可再被公开调用，如果需要，请使用`EEMicroAppSDK组件下的EMARouteProvider`
//@property (nonatomic, weak, readonly, nullable) id<EMAProtocol> delegate DEPRECATED_MSG_ATTRIBUTE("");

- (NSDictionary *)preloadABTestDicWith:(nullable id<EMAProtocol>)delegate;

/// 仅提供给passport登陆前调用活体相关能力
@property (nonatomic, weak) id<EMALiveFaceProtocol> liveFaceDelegate DEPRECATED_MSG_ATTRIBUTE("you should not use it directly. please use EMAProtocolProvider in OPPluginBiz");


/*----------------------------------------------------------*/
#pragma mark                接口
/*----------------------------------------------------------*/

/**
 清除小程序缓存
 */
- (void)clearTaskCache;

/**
 清除指定小程序的缓存

 @param uniqueID 小程序的uniqueID
 */
- (void)clearTaskCacheWithUniqueID:(BDPUniqueID *)uniqueID;

- (void)setJSSDKUrlString:(NSString *)urlString;
- (void)setBlockJSSDKUrlString:(NSString *)urlString; // 设置debug下block js sdk地址

/// 是否开启开发者调试开关
@property BOOL debugEnable;

- (EMAConfig * _Nullable)onlineConfig;

- (void)updateDebug;

#pragma mark --H5 JsApi
/// 网页调用tt系列API， params 必须封装为如下字典，否则无法兼容遗留代码的字典取值，本次修改增加一个shouldUseNewbridgeProtocol用于灰度
/*
{
 "params": {
    业务数据
 },
 "callbackId": ""
}
*/
///  shouldUseNewbridgeProtocol代表是否使用了新的协议，webappengine看了一下代码是和controller生命周期挂钩，但是webvc加载不同的网页的时候，不同网页引入的jssdk可能是新的也可能是老的，需要兼容
- (void)invokeWebMethod:(NSString *)method
                 params:(NSDictionary *)params
                 engine:(id)engine
             controller: (UIViewController *)controller
               needAuth:(BOOL)needAuth
shouldUseNewbridgeProtocol:(BOOL)shouldUseNewbridgeProtocol
                  trace: (OPTrace *)trace
               webTrace: (OPTrace *)webTrace;

@end

@interface EERoute(Permission)

/**
 获取应用权限数据

 @param uniqueID uniqueID
 @return 权限数组
 */
- (NSArray<EMAPermissionData *> *)getPermissionDataArrayWithUniqueID:(BDPUniqueID *)uniqueID;

/**
 设置应用权限

 @param permissons 标识授权状态的键值对：@{(NSString *)scopeKey: @((BOOL)approved)}
 @param uniqueID uniqueID
 */
- (void)setPermissons:(NSDictionary<NSString *, NSNumber *> *)permissons uniqueID:(BDPUniqueID *)uniqueID;

/**
 处理 wsURL 调用
 @param url 开关调试的URL ws://ip:port?allow=[true|false]
 */
- (void)handleDebuggerWSURL:(NSString * _Nonnull)wsURL;

- (void)fetchAuthorizeData:(BDPUniqueID *)uniqueID storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion;

@end

FOUNDATION_EXTERN id<EMAProtocol> _Nullable getEERouteDelegate(void);
