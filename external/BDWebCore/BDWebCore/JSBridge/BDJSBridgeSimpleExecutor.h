//
//  BDJSBridgeSimpleExecutor.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/5.
//

#import <Foundation/Foundation.h>
#import "BDJSBridgeExecutor.h"
#import "BDJSBridgeAuthenticator.h"
#import "BDJSBridgeCoreDefines.h"
#import <WebKit/WebKit.h>
#import <Gaia/Gaia.h>

NS_ASSUME_NONNULL_BEGIN

#define BDRegisterSimpleBridgeGaiaKey "BDRegisterSimpleBridgeGaiaKey"
#define BDRegisterSimpleBridgeFunction GAIA_FUNCTION(BDRegisterSimpleBridgeGaiaKey)
#define BDRegisterSimpleBridgeMethod GAIA_METHOD(BDRegisterSimpleBridgeGaiaKey);

typedef void(^BDJSBridgeSimpleHandler)(WKWebView *webView, NSDictionary * _Nullable params, BDJSBridgeCallback callback);

typedef NS_ENUM(NSInteger, BDJSSimpleBridgeCompatibility) {
    BDJSSimpleBridgeCompatibilityRequireNoHandler, //当没有其他 executor/SDK 处理这个 bridge
    BDJSSimpleBridgeCompatibilityOverride, //优先级最高，会覆盖其他 executor 的 bridge 实现，慎用
};

@interface BDJSBridgeSimpleExecutor : NSObject<BDJSBridgeExecutor>

@property(nonatomic, strong, class) id<BDJSBridgeAuthenticator> authenticator;

/// 注册一个 local bridge, 仅针对当前 webView 生效, 同名 bridge 重复注册时 local bridge 优先级高于 global bridge
- (void)registerBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler;
- (void)registerBridge:(NSString *)bridgeName namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler;


/// 注册一个 global bridge, 针对所有加载了  BDJSBridgePluginObject 的 webView 生效
+ (void)registerGlobalBridge:(NSString *)bridgeName compatibility:(BDJSSimpleBridgeCompatibility)compatibility authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler;
+ (void)registerGlobalBridge:(NSString *)bridgeName namespace:(NSString *)namespace authType:(BDJSBridgeAuthType)authType handler:(BDJSBridgeSimpleHandler)handler;

@end

@interface WKWebView (BDSimpleExecutor)

@property(nonatomic, weak, readonly) BDJSBridgeSimpleExecutor *bdw_bridgeSimpleExecutor;

@end

NS_ASSUME_NONNULL_END
