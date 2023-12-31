//
//  OPJSEngineProtocol.h
//  OPJSEngine
//
//  Created by coderyi on 2021/12/24.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OPAppUniqueID.h"
#import "BDPJSBridgeMethod.h"
#import "OPJSEngineBase.h"

#define BDPUniqueID OPAppUniqueID

@protocol BDPJSBridgeEngineProtocol;
@protocol BDPJSBridgeAuthorizationProtocol;
@class OpenJSWorkerQueue;

typedef NSObject<BDPJSBridgeEngineProtocol> *BDPJSBridgeEngine;
// 迁移到 OPMicroAppJSRuntimeProtocol.h 文件中
//typedef id<OPMicroAppJSRuntimeProtocol> BDPMicroAppJSRuntimeEngine;
typedef id<BDPJSBridgeAuthorizationProtocol> BDPJSBridgeAuthorization;
/**
 JSBridge 调用前会进行权限校验，只有返回值为 BDPAuthorizationPermissionResultEnabled 时才可进入调用。
 */
typedef NS_ENUM(NSUInteger, BDPAuthorizationPermissionResult) {
    BDPAuthorizationPermissionResultEnabled = 0,                    // 权限请求 - 成功
    BDPAuthorizationPermissionResultSystemDisabled,                 // 权限请求 - 失败，用户未对该小程序/小游戏授权
    BDPAuthorizationPermissionResultUserDisabled,                   // 权限请求 - 失败，系统未对该宿主程序授权
    BDPAuthorizationPermissionResultPlatformDisabled,               // 权限请求 - 失败，开放平台 SDK 未授予权限(黑白名单策略限制)
    BDPAuthorizationPermissionResultInvalidScope                    // 权限请求 - 失败，请求权限类型无效
};

@protocol BDPAuthorizationDelegate <NSObject>

- (UIViewController * _Nullable)controller;

@end

#pragma mark - BDPlatform JSBridge Authorization Protocol
/* ------- 开放平台JSBridge 权限校验协议 ------- */
@protocol BDPJSBridgeAuthorizationProtocol <NSObject>

@required
/// 校验开放平台API权限
/// @param method API方法
/// @param engine JSBridge 引擎
/// @param completion 权限回调
- (void)checkAuthorization:(BDPJSBridgeMethod * _Nullable)method engine:(BDPJSBridgeEngine _Nullable)engine completion:(void (^ _Nullable)(BDPAuthorizationPermissionResult))completion;

@end

#pragma mark - BDPlatform JSBridge Engine Protocol
/* ------- 开放平台 JSBridge 引擎协议 ------- */
@protocol BDPJSBridgeEngineProtocol <NSObject>

@required
/// 引擎唯一标示符
@property (nonatomic, strong, readonly, nonnull) BDPUniqueID *uniqueID;
/// 开放平台 JSBridge 方法类型
@property (nonatomic, assign, readonly) BDPJSBridgeMethodType bridgeType;
/// 调用 API 所在的 ViewController 环境
@property (nonatomic, weak, readonly, nullable) UIViewController *bridgeController;
/// 权限校验器
@property (nonatomic, strong, nullable) BDPJSBridgeAuthorization authorization;
- (void)bdp_evaluateJavaScript:(NSString * _Nonnull)script
                    completion:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completion;
- (void)bdp_fireEventV2:(NSString * _Nonnull)event data:(NSDictionary * _Nullable)data;  // data 支持 arrayBuffer
- (void)bdp_fireEvent:(NSString * _Nonnull)event sourceID:(NSInteger)sourceID data:(NSDictionary * _Nullable)data;

@optional
/*
 worker
 */
// sub workers节点
@property (nonatomic, strong, readonly, nullable) OpenJSWorkerQueue *workers;
// worker间传递消息
- (void)transferMessage:(NSDictionary * _Nullable)data;
@end

/* ------- 各应用类型提供的webview(engine)遵循的协议 ------- */
@protocol BDPEngineProtocol <NSObject>

@required
/// 引擎唯一标示符
@property (nonatomic, strong, readonly, nonnull) BDPUniqueID *uniqueID;
//@property (nonatomic, copy, readonly, nonnull) NSString *appId;
//@property (nonatomic, assign, readonly) BDPType appType;
/// 权限校验器
@property (nonatomic, strong, nullable) BDPJSBridgeAuthorization authorization;

- (void)bdp_fireEventV2:(NSString * _Nonnull)event data:(NSDictionary * _Nullable)data;  // data 支持 arrayBuffer
- (void)bdp_fireEvent:(NSString * _Nonnull)event sourceID:(NSInteger)sourceID data:(NSDictionary * _Nullable)data;

@optional
///optional里是形态独有的方法
#pragma mark Web应用的方法
- (NSString *)getSession;

/*
 worker
 */
@property (nonatomic, strong, readonly, nullable) OpenJSWorkerQueue *workers;

@end



@protocol OPBaseJSRuntimeProtocol <BDPEngineProtocol, BDPJSBridgeEngineProtocol>

@end


// TO: OPJSEngine :  GeneralJSRuntimeDelegate.h

//#import "BDPJSRuntimeSocketConnection.h"
//#import <UIKit/UIKit.h>
//@class JSValue;
//@class BDPJSRuntimeSocketConnection;
//@class BDPJSRuntimeSocketMessage;
//@protocol GeneralJSRuntimeDelegate <NSObject>
//// runtime 加载完成
//- (void)runtimeLoad;
//@optional
//// runtime exception
//- (void)runtimeException: (NSDictionary * _Nullable)data exception: (JSValue * _Nullable)exception;
//// runtime 中断
//- (void)runtimeInterrupt:(BOOL)stop;
//// runtime publish消息到渲染层
//- (void)runtimePublish:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs useNewPublish:(BOOL)useNewPublish;
//// 前端触发的onDocumentReady
//- (void)runtimeOnDocumentReady;
//
//// runtime 的bridge controller
//- (UIViewController * __nullable) runtimeBridgeController;
//
//// socket debug相关
//
//- (void)socketDidConnected;
//- (void)socketDidFailWithError:(NSError *)error;
//- (void)socketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
//
//// 连接状态变化，在JS线程调用
//- (void)connection:(BDPJSRuntimeSocketConnection *)connection statusChanged:(BDPJSRuntimeSocketStatus)status;
//// 收到消息，在JS线程调用
//- (void)connection:(BDPJSRuntimeSocketConnection *)connection didReceiveMessage:(BDPJSRuntimeSocketMessage *)message;
//
//// trace
//- (void)bindCurrentThreadTracing;
//- (void)bindCurrentThreadTracingFromUniqueID;
//
//@end
