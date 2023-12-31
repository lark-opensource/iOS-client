//
//  BDPJSBridgeBase.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/12.
//

#import <Foundation/Foundation.h>
//#import "BDPDefineBase.h"
#import <OPFoundation/OPJSEngineBase.h>

#pragma mark - BDPlatformJSBridge PluginMode
/* ------- 开放平台 JSBridge 插件模式 ------- */
typedef NS_ENUM(NSUInteger, BDPJSBridgePluginMode) {
    BDPJSBridgePluginModeUnknown        = 0,    // 插件模式 - 未知模式
    BDPJSBridgePluginModeNewInstance    = 1,    // 插件模式 - 每次使用新实例(默认)
    BDPJSBridgePluginModeGlobal         = 2,    // 插件模式 - 全局单例
    BDPJSBridgePluginModeLifeCycle      = 3     // 插件模式 - 跟随 JavaScriptEngine 生命周期
};

#pragma mark - BDPlatformJSBridge Callback
/* ------- 开放平台 JSBridge 回调类型 ------- */
typedef NS_ENUM(NSUInteger, BDPJSBridgeCallBackType) {
    BDPJSBridgeCallBackTypeUnknown,                                 // 回调类型 - 未知类型
    BDPJSBridgeCallBackTypeSuccess,                                 // 回调类型 - 成功
    BDPJSBridgeCallBackTypeFailed,                                  // 回调类型 - 失败
    BDPJSBridgeCallBackTypeUserCancel,                              // 回调类型 - 失败，用户取消
    BDPJSBridgeCallBackTypeParamError,                              // 回调类型 - 失败，参数错误
    BDPJSBridgeCallBackTypeInvalidScope,                            // 回调类型 - 失败，请求权限非法
    
    BDPJSBridgeCallBackTypeNoHandler,                               // 回调类型 - 失败，API SDK 内部未实现/未注册
    BDPJSBridgeCallBackTypeNoHostHandler,                           // 回调类型 - 失败，API 宿主程序未实现
    BDPJSBridgeCallBackTypeNoAuthorization,                         // 回调类型 - 失败，无权限管理器 (common.auth)
    BDPJSBridgeCallBackTypeNoUserPermission,                        // 回调类型 - 失败，用户未对该小程序/小游戏授权
    BDPJSBridgeCallBackTypeNoSystemPermission,                      // 回调类型 - 失败，系统未对该宿主程序授权
    BDPJSBridgeCallBackTypeNoPlatformPermission,                     // 回调类型 - 失败，开放平台 SDK 未授予权限 (黑白名单策略限制)
    BDPJSBridgeCallBackTypeContinued    //  目前仅网页应用在新协议下使用
};

typedef void(^BDPJSBridgeCallback)(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response);

#pragma mark - BDPlatformJSBridge BaseMacro
/* ------- 开放平台 JSBridge 基础定义 ------- */
//  提供给外部调用，所有的参数都可能为空 , 即将淘汰的老接口，新接口请使用 BDP_HANDLER
#define BDP_EXPORT_HANDLER(NAME) \
- (void)NAME##WithParam:(NSDictionary * _Nullable)param \
               callback:(BDPJSBridgeCallback _Nullable)callback \
                 engine:(BDPJSBridgeEngine _Nullable)engine \
             controller:(UIViewController * _Nullable)controller;

//  提供给外部调用，所有的参数都可能为空
#define BDP_HANDLER(NAME) \
- (void)NAME##WithParam:(NSDictionary * _Nullable)param \
               callback:(BDPJSBridgeCallback _Nullable)callback \
                context:(BDPPluginContext _Nullable)context;
