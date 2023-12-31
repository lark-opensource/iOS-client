//
//  TTBridgeEngine
//  TTBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by lizhuopeng on 2018/10/30.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTBridgeAuthorization;
@class TTBridgeRegister;

@protocol TTBridgeEngine <NSObject>

@required

/**
 The source ViewController of the engine.
 */
@property (nonatomic, weak, nullable, readonly) UIViewController *sourceController;

/**
 The url of the current webpage of the engine.
 */
@property (nonatomic, strong, readonly, nullable) NSURL *sourceURL;

/**
 The source object of the engine, and it is a webView generally.
 */
@property (nonatomic, weak, readonly) NSObject *sourceObject;

/**
 The local register. Bridges registered by the local register can only be used in the register's engine. The bridge registered by the local register is prefered when bridge's name is same.
 */
@property(nonatomic, strong, readonly) TTBridgeRegister *bridgeRegister;

@optional
/**
 The authorization of bridges. It can be customized and it is nil by default, which means all bridges are public.
 */
@property (nonatomic, strong) id<TTBridgeAuthorization> authorization;

- (TTBridgeRegisterEngineType)engineType;

- (void)fireEvent:(TTBridgeName)eventName params:(nullable NSDictionary *)params;
- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params;
- (void)fireEvent:(TTBridgeName)eventName params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock;
- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock;

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName;

#pragma mark - deprecated
- (void)callbackBridge:(TTBridgeName)bridgeName params:(nullable NSDictionary *)params __deprecated_msg("Use -[TTBridgeEngine fireEvent:params:]");
- (void)callbackBridge:(TTBridgeName)bridgeName params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock __deprecated_msg("Use -[TTBridgeEngine fireEvent:params:resultBlock:]");
- (void)callbackBridge:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock __deprecated_msg("Use -[TTBridgeEngine fireEvent:msg:params:resultBlock:]");

@end
NS_ASSUME_NONNULL_END
