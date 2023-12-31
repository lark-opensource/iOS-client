//
//  BDXBridge.h
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXBridgeMethod;
@protocol BDXBridgeEngineProtocol;

typedef BOOL(^BDXBridgeMethodFilter)(BDXBridgeMethod *method);

@interface BDXBridge : NSObject

@property (nonatomic, strong, readonly) id<BDXBridgeEngineProtocol> engine;

@property (class, nonatomic, copy, readonly) NSDictionary<NSString *, BDXBridgeMethod *> *registeredGlobalMethods;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, BDXBridgeMethod *> *registeredLocalMethods;

/// Register the engine class used to power up the x-bridge.
/// @param engineClass The engine class which powers up the x-bridge.
/// @param inDevelopmentMode Indicate whether currently the app is running in development mode. BDXBridgeKit will register some additional bridge method in development mode to assist debugging.
/// @note The `Engine/TTBridgeUnifyAdapter` subspec has already provided a default engine class, just introduce it into your CocoaPods dependency.
+ (void)registerEngineClass:(Class<BDXBridgeEngineProtocol>)engineClass inDevelopmentMode:(BOOL)inDevelopmentMode;

+ (void)registerDefaultGlobalMethodsWithFilter:(nullable BDXBridgeMethodFilter)filter;

+ (void)registerGlobalMethod:(BDXBridgeMethod *)method;
+ (void)deregisterGlobalMethodNamed:(NSString *)methodName;

- (void)registerLocalMethod:(BDXBridgeMethod *)method;
- (void)deregisterLocalMethodNamed:(NSString *)methodName;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
