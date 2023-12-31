//
//  BridgeRegister.h
//  Pods
//
//  Created by renpeng on 2018/10/9.
//

#import <Foundation/Foundation.h>
#import "TTBridgePlugin.h"
#import "TTBridgeDefines.h"
#import "TTBridgeCommand.h"
#import "TTBridgeEngine.h"

NS_ASSUME_NONNULL_BEGIN


@protocol TTBridgeInterceptor;

/**
 Register bridge.

 @param engineType the platform of the bridge, which can be RN, webView or Lynx
 @param pluginName plugin name
 @param bridgeName bridge name
 @param authType authrization type of the bridge
 @param domains bridge's private domains
 */
FOUNDATION_EXTERN void TTRegisterBridge(TTBridgeRegisterEngineType engineType,
                             NSString *pluginName,
                             TTBridgeName bridgeName,
                             TTBridgeAuthType authType,
                             NSArray<NSString *> * _Nullable domains);

FOUNDATION_EXTERN void TTRegisterWebViewBridge(NSString *pluginName, TTBridgeName bridgeName);

FOUNDATION_EXTERN void TTRegisterRNBridge(NSString *pluginName, TTBridgeName bridgeName);

FOUNDATION_EXTERN void TTRegisterJSWorkerBridge(NSString *pluginName, TTBridgeName bridgeName);

FOUNDATION_EXTERN void TTRegisterAllBridge(NSString *pluginName, TTBridgeName bridgeName);

@interface TTBridgeMethodInfo : NSObject

@property (nonatomic, copy, readonly) NSDictionary<NSNumber*, NSNumber*> *authTypes;

@end

typedef void(^TTBridgeHandler)(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller);


@interface TTBridgeRegisterMaker : NSObject

@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^authType)(TTBridgeAuthType authType);//Default: TTBridgeAuthProtected.
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^pluginName)(NSString *pluginName);
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^bridgeName)(NSString *bridgeName);
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^engineType)(TTBridgeRegisterEngineType engineType);//Default: TTBridgeRegisterAll.
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^privateDomains)(NSArray<NSString *> *domains);//This needs be configured when registering private bridges.
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^handler)(TTBridgeHandler handler);//The bridge can also be implemented By sending a block.
@property (nonatomic, copy, readonly, nullable) TTBridgeRegisterMaker *(^extraInfo)(NSDictionary *extraInfo);//This property is the extra info needed to send to the front-end for local bridge.
@end

@protocol TTBridgeDocumentor <NSObject>

- (void)documentizeBridge:(TTBridgeName)bridgeName authType:(TTBridgeAuthType)authType engineType:(TTBridgeRegisterEngineType)engineType desc:(nullable NSString *)desc;

@end

@protocol TTBridgeRegisterProtocol <NSObject>

@optional
- (void)didRegisterMethod:(TTBridgeName)bridgeName
                  handler:(nullable TTBridgeHandler)handler
               engineType:(TTBridgeRegisterEngineType)engineType
                 authType:(TTBridgeAuthType)authType
                  domains:(nullable NSArray<NSString *> *)domains
               inRegister:(TTBridgeRegister*)bridgeRegister;
@end

typedef void(^TTBridgePreExecuteHandler)(TTBridgeMethodInfo *methodInfo);

@interface TTBridgeRegister : NSObject

@property(nonatomic, weak, class) id<TTBridgeDocumentor> documentor;
@property(nonatomic, weak) id<TTBridgeRegisterProtocol> delegate;
@property (nonatomic, weak) id<TTBridgeEngine> engine;

+ (instancetype)sharedRegister;

- (void)registerMethod:(TTBridgeName)bridgeName
            engineType:(TTBridgeRegisterEngineType)engineType
              authType:(TTBridgeAuthType)authType
               domains:(NSArray<NSString *> *)domains;

- (void)registerMethod:(TTBridgeName)bridgeName
               handler:(nullable TTBridgeHandler)handler
            engineType:(TTBridgeRegisterEngineType)engineType
              authType:(TTBridgeAuthType)authType
               domains:(nullable NSArray<NSString *> *)domains;


- (BOOL)respondsToBridge:(TTBridgeName)bridgeName;
- (BOOL)respondsToBridge:(TTBridgeName)bridgeName engineType:(TTBridgeRegisterEngineType)engineType;
- (TTBridgeMethodInfo *)methodInfoForBridge:(TTBridgeName)bridgeName;
- (NSMutableArray *)privateBridgesOfDomain:(NSString *)domain;

- (void)registerBridge:(void(^)(TTBridgeRegisterMaker *maker))block;
- (void)unregisterBridge:(TTBridgeName)bridgeName;

- (void)executeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion;
- (void)executeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine completion:(TTBridgeCallback)completion preExecuteHander:(TTBridgePreExecuteHandler)handler;

#pragma mark - deprecated
- (BOOL)bridgeHasRegistered:(TTBridgeName)bridgeName __deprecated_msg("Use -[TTBridgeRegister respondsToBridge:");


/// If the engine has not only one interceptor, please use +[TTBridgeRegister addInterceptor:] to add interceptors.
@property(nonatomic, weak, class) id<TTBridgeInterceptor> interceptor;

+ (void)addInterceptor:(id<TTBridgeInterceptor>)interceptor;
+ (void)removeInterceptor:(id<TTBridgeInterceptor>)interceptor;

+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleGlobalBridgeCommand:(TTBridgeCommand *)command;
+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleLocalBridgeCommand:(TTBridgeCommand *)command;
+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willExecuteBridgeCommand:(TTBridgeCommand *)command;
+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldCallbackUnregisteredCommand:(TTBridgeCommand *)command;
+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willCallbackBridgeCommand:(TTBridgeCommand *)command;

@end

@protocol TTBridgeInterceptor <NSObject>

@optional
+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleGlobalBridgeCommand:(TTBridgeCommand *)command;
+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleLocalBridgeCommand:(TTBridgeCommand *)command;
+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willExecuteBridgeCommand:(TTBridgeCommand *)command;
+ (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldCallbackUnregisteredCommand:(TTBridgeCommand *)command;
+ (void)bridgeEngine:(id<TTBridgeEngine>)engine willCallbackBridgeCommand:(TTBridgeCommand *)command;

- (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleGlobalBridgeCommand:(TTBridgeCommand *)command;
- (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldHandleLocalBridgeCommand:(TTBridgeCommand *)command;
- (void)bridgeEngine:(id<TTBridgeEngine>)engine willExecuteBridgeCommand:(TTBridgeCommand *)command;
- (BOOL)bridgeEngine:(id<TTBridgeEngine>)engine shouldCallbackUnregisteredCommand:(TTBridgeCommand *)command;
- (void)bridgeEngine:(id<TTBridgeEngine>)engine willCallbackBridgeCommand:(TTBridgeCommand *)command;

@end



NS_ASSUME_NONNULL_END
